ioctl_call label="ioctl(fd, VIDIOC_REQBUFS, p)"
# structs
## v4l2_ioctl_ops 
implemented by hantro_ioctl_ops
## vb2_buffer
### vb2_queue
- is part of vb2_buffer
# kernel
## iminor
static inline unsigned iminor(const struct inode *inode)
Structs:
- inode read
## file_inode
static inline struct inode *file_inode(const struct file *f)
structs:
- file read
## memset_after (makro)
calls:
- typeof
- memset
## bitmap_weight
## mutex_lock
## kzalloc
slab.h
# v4l2 ioctl
## v4l_reqbufs
static int v4l_reqbufs(const struct v4l2_ioctl_ops *ops, struct file *file, void *fh, void *arg)

Structs:
- v4l2_ioctl_ops read
- file argument
- video_device create
- v4l2_requestbuffers create

calls:
- video_devdata
- check_fmt
- memset_after
- is_valid_ioctl (macro)
indirect:
- v4l2_ioctl_ops->vidioc_reqbufs calls v4l2_m2m_ioctl_reqbufs
## check_fmt
static int check_fmt(struct file *file, enum v4l2_buf_type type)

Structs:
- file
- video_device
- v4l2_ioctl_ops

calls:
- video_devdata
indirect:
- ops->vidioc_g_fmt_vid_cap: NULL
- ops->vidioc_g_fmt_vid_cap_mplane: calls vidioc_g_fmt_cap_mplane
- ops->vidioc_g_fmt_vid_overlay: NULL
- ops->vidioc_g_fmt_vid_out: NULL
- ops->vidioc_g_fmt_vid_out_mplane: calls vidioc_g_fmt_out_mplane
- ops->vidioc_g_fmt_vid_out_overlay: NULL
- ops->vidioc_g_fmt_vbi_cap: NULL
- ops->vidioc_g_fmt_vbi_out: NULL
- ops->vidioc_g_fmt_sliced_vbi_cap: NULL
- ops->vidioc_g_fmt_sliced_vbi_out: NULL
- ops->vidioc_g_fmt_sdr_cap: NULL
- ops->vidioc_g_fmt_sdr_out: NULL
- ops->vidioc_g_fmt_meta_cap: NULL
- ops->vidioc_g_fmt_meta_out: NULL

# Other v4l2
## video_devdata
struct video_device *video_devdata(struct file *file)
Structs:
- file argument
calls:
- file_inode
- iminor

# vpu981_hw_av1_dec

## rockchip_vpu981_av1_dec_exit
void rockchip_vpu981_av1_dec_exit(struct hantro_ctx *ctx)

structs:
- struct hantro_ctx: read
- struct hantro_dev: read (ctx->dev)
- struct hantro_av1_dec_hw_ctx: read/write (ctx->av1_dec)
- struct hantro_aux_buf: read/write (nested members like global_model, tile_info, etc.)

calls:
- dma_free_coherent
- rockchip_vpu981_av1_dec_tiles_free

## rockchip_vpu981_av1_dec_tiles_free
static void rockchip_vpu981_av1_dec_tiles_free(struct hantro_ctx *ctx)

structs:
- struct hantro_ctx: read
- struct hantro_dev: read (ctx->dev)
- struct hantro_av1_dec_hw_ctx: read/write (ctx->av1_dec)
- struct hantro_aux_buf: read/write (nested members like db_data_col, cdef_col, etc.)

calls:
- dma_free_coherent

