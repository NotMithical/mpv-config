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

//!PARAM cfl_antiring
//!DESC CfL Antiring Parameter
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM ravu_antiring
//!DESC RAVU Chroma Antiring Parameter
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.8

//!HOOK CHROMA
//!BIND CHROMA
//!BIND LUMA
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC CfL Downscaling Yx Box
#define axis 0
#define weight box

float box(const float d)       { return float(abs(d) <= 0.5); }
float triangle(const float d)  { return max(1.0 - abs(d), 0.0); }
float hermite(const float d)   { return smoothstep(0.0, 1.0, 1 - abs(d)); }
float quadratic(const float d) {
    float x = 1.5 * abs(d);
    if (x < 0.5)
        return(0.75 - x * x);
    if (x < 1.5)
        return(0.5 * (x - 1.5) * (x - 1.5));
    return(0.0);
}

vec2 scale  = LUMA_size / CHROMA_size;
vec2 radius = ceil(scale);
vec2 pp     = fract(LUMA_pos * LUMA_size - 0.5);
const vec2 axle = vec2(axis == 0, axis == 1);

vec4 hook() {
    float d, w, wsum, ysum = 0.0;
    if(bool(mod(scale[axis], 2))) {
        for(float i = 1.0 - radius[axis]; i <= radius[axis]; i++) {
            d = i - pp[axis];
            w = weight(d / scale[axis]);
            if (w == 0.0) { continue; }
            wsum += w;
            ysum += w * LUMA_texOff(axle * vec2(d)).x;
        }
    }
    else {
        for(float i = 0.0; i <= radius[axis]; i++) {
            d = i + 0.5;
            w = weight(d / scale[axis]);
            if (w == 0.0) { continue; }
            wsum += w * 2.0;
            ysum += w * (LUMA_texOff(axle * vec2( d)).x +
                         LUMA_texOff(axle * vec2(-d)).x);
        }
    }
    return vec4(ysum / wsum, 0.0, 0.0, 1.0);
}

//!HOOK CHROMA
//!BIND CHROMA
//!BIND LUMA_LOWRES
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.h LUMA_LOWRES.h <
//!DESC CfL Downscaling Yy Box
#define axis 1
#define weight box

float box(const float d)       { return float(abs(d) <= 0.5); }
float triangle(const float d)  { return max(1.0 - abs(d), 0.0); }
float hermite(const float d)   { return smoothstep(0.0, 1.0, 1 - abs(d)); }
float quadratic(const float d) {
    float x = 1.5 * abs(d);
    if (x < 0.5)
        return(0.75 - x * x);
    if (x < 1.5)
        return(0.5 * (x - 1.5) * (x - 1.5));
    return(0.0);
}

vec2 scale  = LUMA_LOWRES_size / CHROMA_size;
vec2 radius = ceil(scale);
vec2 pp     = fract(LUMA_LOWRES_pos * LUMA_LOWRES_size - 0.5);
const vec2 axle = vec2(axis == 0, axis == 1);

vec4 hook() {
    float d, w, wsum, ysum = 0.0;
    if(bool(mod(scale[axis], 2))) {
        for(float i = 1.0 - radius[axis]; i <= radius[axis]; i++) {
            d = i - pp[axis];
            w = weight(d / scale[axis]);
            if (w == 0.0) { continue; }
            wsum += w;
            ysum += w * LUMA_LOWRES_texOff(axle * vec2(d)).x;
        }
    }
    else {
        for(float i = 0.0; i <= radius[axis]; i++) {
            d = i + 0.5;
            w = weight(d / scale[axis]);
            if (w == 0.0) { continue; }
            wsum += w * 2.0;
            ysum += w * (LUMA_LOWRES_texOff(axle * vec2( d)).x +
                         LUMA_LOWRES_texOff(axle * vec2(-d)).x);
        }
    }
    return vec4(ysum / wsum, 0.0, 0.0, 1.0);
}

