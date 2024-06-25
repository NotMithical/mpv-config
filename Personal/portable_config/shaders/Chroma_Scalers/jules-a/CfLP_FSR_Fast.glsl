// MIT License

// Copyright (c) 2023 João Chrisóstomo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//!HOOK CHROMA
//!BIND LUMA
//!BIND HOOKED
//!SAVE LUMA_LOWRES2
//!WIDTH CHROMA.w 2 *
//!HEIGHT CHROMA.h 2 *
//!WHEN LUMA.w CHROMA.w >
//!DESC CFL Downscaling Luma 1 (HermitexFSRxJinc)

#define M_PI 3.1415927 // pi
#define M_PI_4 0.7853982 // pi/4
#define M_2_PI 0.6366198 // 2/pi
#define M_SQRT2 1.4142136 // sqrt(2)
#define EPS 1e-6

//Credit Garamond13 for jinc code
float bessel_J1(float x)
{
  if (x < 2.2931157)
      return x / 2.0 - x * x * x / 16.0 + x * x * x * x * x / 384.0 - x * x * x * x * x * x * x / 18432.0;
  else
      return sqrt(M_2_PI / x) * (1.0 + 0.1875 / (x * x) - 0.1933594 / (x * x * x * x)) * cos(x - 3.0 * M_PI_4 + 0.375 / x - 0.1640625 / (x * x * x));
}

#define jinc(x) ((x < EPS) ? 1.0 : (2.0 * bessel_J1(M_PI * x) / (M_PI * x)))
#define fsr(x) (25.0 / 16.0 * pow(2.0 / 5.0 * x - 1.0, 2.0) - (25.0 / 16.0 - 1.0)) * pow(1.0 / 4.0 * x - 1.0, 2.0)
#define hermite(x, y) smoothstep(0.0, 1.0, 1.0 - ((x) / (y + 0.5)))

vec4 hook() {
    float factor = ceil(LUMA_size.x / (HOOKED_size.x * 2));
    ivec2 posx = ivec2(int(ceil(-factor / 2.0 - 0.5)), int(floor(factor / 2.0 - 0.5)));
    float output_luma, wt, w, d = 0.0;
    
    for (int dx = posx.x; dx <= posx.y; dx++) {
        d = dx + 0.5;
        w = hermite(d, posx.y) * fsr((d/2)/factor) * jinc(d/factor*1.2196699);
        if (w < 0.00005) {
            continue;
        }
        wt += w;
        output_luma += w * LUMA_texOff(vec2(d, 0.0)).x;
    }
    return vec4(output_luma / wt, 0.0, 0.0, 1.0);
}

//!DESC CfL Upscaling FSR EASU
//!HOOK CHROMA
//!BIND HOOKED
//!SAVE CHROMA_HIGHRES
//!WIDTH CHROMA.w 2 *
//!HEIGHT CHROMA.h 2 *
//!OFFSET ALIGN

// User variables - EASU
#define FSR_EASU_DERING 1          // If set to 0, disables deringing for a small increase in performance. 0 or 1.
#define FSR_EASU_SIMPLE_ANALYSIS 0 // If set to 1, uses a simpler single-pass direction and length analysis for an increase in performance. 0 or 1.
#define FSR_EASU_QUIT_EARLY 0      // If set to 1, uses bilinear filtering for non-edge pixels and skips EASU on those regions for an increase in performance. 0 or 1.

// Shader code

#ifndef FSR_EASU_DIR_THRESHOLD
	#if (FSR_EASU_QUIT_EARLY == 1)
		#define FSR_EASU_DIR_THRESHOLD 64.0
	#elif (FSR_EASU_QUIT_EARLY == 0)
		#define FSR_EASU_DIR_THRESHOLD 32768.0
	#endif
#endif

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxLoRsqF1(float a) {
	return uintBitsToFloat(uint(0x5f347d74) - (floatBitsToUint(a) >> uint(1)));
}

float AMin3F1(float x, float y, float z) {
	return min(x, min(y, z));
}

float AMax3F1(float x, float y, float z) {
	return max(x, max(y, z));
}

#if (FSR_PQ == 1)

float ToGamma2(float a) {
	return pow(a, 4.0);
}

