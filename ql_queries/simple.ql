import cpp

// Quick check: find all initializations of v4l2_ctrl_type_ops
from ClassAggregateLiteral init, Field f, Function target
where
  init.getType().getUnspecifiedType().(Struct).getName() = "v4l2_ctrl_type_ops" and
  f = init.getAFieldExpr(_).getTarget() and       // any field
  target.getAnAccess() = init.getAFieldExpr(f)
select
  init.getFile().getBaseName(),
  init.getLocation().getStartLine(),
  f.getName()              as field,
  target.getName()         as resolved_function
order by field
