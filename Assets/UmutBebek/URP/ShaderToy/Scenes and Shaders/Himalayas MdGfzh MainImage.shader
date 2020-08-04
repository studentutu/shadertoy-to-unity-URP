Shader "UmutBebek/URP/ShaderToy/Himalayas MdGfzh MainImage"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)


    }

        SubShader
        {
            // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
            // "UniversalRenderPipeline"
            Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
            LOD 300

            // ------------------------------------------------------------------
            // Forward pass. Shades GI, emission, fog and all lights in a single pass.
            // Compared to Builtin pipeline forward renderer, LWRP forward renderer will
            // render a scene with multiple lights with less drawcalls and less overdraw.
            Pass
            {
                // "Lightmode" tag must be "UniversalForward" or not be defined in order for
                // to render objects.
                Name "StandardLit"
                //Tags{"LightMode" = "UniversalForward"}

                //Blend[_SrcBlend][_DstBlend]
                //ZWrite Off ZTest Always
                //ZWrite[_ZWrite]
                //Cull[_Cull]

                HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //do not add LitInput, it has already BaseMap etc. definitions, we do not need them (manually described below)
            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            float4 _Channel0_ST;
            TEXTURE2D(_Channel0);       SAMPLER(sampler_Channel0);
            float4 _Channel1_ST;
            TEXTURE2D(_Channel1);       SAMPLER(sampler_Channel1);
            float4 _Channel2_ST;
            TEXTURE2D(_Channel2);       SAMPLER(sampler_Channel2);
            float4 _Channel3_ST;
            TEXTURE2D(_Channel3);       SAMPLER(sampler_Channel3);

            float4 iMouse;


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionCS               : SV_POSITION;
                float4 screenPos                : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space)
                // Our compiler will strip all unused references (say you don't use view space).
                // Therefore there is more flexibility at no additional cost with this struct.
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                // TRANSFORM_TEX is the same as the old shader library.
                output.uv = TRANSFORM_TEX(input.uv, _Channel0);
                // We just use the homogeneous clip position from the vertex input
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            #define FLT_MAX 3.402823466e+38
            #define FLT_MIN 1.175494351e-38
            #define DBL_MAX 1.7976931348623158e+308
            #define DBL_MIN 2.2250738585072014e-308

             #define iTimeDelta unity_DeltaTime.x
            // float;

            #define iFrame ((int)(_Time.y / iTimeDelta))
            // int;

           #define clamp(x,minVal,maxVal) min(max(x, minVal), maxVal)

           float mod(float a, float b)
           {
               return a - floor(a / b) * b;
           }
           float2 mod(float2 a, float2 b)
           {
               return a - floor(a / b) * b;
           }
           float3 mod(float3 a, float3 b)
           {
               return a - floor(a / b) * b;
           }
           float4 mod(float4 a, float4 b)
           {
               return a - floor(a / b) * b;
           }

           float3 makeDarker(float3 item) {
               float darken = 0.10;
               item.x = max(item.x - darken, 0);
               item.y = max(item.y - darken, 0);
               item.z = max(item.z - darken, 0);
               return item;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Himalayas. Created by Reinder Nijhoff 2018 
// @reindernijhoff 
// 
// https: // www.shadertoy.com / view / MdGfzh 
// 
// This is my first attempt to render volumetric clouds in a fragment shader. 
// 
// 1 unit correspondents to SCENE_SCALE meter. 

#define SCENE_SCALE ( 10. ) 
#define INV_SCENE_SCALE ( .1 ) 

#define MOUNTAIN_HEIGHT ( 5000. ) 
#define MOUNTAIN_HW_RATIO ( 0.00016 ) 

#define SUN_DIR normalize ( float3 ( - .7 , .5 , .75 ) ) 
#define SUN_COLOR ( float3 ( 1. , .9 , .85 ) * 1.4 ) 

#define FLAG_POSITION ( float3 ( 3900.5 , 720. , - 2516. ) * INV_SCENE_SCALE ) 
#define HUMANOID_SCALE ( 2. ) 

#define CAMERA_RO ( float3 ( 3980. , 730. , - 2650. ) * INV_SCENE_SCALE ) 
#define CAMERA_FL 2. 

#define HEIGHT_BASED_FOG_B 0.02 
#define HEIGHT_BASED_FOG_C 0.05 


float3x3 getCamera(in float time , in float4 mouse , inout float3 ro , inout float3 ta) {
    ro = CAMERA_RO;
    float3 cw;
    if (mouse.z > 0.) {
        float2 m = (mouse.xy - .5) * 2.3;
        float my = -sin(m.y);
        cw = normalize(float3 (-sin(-m.x) , my + .15 , cos(-m.x)));
     }
else {
 ro.x += -cos(time * .13) * 5. * INV_SCENE_SCALE;
 ro.z += (-cos(time * .1) * 100. + 20.) * INV_SCENE_SCALE;
 cw = normalize(float3 (-.1 , .18 , 1.));
}
ta = ro + cw * (200. * INV_SCENE_SCALE);
 float3 cp = float3 (0.0 , 1.0 , 0.0);
 float3 cu = normalize(cross(cw , cp));
 float3 cv = normalize(cross(cu , cw));
return float3x3 (cu , cv , cw);
}

void getRay(in float time , in float2 fragCoord , in float2 resolution , in float4 mouse , inout float3 ro , inout float3 rd) {
     float3 ta;
     float3x3 cam = getCamera(time , mouse , ro , ta);
    float2 p = (-resolution.xy + 2.0 * (fragCoord)) / resolution.y;
    rd = mul(cam , normalize(float3 (p , CAMERA_FL)));
 }

// 
// To reduce noise I use temporal reprojection ( both for clouds ( Buffer D ) and the terrain 
// ( Buffer C ) seperatly. The temporal repojection code is based on code from the shader 
// "Rain Forest" ( again by Íñigo Quílez ) : 
// 
// https: // www.shadertoy.com / view / 4ttSWf 
// 
float4 saveCamera(in float time , in float2 fragCoord , in float4 mouse) {
    float3 ro , ta;
    float3x3 cam = getCamera(time , mouse , ro , ta);
    float4 fragColor;

    if (abs(fragCoord.x - 4.5) < 0.5) fragColor = float4 (cam[2] , -dot(cam[2] , ro));
    if (abs(fragCoord.x - 3.5) < 0.5) fragColor = float4 (cam[1] , -dot(cam[1] , ro));
    if (abs(fragCoord.x - 2.5) < 0.5) fragColor = float4 (cam[0] , -dot(cam[0] , ro));

    return fragColor;
 }

float2 reprojectPos(in float3 pos , in float2 resolution , in Texture2D storage, in SamplerState samp) {
    float4x4 oldCam = float4x4 (pointSampleTex2D(storage , samp,  int2 (2 , 0) ) ,
                        pointSampleTex2D(storage , samp, int2 (3 , 0) ) ,
                        pointSampleTex2D(storage , samp, int2 (4 , 0) ) ,
                        0.0 , 0.0 , 0.0 , 1.0);

    float4 wpos = float4 (pos , 1.0);
    float3 cpos = (mul(wpos , oldCam)).xyz;
    float2 npos = CAMERA_FL * cpos.xy / cpos.z;
    return 0.5 + 0.5 * npos * float2 (resolution.y / resolution.x , 1.0);
 }

// 
// Fast skycolor function by Íñigo Quílez 
// https: // www.shadertoy.com / view / MdX3Rr 
// 
float3 getSkyColor(float3 rd) {
    float sundot = clamp(dot(rd , SUN_DIR) , 0.0 , 1.0);
     float3 col = float3 (0.2 , 0.5 , 0.85) * 1.1 - max(rd.y , 0.01) * max(rd.y , 0.01) * 0.5;
    col = lerp(col , 0.85 * float3 (0.7 , 0.75 , 0.85) , pow(1.0 - max(rd.y , 0.0) , 6.0));

    col += 0.25 * float3 (1.0 , 0.7 , 0.4) * pow(sundot , 5.0);
    col += 0.25 * float3 (1.0 , 0.8 , 0.6) * pow(sundot , 64.0);
    col += 0.20 * float3 (1.0 , 0.8 , 0.6) * pow(sundot , 512.0);

    col += clamp((0.1 - rd.y) * 10. , 0. , 1.) * float3 (.0 , .1 , .2);
    col += 0.2 * float3 (1.0 , 0.8 , 0.6) * pow(sundot , 8.0);
    return col;
 }

bool letterBox(float2 fragCoord , const float2 resolution , const float aspect) {
    if (fragCoord.x < 0. || fragCoord.x > resolution.x ||
        abs(2. * fragCoord.y - resolution.y) > resolution.x * (1. / aspect)) {
        return true;
     }
else {
return false;
}
}

// 
// Noise functions 
// 
// Hash without Sine by DaveHoskins 
// 
// https: // www.shadertoy.com / view / 4djSRW 
// 
float hash12(float2 p) {
    p = 50.0 * frac(p * 0.3183099);
    return frac(p.x * p.y * (p.x + p.y));
 }

float hash13(float3 p3) {
    p3 = frac(p3 * 1031.1031);
    p3 += dot(p3 , p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
 }

float3 hash33(float3 p3) {
     p3 = frac(p3 * float3 (.1031 , .1030 , .0973));
    p3 += dot(p3 , p3.yxz + 19.19);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
 }

float valueHash(float3 p3) {
    p3 = frac(p3 * 0.1031);
    p3 += dot(p3 , p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
 }

// 
// Noise functions used for cloud shapes 
// 
float valueNoise(in float3 x , float tile) {
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);

    return lerp(lerp(lerp(valueHash(mod(p + float3 (0 , 0 , 0) , tile)) ,
                        valueHash(mod(p + float3 (1 , 0 , 0) , tile)) , f.x) ,
                   lerp(valueHash(mod(p + float3 (0 , 1 , 0) , tile)) ,
                        valueHash(mod(p + float3 (1 , 1 , 0) , tile)) , f.x) , f.y) ,
               lerp(lerp(valueHash(mod(p + float3 (0 , 0 , 1) , tile)) ,
                        valueHash(mod(p + float3 (1 , 0 , 1) , tile)) , f.x) ,
                   lerp(valueHash(mod(p + float3 (0 , 1 , 1) , tile)) ,
                        valueHash(mod(p + float3 (1 , 1 , 1) , tile)) , f.x) , f.y) , f.z);
 }

float voronoi(float3 x , float tile) {
    float3 p = floor(x);
    float3 f = frac(x);

    float res = 100.;
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                float3 b = float3 (i , j , k);
                float3 c = p + b;

                if (tile > 0.) {
                    c = mod(c , float3 (tile, tile, tile));
                 }

                float3 r = float3 (b)-f + hash13(c);
                float d = dot(r , r);

                if (d < res) {
                    res = d;
                 }
             }
         }
     }

    return 1. - res;
 }

