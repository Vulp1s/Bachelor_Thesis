import cpp
import hantro_lib

from Function entry, Function reached
where
  entry.getName() = "vb2_core_reqbufs" and
  Hantro::calls+(entry, reached) and     // transitive
  Hantro::isDriverFile(entry.getFile()) // tracks calls outside but not further
select
  reached.getName(),
  reached.getFile().getBaseName()