# Hantro
## v4l2_ioctl_ops
const struct v4l2_ioctl_ops hantro_ioctl_ops = {

calls:
- v4l2_m2m_ioctl_reqbufs

## vidioc_g_fmt_out_mplane
static int vidioc_g_fmt_out_mplane(struct file *file, void *priv, struct v4l2_format *f)
structs:
- file unused
- v4l2_format read
- v4l2_pix_format_mplane write
- hantro_ctx created
calls:
fh_to_ctx

## vidioc_g_fmt_out_mplane
static int vidioc_g_fmt_out_mplane(struct file *file, void *priv, struct v4l2_format *f)

structs:
- struct v4l2_format: write
- struct v4l2_pix_format_mplane: write (via f->fmt.pix_mp)
- struct hantro_ctx: read

calls:
- fh_to_ctx
- vpu_debug
## fh_to_ctx
static __always_inline struct hantro_ctx *fh_to_ctx(struct v4l2_fh *fh)
structs:
- v4l2_fh upcast into hantro_ctx
## hantro_stop_streaming
static void hantro_stop_streaming(struct vb2_queue *q)

structs:
- struct vb2_queue: read
- struct hantro_ctx: read/write
- struct hantro_codec_ops: read
- struct v4l2_fh: read (ctx->fh)
- struct v4l2_m2m_ctx: read/write (ctx->fh.m2m_ctx)

calls:
- vb2_get_drv_priv
- hantro_vq_is_coded
- hantro_postproc_free
- V4L2_TYPE_IS_OUTPUT
- hantro_return_bufs
- v4l2_m2m_src_buf_remove
- v4l2_m2m_dst_buf_remove
- v4l2_m2m_update_stop_streaming_state
- v4l2_m2m_has_stopped
- v4l2_event_queue_fh
indirect:
- ctx->codec_ops->exit calls rockchip_vpu981_av1_dec_exit defined at hantro_codec_ops rk3588_vpu981_codec_ops[] 

## hantro_return_bufs
static void hantro_return_bufs(struct vb2_queue *q, struct vb2_v4l2_buffer *(*buf_remove)(struct v4l2_m2m_ctx *))
structs:
- vb2_queue argument
- vb2_v4l2_buffer
calls:
- vb2_get_drv_priv
- v4l2_ctrl_request_complete
- v4l2_m2m_buf_done

# v4l2-ctrls-core
## handler_new_ref
int handler_new_ref(struct v4l2_ctrl_handler *hdl, struct v4l2_ctrl *ctrl, struct v4l2_ctrl_ref **ctrl_ref, bool from_other_dev, bool allocate_req)

structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl: read/write
- struct v4l2_ctrl_ref: read/write/create

calls:
- V4L2_CTRL_ID2WHICH
- find_ref_lock
- v4l2_ctrl_new_std
- kzalloc
- handler_set_err
- INIT_LIST_HEAD
- mutex_lock
- list_empty
- node2id
- list_add_tail
- list_for_each_entry
- kfree
- list_add
- mutex_unlock

## v4l2_ctrl_new_std
struct v4l2_ctrl *v4l2_ctrl_new_std(struct v4l2_ctrl_handler *hdl, const struct v4l2_ctrl_ops *ops, u32 id, s64 min, s64 max, u64 step, s64 def)

structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl_ops: read
- struct v4l2_ctrl: create

calls:
- v4l2_ctrl_fill
- handler_set_err
- v4l2_ctrl_new

## v4l2_ctrl_new
static struct v4l2_ctrl *v4l2_ctrl_new(struct v4l2_ctrl_handler *hdl, const struct v4l2_ctrl_ops *ops, const struct v4l2_ctrl_type_ops *type_ops, u32 id, const char *name, enum v4l2_ctrl_type type, s64 min, s64 max, u64 step, s64 def, const u32 dims[V4L2_CTRL_MAX_DIMS], u32 elem_size, u32 flags, const char * const *qmenu, const s64 *qmenu_int, const union v4l2_ctrl_ptr p_def, void *priv)

structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl: read/write/create
- struct v4l2_ctrl_ops: read
- struct v4l2_ctrl_type_ops: read
- struct v4l2_ctrl_mpeg2_sequence: read (sizeof)
- struct v4l2_ctrl_mpeg2_picture: read (sizeof)
- struct v4l2_ctrl_mpeg2_quantisation: read (sizeof)
- struct v4l2_ctrl_fwht_params: read (sizeof)
- struct v4l2_ctrl_h264_sps: read (sizeof)
- struct v4l2_ctrl_h264_pps: read (sizeof)
- struct v4l2_ctrl_h264_scaling_matrix: read (sizeof)
- struct v4l2_ctrl_h264_slice_params: read (sizeof)
- struct v4l2_ctrl_h264_decode_params: read (sizeof)
- struct v4l2_ctrl_h264_pred_weights: read (sizeof)
- struct v4l2_ctrl_vp8_frame: read (sizeof)
- struct v4l2_ctrl_hevc_sps: read (sizeof)
- struct v4l2_ctrl_hevc_pps: read (sizeof)
- struct v4l2_ctrl_hevc_slice_params: read (sizeof)
- struct v4l2_ctrl_hevc_scaling_matrix: read (sizeof)
- struct v4l2_ctrl_hevc_decode_params: read (sizeof)
- struct v4l2_ctrl_hdr10_cll_info: read (sizeof)
- struct v4l2_ctrl_hdr10_mastering_display: read (sizeof)
- struct v4l2_ctrl_vp9_compressed_hdr: read (sizeof)
- struct v4l2_ctrl_vp9_frame: read (sizeof)
- struct v4l2_ctrl_av1_sequence: read (sizeof)
- struct v4l2_ctrl_av1_tile_group_entry: read (sizeof)
- struct v4l2_ctrl_av1_frame: read (sizeof)
- struct v4l2_ctrl_av1_film_grain: read (sizeof)
- struct v4l2_area: read (sizeof)
- union v4l2_ctrl_ptr: read

calls:
- handler_set_err
- check_range
- kvzalloc
- INIT_LIST_HEAD
- memcpy
- kvfree
- cur_to_new
- handler_new_ref
- mutex_lock
- list_add_tail
- mutex_unlock
indirect:
- ctrl->type_ops->init (indirect call)

## check_range
int check_range(enum v4l2_ctrl_type type, s64 min, s64 max, u64 step, s64 def)

structs:
- None (Operates on primitive types and enums)

calls:
- BIT_ULL

## handler_set_err
static inline int handler_set_err(struct v4l2_ctrl_handler *hdl, int err)

structs:
- struct v4l2_ctrl_handler: read/write

calls:
- None

## find_ref_lock
struct v4l2_ctrl_ref *find_ref_lock(struct v4l2_ctrl_handler *hdl, u32 id)

structs:
- struct v4l2_ctrl_handler: read
- struct v4l2_ctrl_ref: read

calls:
- mutex_lock
- find_ref
- mutex_unlock

## find_ref
struct v4l2_ctrl_ref *find_ref(struct v4l2_ctrl_handler *hdl, u32 id)

structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl_ref: read
- struct v4l2_ctrl: read

calls:
- find_private_ref

## find_private_ref
static struct v4l2_ctrl_ref *find_private_ref(struct v4l2_ctrl_handler *hdl, u32 id)

structs:
- struct v4l2_ctrl_handler: read
- struct v4l2_ctrl_ref: read
- struct v4l2_ctrl: read

calls:
- list_for_each_entry
- V4L2_CTRL_ID2WHICH
- V4L2_CTRL_DRIVER_PRIV

## v4l2_ctrl_handler_free
void v4l2_ctrl_handler_free(struct v4l2_ctrl_handler *hdl)

structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl_ref: read/write
- struct v4l2_ctrl: read/write
- struct v4l2_subscribed_event: read/write

calls:
- v4l2_ctrl_handler_free_request
- mutex_lock
- list_for_each_entry_safe
- list_del
- kvfree
- kfree
- mutex_unlock
- mutex_destroy

## v4l2_ctrl_lock
static inline void v4l2_ctrl_lock(struct v4l2_ctrl *ctrl)

structs:
- struct v4l2_ctrl: read
- struct v4l2_ctrl_handler: read

calls:
- mutex_lock
## v4l2_ctrl_unlock
static inline void v4l2_ctrl_unlock(struct v4l2_ctrl *ctrl)

structs:
- struct v4l2_ctrl: read
- struct v4l2_ctrl_handler: read

calls:
- mutex_lock

## cur_to_new
void cur_to_new(struct v4l2_ctrl *ctrl)

structs:
- struct v4l2_ctrl: read/write

calls:
- ptr_to_ptr

## cur_to_req
void cur_to_req(struct v4l2_ctrl_ref *ref)

structs:
- struct v4l2_ctrl_ref: read/write
- struct v4l2_ctrl: read

calls:
- req_alloc_array
- ptr_to_ptr

## req_alloc_array
static bool req_alloc_array(struct v4l2_ctrl_ref *ref, u32 elems)

structs:
- struct v4l2_ctrl_ref: read/write
- struct v4l2_ctrl: read
- union v4l2_ctrl_ptr: write (p member)

calls:
- kvmalloc
- kvfree

## ptr_to_ptr
static void ptr_to_ptr(struct v4l2_ctrl *ctrl, union v4l2_ctrl_ptr from, union v4l2_ctrl_ptr to, unsigned int elems)

structs:
- struct v4l2_ctrl: read
- union v4l2_ctrl_ptr: read

calls:
- memcpy

## new_to_req
void new_to_req(struct v4l2_ctrl_ref *ref)

structs:
- struct v4l2_ctrl_ref: read/write
- struct v4l2_ctrl: read

calls:
- req_alloc_array
- ptr_to_ptr

# v4l2-ctrls-priv
## node2id
static inline u32 node2id(struct list_head *node)

structs:
- struct list_head: read
- struct v4l2_ctrl_ref: read
- struct v4l2_ctrl: read

calls:
- list_entry

# v4l2-ctrls-defs
## v4l2_ctrl_get_name
const char *v4l2_ctrl_get_name(u32 id)
none

## v4l2_ctrl_fill
void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type, s64 *min, s64 *max, u64 *step, s64 *def, u32 *flags)

