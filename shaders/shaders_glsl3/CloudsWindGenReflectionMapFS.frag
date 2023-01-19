#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
const float f0[48] = float[](15.71790981292724609375, 12.89408969879150390625, 7.7199840545654296875, 5.107762813568115234375, 3.9570920467376708984375, 3.1285419464111328125, 2.467976093292236328125, 1.94060599803924560546875, 1.519268035888671875, 1.1720600128173828125, 0.9068109989166259765625, 0.696639001369476318359375, 0.53097999095916748046875, 0.4037419855594635009765625, 0.3046739995479583740234375, 0.230042994022369384765625, 0.1724649965763092041015625, 0.12898500263690948486328125, 0.096061997115612030029296875, 0.07203499972820281982421875, 0.0546710006892681121826171875, 0.0418930016458034515380859375, 0.0329019986093044281005859375, 0.0265490002930164337158203125, 0.022500999271869659423828125, 0.02016899921000003814697265625, 0.01880300045013427734375, 0.01828599907457828521728515625, 0.01808599941432476043701171875, 0.02294900082051753997802734375, 0.02805699966847896575927734375, 0.0330980010330677032470703125, 0.033073000609874725341796875, 0.03599999845027923583984375, 0.051086999475955963134765625, 0.108067996799945831298828125, 0.17280800640583038330078125, 0.2078000009059906005859375, 0.13236899673938751220703125, 0.111766003072261810302734375, 0.110400997102260589599609375, 0.10523100197315216064453125, 0.104189001023769378662109375, 0.108497999608516693115234375, 0.12747399508953094482421875, 0.2075670063495635986328125, 0.3197790086269378662109375, 0.4679400026798248291015625);

#include <CloudsParams.h>
#include <RayFrame.h>
uniform vec4 CB0[57];
uniform vec4 CB5[5];
uniform vec4 CB4[2];
uniform samplerCube PrefilteredEnvTexture;
uniform sampler2D CloudsDistanceFieldTexture;
uniform sampler2D DetailTexTexture;

out vec4 _entryPointOutput_color;

