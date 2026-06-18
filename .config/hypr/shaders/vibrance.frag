#version 300 es
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;

// Atur tingkat saturasi di sini. 1.0 itu bawaan, > 1.0 makin saturated
const float SATURATION = 1.35;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;
    
    // Pake rumus luminance standar BT.709
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    
    // Mix antara grayscale dan warna asli biar dapet saturasi lebih
    vec3 satColor = mix(vec3(luma), color, SATURATION);
    
    fragColor = vec4(satColor, pixColor.a);
}
