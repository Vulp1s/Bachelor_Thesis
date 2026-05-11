import cpp
import hantro_lib

bindingset[t]
Struct getStructType(Type t) {
  result = t.getUnspecifiedType() or
  result = t.getUnspecifiedType().(PointerType).getBaseType().getUnspecifiedType() or
  result = t.getUnspecifiedType().(ReferenceType).getBaseType().getUnspecifiedType()
}

predicate structAccess(Function f, Struct s, string status) {
  status = max(string st |
    exists(VariableAccess va |
      va.getEnclosingFunction() = f and
      s = getStructType(va.getTarget().getType()) and
      ((
          va.isModified() or
          exists(FieldAccess fa | fa.getQualifier() = va and fa.isModified())
        ) and st = "Modified"
        or
        not (
          va.isModified() or
          exists(FieldAccess fa | fa.getQualifier() = va and fa.isModified())
        ) and st = "Read-only"
      ))
  | st)
}

predicate isDriverStruct(Struct s) {
  Hantro::isDriverFile(s.getFile())
}

predicate isKernelStruct(Struct s) {
  not isDriverStruct(s) and
  // exclude anonymous/compiler-generated structs
  not s.getName() = "" and
  s.getFile().getAbsolutePath().matches("%/include/%")
}


string structOrigin(Struct s) {
  isDriverStruct(s) and result = "driver"
  or
  isKernelStruct(s) and result = "kernel"
  or
  not isKernelStruct(s) and result = "other"
}

from
  Function entry, Function caller, Function reached,
  Struct s, string status, string origin
where
  entry.getName() = "v4l_reqbufs" and
  (caller = entry or Hantro::calls+(entry, caller)) and
  Hantro::calls(caller, reached) and
  Hantro::isDriverFile(reached.getFile()) and
  structAccess(reached, s, status) and
  origin = structOrigin(s) and
  // exclude anonymous structs and noise
  not s.getName() = ""
select
  reached.getName()            as func_name,
  s.getName()                  as struct_name,
  origin                       as struct_origin,
  status                       as access_type,
  reached.getFile().getBaseName() as file
order by struct_origin, func_name, struct_name
