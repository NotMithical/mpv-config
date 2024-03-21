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

//!DESC Luma Downscaler (Hermite 1st Step)
//!HOOK LUMA
//!BIND LUMA
//!SAVE LUMA_LR
//!WIDTH OUTPUT.w
//!HEIGHT LUMA.h
//!WHEN OUTPUT.w LUMA.w / 1.000 < OUTPUT.h LUMA.h / 1.000 < *
//!COMPONENTS 4

float comp_wd(vec2 v) {
    float x = min(length(v), 1.0);
    return smoothstep(0.0, 1.0, 1.0 - x);
}

vec4 hook() {
    float start  = ceil((LUMA_pos.x - (1.0 / target_size.x)) * LUMA_size.x - 0.5);
    float end = floor((LUMA_pos.x + (1.0 / target_size.x)) * LUMA_size.x - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = LUMA_pos;

    for (float dx = start.x; dx <= end.x; dx++) {
        pos.x = LUMA_pt.x * (dx + 0.5);
        vec2 dist = (pos - LUMA_pos) * target_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    return clamp(output_pix, 0.0, 1.0);
}

//!DESC Luma Downscaler (Hermite 2nd Step)
//!HOOK LUMA
//!BIND LUMA_LR
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w LUMA.w / 1.000 < OUTPUT.h LUMA.h / 1.000 < *
//!COMPONENTS 4

float comp_wd(vec2 v) {
    float x = min(length(v), 1.0);
    return smoothstep(0.0, 1.0, 1.0 - x);
}

vec4 hook() {
    float start  = ceil((LUMA_LR_pos.y - (1.0 / target_size.y)) * LUMA_LR_size.y - 0.5);
    float end = floor((LUMA_LR_pos.y + (1.0 / target_size.y)) * LUMA_LR_size.y - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = LUMA_LR_pos;

    for (float dy = start; dy <= end; dy++) {
        pos.y = LUMA_LR_pt.y * (dy + 0.5);
        vec2 dist = (pos - LUMA_LR_pos) * target_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_LR_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    return clamp(output_pix, 0.0, 1.0);
}
