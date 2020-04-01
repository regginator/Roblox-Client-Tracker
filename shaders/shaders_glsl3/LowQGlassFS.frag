#version 150

struct Globals
{
    mat4 ViewProjection;
    vec4 ViewRight;
    vec4 ViewUp;
    vec4 ViewDir;
    vec3 CameraPosition;
    vec3 AmbientColor;
    vec3 SkyAmbient;
    vec3 Lamp0Color;
    vec3 Lamp0Dir;
    vec3 Lamp1Color;
    vec4 FogParams;
    vec4 FogColor_GlobalForceFieldTime;
    vec3 Exposure;
    vec4 LightConfig0;
    vec4 LightConfig1;
    vec4 LightConfig2;
    vec4 LightConfig3;
    vec4 ShadowMatrix0;
    vec4 ShadowMatrix1;
    vec4 ShadowMatrix2;
    vec4 RefractionBias_FadeDistance_GlowFactor_SpecMul;
    vec4 OutlineBrightness_ShadowInfo;
    vec4 SkyGradientTop_EnvDiffuse;
    vec4 SkyGradientBottom_EnvSpec;
    vec3 AmbientColorNoIBL;
    vec3 SkyAmbientNoIBL;
    vec4 AmbientCube[12];
    vec4 CascadeSphere0;
    vec4 CascadeSphere1;
    vec4 CascadeSphere2;
    vec4 CascadeSphere3;
    float hybridLerpDist;
    float hybridLerpSlope;
    float evsmPosExp;
    float evsmNegExp;
    float globalShadow;
    float shadowBias;
    float shadowAlphaRef;
    float debugFlags;
};

uniform vec4 CB0[47];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform sampler2D DiffuseMapTexture;

in vec2 VARYING0;
in vec4 VARYING2;
in vec3 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
out vec4 _entryPointOutput;

void main()
{
    vec4 f0 = texture(DiffuseMapTexture, VARYING0);
    vec3 f1 = f0.xyz * VARYING2.xyz;
    vec4 f2 = vec4(f1.x, f1.y, f1.z, f0.w);
    f2.w = VARYING2.w;
    float f3 = clamp(dot(step(CB0[19].xyz, abs(VARYING3 - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f4 = VARYING3.yzx - (VARYING3.yzx * f3);
    vec4 f5 = vec4(clamp(f3, 0.0, 1.0));
    vec4 f6 = mix(texture(LightMapTexture, f4), vec4(0.0), f5);
    vec4 f7 = mix(texture(LightGridSkylightTexture, f4), vec4(1.0), f5);
    float f8 = f7.x;
    vec4 f9 = texture(ShadowMapTexture, VARYING7.xy);
    float f10 = (1.0 - ((step(f9.x, VARYING7.z) * clamp(CB0[24].z + (CB0[24].w * abs(VARYING7.z - 0.5)), 0.0, 1.0)) * f9.y)) * f7.y;
    vec3 f11 = reflect(-normalize(VARYING4.xyz), normalize(VARYING5.xyz));
    float f12 = (VARYING7.w != 0.0) ? 0.0 : (max(VARYING5.w, 0.04500000178813934326171875) * 5.0);
    vec3 f13 = (((VARYING6.xyz * f10) + min((f6.xyz * (f6.w * 120.0)).xyz + (CB0[8].xyz + (CB0[9].xyz * f8)), vec3(CB0[16].w))) * ((mix(vec3(1.0), textureLod(PrefilteredEnvTexture, vec4(f11, f12).xyz, f12).xyz * mix(CB0[26].xyz, CB0[25].xyz, vec3(clamp(f11.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f8)) * VARYING7.w) + ((f2.xyz * f2.xyz).xyz * (VARYING2.w - VARYING7.w)))) + (CB0[10].xyz * ((VARYING6.w * f10) * 0.100000001490116119384765625));
    vec4 f14 = vec4(f13.x, f13.y, f13.z, vec4(0.0).w);
    f14.w = VARYING2.w;
    float f15 = clamp((CB0[13].x * length(VARYING4.xyz)) + CB0[13].y, 0.0, 1.0);
    vec3 f16 = mix(CB0[14].xyz, sqrt(clamp(f14.xyz * CB0[15].y, vec3(0.0), vec3(1.0))).xyz, vec3(f15));
    vec4 f17 = vec4(f16.x, f16.y, f16.z, f14.w);
    f17.w = mix(1.0, VARYING2.w, f15);
    _entryPointOutput = f17;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$DiffuseMapTexture=s3