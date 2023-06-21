//!HOOK MAINPRESUB
//!BIND HOOKED

const float videoNonLinStretchRatio = 0.5; // x coord stretch factor
const float invideoNonLinStretchRatio = 0.5; // y coord stretch factor

vec2 stretch(vec2 pos, float par, float inpar) {
  float m_stretch = pow(par, videoNonLinStretchRatio);
  float inm_stretch = pow(inpar, invideoNonLinStretchRatio);

  float x = pos.x - 0.5;
  float y = pos.y - 0.5;
  
  return vec2(mix(x * abs(x) * 2.0, x, m_stretch) + 0.5, mix(y * abs(y) * 2.0, y, inm_stretch) + 0.5);
}

vec4 hook() {
  float dar = target_size.x / target_size.y,
        sar = HOOKED_size.x / HOOKED_size.y,
        par = dar / sar,
		inpar = sar / dar;

  return HOOKED_tex(stretch(HOOKED_pos, par, inpar));
}
