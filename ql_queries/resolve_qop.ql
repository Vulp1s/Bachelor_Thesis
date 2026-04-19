import cpp
import hantro_lib

/**
 * Find all function-pointer assignments across every tracked ops struct.
 * Covers both static initializers and dynamic assignments.
 */
from Field f, Function target, Expr assignSite, string kind
where
  Hantro::isTrackedField(f) and
  (
    // Static initializer:  .queue_setup = hantro_queue_setup
    exists(ClassAggregateLiteral init |
      assignSite = init and
      kind = "static init" and
      target.getAnAccess() = init.getAFieldExpr(f)
    )
    or
    // Dynamic assignment: ops->device_run = hantro_device_run
    exists(Assignment assign, FieldAccess lhs |
      assignSite = assign and
      kind = "dynamic assign" and
      lhs = assign.getLValue() and
      f = lhs.getTarget() and
      target.getAnAccess() = assign.getRValue()
    )
  )
select
  f.getDeclaringType().getName() as ops_struct,
  f.getName()                    as field,
  target.getName()               as resolved_function,
  assignSite.getFile().getBaseName() as defined_in,
  assignSite.getLocation().getStartLine() as line,
  kind
order by ops_struct, field
