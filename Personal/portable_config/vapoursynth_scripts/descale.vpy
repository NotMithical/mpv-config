from vapoursynth import core
import vapoursynth as vs

video_in = core.fmtc.bitdepth(video_in, bits=32)

video_in = core.descale.Debilinear(video_in, 1280, 720)

video_in = core.fmtc.bitdepth(video_in, bits=10, dmode=8, dyn=1)

video_in.set_output()