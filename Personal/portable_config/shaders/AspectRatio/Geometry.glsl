//!PARAM outputResolutionX
//!DESC Horizontal resolution of the screen
//!TYPE float
//!MINIMUM 0.0
3840.0

//!PARAM outputResolutionY
//!DESC Vertical resolution of the screen
//!TYPE float
//!MINIMUM 0.0
2160.0

//!PARAM distortionFactorX
//!DESC Horizontal distortion factor (higher = more curved distortion)
//!TYPE float
0.0

//!PARAM distortionFactorY
//!DESC Vertical distortion factor (higher = more curved distortion)
//!TYPE float
0.0

//!PARAM distortionCenterX
//!DESC Horizontal center of the distortion adjustment. 1 = symmetrical to y, 0 = only bottom, 2 = only top
//!TYPE float
1.0

//!PARAM distortionCenterY
//!DESC Vertical center of the distortion adjustment. 1 = symmetrical to y, 0 = only bottom, 2 = only top
//!TYPE float
1.0

//!PARAM distortionBowY
//!DESC Vertical bow factor, 1 = none, >1 bow to bottom, <1 bow to top
//!TYPE float
1.0

//!PARAM trapezTop
//!DESC Trapezoid distortion factor for the top of the picture
//!TYPE float
1.0

//!PARAM trapezBottom
//!DESC Trapezoid distortion factor for the bottom of the picture
//!TYPE float
1.0

//!PARAM linearityCorrectionX
//!DESC Horizontal linearity correction for anamorphic lens
//!TYPE float
1.0

//!PARAM linearityCorrectionY
//!DESC Vertical linearity correction for anamorphic lens
//!TYPE float
1.0

//!DESC geometry correction (warping)
//!HOOK OUTPUT   
//!BIND HOOKED
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

// float outputResolutionX = 3840.0;
// float outputResolutionY = 2160.0;
//
// float distortionFactorX = 0.0; 		// higher = more curved distortion
// float distortionFactorY = 0.0; 		// higher = more curved distortion
// float distortionCenterX = 1.0; 		// 1 = symmetrical to y. 0 = only bottom. 2 = only top.
// float distortionCenterY = 1.0; 		// 1 = symmetrical to y. 0 = only bottom. 2 = only top.
// float distortionBowY = 1.0;		// 1 = none. >1 bow to bottom. <1 bow to top
// 
// float trapezTop = 1.0;			// trapezoid distortion factor for the top of the picture
// float trapezBottom = 1.0;		// trapezoid distortion factor for the bottom of the picture
// 
// float linearityCorrectionX = 1.0;	// corrects horizontal linearity for anamorphic lens
// float linearityCorrectionY = 1.0;	// corrects vertical linearity for anamorphic lens

vec3 Bicubic_fast(in vec2 uv, in vec2 InvResolution)
{
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) // ignore pixels outside the picture
    return vec3(0.0);
    
    // the following code is adapted from here: https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    vec2 samplePos = uv / InvResolution;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / (w1 + w2);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0 = texPos1 - 1;
    vec2 texPos3 = texPos1 + 2;
    vec2 texPos12 = texPos1 + offset12;

    texPos0 *= InvResolution;
    texPos3 *= InvResolution;
    texPos12 *= InvResolution;

    vec4 result = vec4(0.0);
    result += HOOKED_tex(vec2(texPos0.x, texPos0.y)) * w0.x * w0.y;
    result += HOOKED_tex(vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += HOOKED_tex(vec2(texPos3.x, texPos0.y)) * w3.x * w0.y;

    result += HOOKED_tex(vec2(texPos0.x, texPos12.y)) * w0.x * w12.y;
    result += HOOKED_tex(vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += HOOKED_tex(vec2(texPos3.x, texPos12.y)) * w3.x * w12.y;
    
    result += HOOKED_tex(vec2(texPos0.x, texPos3.y)) * w0.x * w3.y;
    result += HOOKED_tex(vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += HOOKED_tex(vec2(texPos3.x, texPos3.y)) * w3.x * w3.y;

    return result.rgb;
}

vec4 hook() 
{
    vec2 uv = HOOKED_pos;
    
    float zoomX = outputResolutionX / target_size.x;
    float zoomY = outputResolutionY / target_size.y;
    float xZoomed = (uv.x - 0.5) / zoomX + 0.5;
    float yZoomed = (uv.y - 0.5) / zoomY + 0.5;

    // perform distortion for curved screen (follows a parabola)
    uv.x += distortionFactorX * (-2.0 * uv.x + distortionCenterX) * yZoomed * (yZoomed - 1.0);	
    uv.y += distortionFactorY * (-2.0 * pow(uv.y, distortionBowY) + distortionCenterY) * xZoomed * (xZoomed - 1.0);
    
    // trapezoid
    float size = mix(trapezTop, trapezBottom, yZoomed);
    float reciprocal = 1.0 / size;
    uv.x = uv.x * reciprocal + (1.0 - reciprocal) / 2.0;
    
    // linearity
    if(linearityCorrectionX != 1.0)
    {
        float x = xZoomed - 0.5;
        uv.x = mix(x * abs(x) * 2.0, uv.x - 0.5, linearityCorrectionX) + 0.5;
    }
    if(linearityCorrectionY != 1.0)
    {
        float y = yZoomed - 0.5;
        uv.y = mix(y * abs(y) * 2.0, uv.y - 0.5, linearityCorrectionY) + 0.5;
    }
    
    vec3 result = Bicubic_fast(uv, 1.0 / HOOKED_size);
    
    return vec4(result, 1.0);
}
