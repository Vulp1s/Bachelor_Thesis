import cpp
import hantro_lib

from Function entry, Function caller, Function reached
where
  entry.getName() = "v4l_reqbufs" and
  (caller = entry or Hantro::calls+(entry, caller)) and
  Hantro::calls(caller, reached) and
  Hantro::isDriverFile(reached.getFile())
select
  caller.getName() as caller_func,
  reached.getName() as called_func,
  reached.getFile().getBaseName() as file
