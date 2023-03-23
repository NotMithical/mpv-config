//!HOOK MAINPRESUB
//!BIND HOOKED

const float stretchFactor = 1;      //increase to add center area with no stretch at all (start with 1.1 for example)           

vec2 stretch(vec2 pos, float stretchRatio) {
  float mix_stretch = pow(stretchRatio, stretchFactor);

  float x = pos.x - 0.5;
  float actualx = x * stretchRatio ;
  
  float newx = mix(x * abs(x) * 2.0, x, mix_stretch) ; 

  if ((newx / actualx) < 1) {
     return vec2(newx + 0.5, pos.y);
  } else {
     return vec2(actualx + 0.5, pos.y);
  }
}

vec4 hook() {
  float sourceRatio  = target_size.x / target_size.y;
  float displayRatio = HOOKED_size.x / HOOKED_size.y;
  float stretchRatio = sourceRatio  / displayRatio;

  return HOOKED_tex(stretch(HOOKED_pos, stretchRatio));
}