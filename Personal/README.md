# mpv-config
My personal configuration files, scripts and shaders for MPV

Tested on and optimized for the following specs:

OS: Windows 10

CPU: Ryzen 5 5600X

GPU: Vega 56 (Undervolted and power limited)

Monitor: CoolerMaster GP27Q

## Scripts used

**[SmartCopyPaste](https://github.com/Eisa01/mpv-scripts#smartcopypaste)**

**[cycle-profile](https://github.com/CogentRedTester/mpv-scripts#cycle-profile)**

**[hdr-toys-helper](https://github.com/natural-harmonia-gropius/hdr-toys)**
> Used with hdr-toys shaders

**[input-event](https://github.com/natural-harmonia-gropius/input-event)**

**[osc](https://github.com/po5/thumbfast/blob/vanilla-osc/player/lua/osc.lua)**
> Vanilla OSC with thumbfast support

**[reduce_stream_cache](https://github.com/divout/mpv_reduce_stream_cache)**

**[reload](https://github.com/sibwaf/mpv-scripts#reload.lua)**

**[sponsorblock_minimal](https://codeberg.org/jouni/mpv_sponsorblock_minimal)**

**[thumbfast](https://github.com/po5/thumbfast)**

**[track-list](https://github.com/dyphire/mpv-scripts#track-list.lua)**

**[auto_profiles_mod](https://github.com/NotMithical/mpv-config/blob/main/portable_config/scripts/auto_profiles_mod.lua)**
> Almost identical to MPV's internal [auto_profiles.lua](https://github.com/mpv-player/mpv/blob/master/player/lua/auto_profiles.lua) with one line added to enable reloading profiles with a hotkey. Requires --load-auto-profiles=no.

## Shaders used

**[NLS#](https://github.com/NotMithical/mpv-config/blob/main/Personal/portable_config/shaders/AspectRatio/NLS%23.glsl)**
> Handles mismatched aspect ratios by nonlinearly stretching (vertically and horizontally), cropping, and padding the source image/video to match the window or screen. Includes four tuneable parameters: VerticalStretch, HorizontalStretch, CropAmount and BarsAmount, all of which have a range of 0.0 to 1.0. The first 2 parameters control the balance between vertical and horizontal stretching, allowing you to stretch in only one direction or distribute stretching evenly across all edges (default). CropAmount behaves similarly to PanScan, allowing you to crop edges of the image in favor of reducing distortion. BarsAmount allows you to preserve/add padding at the edges of the image in favor of reducing distortion. Use with `--no-keepaspect`

**AMD-CAS**
> Some ported by [deus0ww](https://github.com/deus0ww), some ported by [agyild](https://gist.github.com/agyild) and some I can't find the source of.

**[AMD-FSR](https://github.com/dyphire/mpv-config/tree/master/shaders/AMD-FSR)**

**[hyperview](https://gist.github.com/bjin/399cb23818ad210941725ef768893499)**

**[mdann_nls](https://www.heimkinoverein.de/forum/thread/21670-mpv-shader-non-linear-stretch/)**

**[nonlinear-stretch](https://gist.github.com/sarahzrf/c9909aee70e3656895820f20ac395956)**

**[ACNet](https://github.com/TianZerL/ACNetGLSL)**

**[Anime4k](https://github.com/bloc97/Anime4K)**

**[FSRCNN](https://github.com/igv/FSRCNN-TensorFlow)**

**[FSRCNNX_x2_56](https://github.com/hooke007/MPV_lazy/blob/main/portable_config/shaders/FSRCNNX_x2_56_16_4_1.glsl)**

**[nnedi and ravu](https://github.com/bjin/mpv-prescalers)**

**[SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b)**

**[SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10)**

**[Tsuba Scalers](https://github.com/Tsubajashi/mpv-settings/tree/master/shaders)**

**[LumaSharpenHook](https://github.com/boned101/MPV-Custom-Shaders)**

**[adaptive-sharpen](https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e)**

**[unsharp_masking](https://github.com/garamond13/unsharp_masking.glsl)**

**[alt-scalers](https://github.com/garamond13/alt-scale)**

**[hdr-toys](https://github.com/natural-harmonia-gropius/hdr-toys)**

**[KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)**

**[Non-local means](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)**

**[Film Grain](https://github.com/haasn/gentoo-conf/tree/xor/home/nand/.mpv/shaders)**

**[Super XBR](https://github.com/dyphire/mpv-config/tree/master/shaders/superxbr)**