structs:
- None
calls:
- v4l2_ctrl_get_name


# v4l2-ctrls-request

## v4l2_ctrl_handler_free_request
void v4l2_ctrl_handler_free_request(struct v4l2_ctrl_handler *hdl)

structs:
- struct v4l2_ctrl_handler: read/write

calls:
- list_empty
- list_for_each_entry_safe
- media_request_object_unbind
- media_request_object_put

## v4l2_ctrl_request_complete
void v4l2_ctrl_request_complete(struct media_request *req, struct v4l2_ctrl_handler *main_hdl)
structs:
- media_request_object
- v4l2_ctrl_handler
- v4l2_ctrl_ref
calls:
- media_request_object_find mc-request.c returns struct
- kzalloc
- v4l2_ctrl_handler_init
- v4l2_ctrl_request_bind
- v4l2_ctrl_handler_free
- kfree
- container_of
- list_for_each_entry
- v4l2_ctrl_lock
- cur_to_new
- call_op
- new_to_req
- v4l2_ctrl_unlock
- cur_to_req
- mutex_lock
- WARN_ON
- list_del_init
- mutex_unlock
- media_request_object_complete
- media_request_object_put

## v4l2_ctrl_request_clone
static int v4l2_ctrl_request_clone(struct v4l2_ctrl_handler *hdl, const struct v4l2_ctrl_handler *from)
structs:
- struct v4l2_ctrl_handler: read/write
- struct v4l2_ctrl_ref: read/create
- struct v4l2_ctrl: read

