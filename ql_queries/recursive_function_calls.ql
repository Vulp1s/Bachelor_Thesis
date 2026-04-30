import cpp
import hantro_lib

from Function entry, Function caller, Function reached, string section
where
  Hantro::isHantroIoctl(entry) and
  (caller = entry or Hantro::calls+(entry, caller)) and
  Hantro::calls(caller, reached) and
  Hantro::isDriverFile(caller.getFile()) and
  (
    Hantro::isDriverFile(reached.getFile()) and section = "1_driver"
    or
    not Hantro::isDriverFile(reached.getFile()) and section = "2_kernel"
  )
select
  section                            as scope,
  caller.getName()                   as caller_func,
  reached.getName()                  as called_func,
  reached.getFile().getBaseName()    as file
order by scope, caller_func
