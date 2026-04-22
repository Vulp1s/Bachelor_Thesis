// hantro_lib.qll
import cpp

module Hantro {
  predicate isDriverFile(File f) {
  exists(string path | 
    path = f.getAbsolutePath() |
    path.matches("%drivers/media%")        or  // all media drivers
    path.matches("%include/media%")        or  // media headers
    path.matches("%include/linux/videodev2%")  // uapi (optional)
  )
  }

  predicate isDriverStruct(Struct s) {
    s.getName() in [
      "vb2_queue", "vb2_buffer", "vb2_v4l2_buffer",
      "hantro_ctx", "hantro_dev", "hantro_buf"
    ]
  }

  predicate isActiveImpl(Field f, Function impl) {
    // mem_ops: only dma-contig, not dma-sg or vmalloc
    f.getDeclaringType().getName() = "vb2_mem_ops" and
    impl.getFile().getBaseName() = "videobuf2-dma-contig.c"
    or
    // codec_ops: only av1, not other decoders
    f.getDeclaringType().getName() = "hantro_codec_ops" and
    impl.getFile().getBaseName() = "rockchip_vpu981_hw_av1_dec.c"
    or
    // all other tracked structs: no restriction on impl file
    not f.getDeclaringType().getName() in [
      "vb2_mem_ops", "hantro_codec_ops"
    ]
  }

  predicate isImplementedOpsField(string structName, string fieldName) {
    // vb2_ops — hantro_queue_ops in hantro_v4l2.c
    structName = "vb2_ops" and fieldName in [
      "queue_setup", "buf_prepare", "buf_queue",
      "buf_request_complete", "buf_out_validate",
      "start_streaming", "stop_streaming",
      "wait_prepare", "wait_finish"
    ]
    or
    // hantro_codec_ops - rk3036_vpu_codec_ops in rockchip_vpu_hw.c
    structName = "hantro_codec_ops" and fieldName in [
      "run", "init", "exit", "reset"
    ]
    or
    // vb2_mem_ops — vb2_dma_contig_memops in videobuf2-dma-contig.c
    structName = "vb2_mem_ops" and fieldName in [
      "alloc", "put", "get_dmabuf", "cookie", "vaddr", "mmap",
      "get_userptr", "put_userptr", "prepare", "finish",
      "map_dmabuf", "unmap_dmabuf", "attach_dmabuf", "detach_dmabuf",
      "num_users"
    ]
    or
    // vb2_buf_ops - v4l2_buf_ops in videobuf2-v4l2.c
    structName = "vb2_buf_ops" and fieldName in [
      "verify_planes_array", "init_buffer", "fill_user_buffer",
      "fill_vb2_buffer", "copy_timestamp"
    ]
    or
    // v4l2_ioctl_ops — hantro_ioctl_ops
    structName = "v4l2_ioctl_ops" and fieldName in [
      "vidioc_querycap", "vidioc_enum_framesizes",
      "vidioc_try_fmt_vid_cap_mplane", "vidioc_try_fmt_vid_out_mplane",
      "vidioc_s_fmt_vid_out_mplane", "vidioc_s_fmt_vid_cap_mplane",
      "vidioc_g_fmt_vid_out_mplane", "vidioc_g_fmt_vid_cap_mplane",
      "vidioc_enum_fmt_vid_out", "vidioc_enum_fmt_vid_cap",
      "vidioc_reqbufs", "vidioc_querybuf", "vidioc_qbuf", "vidioc_dqbuf",
      "vidioc_prepare_buf", "vidioc_create_bufs", "vidioc_remove_bufs",
      "vidioc_expbuf", "vidioc_subscribe_event", "vidioc_unsubscribe_event",
      "vidioc_streamon", "vidioc_streamoff", "vidioc_g_selection",
      "vidioc_s_selection", "vidioc_decoder_cmd", "vidioc_try_decoder_cmd",
      "vidioc_try_encoder_cmd", "vidioc_encoder_cmd"
    ]
  }

  /** Convenience: does this Field match any tracked ops entry? */
  predicate isImplementedField(Field f) {
    exists(string sn, string fn |
      isImplementedOpsField(sn, fn) and
      f.getDeclaringType().getUnspecifiedType().(Struct).getName() = sn and
      f.getName() = fn
    )
  }

  predicate resolvesOpsField(Field f, Function impl) {
    isImplementedField(f) and
    isActiveImpl(f, impl) and
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
      resolvesOpsField(f, callee)
    )
  }
}