calls:
- WARN_ON
- mutex_lock
- list_for_each_entry
- handler_new_ref
- mutex_unlock

## v4l2_ctrl_request_bind
'static int v4l2_ctrl_request_bind(struct media_request *req, struct v4l2_ctrl_handler *hdl, struct v4l2_ctrl_handler *from)'
structs:
- media_request read
- v4l2_ctrl_handler write
calls:
- v4l2_ctrl_request_clone
- media_request_object_bind
- mutex_lock
- list_add_tail
- mutex_unlock

## hantro_postproc_free
void hantro_postproc_free(struct hantro_ctx *ctx)
structs:
- hantro_ctx read
- hantro_dev read
- v4l2_m2m_ctx read
- vb2_queue read
- hantro_aux_buf read
calls:
- dma_free_attrs
## hantro_vq_is_coded
static bool hantro_vq_is_coded(struct vb2_queue *q)
structs:
- vb2_queue read
- hantro_ctx read
calls:
- vb2_get_drv_priv

# v4l2 m2m
## v4l2_m2m_ioctl_reqbufs
int v4l2_m2m_ioctl_reqbufs(struct file *file, void *priv, struct v4l2_requestbuffers *rb)

Structs:
- file read
- v4l2_fh create

calls:
- v4l2_m2m_reqbufs

