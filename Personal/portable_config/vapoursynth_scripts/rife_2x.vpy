### rife v4 #! https://github.com/hooke007/MPV_lazy/blob/main/portable_config/vs/rife_2x.vpy

import vapoursynth as vs
from vapoursynth import core
import math

input = video_in
colorlv = input.get_frame(0).props._ColorRange
fmt_src = input.format
source = fmt_src.id

max_Leng = 720
scene_th = 0.1
GPU = 0
GPU_t = 2
static_th = 60.0
fmt_out = vs.YUV420P8

if container_fps > 32 :
	raise Exception("EX_2X_1")

if input.width >= input.height :
	short_edge = input.height
	max_Leng2 = input.width*(max_Leng/input.height)
	w_ds = max_Leng2
	h_ds = max_Leng
else :
	short_edge = input.width
	max_Leng2 = input.height*(max_Leng/input.width)
	w_ds = max_Leng
	h_ds = max_Leng2

if fmt_src.subsampling_w or fmt_src.subsampling_h :
	if not (w_ds % 2 == 0) :
		w_ds = math.floor(w_ds / 2) * 2
	if not (h_ds % 2 == 0) :
		h_ds = math.floor(h_ds / 2) * 2

cut0 = core.misc.SCDetect(clip=input, threshold=scene_th)

if short_edge > max_Leng :
	cut1 = cut0.resize.Lanczos(width=w_ds, height=h_ds, format=vs.RGBS, matrix_in_s="709")
else :
	cut1 = cut0.resize.Bilinear(format=vs.RGBS, matrix_in_s="709")
cut2 = core.rife.RIFE(clip=cut1, model=9, factor_num=2, factor_den=1, gpu_id=GPU, gpu_thread=GPU_t, sc=True, skip=True, skip_threshold=static_th)

output = cut2.resize.Bilinear(format=fmt_out, matrix_s="709", range=1 if colorlv==0 else None)

output.set_output()
