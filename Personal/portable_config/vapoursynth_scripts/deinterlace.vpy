from vapoursynth import core
import vapoursynth as vs

import havsfunc

if container_fps > 47 :
	raise Exception("Input framerate too high!")

elif video_in.width > 900 :
    #video_in = core.znedi3.nnedi3(clip=video_in, field=3)
    #ref = core.znedi3.nnedi3(clip=video_in, field=3)
    
    video_in = core.nnedi3cl.NNEDI3CL(clip=video_in, field=3, device=0)
    #ref = core.nnedi3cl.NNEDI3CL(clip=video_in, field=3)
    
    #video_in = core.bwdif.Bwdif(clip=video_in, field=3, edeint=ref)
    
    #video_in = core.tdm.TDeintMod(video_in, order=1, mode=1, ttype=0, edeint=ref)
    
    #video_in = core.std.SeparateFields(video_in, 1).std.DoubleWeave() 
    #video_in = core.sangnom.SangNom(video_in, order=0)
    
    #antialiased = core.nnedi3cl.NNEDI3CL(clip=video_in, field=1, dh=1, dw=1)
    #video_in = core.resize.Bicubic(antialiased, filter_param_a=0.0, filter_param_b=0.0, width=video_in.width, height=video_in.height)
    
elif video_in.width >= 720 :
    video_in = havsfunc.QTGMC(Input=video_in, Preset="Slow", NoiseProcess=0, TFF=1)

else :
    video_in = havsfunc.QTGMC(Input=video_in, Preset="Very Slow", NoiseProcess=0, TFF=1)

target_fpsnum = (container_fps * 2)

video_in = core.std.AssumeFPS(video_in, fpsnum=target_fpsnum, fpsden=1)

video_in.set_output()