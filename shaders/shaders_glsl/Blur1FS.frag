#version 110

#extension GL_ARB_shading_language_include : require
#include <Params.h>
uniform vec4 CB1[10];
uniform sampler2D Texture0Texture;

varying vec2 VARYING0;

void main()
{
    float f0 = (2.0 * CB1[1].z) * CB1[1].z;
    float f1 = exp((-4.0) / f0);
    float f2 = exp((-1.0) / f0) + f1;
    vec2 f3 = CB1[1].xy * (1.0 + (f1 / f2));
    gl_FragData[0] = (texture2D(Texture0Texture, VARYING0) + ((texture2D(Texture0Texture, VARYING0 + f3) + texture2D(Texture0Texture, VARYING0 - f3)) * f2)) / vec4(1.0 + (2.0 * f2));
}

//$$Texture0Texture=s0
