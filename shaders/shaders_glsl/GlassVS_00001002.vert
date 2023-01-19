#version 110

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB0[57];
uniform vec4 CB1[216];
attribute vec4 POSITION;
attribute vec4 NORMAL;
attribute vec2 TEXCOORD0;
attribute vec4 COLOR0;
attribute vec4 COLOR1;
varying vec2 VARYING0;
varying vec3 VARYING1;
varying vec4 VARYING2;
varying vec4 VARYING3;
varying vec4 VARYING4;
varying vec4 VARYING5;
varying vec4 VARYING6;
varying vec4 VARYING7;

void main()
{
    vec3 v0 = (NORMAL.xyz * 0.0078740157186985015869140625) - vec3(1.0);
    int v1 = int(COLOR1.x) * 3;
    int v2 = v1 + 1;
    int v3 = v1 + 2;
    float v4 = dot(CB1[v1 * 1 + 0], POSITION);
    float v5 = dot(CB1[v2 * 1 + 0], POSITION);
    float v6 = dot(CB1[v3 * 1 + 0], POSITION);
    vec3 v7 = vec3(v4, v5, v6);
    float v8 = dot(CB1[v1 * 1 + 0].xyz, v0);
    float v9 = dot(CB1[v2 * 1 + 0].xyz, v0);
    float v10 = dot(CB1[v3 * 1 + 0].xyz, v0);
    vec3 v11 = vec3(v8, v9, v10);
    vec3 v12 = CB0[11].xyz - v7;
    vec2 v13 = vec2(TEXCOORD0.x * 4.0, TEXCOORD0.y) * clamp(NORMAL.w, 0.0, 1.0);
    vec3 v14 = vec3(0.0);
    v14.z = NORMAL.w - 1.0;
    vec3 v15 = -CB0[16].xyz;
    float v16 = dot(v11, v15);
    vec4 v17 = vec4(v4, v5, v6, 1.0);
    vec4 v18 = v17 * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec3 v19 = v14;
    v19.x = v13.x;
    vec3 v20 = v19;
    v20.y = v13.y;
    vec3 v21 = ((v7 + (v11 * 6.0)).yxz * CB0[21].xyz) + CB0[22].xyz;
    vec4 v22 = vec4(0.0);
    v22.x = v21.x;
    vec4 v23 = v22;
    v23.y = v21.y;
    vec4 v24 = v23;
    v24.z = v21.z;
    vec4 v25 = v24;
    v25.w = 0.0;
    vec4 v26 = vec4(v12, v18.w);
    float v27 = COLOR0.w * 2.0;
    float v28 = clamp(v27 - 1.0, 0.0, 1.0);
    float v29 = (clamp(2.0 - (dot(v11, normalize(v26.xyz)) * 3.0), 0.0, 1.0) * 0.300000011920928955078125) * clamp(v27, 0.0, 1.0);
    vec4 v30 = COLOR0;
    v30.w = mix(v28, 1.0, v29);
    vec4 v31 = vec4(dot(CB0[25], v17), dot(CB0[26], v17), dot(CB0[27], v17), 0.0);
    v31.w = mix((COLOR1.w * 0.0039215688593685626983642578125) * v28, 1.0, v29);
    float v32 = COLOR1.y * 0.50359570980072021484375;
    float v33 = clamp(v16, 0.0, 1.0);
    vec3 v34 = (CB0[15].xyz * v33) + (CB0[17].xyz * clamp(-v16, 0.0, 1.0));
    vec4 v35 = vec4(0.0);
    v35.x = v34.x;
    vec4 v36 = v35;
    v36.y = v34.y;
    vec4 v37 = v36;
    v37.z = v34.z;
    vec4 v38 = v37;
    v38.w = (v33 * CB0[28].w) * (COLOR1.y * exp2((v32 * dot(v11, normalize(v15 + normalize(v12)))) - v32));
    gl_Position = v18;
    VARYING0 = TEXCOORD0;
    VARYING1 = v20;
    VARYING2 = v30;
    VARYING3 = v25;
    VARYING4 = v26;
    VARYING5 = vec4(v8, v9, v10, COLOR1.z);
    VARYING6 = v38;
    VARYING7 = v31;
}

