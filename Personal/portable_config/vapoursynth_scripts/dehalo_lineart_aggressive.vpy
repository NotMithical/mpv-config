from vapoursynth import core
import vapoursynth as vs

import vsutil
import vsdehalo

src = video_in

mask = core.std.Sobel(src, 0)
luma = core.std.ShufflePlanes(mask, 0, colorfamily=vs.GRAY)

mask_outer = core.std.Maximum(luma)

mask_inner = core.std.Minimum(luma)

halos = core.std.Expr([mask_outer, mask_inner], 'x y -')

dehalo = vsdehalo.dehalo_alpha(src)

masked_dehalo = core.std.MaskedMerge(src, dehalo, halos)

masked_dehalo.set_output()