//!DESC CfL Upscaling UV RAVU-Zoom-AR [R2X]
//!HOOK CHROMA
//!BIND HOOKED
//!BIND ravu_zoom_lut2
//!BIND ravu_zoom_lut2_ar
//!SAVE CHROMA_HIGHRES
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!OFFSET ALIGN
//!WHEN HOOKED.w LUMA.w < HOOKED.h LUMA.h < *
#define LUTPOS(x, lut_size) mix(0.5 / (lut_size), 1.0 - 0.5 / (lut_size), (x))
vec4 hook() {
vec2 pos = HOOKED_pos * HOOKED_size;
vec2 subpix = fract(pos - 0.5);
pos -= subpix;
subpix = LUTPOS(subpix, vec2(9.0));
vec2 subpix_inv = 1.0 - subpix;
subpix /= vec2(2.0, 288.0);
subpix_inv /= vec2(2.0, 288.0);

const ivec2 quad_idx[4] = {{-1,-1}, {-1, 1}, { 1, -1}, { 1, 1}};
vec4 q[3][4];
for(int i = 0; i < 4; i++) {
    q[0][i] = HOOKED_mul * textureGatherOffset(HOOKED_raw, pos * HOOKED_pt, quad_idx[i], 0);
    q[1][i] = HOOKED_mul * textureGatherOffset(HOOKED_raw, pos * HOOKED_pt, quad_idx[i], 1);
}
vec2 sample0  = {q[0][0].w, q[1][0].w};
vec2 sample1  = {q[0][0].x, q[1][0].x};
vec2 sample2  = {q[0][1].w, q[1][1].w};
vec2 sample3  = {q[0][1].x, q[1][1].x};
vec2 sample4  = {q[0][0].z, q[1][0].z};
vec2 sample5  = {q[0][0].y, q[1][0].y};
vec2 sample6  = {q[0][1].z, q[1][1].z};
vec2 sample7  = {q[0][1].y, q[1][1].y};
vec2 sample8  = {q[0][2].w, q[1][2].w};
vec2 sample9  = {q[0][2].x, q[1][2].x};
vec2 sample10 = {q[0][3].w, q[1][3].w};
vec2 sample11 = {q[0][3].x, q[1][3].x};
vec2 sample12 = {q[0][2].z, q[1][2].z};
vec2 sample13 = {q[0][2].y, q[1][2].y};
vec2 sample14 = {q[0][3].z, q[1][3].z};
vec2 sample15 = {q[0][3].y, q[1][3].y};

mat2x3 abd = mat2x3(0.0);
vec2 gx, gy;
gx = (sample4-sample0);
gy = (sample1-sample0);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (sample5-sample1);
gy = (sample2-sample0)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample6-sample2);
gy = (sample3-sample1)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample7-sample3);
gy = (sample3-sample2);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (sample8-sample0)/2.0;
gy = (sample5-sample4);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample9-sample1)/2.0;
gy = (sample6-sample4)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample10-sample2)/2.0;
gy = (sample7-sample5)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample11-sample3)/2.0;
gy = (sample7-sample6);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-sample4)/2.0;
gy = (sample9-sample8);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample13-sample5)/2.0;
gy = (sample10-sample8)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample14-sample6)/2.0;
gy = (sample11-sample9)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.07901060453704994;
gx = (sample15-sample7)/2.0;
gy = (sample11-sample10);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample12-sample8);
gy = (sample13-sample12);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
gx = (sample13-sample9);
gy = (sample14-sample12)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample14-sample10);
gy = (sample15-sample13)/2.0;
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.06153352068439959;
gx = (sample15-sample11);
gy = (sample15-sample14);
abd += mat2x3(gx * gx, gx * gy, gy * gy) * 0.04792235409415088;
vec2 a = vec2(abd[0].x, abd[1].x), b = vec2(abd[0].y, abd[1].y), d = vec2(abd[0].z, abd[1].z);
vec2 T = a + d, D = a * d - b * b;
vec2 delta = sqrt(max(T * T / 4.0 - D, 0.0));
vec2 L1 = T / 2.0 + delta, L2 = T / 2.0 - delta;
vec2 sqrtL1 = sqrt(L1), sqrtL2 = sqrt(L2);
vec2 theta = mix(mod(atan(L1 - a, b) + 3.141592653589793, 3.141592653589793), vec2(0.0), lessThan(abs(b), vec2(1.192092896e-7)));
vec2 lambda = sqrtL1;
vec2 mu = mix((sqrtL1 - sqrtL2) / (sqrtL1 + sqrtL2), vec2(0.0), lessThan(sqrtL1 + sqrtL2, vec2(1.192092896e-7)));
vec2 angle = floor(theta * 24.0 / 3.141592653589793);
vec2 strength = mix(mix(vec2(0.0), vec2(1.0), greaterThanEqual(lambda, vec2(0.004))), mix(vec2(2.0), vec2(3.0), greaterThanEqual(lambda, vec2(0.05))), greaterThanEqual(lambda, vec2(0.016)));
vec2 coherence = mix(mix(vec2(0.0), vec2(1.0), greaterThanEqual(mu, vec2(0.25))), vec2(2.0), greaterThanEqual(mu, vec2(0.5)));
vec2 coord_y = ((angle * 4.0 + strength) * 3.0 + coherence) / 288.0;
vec2 res = vec2(0.0);
mat2x4 w;
mat4x2 cg, cg1;
vec2 lo = vec2(0.0), hi = vec2(0.0);
vec2 lo2 = vec2(0.0), hi2 = vec2(0.0);
w[0] = texture(ravu_zoom_lut2, vec2(0.0, coord_y[0]) + subpix);
w[1] = texture(ravu_zoom_lut2, vec2(0.0, coord_y[1]) + subpix);
res += sample0 * vec2(w[0][0], w[1][0]);
res += sample1 * vec2(w[0][1], w[1][1]);
res += sample2 * vec2(w[0][2], w[1][2]);
res += sample3 * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2, vec2(0.5, coord_y[0]) + subpix);
w[1] = texture(ravu_zoom_lut2, vec2(0.5, coord_y[1]) + subpix);
res += sample4 * vec2(w[0][0], w[1][0]);
res += sample5 * vec2(w[0][1], w[1][1]);
res += sample6 * vec2(w[0][2], w[1][2]);
res += sample7 * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2, vec2(0.0, coord_y[0]) + subpix_inv);
w[1] = texture(ravu_zoom_lut2, vec2(0.0, coord_y[1]) + subpix_inv);
res += sample15 * vec2(w[0][0], w[1][0]);
res += sample14 * vec2(w[0][1], w[1][1]);
res += sample13 * vec2(w[0][2], w[1][2]);
res += sample12 * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2, vec2(0.5, coord_y[0]) + subpix_inv);
w[1] = texture(ravu_zoom_lut2, vec2(0.5, coord_y[1]) + subpix_inv);
res += sample11 * vec2(w[0][0], w[1][0]);
res += sample10 * vec2(w[0][1], w[1][1]);
res += sample9 * vec2(w[0][2], w[1][2]);
res += sample8 * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2_ar, vec2(0.0, coord_y[0]) + subpix);
w[1] = texture(ravu_zoom_lut2_ar, vec2(0.0, coord_y[1]) + subpix);
cg = mat4x2(0.1 + sample0, 1.1 - sample0, 0.1 + sample1, 1.1 - sample1);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo2 += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = mat4x2(0.1 + sample2, 1.1 - sample2, 0.1 + sample3, 1.1 - sample3);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo2 += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2_ar, vec2(0.5, coord_y[0]) + subpix);
w[1] = texture(ravu_zoom_lut2_ar, vec2(0.5, coord_y[1]) + subpix);
cg = mat4x2(0.1 + sample4, 1.1 - sample4, 0.1 + sample5, 1.1 - sample5);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo2 += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = mat4x2(0.1 + sample6, 1.1 - sample6, 0.1 + sample7, 1.1 - sample7);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo2 += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2_ar, vec2(0.0, coord_y[0]) + subpix_inv);
w[1] = texture(ravu_zoom_lut2_ar, vec2(0.0, coord_y[1]) + subpix_inv);
cg = mat4x2(0.1 + sample15, 1.1 - sample15, 0.1 + sample14, 1.1 - sample14);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo2 += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = mat4x2(0.1 + sample13, 1.1 - sample13, 0.1 + sample12, 1.1 - sample12);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo2 += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
w[0] = texture(ravu_zoom_lut2_ar, vec2(0.5, coord_y[0]) + subpix_inv);
w[1] = texture(ravu_zoom_lut2_ar, vec2(0.5, coord_y[1]) + subpix_inv);
cg = mat4x2(0.1 + sample11, 1.1 - sample11, 0.1 + sample10, 1.1 - sample10);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][0], w[1][0]) + cg[2] * vec2(w[0][1], w[1][1]);
lo2 += cg[1] * vec2(w[0][0], w[1][0]) + cg[3] * vec2(w[0][1], w[1][1]);
cg = mat4x2(0.1 + sample9, 1.1 - sample9, 0.1 + sample8, 1.1 - sample8);
cg1 = cg;
cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);cg = matrixCompMult(cg, cg);
hi += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
cg = matrixCompMult(cg, cg1);
hi2 += cg[0] * vec2(w[0][2], w[1][2]) + cg[2] * vec2(w[0][3], w[1][3]);
lo2 += cg[1] * vec2(w[0][2], w[1][2]) + cg[3] * vec2(w[0][3], w[1][3]);
hi = hi2 / hi - 0.1;
lo = 1.1 - lo2 / lo;
res = mix(res, clamp(res, lo, hi), ravu_antiring);
return vec4(res, 0.0, 1.0);
}
//!TEXTURE ravu_zoom_lut2
//!SIZE 18 2592
//!FORMAT rgba16f
//!FILTER LINEAR
//!TEXTURE ravu_zoom_lut2_ar
//!SIZE 18 2592
//!FORMAT rgba16f
//!FILTER LINEAR

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!BIND LUMA_LOWRES
//!BIND CHROMA_HIGHRES
//!WHEN CHROMA.w LUMA.w <
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!OFFSET ALIGN
//!DESC CfL Prediction

