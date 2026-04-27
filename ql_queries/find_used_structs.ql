import cpp
import hantro_lib

Struct getStructType(Type t) {
  result = t.getUnspecifiedType() or
  result = t.getUnspecifiedType().(PointerType).getBaseType().getUnspecifiedType() or
  result = t.getUnspecifiedType().(ReferenceType).getBaseType().getUnspecifiedType()
}

predicate modifiesStruct(Function f, Struct s) {
  exists(VariableAccess va |
    va.getEnclosingFunction() = f and
    s = getStructType(va.getTarget().getType()) and
    (
      va.isModified() or 
      exists(FieldAccess fa | fa.getQualifier() = va and fa.isModified())
    )
  )
}

predicate accessesStruct(Function f, Struct s) {
  exists(VariableAccess va |
    va.getEnclosingFunction() = f and
    s = getStructType(va.getTarget().getType())
  )
}

from 
  Function entry, Function caller, Function reached, 
  Struct s, string status
where
  entry.getName() = "v4l_reqbufs" and
  (caller = entry or Hantro::calls+(entry, caller)) and
  Hantro::calls(caller, reached) and
  Hantro::isDriverFile(reached.getFile()) and

  accessesStruct(reached, s) and

  if modifiesStruct(reached, s)
  then status = "Modified"
  else status = "Read-only"

select
  reached.getName() as func_name,
  s.getName() as struct_name,
  status,
  reached.getFile().getBaseName() as file
