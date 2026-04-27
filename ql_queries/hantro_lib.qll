// hantro_lib.qll
import cpp

module Hantro {
  predicate isDriverFile(File f) {
    exists(string path |
      path = f.getAbsolutePath() |
      path.matches("%drivers/media/v4l2-core%") or // v4l2-core
      path.matches("%videobuf2%") or // videobuf2
      path.matches("%verisilicon%") // decoder driver
    )
  }

  // we know where this struct is defined and which functions are used by av1 decoding
  predicate isTrackedOpsStruct(string structName) {
    structName in [
      "vb2_ops",
      "hantro_codec_ops",
      "vb2_mem_ops",
      "vb2_buf_ops",
      "v4l2_ioctl_ops",
      "v4l2_ctrl_ops",
      "v4l2_ctrl_type_ops",
      "v4l2_subscribed_event_ops",
      "v4l2_m2m_ops",
      "hantro_postproc_ops",
      "v4l2_subdev_video_ops",
      "v4l2_subdev_pad_ops"
    ]
  }

  predicate isActiveImplementation(Function f) {
    // vb2_ops — hantro_queue_ops (hantro_v4l2.c)
    f.getName() in [
      "hantro_queue_setup", //confirmed using kprobe
      "hantro_buf_prepare",
      "hantro_buf_queue",
      "hantro_buf_out_validate",
      "hantro_buf_request_complete",
      "hantro_start_streaming",
      "hantro_stop_streaming",
      "vb2_ops_wait_prepare",
      "vb2_ops_wait_finish"
    ]
    or
    // hantro_codec_ops — RK3588 AV1 only (rockchip_vpu981_hw_av1_dec.c)
    f.getName() in [
      "rockchip_vpu981_av1_dec_run",
      "rockchip_vpu981_av1_dec_init",
      "rockchip_vpu981_av1_dec_exit",
      "rockchip_vpu981_av1_dec_done"
    ]
    or
    // vb2_mem_ops — dma-contig only (videobuf2-dma-contig.c)
    // dma-sg and vmalloc implementations are excluded by omission
    f.getName() in [
      "vb2_dc_alloc", //confimed using kprobe
      "vb2_dc_put",
      "vb2_dc_get_dmabuf",
      "vb2_dc_cookie",
      "vb2_dc_vaddr",
      "vb2_dc_mmap",
      "vb2_dc_get_userptr",
      "vb2_dc_put_userptr",
      "vb2_dc_prepare",
      "vb2_dc_finish",
      "vb2_dc_map_dmabuf",
      "vb2_dc_unmap_dmabuf",
      "vb2_dc_attach_dmabuf",
      "vb2_dc_detach_dmabuf",
      "vb2_dc_num_users"
    ]
    or
    // vb2_buf_ops — v4l2_buf_ops (videobuf2-v4l2.c)
    f.getName() in [
      "__verify_planes_array_core",
      "__init_vb2_v4l2_buffer", //confirmed using kprobe
      "__fill_v4l2_buffer",
      "__fill_vb2_buffer",
      "__copy_timestamp"
    ]
    or
    // v4l2_ioctl_ops — hantro_ioctl_ops (hantro_v4l2.c)
    f.getName() in [
      "vidioc_querycap",
      "vidioc_enum_framesizes",
      "vidioc_try_fmt_cap_mplane",
      "vidioc_try_fmt_out_mplane",
      "vidioc_s_fmt_out_mplane",
      "vidioc_s_fmt_cap_mplane",
      "vidioc_g_fmt_out_mplane",
      "vidioc_g_fmt_cap_mplane",
      "vidioc_enum_fmt_vid_out",
      "vidioc_enum_fmt_vid_cap",
      "v4l2_m2m_ioctl_reqbufs",
      "v4l2_m2m_ioctl_querybuf",
      "v4l2_m2m_ioctl_qbuf",
      "v4l2_m2m_ioctl_dqbuf",
      "v4l2_m2m_ioctl_prepare_buf",
      "v4l2_m2m_ioctl_create_bufs",
      "v4l2_m2m_ioctl_remove_bufs",
      "v4l2_m2m_ioctl_expbuf",
      "v4l2_ctrl_subscribe_event",
      "v4l2_event_unsubscribe",
      "v4l2_m2m_ioctl_streamon",
      "v4l2_m2m_ioctl_streamoff",
      "vidioc_g_selection",
      "vidioc_s_selection",
      "v4l2_m2m_ioctl_stateless_decoder_cmd",
      "v4l2_m2m_ioctl_stateless_try_decoder_cmd",
      "v4l2_m2m_ioctl_try_encoder_cmd",
      "vidioc_encoder_cmd"
    ]
    or
    // v4l2_ctrl_ops -> hantro_av1_ctrl_ops in hantro_drv
    f.getName() in [
      "hantro_try_ctrl",
      "hantro_av1_s_ctrl"
      // g_volatile_ctrl is null
      ]
    or
    // v4l2_ctrl_type_ops in v4l2-ctrls-core
    f.getName() in [
      "v4l2_ctrl_type_op_equal",
      "v4l2_ctrl_type_op_init",
      "v4l2_ctrl_type_op_log",
      "v4l2_ctrl_type_op_validate"
      ]
    // v4l2_subscribed_event_ops is not triggered by simple decoding
    or 
    // v4l2_m2m_ops vpu_m2m_ops in hantro_drv.c
    f.getName() in [
      "device_run" // confirmed using kprobe
      // job_abort and job_ready are null
      ]
    or
    f.getName() in [
      "rockchip_vpu981_postproc_disable", //confirmed using kprobe
      "rockchip_vpu981_postproc_enable"
      ]
    // v4l2_subdev_video_ops is not reached 
    // v4l2_subdev_pad_ops is not reached
  }

  predicate resolvesTrackedOpsField(Field f, Function impl) {
    // struct is in our discovery list
    isTrackedOpsStruct(f.getDeclaringType().getUnspecifiedType().(Struct).getName()) and
    // implementation is on the active RK3588 AV1 path
    isActiveImplementation(impl) and
    // static resolution from initializer
    exists(ClassAggregateLiteral init |
      init.getType().getUnspecifiedType().(Struct).getName() =
        f.getDeclaringType().getUnspecifiedType().(Struct).getName() and
      impl.getAnAccess() = init.getAFieldExpr(f)
    )
  }

  predicate calls(Function caller, Function callee) {
    exists(Call c |
      c.getEnclosingFunction() = caller and
      callee = c.getTarget()
    )
    or
    exists(ExprCall c, PointerFieldAccess fa, Field f |
      c.getEnclosingFunction() = caller and
      fa = c.getExpr() and
      f = fa.getTarget() and
      resolvesTrackedOpsField(f, callee)
    )
  }
}