## v4l2_m2m_reqbufs
int v4l2_m2m_reqbufs(struct file *file, struct v4l2_m2m_ctx *m2m_ctx, struct v4l2_requestbuffers *reqbufs)

Structs:
- file read
- v4l2_m2m_ctx read
- vb2_queue create
- v4l2_requestbuffers read

calls:
- v4l2_m2m_get_vq
- vb2_reqbufs

## v4l2_m2m_get_vq
struct vb2_queue *v4l2_m2m_get_vq(struct v4l2_m2m_ctx *m2m_ctx, enum v4l2_buf_type type)

Structs:
- v4l2_m2m_queue_ctx create
- v4l2_m2m_ctx argument

calls:
- get_queue_ctx

## get_queue_ctx
static struct v4l2_m2m_queue_ctx *get_queue_ctx(struct v4l2_m2m_ctx *m2m_ctx, enum v4l2_buf_type type)

Structs:
- v4l2_m2m_ctx read

## v4l2_m2m_buf_done
static inline void v4l2_m2m_buf_done(struct vb2_v4l2_buffer *buf, enum vb2_buffer_state state)

structs:
- struct vb2_v4l2_buffer: read
- struct vb2_buffer: read (nested in vb2_v4l2_buffer)

calls:
- vb2_buffer_done