#define USE_12_TAP_REGRESSION 1
#define USE_8_TAP_REGRESSIONS 1
#define DEBUG 0

#define weight fsr

float fsr(vec2 v) {
    float d2  = min(dot(v, v), 4.0);
    float d24 = d2 - 4.0;
    return d24 * d24 * d24 * (d2 - 1.0);
}

float cubic(vec2 v) {
    float d2 = min(dot(v, v), 4.0);
    float d  = sqrt(d2);
    float d3 = d2 * d;
    return d < 1.0 ? 1.25 * d3 - 2.25 * d2 + 1.0 : -0.75 * d3 + 3.75 * d2 - 6.0 * d + 3.0;
}

vec4 hook() {
    vec2 mix_coeff = vec2(1.0);
    vec2 corr_exponent = vec2(8.0);

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    float luma_zero = LUMA_tex(LUMA_pos).x;

    vec2 p = HOOKED_pos * HOOKED_size - vec2(0.5);
    vec2 fp = floor(p);
    vec2 pp = fract(p);

#ifdef HOOKED_gather
    const vec2 quad_idx[4] = {{0.0, 0.0}, {2.0, 0.0}, {0.0, 2.0}, {2.0, 2.0}};
    vec4 q[3][4];
    for(int i = 0; i < 4; i++) {
        q[0][i] = LUMA_LOWRES_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 0);
        q[1][i] =      HOOKED_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 0);
        q[2][i] =      HOOKED_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 1);
    }
    vec2 chroma_pixels[16] = {
        {q[1][0].w, q[2][0].w},  {q[1][0].z, q[2][0].z},  {q[1][1].w, q[2][1].w},  {q[1][1].z, q[2][1].z},
        {q[1][0].x, q[2][0].x},  {q[1][0].y, q[2][0].y},  {q[1][1].x, q[2][1].x},  {q[1][1].y, q[2][1].y},
        {q[1][2].w, q[2][2].w},  {q[1][2].z, q[2][2].z},  {q[1][3].w, q[2][3].w},  {q[1][3].z, q[2][3].z},
        {q[1][2].x, q[2][2].x},  {q[1][2].y, q[2][2].y},  {q[1][3].x, q[2][3].x},  {q[1][3].y, q[2][3].y}};
    float luma_pixels[16] = {
         q[0][0].w, q[0][0].z, q[0][1].w, q[0][1].z,
         q[0][0].x, q[0][0].y, q[0][1].x, q[0][1].y,
         q[0][2].w, q[0][2].z, q[0][3].w, q[0][3].z,
         q[0][2].x, q[0][2].y, q[0][3].x, q[0][3].y};
