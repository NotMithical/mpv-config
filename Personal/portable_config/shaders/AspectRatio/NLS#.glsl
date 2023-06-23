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

//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC Bidirectional Nonlinear Stretch

vec2 stretch(vec2 pos, float h_par, float v_par)
{
	float h_m_stretch = pow(h_par, HorizontalStretch),
		  v_m_stretch = pow(v_par, VerticalStretch),
		  x = pos.x - 0.5,
		  y = pos.y - 0.5;
	
	//Map x & y coordinates to themselves with a curve
	if (h_par < 1)
	{
		return vec2(mix(x * abs(x) * (2 - (CropAmount * 2)), x, h_m_stretch) + 0.5, mix(y * abs(y) * 2, y, v_m_stretch) + 0.5);
	}
	
	else
	{
		return vec2(mix(x * abs(x) * 2, x, h_m_stretch) + 0.5, mix(y * abs(y) * (2 - (CropAmount * 2)), y, v_m_stretch) + 0.5);
	}
}

vec4 hook()
{
	float dar = target_size.x / target_size.y,
		  sar = HOOKED_size.x / HOOKED_size.y,
		  h_par = dar / sar,
		  v_par = sar / dar;

	return HOOKED_tex(stretch(HOOKED_pos, h_par, v_par));
}
