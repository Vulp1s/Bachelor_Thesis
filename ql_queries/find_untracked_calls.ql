import cpp
import hantro_lib

from Function entry, ExprCall c, PointerFieldAccess fa, Field f, ClassAggregateLiteral init, Function impl
where
  entry.getName() in [
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
    ] and
  Hantro::calls+(entry, c.getEnclosingFunction()) and
  fa = c.getExpr() and
  f = fa.getTarget() and
  // find resulting function
  init.getType().getUnspecifiedType().(Struct).getName() = 
    f.getDeclaringType().getUnspecifiedType().(Struct).getName() and
  impl.getAnAccess() = init.getAFieldExpr(f) and
  // filter
  Hantro::isDriverFile(c.getFile()) and 
  (
    not Hantro::isTrackedOpsStruct(
    f.getDeclaringType().getUnspecifiedType().(Struct).getName()) 
    //or
    //not exists(Function impl | Hantro::resolvesTrackedOpsField(f, impl))
  )
select
  f.getDeclaringType().getName()      as ops_struct,
  f.getName()                         as field,
  c.getEnclosingFunction().getName()  as called_from,
  c.getFile().getBaseName()           as file,
  c.getLocation().getStartLine()      as line,
  impl.getName() as implementation_func,
  impl.getFile().getBaseName() as implementation_file,
  impl.getLocation().getStartLine() as impl_line
