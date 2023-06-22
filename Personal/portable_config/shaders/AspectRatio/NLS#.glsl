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

//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC Bidirectional Nonlinear Stretch

vec2 stretch(vec2 pos, float h_par, float v_par) {
  float h_m_stretch = pow(h_par, HorizontalStretch);
  float v_m_stretch = pow(v_par, VerticalStretch);

  float x = pos.x - 0.5;
  float y = pos.y - 0.5;
  
  return vec2(mix(x * abs(x) * 2.0, x, h_m_stretch) + 0.5, mix(y * abs(y) * 2.0, y, v_m_stretch) + 0.5);
}

vec4 hook() {
  float dar = target_size.x / target_size.y,
        sar = HOOKED_size.x / HOOKED_size.y,
        h_par = dar / sar,
		v_par = sar / dar;

  return HOOKED_tex(stretch(HOOKED_pos, h_par, v_par));
}