#else
    vec2 pix_idx[16] = {{-0.5,-0.5}, {0.5,-0.5}, {1.5,-0.5}, {2.5,-0.5},
                        {-0.5, 0.5}, {0.5, 0.5}, {1.5, 0.5}, {2.5, 0.5},
                        {-0.5, 1.5}, {0.5, 1.5}, {1.5, 1.5}, {2.5, 1.5},
                        {-0.5, 2.5}, {0.5, 2.5}, {1.5, 2.5}, {2.5, 2.5}};

    float luma_pixels[16];
    vec2 chroma_pixels[16];

    for (int i = 0; i < 16; i++) {
        luma_pixels[i] = LUMA_LOWRES_tex(vec2((fp + pix_idx[i]) * HOOKED_pt)).x;
        chroma_pixels[i] = HOOKED_tex(vec2((fp + pix_idx[i]) * HOOKED_pt)).xy;
    }
#endif

#if (DEBUG == 1)
    vec2 chroma_spatial = vec2(0.5);
    mix_coeff = vec2(1.0);
#else
#ifdef CHROMA_HIGHRES_tex
    vec2 chroma_spatial = CHROMA_HIGHRES_tex(CHROMA_HIGHRES_pos).xy;
#else
    float wt = 0.0;
    vec2 ct = vec2(0.0);
    const int dx[16] = {-1, 0, 1, 2, -1, 0, 1, 2, -1, 0, 1, 2, -1, 0, 1, 2};
    const int dy[16] = {-1, -1, -1, -1, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2};
    float wd[16];
    for(int i = 0; i < 16; i++) {
        wd[i] = weight(vec2(dx[i], dy[i]) - pp);
        wt += wd[i];
        ct += wd[i] * chroma_pixels[i];
    }
    vec2 chroma_spatial = ct / wt;
    vec2 chroma_min = min(min(min(chroma_pixels[5], chroma_pixels[6]), chroma_pixels[9]), chroma_pixels[10]);
    vec2 chroma_max = max(max(max(chroma_pixels[5], chroma_pixels[6]), chroma_pixels[9]), chroma_pixels[10]);
    chroma_spatial = clamp(mix(chroma_spatial, clamp(chroma_spatial, chroma_min, chroma_max), cfl_antiring), 0.0, 1.0);
