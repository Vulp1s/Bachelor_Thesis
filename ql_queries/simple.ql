// Quick database coverage check
import cpp

from File f
where
  f.getAbsolutePath().matches("%media%") and
  f.getExtension() = "c"
select f.getAbsolutePath()