### v4l2_m2m_src_buf_remove
static inline struct vb2_v4l2_buffer * v4l2_m2m_src_buf_remove(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: read
- struct v4l2_m2m_queue_ctx: read (m2m_ctx->out_q_ctx)

calls:
- v4l2_m2m_buf_remove

## v4l2_m2m_dst_buf_remove
static inline struct vb2_v4l2_buffer * v4l2_m2m_dst_buf_remove(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: read
- struct v4l2_m2m_queue_ctx: read (m2m_ctx->out_q_ctx)

calls:
- v4l2_m2m_buf_remove

## v4l2_m2m_src_buf_remove
static inline struct vb2_v4l2_buffer * v4l2_m2m_src_buf_remove(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: read
- struct v4l2_m2m_queue_ctx: read (m2m_ctx->out_q_ctx)

calls:
- v4l2_m2m_buf_remove

## v4l2_m2m_buf_remove
struct vb2_v4l2_buffer *v4l2_m2m_buf_remove(struct v4l2_m2m_queue_ctx *q_ctx)

structs:
- struct v4l2_m2m_queue_ctx: read/write
- struct v4l2_m2m_buffer: read/write
- struct vb2_v4l2_buffer: read (return type)

calls:
- spin_lock_irqsave
- list_empty
- spin_unlock_irqrestore
- list_first_entry
- list_del

## v4l2_m2m_update_stop_streaming_state
void v4l2_m2m_update_stop_streaming_state(struct v4l2_m2m_ctx *m2m_ctx, struct vb2_queue *q)

structs:
- struct v4l2_m2m_ctx: read/write
- struct vb2_queue: read
- struct vb2_v4l2_buffer: read/write (via v4l2_m2m_dst_buf_remove)

calls:
- V4L2_TYPE_IS_OUTPUT
- v4l2_m2m_dst_buf_remove
- v4l2_m2m_last_buffer_done
- v4l2_m2m_clear_state

## v4l2_m2m_clear_state
static inline void v4l2_m2m_clear_state(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: write

calls:
- None

## v4l2_m2m_last_buffer_done
void v4l2_m2m_last_buffer_done(struct v4l2_m2m_ctx *m2m_ctx, struct vb2_v4l2_buffer *vbuf)

structs:
- struct v4l2_m2m_ctx: read/write
- struct vb2_v4l2_buffer: read/write
- struct vb2_buffer: read/write (nested in vb2_v4l2_buffer)

calls:
- vb2_buffer_done
- v4l2_m2m_mark_stopped

## v4l2_m2m_mark_stopped
static inline void v4l2_m2m_mark_stopped(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: write

calls:
- None

## v4l2_m2m_has_stopped
static inline bool v4l2_m2m_has_stopped(struct v4l2_m2m_ctx *m2m_ctx)

structs:
- struct v4l2_m2m_ctx: read

calls:
- None

# v4l2-event

## v4l2_event_queue_fh
void v4l2_event_queue_fh(struct v4l2_fh *fh, const struct v4l2_event *ev)

structs:
- struct v4l2_fh: read
- struct video_device: read (via fh->vdev)
- struct v4l2_event: read

calls:
- ktime_get_ns
- spin_lock_irqsave
- __v4l2_event_queue_fh
- spin_unlock_irqrestore

## __v4l2_event_queue_fh
static void __v4l2_event_queue_fh(struct v4l2_fh *fh, const struct v4l2_event *ev, u64 ts)

structs:
- struct v4l2_fh: read/write
- struct v4l2_event: read
- struct v4l2_subscribed_event: read/write
- struct v4l2_kevent: read/write
- struct v4l2_event_ops: read (sev->ops)

calls:
- v4l2_event_subscribed
- sev_pos
- list_del
- list_add_tail
- wake_up_all
indirect:
- sev->ops->replace (indirect call)
- sev->ops->merge (indirect call)
## sev_pos
static unsigned int sev_pos(const struct v4l2_subscribed_event *sev, unsigned int idx)

structs:
- struct v4l2_subscribed_event: read

calls:
- None

## v4l2_event_subscribed
static struct v4l2_subscribed_event *v4l2_event_subscribed(struct v4l2_fh *fh, u32 type, u32 id)

structs:
- struct v4l2_fh: read
- struct video_device: read (via fh->vdev)
- struct v4l2_subscribed_event: read

calls:
- assert_spin_locked
- list_for_each_entry

# VB2 v4l2
## vb2_reqbufs
int vb2_reqbufs(struct vb2_queue *q, struct v4l2_requestbuffers *req)

Structs:
- vb2_queue argument
- v4l2_requestbuffers read

calls:
- vb2_set_flags_and_caps
- vb2_core_reqbufs
- vb2_verify_memory_type

## vb2_set_flags_and_caps
static void vb2_set_flags_and_caps(struct vb2_queue *q, u32 memory, u32 *flags, u32 *caps, u32 *max_num_bufs)

Structs:
- vb2_queue read

## vb2_verify_memory_type
int vb2_verify_memory_type(struct vb2_queue *q, enum vb2_memory memory, unsigned int type)

Structs:
- vb2_queue read

calls:
- __verify_mmap_ops
- __verify_userptr_ops
- __verify_dmabuf_ops
- vb2_fileio_is_active
- dprintk

## __verify_mmap_ops
static int __verify_mmap_ops(struct vb2_queue *q)
structs:
- vb2_queue read
## __verify_userptr_ops
static int __verify_userptr_ops(struct vb2_queue *q)
structs:
- vb2_queue read
## __verify_dmabuf_ops
static int __verify_dmabuf_ops(struct vb2_queue *q)
structs:
- vb2_queue read
## vb2_fileio_is_active
static inline bool vb2_fileio_is_active(struct vb2_queue *q)
Structs:
- vb2_queue read
# VB2 Core
## vb2_get_drv_priv
static inline void *vb2_get_drv_priv(struct vb2_queue *q)
structs:
- vb2_queue read

## vb2_core_reqbufs
int vb2_core_reqbufs(struct vb2_queue *q, enum vb2_memory memory, unsigned int flags, unsigned int *count)

Structs:
- vb2_queue write

calls:
- vb2_get_num_buffers
- verify_coherency_flags
- dprintk
- __buffers_in_use
- __vb2_queue_cancel
- __vb2_queue_free
- vb2_core_allocated_buffers_storage
- set_queue_coherency
- __vb2_queue_alloc
- vb2_core_free_buffers_storage
- mutex_lock / mutex_unlock
- max_t / min_t
- memset
- WARN_ON
inderect:
- qop queue_setup

## vb2_get_num_buffers
static inline unsigned int vb2_get_num_buffers(struct vb2_queue *q)
Structs:
- vb2_queue read
calls:
- bitmap_weight

## verify_coherency_flags
static bool verify_coherency_flags(struct vb2_queue *q, bool non_coherent_mem)
structs:
- vb2_queue read
calls:
- dprintk

## __buffers_in_use
static bool __buffers_in_use(struct vb2_queue *q)
struct:
- vb2_queue read
- vb2_buffer create
calls:
- vb2_get_buffer
- vb2_buffer_in_use

## vb2_get_buffer
static inline struct vb2_buffer *vb2_get_buffer(struct vb2_queue *q, unsigned int index)
struct:
- vb2_queue read
calls:
- test_bit ## vb2_buffer_in_use
bool vb2_buffer_in_use(struct vb2_queue *q, struct vb2_buffer *vb)
structs:
- vb2_queue unused 
- vb2_buffer read
indirect:
num_users of vb2_buffer
## __vb2_queue_cancel
static void __vb2_queue_cancel(struct vb2_queue *q)
struct:
- vb2_queue read
- vb2_buffer reinitialize 
calls:
- atomic_read / atomic_set
- vb2_get_buffer
- pr_warn
- vb2_buffer_done
- INIT_LIST_HEAD
- wake_up_all
- spin_lock_irqsave / spin_unlock_irqrestore
- __vb2_buf_mem_finish
- __vb2_dqbuf
- media_request*
indirect:
- stop_streaming calls hantro_stop_streaming
- unprepare_streaming (driver)
- vb_qop buf_request_complete
- vb_qop buf_finish
## __vb2_queue_free
static void __vb2_queue_free(struct vb2_queue *q, unsigned int start, unsigned int count)
structs:
- vb2_queue write
- vb2_buffer cleanup
calls:
- lockdep_assert_held
- vb2_get_buffer
- __vb2_free_mem
- vb2_queue_remove_buffer
- kfree
- vb2_get_num_buffers
- INIT_LIST_HEAD
indirect:
- vb_qop buf_cleanup (driver)

## __vb2_free_mem
static void __vb2_free_mem(struct vb2_queue *q, unsigned int start, unsigned int count)
structs:
- vb2_queue read
- vb2_buffer read
calls:
- vb2_get_buffer
- __vb2_buf_mem_free
- __vb2_buf_dmabuf_put
- __vb2_buf_userptr_put

## __vb2_buf_mem_free
static void __vb2_buf_mem_free(struct vb2_buffer *vb)
structs:
- vb2_buffer read
calls:
- dprintk
indirect:
- memop put (driver)

## __vb2_buf_dmabuf_put
static void __vb2_buf_dmabuf_put(struct vb2_buffer *vb)
structs:
- vb2_buffer read
calls:
- __vb2_plane_dmabuf_put
## __vb2_plane_dmabuf_put
static void __vb2_plane_dmabuf_put(struct vb2_buffer *vb, struct vb2_plane *p)
structs:
- vb2_buffer read
- vb2_plane write
calls:
- dma_buf_put
indirect:
- memop unmap_dmabuf
- memop detach_dmabuf
## dma_buf_put
void dma_buf_put(struct dma_buf *dmabuf)
structs:
- dma_buf read
calls:
- fput
- WARN_ON
## __vb2_buf_userptr_put
static void __vb2_buf_userptr_put(struct vb2_buffer *vb)
structs:
- vb2_buffer read
indirect:
- memop put_userptr (driver)

## __vb2_dqbuf
static void __vb2_dqbuf(struct vb2_buffer *vb)
structs: 
- vb2_buffer write
indirect:
- bufop init_buffer

## vb2_core_dqbuf
int vb2_core_dqbuf(struct vb2_queue *q, unsigned int *pindex, void *pb)

calls:
- init_buffer (driver)

## vb2_buffer_done
void vb2_buffer_done(struct vb2_buffer *vb, enum vb2_buffer_state state)
structs:
- struct vb2_buffer: read/write
- struct vb2_queue: read/write
- struct media_request: read (via vb->req_obj.req)
calls:
- WARN_ON
- dprinktk
- vb2_state_name
- __vb2_buf_mem_finish
- list_add_tail
- atomic_dec
- media_request_object_unbind
- media_request_object_put
- spin_lock_irqsave / spin_unlock_irqrestore
- trace_vb2_buf_done event
- wake_up

## vb2_state_name
static const char *vb2_state_name(enum vb2_buffer_state s)

calls:
- ARRAY_SIZE

## __vb2_buf_mem_finish
static void __vb2_buf_mem_finish(struct vb2_buffer *vb)
struct:
- vb2_buffer write
indirect:
- memop vb_buffer -> finish 

## set_queue_coherency
static void set_queue_coherency(struct vb2_queue *q, bool non_coherent_mem)
structs:
- vb2_queue write
calls:
- vb2_queue_allows_cache_hints

## vb2_queue_allows_cache_hints
static inline bool vb2_queue_allows_cache_hints(struct vb2_queue *q)
structs:
- vb2_queue read

## __vb2_queue_alloc
static int __vb2_queue_alloc(struct vb2_queue *q, enum vb2_memory memory, unsigned int num_buffers, unsigned int num_planes, const unsigned int plane_sizes[VB2_MAX_PLANES], unsigned int *first_index)
structs:
- vb2_queue read
- vb2_buffer write
calls:
- min_t
- vb2_get_num_buffers
- bitmap_find_next_zero_area read vb2_queue
- kzalloc
- dprintk
- init_buffer_cache_hints
- vb2_queue_add_buffer
- __vb2_buf_mem_alloc
- vb2_queue_remove_buffer
- kfree
- __setup_offsets
- __vb2_buf_mem_free
indirect:
- bufop init_buffer

## __setup_offsets
static void __setup_offsets(struct vb2_buffer *vb)
structs:
- vb2_queue read
- vb2_buffer write
calls:
- dprintk

## vb2_queue_remove_buffer
static void vb2_queue_remove_buffer(struct vb2_buffer *vb)
structs:
- vb2_buffer write
calls:
- clear_bit

## __vb2_buf_mem_alloc
static int __vb2_buf_mem_alloc(struct vb2_buffer *vb)
structs:
- vb2_buffer write 
- vb2_queue read
calls:
- IS_ERR_OR_NULL
- PTR_ERR
indirect:
- ptr_memop alloc (driver)
- memop put (driver)

## vb2_queue_add_buffer
static void vb2_queue_add_buffer(struct vb2_queue *q, struct vb2_buffer *vb, unsigned int index)
structs:
- vb2_queue write
- vb2_buffer write
calls:
- WARN_ON
- test_bit
- set_bit wrties vb2_queue

## init_buffer_cache_hints
static void init_buffer_cache_hints(struct vb2_queue *q, struct vb2_buffer *vb)
structs:
- vb2_queue read
- vb2_buffer write
## vb2_core_free_buffers_storage
static void vb2_core_free_buffers_storage(struct vb2_queue *q)

calls:
- kfree
- bitmap_free

## vb2_core_allocated_buffers_storage
Structs:
- vb2_queue read

calls:
- kcalloc
- sizeof
- bitmap_zalloc
- kfree