#endif

 // Filtering for a given tap for the scalar.
 void FsrEasuTap(
	inout float aC,	// Accumulated color, with negative lobe.
	inout float aW, // Accumulated weight.
	vec2 off,       // Pixel offset from resolve position to tap.
	vec2 dir,       // Gradient direction.
	vec2 len,       // Length.
	float lob,      // Negative lobe strength.
	float clp,		// Clipping point.
	float c){		// Tap color.
	// Rotate offset by direction.
	vec2 v;
	v.x = (off.x * ( dir.x)) + (off.y * dir.y);
	v.y = (off.x * (-dir.y)) + (off.y * dir.x);
	// Anisotropy.
	v *= len;
	// Compute distance^2.
	float d2 = v.x * v.x + v.y * v.y;
	// Limit to the window as at corner, 2 taps can easily be outside.
	d2 = min(d2, clp);
	// Approximation of lancos2 without sin() or rcp(), or sqrt() to get x.
	//  (25/16 * (2/5 * x^2 - 1)^2 - (25/16 - 1)) * (1/4 * x^2 - 1)^2
	//  |_______________________________________|   |_______________|
	//                   base                             window
	// The general form of the 'base' is,
	//  (a*(b*x^2-1)^2-(a-1))
	// Where 'a=1/(2*b-b^2)' and 'b' moves around the negative lobe.
	float wB = float(2.0 / 5.0) * d2 + -1.0;
	float wA = lob * d2 + -1.0;
	wB *= wB;
	wA *= wA;
	wB = float(25.0 / 16.0) * wB + float(-(25.0 / 16.0 - 1.0));
	float w = wB * wA;
	// Do weighted average.
	aC += c * w;
	aW += w;
}

// Accumulate direction and length.
void FsrEasuSet(
	inout vec2 dir,
	inout float len,
	vec2 pp,
#if (FSR_EASU_SIMPLE_ANALYSIS == 1)
	float b, float c,
	float i, float j, float f, float e,
	float k, float l, float h, float g,
	float o, float n
#elif (FSR_EASU_SIMPLE_ANALYSIS == 0)
	bool biS, bool biT, bool biU, bool biV,
	float lA, float lB, float lC, float lD, float lE
#endif
	){
	// Compute bilinear weight, branches factor out as predicates are compiler time immediates.
	//  s t
	//  u v
#if (FSR_EASU_SIMPLE_ANALYSIS == 1)
	vec4 w = vec4(0.0);
	w.x = (1.0 - pp.x) * (1.0 - pp.y);
	w.y =        pp.x  * (1.0 - pp.y);
	w.z = (1.0 - pp.x) *        pp.y;
	w.w =        pp.x  *        pp.y;

	float lA = dot(w, vec4(b, c, f, g));
	float lB = dot(w, vec4(e, f, i, j));
	float lC = dot(w, vec4(f, g, j, k));
	float lD = dot(w, vec4(g, h, k, l));
	float lE = dot(w, vec4(j, k, n, o));
#elif (FSR_EASU_SIMPLE_ANALYSIS == 0)
	float w = 0.0;
	if (biS)
		w = (1.0 - pp.x) * (1.0 - pp.y);
	if (biT)
		w =        pp.x  * (1.0 - pp.y);
	if (biU)
		w = (1.0 - pp.x) *        pp.y;
	if (biV)
		w =        pp.x  *        pp.y;
#endif
	// Direction is the '+' diff.
	//    a
	//  b c d
	//    e
	// Then takes magnitude from abs average of both sides of 'c'.
	// Length converts gradient reversal to 0, smoothly to non-reversal at 1, shaped, then adding horz and vert terms.
	float dc = lD - lC;
	float cb = lC - lB;
	float lenX = max(abs(dc), abs(cb));
	lenX = APrxLoRcpF1(lenX);
	float dirX = lD - lB;
	lenX = clamp(abs(dirX) * lenX, 0.0, 1.0);
	lenX *= lenX;
	// Repeat for the y axis.
	float ec = lE - lC;
	float ca = lC - lA;
	float lenY = max(abs(ec), abs(ca));
	lenY = APrxLoRcpF1(lenY);
	float dirY = lE - lA;
	lenY = clamp(abs(dirY) * lenY, 0.0, 1.0);
	lenY *= lenY;
#if (FSR_EASU_SIMPLE_ANALYSIS == 1)
	len = lenX + lenY;
	dir = vec2(dirX, dirY);
#elif (FSR_EASU_SIMPLE_ANALYSIS == 0)
	dir += vec2(dirX, dirY) * w;
	len += dot(vec2(w), vec2(lenX, lenY));
#endif
}