void main()
{
    vec2 f1 = ((gl_FragCoord.xy * CB4[0].xy) - vec2(0.5)) * 2.0;
    float f2 = dot(f1, f1);
    vec4 f3;
    if (f2 > 1.0)
    {
        f3 = vec4(0.0);
    }
    else
    {
        vec3 f4 = normalize(vec3(f1.x, 0.5 - (0.5 * f2), f1.y));
        vec4 f5;
        do
        {
            if (f4.y < 0.0)
            {
                f5 = vec4(0.0);
                break;
            }
            vec3 f6 = vec3(CB0[11].x, 0.0, CB0[11].z) * 0.00028000000747852027416229248046875;
            vec3 f7 = f6;
            f7.y = f6.y + 971.0;
            float f8 = dot(f4, f7);
            float f9 = 2.0 * f8;
            vec2 f10 = (vec2(f8 * (-2.0)) + sqrt(vec2(f9 * f9) - ((vec2(dot(f7, f7)) - vec2(948676.0, 953552.25)) * 4.0))) * 0.5;
            float f11 = f10.x;
            float f12 = dot(CB0[16].xyz, f4);
            float f13 = (0.5 + (0.5 * f12)) * 46.5;
            int f14 = int(f13);
            vec3 f15 = f6 + (f4 * f11);
            f15.y = 0.0;
            vec2 f16 = (f15 + CB5[0].xyz).xz;
            float f17 = f11 * 0.0588235296308994293212890625;
            vec4 f18 = textureLod(CloudsDistanceFieldTexture, vec4(f16 * vec2(0.03125), 0.0, f17).xy, f17);
            float f19 = f18.x;
            float f20 = 0.001000000047497451305389404296875 + CB5[4].y;
            float f21 = 0.550000011920928955078125 * CB5[2].x;
            float f22 = 0.180000007152557373046875 * CB5[4].x;
            float f23 = f19 + ((((15.0 * (f19 - f21)) * CB5[4].x) + f22) * textureLod(DetailTexTexture, vec4(f16 * f20, 0.0, f17).xy, f17).x);
            bool f24 = f23 < CB5[2].x;
            float f25;
            vec4 f26;
            if (f24)
            {
                float f27 = CB5[2].x - f23;
                vec2 f28 = f16 - (CB0[16].xyz.xz * 0.5);
                float f29 = f10.y * 0.0588235296308994293212890625;
                vec4 f30 = textureLod(CloudsDistanceFieldTexture, vec4(f28 * vec2(0.03125), 0.0, f29).xy, f29);
                float f31 = f30.x;
                float f32 = clamp(CB5[2].x - clamp(f31 + ((((15.0 * (f31 - f21)) * CB5[4].x) + f22) * textureLod(DetailTexTexture, vec4(f28 * f20, 0.0, f29).xy, f29).x), 0.0, 1.0), 0.0, 1.0);
                float f33 = 0.5 * f27;
                vec3 f34 = f4 * f4;
                bvec3 f35 = lessThan(f4, vec3(0.0));
                vec3 f36 = vec3(f35.x ? f34.x : vec3(0.0).x, f35.y ? f34.y : vec3(0.0).y, f35.z ? f34.z : vec3(0.0).z);
                vec3 f37 = f34 - f36;
                float f38 = f37.x;
                float f39 = f37.y;
                float f40 = f37.z;
                float f41 = f36.x;
                float f42 = f36.y;
                float f43 = f36.z;
                vec3 f44 = (max(mix(vec3(0.1500000059604644775390625 + (f27 * 0.1500000059604644775390625)), mix(CB0[31].xyz, CB0[30].xyz, vec3(f33)), vec3(clamp(exp2(CB0[16].y), 0.0, 1.0))) * (((((((CB0[40].xyz * f38) + (CB0[42].xyz * f39)) + (CB0[44].xyz * f40)) + (CB0[41].xyz * f41)) + (CB0[43].xyz * f42)) + (CB0[45].xyz * f43)) + (((((((CB0[34].xyz * f38) + (CB0[36].xyz * f39)) + (CB0[38].xyz * f40)) + (CB0[35].xyz * f41)) + (CB0[37].xyz * f42)) + (CB0[39].xyz * f43)) * 1.0)), CB0[33].xyz + CB0[32].xyz) + ((CB0[15].xyz * (((((0.2899999916553497314453125 * exp2(f32 * (-9.19999980926513671875))) + (f27 * 0.1689999997615814208984375)) * 0.93599998950958251953125) + ((f32 * 2.400000095367431640625) * f33)) * (0.100000001490116119384765625 + clamp(1.0 - (2.125 * f32), 0.0, 1.0)))) * 2.099999904632568359375)) * CB5[3].xyz;
                float f45 = pow(exp2((-1.44269502162933349609375) * (((50.0 * CB5[2].y) * clamp(1.0 + (0.001000000047497451305389404296875 * (6000.0 - CB0[11].y)), 0.0, 1.0)) * f27)), 0.3300000131130218505859375);
                vec4 f46 = vec4(0.0);
                f46.x = f44.x;
                vec4 f47 = f46;
                f47.y = f44.y;
                vec4 f48 = f47;
                f48.z = f44.z;
                vec3 f49 = f48.xyz + (((((((CB0[15].xyz * clamp(1.0 - (f32 * 1.2799999713897705078125), 0.0, 1.0)) * 2.0) * clamp(-f12, 0.0, 1.0)) * (mix(f0[f14], f0[f14 + 1], fract(f13)) * 0.125)) * (1.0 - f45)) * exp2(0.10999999940395355224609375 - (f32 * 2.2400000095367431640625))) * CB5[3].xyz);
                vec4 f50 = f48;
                f50.x = f49.x;
                vec4 f51 = f50;
                f51.y = f49.y;
                vec4 f52 = f51;
                f52.z = f49.z;
                f26 = f52;
                f25 = f45;
            }
            else
            {
                f26 = vec4(0.0);
                f25 = 1.0;
            }
            if (!(f24 ? true : false))
            {
                f5 = f26;
                break;
            }
            float f53 = pow(max(exp2((CB0[18].z * 3.5714285373687744140625) * (f11 * f11)), 9.9999997473787516355514526367188e-05), 0.125);
            vec3 f54 = textureLod(PrefilteredEnvTexture, vec4(f4, 0.0).xyz, max(CB0[18].y, f53) * 5.0).xyz;
            bvec3 f55 = bvec3(!(CB0[18].w == 0.0));
            vec3 f56 = mix(vec3(f55.x ? CB0[19].xyz.x : f54.x, f55.y ? CB0[19].xyz.y : f54.y, f55.z ? CB0[19].xyz.z : f54.z), f26.xyz, vec3(f53));
            vec4 f57 = f26;
            f57.x = f56.x;
            vec4 f58 = f57;
            f58.y = f56.y;
            vec4 f59 = f58;
            f59.z = f56.z;
            float f60 = 1.0 - f25;
            vec4 f61 = f59;
            f61.w = f60;
            vec4 f62 = f61;
            f62.w = f60 * max(f53, CB0[18].y);
            f5 = f62;
            break;
        } while(false);
        vec3 f63 = f5.xyz * f5.w;
        vec4 f64 = f5;
        f64.x = f63.x;
        vec4 f65 = f64;
        f65.y = f63.y;
        vec4 f66 = f65;
        f66.z = f63.z;
        f3 = f66;
    }
    _entryPointOutput_color = f3;
}

//$$PrefilteredEnvTexture=s15
//$$CloudsDistanceFieldTexture=s0
//$$DetailTexTexture=s2
