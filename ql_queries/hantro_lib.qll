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

  /**
   * Central registry of all ops structs and the function-pointer
   * fields we want to trace indirect calls through.
   * Add new (structName, fieldName) pairs here as you discover them.
   */
  predicate isTrackedOpsField(string structName, string fieldName) {
    // vb2_ops — driver-provided queue operations
    structName = "vb2_ops" and fieldName in [
      "queue_setup", "buf_init", "buf_prepare",
      "buf_finish", "buf_cleanup", "buf_queue",
      "buf_request_complete",
      "start_streaming", "stop_streaming",
      "wait_prepare", "wait_finish"
    ]
    or
    // hantro_codec_ops — per-codec hardware operations
    // e.g. rk3588_vpu981_codec_ops[HANTRO_MODE_AV1_DEC]
    structName = "hantro_codec_ops" and fieldName in [
      "run", "init", "exit", "done"
    ]
    or
    // vb2_mem_ops — memory allocator operations
    structName = "vb2_mem_ops" and fieldName in [
      "alloc", "put",
      "get_dmabuf",
      "attach_dmabuf", "detach_dmabuf",
      "map_dmabuf", "unmap_dmabuf",
      "prepare", "finish",
      "vaddr", "cookie", "num_users"
    ]
    or
    structName = "vb2_buf_ops" and fieldName in ["init_buffer"]
    or
    // v4l2_ioctl_ops — ioctl dispatch table
    structName = "v4l2_ioctl_ops" and fieldName in [
      "vidioc_querycap",
      "vidioc_g_fmt_vid_cap_mplane",
      "vidioc_g_fmt_vid_out_mplane",
      "vidioc_s_fmt_vid_cap_mplane",
      "vidioc_s_fmt_vid_out_mplane",
      "vidioc_try_fmt_vid_cap_mplane",
      "vidioc_try_fmt_vid_out_mplane",
      "vidioc_reqbufs", "vidioc_querybuf",
      "vidioc_qbuf",   "vidioc_dqbuf",
      "vidioc_streamon", "vidioc_streamoff",
      "vidioc_subscribe_event", "vidioc_unsubscribe_event"
    ]
    or
    // v4l2_m2m_ops — mem2mem framework callbacks
    structName = "v4l2_m2m_ops" and fieldName in [
      "device_run", "job_ready",
      "job_abort", "unlock", "lock"
    ]
    or
    // media_request_ops — request API
    structName = "media_request_ops" and fieldName in [
      "queue", "reinit"
    ]
    or
    // v4l2_ctrl_type_ops — per-control-type operations
    // accessed as ctrl->type_ops->op(...)
    structName = "v4l2_ctrl_type_ops" and fieldName in [
    "equal", "init", "log", "validate"
    ]
  }

  /** Convenience: does this Field match any tracked ops entry? */
  predicate isTrackedField(Field f) {
    exists(string sn, string fn |
      isTrackedOpsField(sn, fn) and
      f.getDeclaringType().getUnspecifiedType().(Struct).getName() = sn and
      f.getName() = fn
    )
  }
}