#endif
#endif

#if (USE_12_TAP_REGRESSION == 1 || USE_8_TAP_REGRESSIONS == 1)
    const int i12[12] = {1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14};
    const int i4y[4] = {1, 2, 13, 14};
    const int i4x[4] = {4, 7, 8, 11};
    const int i4[4] = {5, 6, 9, 10};

    float luma_sum_4 = 0.0;
    float luma_sum_4y = 0.0;
    float luma_sum_4x = 0.0;
    vec2 chroma_sum_4 = vec2(0.0);
    vec2 chroma_sum_4y = vec2(0.0);
    vec2 chroma_sum_4x = vec2(0.0);

    for (int i = 0; i < 4; i++) {
        luma_sum_4 += luma_pixels[i4[i]];
        luma_sum_4y += luma_pixels[i4y[i]];
        luma_sum_4x += luma_pixels[i4x[i]];
        chroma_sum_4 += chroma_pixels[i4[i]];
        chroma_sum_4y += chroma_pixels[i4y[i]];
        chroma_sum_4x += chroma_pixels[i4x[i]];
    }

    float luma_avg_12 = (luma_sum_4 + luma_sum_4y + luma_sum_4x) / 12.0;
    float luma_var_12 = 0.0;
    vec2 chroma_avg_12 = (chroma_sum_4 + chroma_sum_4y + chroma_sum_4x) / 12.0;
    vec2 chroma_var_12 = vec2(0.0);
    vec2 luma_chroma_cov_12 = vec2(0.0);

    float luma_diff_12;
    vec2 chroma_diff_12;
    for(int i = 0; i < 12; i++) {
        luma_diff_12 = luma_pixels[i12[i]] - luma_avg_12;
        chroma_diff_12 = chroma_pixels[i12[i]] - chroma_avg_12;
        luma_var_12 += luma_diff_12 * luma_diff_12;
        chroma_var_12 += chroma_diff_12 * chroma_diff_12;
        luma_chroma_cov_12 += luma_diff_12 * chroma_diff_12;
    }

    vec2 corr = clamp(abs(luma_chroma_cov_12 / max(sqrt(luma_var_12 * chroma_var_12), 1e-6)), 0.0, 1.0);
    mix_coeff = pow(corr, corr_exponent) * mix_coeff;
