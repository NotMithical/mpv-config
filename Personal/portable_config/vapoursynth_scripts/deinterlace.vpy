from vapoursynth import core
import vapoursynth as vs

import havsfunc

video_in = havsfunc.QTGMC(Input=video_in, Preset="Very Slow", NoiseProcess=0, TFF=1)

target_fpsnum = (container_fps * 2)

video_in = core.std.AssumeFPS(video_in, fpsnum=target_fpsnum, fpsden=1)

video_in.set_output()