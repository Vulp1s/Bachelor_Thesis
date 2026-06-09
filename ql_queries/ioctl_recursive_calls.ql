import cpp
import hantro_lib

/**
 * A helper predicate to establish the link between an ioctl and the target function.
 */
predicate ioctlReaches(Function entry,Function caller, Function reached, string section) {
  Hantro::isV4l2Ioctl(entry) and
    Hantro::calls*(entry, caller) and
    Hantro::calls(caller, reached) and
    Hantro::isSubsystemFile(caller.getFile()) and
  (
    Hantro::isDriverFile(reached.getFile()) and section = "1_Driver"
    or
    Hantro::isSubsystemFile(reached.getFile()) and section = "2_SubSystem"
    or
    not Hantro::isSubsystemFile(reached.getFile()) and section = "3_kernel"
  )
  and  not reached.getName().matches("%compiletime_assert%")
}

from Function reached, string section, Function caller
where
ioctlReaches(_,caller, reached, section) and
((Hantro::isDriverFile(caller.getFile()) and not Hantro::isDriverFile(reached.getFile())) or 
 (Hantro::isDriverFile(reached.getFile()) and not Hantro::isDriverFile(caller.getFile())))

select
  caller.getFile().getBaseName() as caller_file,
  section as core_scope,
  count(Function entry | ioctlReaches(entry, caller, reached, section)) as unique_ioctls_calling_this,
  concat(Function entry | ioctlReaches(entry,caller, reached, section) | entry.getName(), ", ") as ioctl_list,
  reached.getFile().getBaseName() as called_file
order by unique_ioctls_calling_this desc