#endif

#if (USE_12_TAP_REGRESSION == 1)
    vec2 alpha_12 = luma_chroma_cov_12 / max(luma_var_12, 1e-6);
    vec2 beta_12 = chroma_avg_12 - alpha_12 * luma_avg_12;
    vec2 chroma_pred_12 = clamp(alpha_12 * luma_zero + beta_12, 0.0, 1.0);
#endif

#if (USE_8_TAP_REGRESSIONS == 1)
    const int i8y[8] = {1, 2, 5, 6, 9, 10, 13, 14};
    const int i8x[8] = {4, 5, 6, 7, 8, 9, 10, 11};

    float luma_avg_8y = (luma_sum_4 + luma_sum_4y) / 8.0;
    float luma_avg_8x = (luma_sum_4 + luma_sum_4x) / 8.0;
    float luma_var_8y = 0.0;
    float luma_var_8x = 0.0;
    vec2 chroma_avg_8y = (chroma_sum_4 + chroma_sum_4y) / 8.0;
    vec2 chroma_avg_8x = (chroma_sum_4 + chroma_sum_4x) / 8.0;
    vec2 luma_chroma_cov_8y = vec2(0.0);
    vec2 luma_chroma_cov_8x = vec2(0.0);

    float luma_diff_8y;
    float luma_diff_8x;
    vec2 chroma_diff_8y;
    vec2 chroma_diff_8x;
    for(int i = 0; i < 8; i++) {
        luma_diff_8y = luma_pixels[i8y[i]] - luma_avg_8y;
        luma_diff_8x = luma_pixels[i8x[i]] - luma_avg_8x;
        chroma_diff_8y = chroma_pixels[i8y[i]] - chroma_avg_8y;
        chroma_diff_8x = chroma_pixels[i8x[i]] - chroma_avg_8x;
        luma_var_8y += luma_diff_8y * luma_diff_8y;
        luma_var_8x += luma_diff_8x * luma_diff_8x;
        luma_chroma_cov_8y += luma_diff_8y * chroma_diff_8y;
        luma_chroma_cov_8x += luma_diff_8x * chroma_diff_8x;
    }

    vec2 alpha_8y = luma_chroma_cov_8y / max(luma_var_8y, 1e-6);
    vec2 alpha_8x = luma_chroma_cov_8x / max(luma_var_8x, 1e-6);
    vec2 beta_8y = chroma_avg_8y - alpha_8y * luma_avg_8y;
    vec2 beta_8x = chroma_avg_8x - alpha_8x * luma_avg_8x;
    vec2 chroma_pred_8y = clamp(alpha_8y * luma_zero + beta_8y, 0.0, 1.0);
    vec2 chroma_pred_8x = clamp(alpha_8x * luma_zero + beta_8x, 0.0, 1.0);
    vec2 chroma_pred_8 = mix(chroma_pred_8y, chroma_pred_8x, 0.5);
#endif

#if (USE_12_TAP_REGRESSION == 1 && USE_8_TAP_REGRESSIONS == 1)
    output_pix.xy = mix(chroma_spatial, mix(chroma_pred_12, chroma_pred_8, 0.5), mix_coeff);
#elif (USE_12_TAP_REGRESSION == 1 && USE_8_TAP_REGRESSIONS == 0)
    output_pix.xy = mix(chroma_spatial, chroma_pred_12, mix_coeff);
#elif (USE_12_TAP_REGRESSION == 0 && USE_8_TAP_REGRESSIONS == 1)
    output_pix.xy = mix(chroma_spatial, chroma_pred_8, mix_coeff);
#else
    output_pix.xy = chroma_spatial;
#endif

    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return output_pix;
}