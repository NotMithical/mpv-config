// https://trev16.hatenablog.com/entry/2020/06/07/094646

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND lut
//!DESC gamut mapping (toru)

vec4 hook(){
	vec4 color = HOOKED_texOff(0);

    color.rgb = vec3(pow(color.r, 1.0 / 2.4), pow(color.g, 1.0 / 2.4), pow(color.b, 1.0 / 2.4));
    color.rgb = texture(lut, color.rgb).rgb;
    color.rgb = vec3(pow(color.r, 2.4), pow(color.g, 2.4), pow(color.b, 2.4));

	return color;
}

//!TEXTURE lut
//!SIZE 33 33 33
//!FORMAT rgba16f
//!FILTER LINEAR