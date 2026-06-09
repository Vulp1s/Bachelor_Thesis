/**
 * Hantro driver — complete kernel/driver boundary taint analysis
 *
 * Three crossing patterns unified into one select:
 *
 *   D→K  : driver passes a driver-struct pointer into a kernel function;
 *           kernel code then accesses fields of that struct.
 *
 *   K→D  : kernel calls a driver callback with a kernel-struct pointer
 *           (vb2_ops, v4l2_ioctl_ops, …); driver code then accesses
 *           fields of that struct.
 *
 *   DQ→K : driver actively queries the kernel (e.g. hantro_get_ctrl)
 *           and receives a kernel-struct pointer back; driver code then
 *           accesses fields of that struct.
 *           These are NOT reachable via isReachableFromIoctl because the
 *           caller chain stays inside driver files — they require their
 *           own bounding.
 */

import cpp
import semmle.code.cpp.ir.dataflow.DataFlow
import semmle.code.cpp.ir.dataflow.TaintTracking
import hantro_lib

// ============================================================
// Bounding
// ============================================================

/**
 * Functions directly involved in the ioctl-driven call tree:
 * either a subsystem function reached from an ioctl entry point,
 * or a function called by such a subsystem function.
 * Keeps D→K and K→D analysis to ~20 s.
 */
cached
predicate isReachableFromIoctl(Function f) {
  exists(Function entry, Function caller, Function reached |
    Hantro::isV4l2Ioctl(entry)            and
    Hantro::calls*(entry, caller)          and
    Hantro::calls(caller, reached)         and
    Hantro::isSubsystemFile(caller.getFile()) and
    (f = caller or f = reached)
  )
}

// ============================================================
// Struct helpers
// ============================================================

private predicate isDriverFile(File f) { Hantro::isDriverFile(f) }

bindingset[t]
private Struct resolveStruct(Type t) {
  result = t.getUnspecifiedType()
  or result = t.getUnspecifiedType().(PointerType).getBaseType().getUnspecifiedType()
  or result = t.getUnspecifiedType().(ReferenceType).getBaseType().getUnspecifiedType()
}

private predicate isDriverStruct(Struct s) {
  isDriverFile(s.getFile()) and not s.getName() = ""
}

private predicate isKernelStruct(Struct s) {
  not isDriverFile(s.getFile()) and
  not s.getName() = "" and
  (
    s.getFile().getAbsolutePath().matches("%/include/%") or
    Hantro::isSubsystemFile(s.getFile())
  )
}

// ============================================================
// Shared flow steps
// ============================================================

private predicate sharedFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
  // ptr ~~> ptr->field
  exists(FieldAccess fa |
    n1.asExpr() = fa.getQualifier() and
    n2.asExpr() = fa
  )
  or
  // function-pointer dispatch (resolved statically by hantro_lib)
  exists(ExprCall c, Function callee, int i |
    Hantro::resolvesFunctionPointerCall(c, _, callee) and
    n1.asExpr()      = c.getArgument(i)       and
    n2.asParameter() = callee.getParameter(i)
  )
  or
  // container_of: structural StmtExpr navigation avoids
  // getAnExpandedElement() cartesian-product explosion.
  // container_of(ptr, T, member) expands to:
  //   ({ typeof(ptr) __mptr = (void*)(ptr);
  //      (T*)((char*)__mptr - offsetof(T, member)); })
  exists(
    MacroInvocation mi, StmtExpr se, BlockStmt blk,
    DeclStmt ds, Variable mptr, Expr ptrArg
  |
    mi.getMacroName()    = "container_of" and
    mi.getExpr()         = se             and
    se.getStmt()         = blk            and
    blk.getStmt(0)       = ds             and
    ds.getADeclaration() = mptr           and
    mptr.getName().matches("__mptr%")     and
    (
      ptrArg = mptr.getInitializer().getExpr().(Cast).getExpr()
      or
      ptrArg = mptr.getInitializer().getExpr() and
      not mptr.getInitializer().getExpr() instanceof Cast
    ) and
    n1.asExpr() = ptrArg and
    n2.asExpr() = se
  )
  or
  // All call arguments flow into the callee (generic; replaces
  // the explicit bridge-function allowlist so the query works
  // on any subsystem, not just Hantro).
  exists(FunctionCall call |
    n1.asExpr() = call.getAnArgument() and
    n2.asExpr() = call
  )
  or
  // v4l2_ctrl union pointer propagation:
  // ctrl->p_<codec> (a v4l2_ctrl_ptr field) carries codec-specific
  // structs (v4l2_ctrl_av1_frame, v4l2_ctrl_hevc_sps, …).
  // Without this step those types are invisible to taint tracking.
  exists(FieldAccess outer, FieldAccess inner |
    outer.getQualifier() = n1.asExpr()                      and
    (
      outer.getTarget().getName().matches("p_%") or
      outer.getTarget().getName() = "controls"
    ) and
    inner.getQualifier() = outer                            and
    n2.asExpr() = inner
  )
}