float tilableVoronoi(float3 p , const int octaves , float tile) {
    float f = 1.;
    float a = 1.;
    float c = 0.;
    float w = 0.;

    if (tile > 0.) f = tile;

    for (int i = 0; i < octaves; i++) {
        c += a * voronoi(p * f , f);
        f *= 2.0;
        w += a;
        a *= 0.5;
     }

    return c / w;
 }

float tilableFbm(float3 p , const int octaves , float tile) {
    float f = 1.;
    float a = 1.;
    float c = 0.;
    float w = 0.;

    if (tile > 0.) f = tile;

    for (int i = 0; i < octaves; i++) {
        c += a * valueNoise(p * f , f);
        f *= 2.0;
        w += a;
        a *= 0.5;
     }

    return c / w;
 }

// Himalayas. Created by Reinder Nijhoff 2018 
// Creative Commons Attribution - NonCommercial - ShareAlike 4.0 International License. 
// @reindernijhoff 
// 
// https: // www.shadertoy.com / view / MdGfzh 
// 
// This is my first attempt to render volumetric clouds in a fragment shader. 
// 
// I started this shader by trying to implement the clouds of Horizon Zero Dawn , as 
// described in "The real - time volumetric cloudscapes of Horizon Zero Dawn" by 
// Andrew Schneider and Nathan Vos.[1] To model the shape of the clouds , two look - up 
// textures are created with different frequencies of ( Perlin - ) Worley noise: 
// 
// Buffer A: The main look - up SAMPLE_TEXTURE2D for the cloud shapes. 
// Buffer B: A 3D ( 32x32x32 ) look - up SAMPLE_TEXTURE2D with Worley Noise used to add small details 
// to the shapes of the clouds. I have packed this 3D SAMPLE_TEXTURE2D into a 2D buffer. 
// 
// Because it is not possible ( yet ) to create buffers with fixed size , or 3D buffers , the 
// look - up SAMPLE_TEXTURE2D in Buffer A is 2D , and a slice of the volume that is described in the 
// article. Therefore , and because I didn't have any slots left ( in Buffer C ) to use a 
// cloud type / cloud coverage SAMPLE_TEXTURE2D , the modelling of the cloud shapes in this shader is 
// in the end mostly based on trial and error , and is probably far from the code used in 
// Horizon Zero Dawn. 
// 
// Buffer D: Rendering of the clouds. 
// 
// I render the clouds using the improved integration method of volumetric media , as described 
// in "Physically Based Sky , Atmosphere and Cloud Rendering in Frostbite" by 
// Sébastien Hillaire.[2] 
// 
// You can find the ( excellent ) example shaders of Sébastien Hillaire ( SebH ) here: 
// 
// https: // www.shadertoy.com / view / XlBSRz 
// https: // www.shadertoy.com / view / MdlyDs 
// 
// Buffer C: Landscape 
// 
// To create an interesting scene and to add some scale to the clouds , I render a 
// terrain using a simple heightmap , based on the work by Íñigo Quílez on value noise and its 
// analytical derivatives.[3] 
// 
// In fact , the heightmap of this shader is almost exactly the same as the heightmap that 
// is used in Íñigo Quílez' shader Elevated: 
// 
// https: // www.shadertoy.com / view / MdX3Rr 
// 
// To reduce noise I use temporal reprojection ( both for clouds ( Buffer D ) and the terrain 
// ( Buffer C ) ) separatly. The temporal reprojection code is based on code from the shader 
// "Rain Forest" ( again by Íñigo Quílez ) : 
// 
// https: // www.shadertoy.com / view / 4ttSWf 
// 
// Finally , in the Image tab , clouds and terrain are combined , a small humanoid is added 
// ( by Hazel Quantock ) and post processing is done. 
// 
// [1] https: // www.guerrilla - games.com / read / the - real - time - volumetric - cloudscapes - of - horizon - zeroExtended - dawn 
// [2] https: // media.contentapi.ea.com / content / dam / eacom / frostbite / files / s2016 - pbs - frostbite - sky - clouds - new.pdf 
// [3] http: // iquilezles.org / www / articles / morenoise / morenoise.htm 
// 

