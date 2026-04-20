import cpp

from ClassAggregateLiteral init
where
  init.getType().getUnspecifiedType().(Struct).getName() = 
    "v4l2_subscribed_event_ops"
select
  init.getFile().getAbsolutePath(),
  init.getLocation().getStartLine()
