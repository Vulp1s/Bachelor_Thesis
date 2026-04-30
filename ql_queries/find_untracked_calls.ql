import cpp
import hantro_lib

from Function entry, ExprCall c, Field f, Function impl
where
  Hantro::isHantroIoctl(entry) and
  Hantro::callsUnfilteredInDriver+(entry, c.getEnclosingFunction()) and
  Hantro::resolvesFunctionPointerCall(c,f,impl) and
  not Hantro::isTrackedOpsStruct(Hantro::fieldStructName(f))

select
  f.getDeclaringType().getName()     as ops_struct,
  f.getName()                        as field,
  c.getEnclosingFunction().getName() as called_from,
  c.getFile().getBaseName()          as file,
  c.getLocation().getStartLine()     as line,
  impl.getName()                     as implementation_func,
  impl.getFile().getBaseName()       as implementation_file,
  impl.getLocation().getStartLine()  as impl_line
