import cpp
import hantro_lib

// All ExprCalls reachable from an ioctl entry point
// whose field is NOT yet in isImplementedOpsField
from Function entry, ExprCall c, PointerFieldAccess fa, Field f
where
  entry.getName() in [
    "v4l2_m2m_ioctl_reqbufs"
  ] and
  // c is reachable from entry (use your calls+ relation)
  Hantro::calls+(entry, c.getEnclosingFunction()) and
  fa = c.getExpr() and
  f = fa.getTarget() and
  // NOT already tracked
  not Hantro::isImplementedOpsField(
    f.getDeclaringType().getUnspecifiedType().(Struct).getName(),
    f.getName()
  )
select
  f.getDeclaringType().getName()  as ops_struct,
  f.getName()                     as field,
  c.getEnclosingFunction().getName() as called_from,
  c.getFile().getBaseName()       as file,
  c.getLocation().getStartLine()  as line
order by ops_struct, field
