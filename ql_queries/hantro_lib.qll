// hantro_lib.qll
import cpp

module Hantro {
  predicate isDriverFile(File f) {
    f.getAbsolutePath().matches("%videobuf2%") or
    f.getAbsolutePath().matches("%verisilicon%") or
    f.getAbsolutePath().matches("%hantro%")
  }

  predicate isDriverStruct(Struct s) {
    s.getName() in [
      "vb2_queue", "vb2_buffer", "vb2_v4l2_buffer",
      "hantro_ctx", "hantro_dev", "hantro_buf"
    ]
  }
}