#define AA 3 

 // 
 // Cheap 2D Humanoid SDF for dropping into scenes to add a sense of scale. 
 // Hazel Quantock 2018 
 // 
 // Based on: https: // www.shadertoy.com / view / 4scBWN 
 // 
float RoundMax(float a , float b , float r) {
    a += r; b += r;
    float f = (a > 0. && b > 0.) ? sqrt(a * a + b * b) : max(a , b);
    return f - r;
 }

float RoundMin(float a , float b , float r) {
    return -RoundMax(-a , -b , r);
 }

float Humanoid(in float2 uv , in float phase) {
    float n3 = sin((uv.y - uv.x * .7) * 11. + phase) * .014; // "pose" 
    float n0 = sin((uv.y + uv.x * 1.1) * 23. + phase * 2.) * .007;
    float n1 = sin((uv.y - uv.x * .8) * 37. + phase * 4.) * .004;
    float n2 = sin((uv.y + uv.x * .9) * 71. + phase * 8.) * .002;


    float head = length((uv - float2 (0 , 1.65)) / float2 (1 , 1.2)) - .15 / 1.2;
    float neck = length(uv - float2 (0 , 1.5)) - .05;
    float torso = abs(uv.x) - .25 - uv.x * .3;

    torso = RoundMax(torso , uv.y - 1.5 , .2);
    torso = RoundMax(torso , -(uv.y - .6) , .0);

    float f = RoundMin(head , neck , .04);
    f = RoundMin(f , torso , .02);

    float leg = abs(abs(uv.x + (uv.y - .9) * .1 * cos(phase * 3.)) - .15 + .075 * uv.y) - .07 - .07 * uv.y;
    leg = max(leg , uv.y - 1.);

    f = RoundMin(f , leg , .1);

    float stick = max(abs(uv.x + .4 - uv.y * .04) - 0.025 , uv.y - 1.15);
    float arm = max(max(abs(uv.y - 1. - uv.x * .3) - .06 , uv.x) , -uv.x - .4);

    f = RoundMin(f , stick , 0.0);
    f = RoundMin(f , arm , 0.05);

    f += (-n0 + n1 + n2 + n3) * (.1 + .9 * uv.y / 1.6);

    return max(f , -uv.y);
 }

