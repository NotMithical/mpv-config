// https://github.com/jedypod/gamut-compress
// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lmt/LMT.Academy.ReferenceGamutCompress.ctl

//!PARAM cyan_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.518705262732682

//!PARAM magenta_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0750082200767368

//!PARAM yellow_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0887800398456782

//!PARAM cyan_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
1.0505085424784364

//!PARAM magenta_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.9405097727736265

//!PARAM yellow_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.9771607745933959

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (jedypod)

#define func    parabolic


// Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
float parabolic(float dist, float lim, float thr) {
    if (dist > thr) {
        // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
        float scale = (1.0 - thr) / sqrt(lim - 1.0);
        float sacle_ = scale * scale / 4.0;
        dist = scale * (sqrt(dist - thr + sacle_) - sqrt(sacle_)) + thr;
    }

    return dist;
}

float power(float dist, float lim, float thr) {
    float pwr = 1.2;

    if (dist > thr) {
        // Calculate scale factor for y = 1 intersect
        float scl = (lim - thr) / pow(pow((1.0 - thr) / (lim - thr), -pwr) - 1.0, 1.0 / pwr);

        // Normalize distance outside threshold by scale factor
        float nd = (dist - thr) / scl;
        float p = pow(nd, pwr);

        // Compress
        dist = thr + scl * nd / (pow(1.0 + p, 1.0 / pwr));
    }

    return dist;
}

vec3 gamut_compress(vec3 rgb) {
    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = vec3(cyan_limit, magenta_limit, yellow_limit);

    // Amount of outer gamut to affect
    vec3 th = vec3(cyan_threshold, magenta_threshold, yellow_threshold);

    // Achromatic axis
    float ac = max(max(rgb.r, rgb.g), rgb.b);

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Compressed distance
    vec3 cd = vec3(
        func(d.x, dl.x, th.x),
        func(d.y, dl.y, th.y),
        func(d.z, dl.z, th.z)
    );

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    return crgb;
}

mat3 M = mat3(
     1.6604910021084354,  -0.5876411387885495,  -0.07284986331988474,
    -0.12455047452159074,  1.1328998971259596,  -0.008349422604369515,
    -0.01815076335490526, -0.10057889800800737,  1.118729661362913);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = gamut_compress(color.rgb * M);

    return color;
}
