import cpp
import hantro_lib

from Variable var, ClassAggregateLiteral init, Field f, Expr value, string assigned_impl
where
  // Set target struct (e.g., "v4l2_ctrl_ops")
  var.getType().getUnspecifiedType().(Struct).getName() in  ["v4l2_ctrl_type_ops","v4l2_subscribed_event_ops"] and
  
  init = var.getInitializer().getExpr() and
  value = init.getAFieldExpr(f) and
  
  // filter
  Hantro::isDriverFile(var.getFile()) and
  (
    (value instanceof FunctionAccess and 
     assigned_impl = value.(FunctionAccess).getTarget().getName())
    or
    (not value instanceof FunctionAccess and 
     assigned_impl = value.toString())
  )
select
  var.getFile().getBaseName() as file,
  var.getLocation().getStartLine() as line,
  var.getName() as instance_name,
  f.getName() as field_name,
  assigned_impl as assigned_implementation
order by
  file, instance_name, field_name
