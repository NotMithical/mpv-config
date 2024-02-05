from vapoursynth import core
import vapoursynth as vs

import vsutil
import havsfunc as hf

src = video_in

mask = core.std.Sobel(src, 0)
luma = core.std.ShufflePlanes(mask, 0, colorfamily=vs.GRAY)

mask_outer = vsutil.iterate(luma, core.std.Maximum, 2)

mask_inner = vsutil.iterate(mask_outer, core.std.Minimum, 3)

halos = core.std.Expr([mask_outer, mask_inner], 'x y -')

dehalo = hf.DeHalo_alpha(src)

masked_dehalo = core.std.MaskedMerge(src, dehalo, halos)

masked_dehalo.set_output()