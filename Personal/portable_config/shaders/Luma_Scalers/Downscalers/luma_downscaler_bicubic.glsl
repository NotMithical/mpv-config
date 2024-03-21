// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//!PARAM radius
//!DESC Filter Radius
//!TYPE float
//!MINIMUM 0.0
2.0

//!PARAM param1
//!DESC Filter Param
//!TYPE float
//!MINIMUM 0.0
0.5

//!PARAM ar_strength
//!DESC AR Strength
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
1.0

//!DESC Luma Downscaler (Bicubic AR 1st Step)
//!HOOK LUMA
//!BIND LUMA
//!SAVE LUMA_LR
//!WIDTH OUTPUT.w
//!HEIGHT LUMA.h
//!WHEN OUTPUT.w LUMA.w / 1.000 < OUTPUT.h LUMA.h / 1.000 < *
//!COMPONENTS 4

float comp_wd(vec2 v) {
    float x = min(length(v), 2.0);
    float c = param1;
    float b = 1.0 - 2.0 * c;
    float  p0 = 6.0 - 2.0 * b,
           p2 = -18.0 + 12.0 * b + 6.0 * c,
           p3 = 12.0 - 9.0 * b - 6.0 * c,
           q0 = 8.0 * b + 24.0 * c,
           q1 = -12.0 * b - 48.0 * c,
           q2 = 6.0 * b + 30.0 * c,
           q3 = -b - 6.0 * c;

    if (x < 1.0) {
        return (p0 + x * x * (p2 + x * p3)) / p0;
    } else {
        return (q0 + x * (q1 + x * (q2 + x * q3))) / p0;
    }
}

vec4 hook() {
    float start  = ceil((LUMA_pos.x - radius * (1.0 / target_size.x)) * LUMA_size.x - 0.5);
    float end = floor((LUMA_pos.x + radius * (1.0 / target_size.x)) * LUMA_size.x - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = LUMA_pos;

    float pix_min = 1.0;
    float pix_max = 0.0;

    for (float dx = start.x; dx <= end.x; dx++) {
        pos.x = LUMA_pt.x * (dx + 0.5);
        vec2 dist = (pos - LUMA_pos) * target_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
        pix_min = min(luma_pix, pix_min);
        pix_max = max(luma_pix, pix_max);
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    output_pix.x = mix(output_pix.x, clamp(output_pix.x, pix_min, pix_max), ar_strength);
    return clamp(output_pix, 0.0, 1.0);
}

//!DESC Luma Downscaler (Bicubic AR 2nd Step)
//!HOOK LUMA
//!BIND LUMA_LR
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w LUMA.w / 1.000 < OUTPUT.h LUMA.h / 1.000 < *
//!COMPONENTS 4

float comp_wd(vec2 v) {
    float x = min(length(v), 2.0);
    float c = param1;
    float b = 1.0 - 2.0 * c;
    float  p0 = 6.0 - 2.0 * b,
           p2 = -18.0 + 12.0 * b + 6.0 * c,
           p3 = 12.0 - 9.0 * b - 6.0 * c,
           q0 = 8.0 * b + 24.0 * c,
           q1 = -12.0 * b - 48.0 * c,
           q2 = 6.0 * b + 30.0 * c,
           q3 = -b - 6.0 * c;

    if (x < 1.0) {
        return (p0 + x * x * (p2 + x * p3)) / p0;
    } else {
        return (q0 + x * (q1 + x * (q2 + x * q3))) / p0;
    }
}

vec4 hook() {
    float start  = ceil((LUMA_LR_pos.y - radius * (1.0 / target_size.y)) * LUMA_LR_size.y - 0.5);
    float end = floor((LUMA_LR_pos.y + radius * (1.0 / target_size.y)) * LUMA_LR_size.y - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = LUMA_LR_pos;

    float pix_min = 1.0;
    float pix_max = 0.0;

    for (float dy = start; dy <= end; dy++) {
        pos.y = LUMA_LR_pt.y * (dy + 0.5);
        vec2 dist = (pos - LUMA_LR_pos) * target_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_LR_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
        pix_min = min(luma_pix, pix_min);
        pix_max = max(luma_pix, pix_max);
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    output_pix.x = mix(output_pix.x, clamp(output_pix.x, pix_min, pix_max), ar_strength);
    return clamp(output_pix, 0.0, 1.0);
}
