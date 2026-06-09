import cpp
import hantro_lib

from Function entry, ExprCall c, Field f, Function callee
where
  Hantro::isV4l2Ioctl(entry) and
  Hantro::callsUnfiltered*(entry, c.getEnclosingFunction()) and
  (
    Hantro::resolvesFunctionPointerCall(c, f, callee)
    or
    Hantro::resolvesTwoLevelOpsCall(c, f, callee) 
  ) and
  not Hantro::isTrackedOpsStruct(Hantro::fieldStructName(f))
select
  f.getDeclaringType().getName() as ops_struct,
  f.getName() as field,
  c.getEnclosingFunction().getName() as called_from,
  c.getFile().getBaseName() as file,
  c.getLocation().getStartLine() as line,
  callee.getName() as implementation_func
order by ops_struct, field
