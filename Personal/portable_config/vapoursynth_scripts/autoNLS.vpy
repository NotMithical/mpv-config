from vapoursynth import core
import vapoursynth as vs

video_in = core.fmtc.bitdepth(video_in, bits=16)

cropped = core.acrop.AutoCrop(video_in, range=1000)

stretched = core.placebo.Shader(cropped, "C:/Users/unsha/MPVStable/portable_config/shaders/AspectRatio/NLS#.glsl", width=video_in.width, height=video_in.height)

stretched.set_output()