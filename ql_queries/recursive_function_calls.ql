 import cpp
import hantro_lib


from Function entry, Function caller, Function reached, string section
where

  Hantro::isV4l2Ioctl(entry) and
  Hantro::calls*(entry, caller) and
  Hantro::calls(caller, reached) and
  Hantro::isSubsystemFile(caller.getFile()) and
  not reached.getName().matches("%compiletime_assert%") and

  (
    Hantro::isDriverFile(reached.getFile()) and section = "1_Driver"
    or
    Hantro::isSubsystemFile(reached.getFile()) and section = "2_SubSystem"
    or
    not Hantro::isSubsystemFile(reached.getFile()) and section = "3_kernel"
  )

select
  section                            as scope,
  caller.getName()                   as caller_func,
  reached.getName()                  as called_func,
  reached.getFile().getBaseName()    as file,
  concat(entry.getName(), ", ") as ioctl_list
order by scope 