// ============================================================
// Config D→K : driver struct passed into kernel, kernel reads/writes it
// ============================================================

module D2KConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    exists(Call call, Function caller, Function callee |
      call.getTarget()              = callee                    and
      call.getEnclosingFunction()   = caller                   and
      isDriverFile(caller.getFile())                           and
      not isDriverFile(callee.getFile())                       and
      isReachableFromIoctl(caller)                             and
      source.asExpr()               = call.getAnArgument()    and
      isDriverStruct(resolveStruct(call.getAnArgument().getType()))
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FieldAccess fa |
      sink.asExpr() = fa                                        and
      not isDriverFile(fa.getEnclosingFunction().getFile())    and
      isReachableFromIoctl(fa.getEnclosingFunction())          and
      isDriverStruct(resolveStruct(fa.getQualifier().getType()))
    )
  }

  predicate isAdditionalFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
    sharedFlowStep(n1, n2)
  }
}
module D2KFlow = TaintTracking::Global<D2KConfig>;

// ============================================================
// Config K→D : kernel passes kernel struct into driver callback
// ============================================================

module K2DConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    exists(Function kernelCaller, Function driverCallee, Parameter p |
      Hantro::callsUnfiltered(kernelCaller, driverCallee)      and
      not isDriverFile(kernelCaller.getFile())                 and
      isDriverFile(driverCallee.getFile())                     and
      isReachableFromIoctl(driverCallee)                       and
      p                  = driverCallee.getAParameter()        and
      source.asParameter() = p                                 and
      isKernelStruct(resolveStruct(p.getType()))
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FieldAccess fa |
      sink.asExpr() = fa                                        and
      isDriverFile(fa.getEnclosingFunction().getFile())        and
      isReachableFromIoctl(fa.getEnclosingFunction())          and
      isKernelStruct(resolveStruct(fa.getQualifier().getType()))
    )
  }

  predicate isAdditionalFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
    sharedFlowStep(n1, n2)
  }
}
module K2DFlow = TaintTracking::Global<K2DConfig>;

// ============================================================
// Config DQ→K : driver actively queries kernel, receives kernel
//               struct pointer back, then accesses its fields.
//               (e.g. hantro_get_ctrl → v4l2_ctrl_av1_frame*)
//               No isReachableFromIoctl needed: bounding is
//               implicit — source must be a kernel-function return
//               value used inside driver code.
// ============================================================

module DQConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    exists(FunctionCall call, Function kernelFunc |
      call.getTarget()            = kernelFunc                 and
      not isDriverFile(kernelFunc.getFile())                   and
      isDriverFile(call.getEnclosingFunction().getFile())      and
      isKernelStruct(resolveStruct(call.getType()))            and
      isReachableFromIoctl(kernelFunc) and
      source.asExpr()             = call
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FieldAccess fa |
      sink.asExpr() = fa                                        and
      isDriverFile(fa.getEnclosingFunction().getFile())        and
      isKernelStruct(resolveStruct(fa.getQualifier().getType()))
    )
  }

  predicate isAdditionalFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
    sharedFlowStep(n1, n2)
  }
}
module DQFlow = TaintTracking::Global<DQConfig>;

// ============================================================
// Unified select
// ============================================================

from
  DataFlow::Node source,
  DataFlow::Node sink,
  string         direction,
  FieldAccess    fa,
  Struct         touchedStruct,
  string         accessType

where
  // ── All three patterns in one disjunction ─────────────────────────
  (
    ( D2KFlow::flow(source, sink) and direction = "Driver → Kernel"       )
    or
    ( K2DFlow::flow(source, sink) and direction = "Kernel → Driver"       )
    or
    ( DQFlow::flow(source, sink)  and direction = "Driver query → Kernel" )
  ) and
  // ── Common conditions ─────────────────────────────────────────────
  fa           = sink.asExpr()                                            and
  touchedStruct = resolveStruct(fa.getQualifier().getType())              and
  not touchedStruct.getName() = ""                                        and
  (
    fa.isModified() and accessType = "Write"
    or
    not fa.isModified() and accessType = "Read"
  ) and
  // ── Noise filters ─────────────────────────────────────────────────
  not sink.getFunction().getName().matches("trace_%")                     and
  not sink.getFunction().getName().matches("__traceiter_%")

select
  direction                                       as flow_direction,
  source.getFunction().getName()                  as source_function,
  sink.getFunction().getName()                    as sink_function,
  touchedStruct.getName()                         as struct_name,
  accessType                                      as access_type,
  sink.getFunction().getFile().getBaseName()      as file
order by flow_direction, struct_name, source_function