vec4 hook() {
	// Result
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);

	//------------------------------------------------------------------------------------------------------------------------------
	//      +---+---+
	//      |   |   |
	//      +--(0)--+
	//      | b | c |
	//  +---F---+---+---+
	//  | e | f | g | h |
	//  +--(1)--+--(2)--+
	//  | i | j | k | l |
	//  +---+---+---+---+
	//      | n | o |
	//      +--(3)--+
	//      |   |   |
	//      +---+---+
	// Get position of 'F'.
	vec2 pp = HOOKED_pos * HOOKED_size - vec2(0.5);
	vec2 fp = floor(pp);
	pp -= fp;
	//------------------------------------------------------------------------------------------------------------------------------
	// 12-tap kernel.
	//    b c
	//  e f g h
	//  i j k l
	//    n o
	// Gather 4 ordering.
	//  a b
	//  r g
	// Allowing dead-code removal to remove the 'z's.
	const ivec2 quad_idx[4] = {{ 1,-1}, { 0, 1}, { 2, 1}, { 1, 3}};
	mat2x4 bczz = mat2x4(HOOKED_gather(vec2((fp + quad_idx[0]) * HOOKED_pt), 0),
                         HOOKED_gather(vec2((fp + quad_idx[0]) * HOOKED_pt), 1));
	mat2x4 ijfe = mat2x4(HOOKED_gather(vec2((fp + quad_idx[1]) * HOOKED_pt), 0),
                         HOOKED_gather(vec2((fp + quad_idx[1]) * HOOKED_pt), 1));
	mat2x4 klhg = mat2x4(HOOKED_gather(vec2((fp + quad_idx[2]) * HOOKED_pt), 0),
                         HOOKED_gather(vec2((fp + quad_idx[2]) * HOOKED_pt), 1));
	mat2x4 zzon = mat2x4(HOOKED_gather(vec2((fp + quad_idx[3]) * HOOKED_pt), 0),
                         HOOKED_gather(vec2((fp + quad_idx[3]) * HOOKED_pt), 1));

