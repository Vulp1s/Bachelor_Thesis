import cpp
import hantro_lib

string getDomain(File f) {
  if Hantro::isDriverFile(f) then result = "Driver" else result = "Kernel"
}
Struct getStructType(FieldAccess fa) {
  result = fa.getTarget().getDeclaringType().getUnspecifiedType()
}

string getAccessType(Function f, Struct s) {
  // Ensure the struct is actually accessed in this function
  exists(FieldAccess fa | fa.getEnclosingFunction() = f and getStructType(fa) = s) and
  
  if exists(FieldAccess fa | 
    fa.getEnclosingFunction() = f and 
    getStructType(fa) = s and 
    fa.isModified()
  )
  then result = "Modified"
  else result = "Read-only"
}

from
  Function entry, 
  Function reached,
  Struct s, 
  string direction, 
  string accessType
where
  Hantro::isV4l2Ioctl(entry) and
  Hantro::calls*(entry, reached) and
  not s.getName() = "" and

  exists(string funcDomain, string structDomain |
    funcDomain = getDomain(reached.getFile()) and
    structDomain = getDomain(s.getFile()) and
    funcDomain != structDomain and
    direction = funcDomain + " -> " + structDomain
  ) and
  accessType = getAccessType(reached, s)

select
  s.getName() as struct_name,
  accessType as access_type
