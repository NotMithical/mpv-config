// PQ_Blackpoint by NotMithical
//
// --Paramters Summary--
// Blackpoint
//		Display's MinTML express as a PQ code value divided by 1024.
// Rolloff
// 		Interpolation between input color and Blackpoint will taper off as it approaches this point, 10 nits by default. Expressed as a PQ code value divided by 1024.

//!PARAM Blackpoint
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.13

//!PARAM Rolloff
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.3

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Blackpoint Correction

vec4 hook() {
    vec4 color = HOOKED_texOff(0);
	
	// Linearly interpolate between the input pixel color and Blackpoint, tapering off as color approaches RolloffStop
	if (((Rolloff - color.x) > 0.0) && (color.x < Blackpoint))
	{
		color.x = mix(color.x, Blackpoint, clamp((Rolloff - color.x), 0.0, 1.0));
	}
	
	if (((Rolloff - color.y) > 0.0) && (color.y < Blackpoint))
	{
		color.y = mix(color.y, Blackpoint, clamp((Rolloff - color.y), 0.0, 1.0));
	}
	
	if (((Rolloff - color.z) > 0.0) && (color.z < Blackpoint))
	{
		color.z = mix(color.z, Blackpoint, clamp((Rolloff - color.z), 0.0, 1.0));
	}

    return color;
}
