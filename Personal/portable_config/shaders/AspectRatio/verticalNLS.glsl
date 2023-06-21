//!HOOK MAINPRESUB
//!BIND HOOKED

const float videoNonLinStretchRatio = 1;

vec2 stretch(vec2 pos, float par) {
  float m_stretch = pow(par, videoNonLinStretchRatio);

  float y = pos.y - 0.5;
  return vec2(pos.x, mix(y * abs(y) * 2.0, y, m_stretch) + 0.5);
}

vec4 hook() {
  float dar = target_size.x / target_size.y,
        sar = HOOKED_size.x / HOOKED_size.y,
        par = sar / dar;

  return HOOKED_tex(stretch(HOOKED_pos, par));
}