for(int i = 0; i < 2; i++)
{
	//------------------------------------------------------------------------------------------------------------------------------
	// Rename.
	float bL = bczz[i].x;
	float cL = bczz[i].y;
	float iL = ijfe[i].x;
	float jL = ijfe[i].y;
	float fL = ijfe[i].z;
	float eL = ijfe[i].w;
	float kL = klhg[i].x;
	float lL = klhg[i].y;
	float hL = klhg[i].z;
	float gL = klhg[i].w;
	float oL = zzon[i].z;
	float nL = zzon[i].w;

	// Accumulate for bilinear interpolation.
	vec2 dir = vec2(0.0);
	float len = 0.0;
#if (FSR_EASU_SIMPLE_ANALYSIS == 1)
	FsrEasuSet(dir, len, pp, bL, cL, iL, jL, fL, eL, kL, lL, hL, gL, oL, nL);
#elif (FSR_EASU_SIMPLE_ANALYSIS == 0)
	FsrEasuSet(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
	FsrEasuSet(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
	FsrEasuSet(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
	FsrEasuSet(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
#endif
	//------------------------------------------------------------------------------------------------------------------------------
	// Normalize with approximation, and cleanup close to zero.
	vec2 dir2 = dir * dir;
	float dirR = dir2.x + dir2.y;
	bool zro = dirR < float(1.0 / FSR_EASU_DIR_THRESHOLD);
	dirR = APrxLoRsqF1(dirR);
#if (FSR_EASU_QUIT_EARLY == 1)
	if (zro) {
		vec4 w = vec4(0.0);
		w.x = (1.0 - pp.x) * (1.0 - pp.y);
		w.y =        pp.x  * (1.0 - pp.y);
		w.z = (1.0 - pp.x) *        pp.y;
		w.w =        pp.x  *        pp.y;

		pix.r = clamp(dot(w, vec4(fL, gL, jL, kL)), 0.0, 1.0);
		return pix;
	}
#elif (FSR_EASU_QUIT_EARLY == 0)
	dirR = zro ? 1.0 : dirR;
	dir.x = zro ? 1.0 : dir.x;
#endif
	dir *= vec2(dirR);
	// Transform from {0 to 2} to {0 to 1} range, and shape with square.
	len = len * 0.5;
	len *= len;
	// Stretch kernel {1.0 vert|horz, to sqrt(2.0) on diagonal}.
	float stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	// Anisotropic length after rotation,
	//  x := 1.0 lerp to 'stretch' on edges
	//  y := 1.0 lerp to 2x on edges
	vec2 len2 = vec2(1.0 + (stretch - 1.0) * len, 1.0 + -0.5 * len);
	// Based on the amount of 'edge',
	// the window shifts from +/-{sqrt(2.0) to slightly beyond 2.0}.
	float lob = 0.5 + float((1.0 / 4.0 - 0.04) - 0.5) * len;
	// Set distance^2 clipping point to the end of the adjustable window.
	float clp = APrxLoRcpF1(lob);
	//------------------------------------------------------------------------------------------------------------------------------
	// Accumulation
	//    b c
	//  e f g h
	//  i j k l
	//    n o
	float aC = 0.0;
	float aW = 0.0;
	FsrEasuTap(aC, aW, vec2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL); // b
	FsrEasuTap(aC, aW, vec2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL); // c
	FsrEasuTap(aC, aW, vec2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL); // i
	FsrEasuTap(aC, aW, vec2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL); // j
	FsrEasuTap(aC, aW, vec2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL); // f
	FsrEasuTap(aC, aW, vec2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL); // e
	FsrEasuTap(aC, aW, vec2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL); // k
	FsrEasuTap(aC, aW, vec2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL); // l
	FsrEasuTap(aC, aW, vec2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL); // h
	FsrEasuTap(aC, aW, vec2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL); // g
	FsrEasuTap(aC, aW, vec2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL); // o
	FsrEasuTap(aC, aW, vec2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL); // n
	//------------------------------------------------------------------------------------------------------------------------------
	// Normalize and dering.
	pix[i] = aC / aW;
#if (FSR_EASU_DERING == 1)
	float min1 = min(AMin3F1(fL, gL, jL), kL);
	float max1 = max(AMax3F1(fL, gL, jL), kL);
	pix[i] = clamp(pix[i], min1, max1);
#endif
	pix[i] = clamp(pix[i], 0.0, 1.0);
}
	return pix;
}

//!HOOK CHROMA
//!BIND CHROMA_HIGHRES
//!BIND LUMA
//!BIND LUMA_LOWRES2
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!OFFSET ALIGN
//!DESC Chroma From Luma Prediction (Upscaling Chroma)

float comp_wd(vec2 v) {
    float d2  = min(dot(v, v), 4.0);
    float d24 = d2 - 4.0;
    return d24 * d24 * d24 * (d2 - 1.0);
}

vec4 hook() {
    float ar_strength = 0.82;
    vec2 mix_coeff = vec2(0.75);
    vec2 corr_exponent = vec2(8.0);

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    float luma_zero = LUMA_texOff(0.0).x;

    vec2 pp = CHROMA_HIGHRES_pos * CHROMA_HIGHRES_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    vec2 quad_idx[4] = {{0.0, 0.0}, {2.0, 0.0}, {0.0, 2.0}, {2.0, 2.0}};

    vec4 luma_quads[4];
    vec4 chroma_quads[4][2];

    for (int i = 0; i < 4; i++) {
        luma_quads[i] = LUMA_LOWRES2_gather(vec2((fp + quad_idx[i]) * CHROMA_HIGHRES_pt), 0);
        chroma_quads[i][0] = CHROMA_HIGHRES_gather(vec2((fp + quad_idx[i]) * CHROMA_HIGHRES_pt), 0);
        chroma_quads[i][1] = CHROMA_HIGHRES_gather(vec2((fp + quad_idx[i]) * CHROMA_HIGHRES_pt), 1);
    }

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = vec2(chroma_quads[0][0].z, chroma_quads[0][1].z);
    chroma_pixels[1]  = vec2(chroma_quads[1][0].w, chroma_quads[1][1].w);
    chroma_pixels[2]  = vec2(chroma_quads[0][0].x, chroma_quads[0][1].x);
    chroma_pixels[3]  = vec2(chroma_quads[0][0].y, chroma_quads[0][1].y);
    chroma_pixels[4]  = vec2(chroma_quads[1][0].x, chroma_quads[1][1].x);
    chroma_pixels[5]  = vec2(chroma_quads[1][0].y, chroma_quads[1][1].y);
    chroma_pixels[6]  = vec2(chroma_quads[2][0].w, chroma_quads[2][1].w);
    chroma_pixels[7]  = vec2(chroma_quads[2][0].z, chroma_quads[2][1].z);
    chroma_pixels[8]  = vec2(chroma_quads[3][0].w, chroma_quads[3][1].w);
    chroma_pixels[9]  = vec2(chroma_quads[3][0].z, chroma_quads[3][1].z);
    chroma_pixels[10] = vec2(chroma_quads[2][0].y, chroma_quads[2][1].y);
    chroma_pixels[11] = vec2(chroma_quads[3][0].x, chroma_quads[3][1].x);

    float luma_pixels[12];
    luma_pixels[0]  = luma_quads[0].z;
    luma_pixels[1]  = luma_quads[1].w;
    luma_pixels[2]  = luma_quads[0].x;
    luma_pixels[3]  = luma_quads[0].y;
    luma_pixels[4]  = luma_quads[1].x;
    luma_pixels[5]  = luma_quads[1].y;
    luma_pixels[6]  = luma_quads[2].w;
    luma_pixels[7]  = luma_quads[2].z;
    luma_pixels[8]  = luma_quads[3].w;
    luma_pixels[9]  = luma_quads[3].z;
    luma_pixels[10] = luma_quads[2].y;
    luma_pixels[11] = luma_quads[3].x;

    float wd[12];
    float wt = 0.0;
    vec2 ct = vec2(0.0);

    vec2 chroma_min = min(min(min(chroma_pixels[3], chroma_pixels[4]), chroma_pixels[7]), chroma_pixels[8]);
    vec2 chroma_max = max(max(max(chroma_pixels[3], chroma_pixels[4]), chroma_pixels[7]), chroma_pixels[8]);

    const int dx[12] = { 0, 1,-1, 0, 1, 2,-1, 0, 1, 2, 0, 1};
    const int dy[12] = {-1,-1, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2};

    for (int i = 0; i < 12; i++) {
        wd[i] = comp_wd(vec2(dx[i], dy[i]) - pp);
        wt += wd[i];
        ct += wd[i] * chroma_pixels[i];
    }

    vec2 chroma_spatial = ct / wt;
    chroma_spatial = clamp(mix(chroma_spatial, clamp(chroma_spatial, chroma_min, chroma_max), ar_strength), 0.0, 1.0);

    float luma_avg = 0.0;
    float luma_var = 0.0;
    vec2 chroma_avg = vec2(0.0);
    vec2 chroma_var = vec2(0.0);
    vec2 luma_chroma_cov = vec2(0.0);

    for (int i = 0; i < 12; i++) {
        luma_avg += luma_pixels[i];
        chroma_avg += chroma_pixels[i];
    }

    luma_avg /= 12.0;
    chroma_avg /= 12.0;

    for (int i = 0; i < 12; i++) {
        luma_var += pow(luma_pixels[i] - luma_avg, 2.0);
        chroma_var += pow(chroma_pixels[i] - chroma_avg, vec2(2.0));
        luma_chroma_cov += (luma_pixels[i] - luma_avg) * (chroma_pixels[i] - chroma_avg);
    }

    vec2 corr = clamp(abs(luma_chroma_cov / max(sqrt(luma_var * chroma_var), 1e-6)), 0.0, 1.0);

    vec2 alpha = luma_chroma_cov / max(luma_var, 1e-6);
    vec2 beta = chroma_avg - alpha * luma_avg;
    vec2 chroma_pred = clamp(alpha * luma_zero + beta, 0.0, 1.0);

    output_pix.xy = mix(chroma_spatial, chroma_pred, pow(corr, corr_exponent) * mix_coeff);
    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return output_pix;
}