// 
// Lens flare , original based on: 
// musk's lens flare by mu6k 
// 
// https: // www.shadertoy.com / view / 4sX3Rs 
// 
float lensflare(float2 fragCoord) {
    float3 ro , ta;
    float3x3 cam = getCamera(_Time.y , iMouse / _ScreenParams.xyxy , ro , ta);
    float3 cpos = mul(SUN_DIR , cam);
    float2 pos = CAMERA_FL * cpos.xy / cpos.z;
    float2 uv = (-_ScreenParams.xy + 2.0 * fragCoord) / _ScreenParams.y;

     float2 uvd = uv * (length(uv));
     float f = 0.1 / (length(uv - pos) * 16.0 + 1.0);
     f += max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.8 * pos) , 2.0)) , .0) * 0.25;
     float2 uvx = lerp(uv , uvd , -0.5);
     f += max(0.01 - pow(length(uvx + 0.4 * pos) , 2.4) , .0) * 6.0;
     f += max(0.01 - pow(length(uvx - 0.3 * pos) , 1.6) , .0) * 6.0;
     uvx = lerp(uv , uvd , -0.4);
     f += max(0.01 - pow(length(uvx + 0.2 * pos) , 5.5) , .0) * 2.0;

     return f;
 }

bool intersectSphere(in float3 ro , in float3 rd , in float4 sph) {
    float3 ds = ro - sph.xyz;
    float bs = dot(rd , ds);
    float cs = dot(ds , ds) - sph.w * sph.w;
    float ts = bs * bs - cs;

    if (ts > 0.0) {
        ts = -bs - sqrt(ts);
          if (ts > 0.) {
               return true;
           }
     }
    return false;
 }

