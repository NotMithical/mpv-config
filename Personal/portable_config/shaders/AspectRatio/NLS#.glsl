//!PARAM HorizontalStretch
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM VerticalStretch
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM CropAmount
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BarsAmount
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC Bidirectional Nonlinear Stretch

vec2 stretch(vec2 pos, float h_par, float v_par)
{
	float h_m_stretch = pow(h_par, HorizontalStretch),
		  v_m_stretch = pow(v_par, VerticalStretch),
		  x = pos.x - 0.5,
		  y = pos.y - 0.5;
		  
	// Check how far each pixel is past the target boundaries
    float x_offset = abs(x) - 0.5 + 0.5 / HOOKED_size.x;
    float y_offset = abs(y) - 0.5 + 0.5 / HOOKED_size.y;
	
	// Check if each pixel is outside the target boundaries
    bool outOfBounds = x_offset > 0.5 || y_offset > 0.5;
	
	//Map x & y coordinates to themselves with a curve, taking into account cropping and padding
	if (h_par < 1)
	{		
		return vec2(mix(x * abs(x) * (2 - (CropAmount * 2)), x, h_m_stretch) + 0.5, mix(y * abs(y) * (2 - (BarsAmount * 2)), y, v_m_stretch) + 0.5);
	}
	
	else
	{
		return vec2(mix(x * abs(x) * (2 - (BarsAmount * 2)), x, h_m_stretch) + 0.5, mix(y * abs(y) * (2 - (CropAmount * 2)), y, v_m_stretch) + 0.5);
	}
}

vec4 hook()
{
	float dar = target_size.x / target_size.y,
		  sar = HOOKED_size.x / HOOKED_size.y,
		  h_par = dar / sar,
		  v_par = sar / dar;

	vec2 stretchedPos = stretch(HOOKED_pos, h_par, v_par);
	
	// Check what pixels are outside the target boundaries
	bool outOfBounds;
	
	if (any(lessThan(stretchedPos, vec2(0.0))) || any(greaterThan(stretchedPos, vec2(1.0))))
	{
		outOfBounds = true;
	}
	
	else
	{
		outOfBounds = false;
	}


	// Black out pixels outside target boundaries
	vec4 color;
	
	if (outOfBounds == true)
	{
		color = vec4(0.0);
	}
	
	else
	{
		color = HOOKED_tex(stretchedPos);
	}
	
	return color;
}