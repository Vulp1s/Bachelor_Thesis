import cpp
import hantro_lib

from FieldAccess fa, Field f, Struct s
where
  f = fa.getTarget() and
  s = f.getDeclaringType() and
  Hantro::isDriverStruct(s) and
  fa.isModified() and                          // writes only
  not Hantro::isDriverFile(fa.getFile())               // from outside driver
select fa, s.getName() + "::" + f.getName(),
       "kernel writes this driver field"