bool intersectPlane(in float3 ro , in float3 rd , in float3 n , in float3 p0 , inout float dist) {
    dist = dot(p0 - ro , n) / dot(rd , n);
    return dist > 0.;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     if (letterBox(fragCoord , _ScreenParams.xy , 2.35)) {
         fragColor = float4 (0. , 0. , 0. , 1.);
      }
 else {
 float4 col = pointSampleTex2D(_Channel0 , sampler_Channel0 , int2 (fragCoord) );
 float4 clouds = pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (fragCoord) );

 col.rgb = clouds.rgb + col.rgb * clouds.a;

 float3 ro , rd , ta;
   float3x3 cam = getCamera(_Time.y , iMouse / _ScreenParams.xyxy , ro , ta);
 float dist;
 float4 tcol = float4 (0. , 0. , 0. , 0.);
 float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord)) / _ScreenParams.y;
 rd = mul(cam , normalize(float3 (p , CAMERA_FL)));

 if (intersectSphere(ro , rd , float4 (FLAG_POSITION , HUMANOID_SCALE * INV_SCENE_SCALE * 2.))) {
     for (int x = 0; x < AA; x++) {
         for (int y = 0; y < AA; y++) {
             float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + float2 (x , y) / float(AA) - .5)) / _ScreenParams.y;
             rd = mul(cam , normalize(float3 (p , CAMERA_FL)));

             if (intersectPlane(ro , rd , float3 (0 , 0 , 1) , FLAG_POSITION , dist) && dist < col.w) {
                 float3 pos = ro + rd * dist;
                 float2 uv = (pos.xy - FLAG_POSITION.xy) * (SCENE_SCALE / HUMANOID_SCALE);
                 uv.x = -uv.x + uv.y * 0.05;
                 float sdf = Humanoid(uv , 3.);
                 float a = smoothstep(.4 , .6 , .5 - .5 * sdf / (abs(sdf) + .002));
                 float sdf2 = Humanoid(uv + float2 (.025 , 0.05) , 3.);
                 float a2 = smoothstep(.4 , .6 , .5 - .5 * sdf2 / (abs(sdf2) + .002));
                 float c = (a - a2) * 2.;
                 c = clamp(c + uv.x * .2 + .6 , 0. , 1.); c *= c; c *= c;
                 tcol += float4 (lerp(float3 (.04 , 0.05 , 0.06) , SUN_COLOR , c) , a);
              }
          }
      }
     tcol /= float(AA * AA);
  }

 col.rgb = lerp(col.rgb , tcol.rgb , tcol.w);

 // lens flare 
col.rgb += SUN_COLOR * lensflare(fragCoord) * smoothstep(-.3 , .5 , dot(rd , SUN_DIR));
col.rgb = clamp(col.rgb , float3 (0 , 0 , 0) , float3 (1 , 1 , 1));

// gamma and contrast 
col.rgb = lerp(col.rgb , pow(col.rgb , float3 (1. / 2.2, 1. / 2.2, 1. / 2.2)) , .85);
col.rgb = lerp(col.rgb , col.bbb , 0.2);

// vignette 
float2 uv = fragCoord / _ScreenParams.xy;
col.rgb = lerp(col.rgb * col.rgb , col.rgb , pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) , 0.1));

// noise 
//col.rgb -= hash12(fragCoord) * .025;

fragColor = float4 (col.rgb , 1.);


     }

     fragColor.xyz = makeDarker(fragColor.xyz);
return fragColor;
}

//half4 LitPassFragment(Varyings input) : SV_Target
//{
//    [FRAGMENT]
//    //float2 uv = input.uv;
//    //SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, uv + float2(-onePixelX, -onePixelY), _Lod);
//    //_ScreenParams.xy 
//    //half4 color = half4(1, 1, 1, 1);
//    //return color;
//}
ENDHLSL
}
        }
}