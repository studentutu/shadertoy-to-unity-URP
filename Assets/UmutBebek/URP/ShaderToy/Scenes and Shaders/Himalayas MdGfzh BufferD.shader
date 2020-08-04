Shader "UmutBebek/URP/ShaderToy/Himalayas MdGfzh BufferD"
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

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv, float lod = 0)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D_LOD(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0), lod);
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

           static const float HEIGHT_BASED_FOG_B = 0.02;
           static const float HEIGHT_BASED_FOG_C = 0.05;


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
    float4x4 oldCam = float4x4 (pointSampleTex2D(storage , samp, int2 (2 , 0) ) ,
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
#define CLOUD_MARCH_STEPS 12 
#define CLOUD_SELF_SHADOW_STEPS 6 

#define EARTH_RADIUS ( 1500000. ) // ( 6371000. ) 
#define CLOUDS_BOTTOM ( 1350. ) 
#define CLOUDS_TOP ( 2350. ) 

#define CLOUDS_LAYER_BOTTOM ( - 150. ) 
#define CLOUDS_LAYER_TOP ( - 70. ) 

#define CLOUDS_COVERAGE ( .52 ) 
#define CLOUDS_LAYER_COVERAGE ( .41 ) 

#define CLOUDS_DETAIL_STRENGTH ( .225 ) 
#define CLOUDS_BASE_EDGE_SOFTNESS ( .1 ) 
#define CLOUDS_BOTTOM_SOFTNESS ( .25 ) 
#define CLOUDS_DENSITY ( .03 ) 
#define CLOUDS_SHADOW_MARGE_STEP_SIZE ( 10. ) 
#define CLOUDS_LAYER_SHADOW_MARGE_STEP_SIZE ( 4. ) 
#define CLOUDS_SHADOW_MARGE_STEP_MULTIPLY ( 1.3 ) 
#define CLOUDS_FORWARD_SCATTERING_G ( .8 ) 
#define CLOUDS_BACKWARD_SCATTERING_G ( - .2 ) 
#define CLOUDS_SCATTERING_LERP ( .5 ) 

#define CLOUDS_AMBIENT_COLOR_TOP ( float3 ( 149. , 167. , 200. ) * ( 1.5 / 255. ) ) 
#define CLOUDS_AMBIENT_COLOR_BOTTOM ( float3 ( 39. , 67. , 87. ) * ( 1.5 / 255. ) ) 
#define CLOUDS_MIN_TRANSMITTANCE .1 

#define CLOUDS_BASE_SCALE 1.51 
#define CLOUDS_DETAIL_SCALE 20. 

 // 
 // Cloud shape modelling and rendering 
 // 
float HenyeyGreenstein(float sundotrd , float g) {
     float gg = g * g;
     return (1. - gg) / pow(1. + gg - 2. * g * sundotrd , 1.5);
 }

float interectCloudSphere(float3 rd , float r) {
    float b = EARTH_RADIUS * rd.y;
    float d = b * b + r * r + 2. * EARTH_RADIUS * r;
    return -b + sqrt(d);
 }

float linearstep(const float s , const float e , float v) {
    return clamp((v - s) * (1. / (e - s)) , 0. , 1.);
 }

float linearstep0(const float e , float v) {
    return min(v * (1. / e) , 1.);
 }

float remap(float v , float s , float e) {
     return (v - s) / (e - s);
 }

float cloudMapBase(float3 p , float norY) {
     float3 uv = p * (0.00005 * CLOUDS_BASE_SCALE);
    float3 cloud = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv.xz).rgb;

    float n = norY * norY;
    n *= cloud.b;
        n += pow(1. - norY , 16.);
     return remap(cloud.r - n , cloud.g , 1.);
 }

float cloudMapDetail(float3 p) {
    // 3d lookup in 2d SAMPLE_TEXTURE2D : ( 
   p = abs(p) * (0.0016 * CLOUDS_BASE_SCALE * CLOUDS_DETAIL_SCALE);

   float yi = mod(p.y , 32.);
   int2 offset = int2 (mod(yi , 8.) , mod(floor(yi / 8.) , 4.)) * 34 + 1;
   float a = SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , (mod(p.xz , 32.) + float2 (offset.xy) + 1.) / _ScreenParams.xy).r;

   yi = mod(p.y + 1. , 32.);
   offset = int2 (mod(yi , 8.) , mod(floor(yi / 8.) , 4.)) * 34 + 1;
   float b = SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , (mod(p.xz , 32.) + float2 (offset.xy) + 1.) / _ScreenParams.xy).r;

   return lerp(a , b , frac(p.y));
}

float cloudGradient(float norY) {
    return linearstep(0. , .05 , norY) - linearstep(.8 , 1.2 , norY);
 }

float cloudMap(float3 pos , float3 rd , float norY) {
    float3 ps = pos;

    float m = cloudMapBase(ps , norY);
     m *= cloudGradient(norY);

     float dstrength = smoothstep(1. , 0.5 , m);

     // erode with detail 
    if (dstrength > 0.) {
          m -= cloudMapDetail(ps) * dstrength * CLOUDS_DETAIL_STRENGTH;
     }

     m = smoothstep(0. , CLOUDS_BASE_EDGE_SOFTNESS , m + (CLOUDS_COVERAGE - 1.));
    m *= linearstep0(CLOUDS_BOTTOM_SOFTNESS , norY);

    return clamp(m * CLOUDS_DENSITY * (1. + max((ps.x - 7000.) * 0.005 , 0.)) , 0. , 1.);
 }

float volumetricShadow(in float3 from , in float sundotrd) {
    float dd = CLOUDS_SHADOW_MARGE_STEP_SIZE;
    float3 rd = SUN_DIR;
    float d = dd * .5;
    float shadow = 1.0;

    for (int s = 0; s < CLOUD_SELF_SHADOW_STEPS; s++) {
        float3 pos = from + rd * d;
        float norY = (length(pos) - (EARTH_RADIUS + CLOUDS_BOTTOM)) * (1. / (CLOUDS_TOP - CLOUDS_BOTTOM));

        if (norY > 1.) return shadow;

        float muE = cloudMap(pos , rd , norY);
        shadow *= exp(-muE * dd);

        dd *= CLOUDS_SHADOW_MARGE_STEP_MULTIPLY;
        d += dd;
     }
    return shadow;
 }

float4 renderClouds(float3 ro , float3 rd , inout float dist) {
    if (rd.y < 0.) {
        return float4 (0 , 0 , 0 , 10);
     }

    ro.xz *= SCENE_SCALE;
    ro.y = sqrt(EARTH_RADIUS * EARTH_RADIUS - dot(ro.xz , ro.xz));

    float start = interectCloudSphere(rd , CLOUDS_BOTTOM);
    float end = interectCloudSphere(rd , CLOUDS_TOP);

    if (start > dist) {
        return float4 (0 , 0 , 0 , 10);
     }

    end = min(end , dist);

    float sundotrd = dot(rd , -SUN_DIR);

    // raymarch 
   float d = start;
   float dD = (end - start) / float(CLOUD_MARCH_STEPS);

   float h = hash13(rd + frac(_Time.y));
   d -= dD * h;

   float scattering = lerp(HenyeyGreenstein(sundotrd , CLOUDS_FORWARD_SCATTERING_G) ,
       HenyeyGreenstein(sundotrd , CLOUDS_BACKWARD_SCATTERING_G) , CLOUDS_SCATTERING_LERP);

   float transmittance = 1.0;
   float3 scatteredLight = float3 (0.0 , 0.0 , 0.0);

   dist = EARTH_RADIUS;

   for (int s = 0; s < CLOUD_MARCH_STEPS; s++) {
       float3 p = ro + d * rd;

       float norY = clamp((length(p) - (EARTH_RADIUS + CLOUDS_BOTTOM)) * (1. / (CLOUDS_TOP - CLOUDS_BOTTOM)) , 0. , 1.);

       float alpha = cloudMap(p , rd , norY);

       if (alpha > 0.) {
           dist = min(dist , d);
           float3 ambientLight = lerp(CLOUDS_AMBIENT_COLOR_BOTTOM , CLOUDS_AMBIENT_COLOR_TOP , norY);

           float3 S = (ambientLight + SUN_COLOR * (scattering * volumetricShadow(p , sundotrd))) * alpha;
           float dTrans = exp(-alpha * dD);
           float3 Sint = (S - S * dTrans) * (1. / alpha);
           scatteredLight += transmittance * Sint;
           transmittance *= dTrans;
        }

       if (transmittance <= CLOUDS_MIN_TRANSMITTANCE) break;

       d += dD;
    }

   return float4 (scatteredLight , transmittance);
}

// 
// 
// !Because I wanted a second cloud layer ( below the horizon ) , I copy - pasted 
// almost all of the code above: 
// 

float cloudMapLayer(float3 pos , float3 rd , float norY) {
    float3 ps = pos;

    float m = cloudMapBase(ps , norY);
    // m *= cloudGradient ( norY ) ; 
   float dstrength = smoothstep(1. , 0.5 , m);

   // erode with detail 
  if (dstrength > 0.) {
        m -= cloudMapDetail(ps) * dstrength * CLOUDS_DETAIL_STRENGTH;
   }

   m = smoothstep(0. , CLOUDS_BASE_EDGE_SOFTNESS , m + (CLOUDS_LAYER_COVERAGE - 1.));

  return clamp(m * CLOUDS_DENSITY , 0. , 1.);
}

float volumetricShadowLayer(in float3 from , in float sundotrd) {
    float dd = CLOUDS_LAYER_SHADOW_MARGE_STEP_SIZE;
    float3 rd = SUN_DIR;
    float d = dd * .5;
    float shadow = 1.0;

    for (int s = 0; s < CLOUD_SELF_SHADOW_STEPS; s++) {
        float3 pos = from + rd * d;
        float norY = clamp((pos.y - CLOUDS_LAYER_BOTTOM) * (1. / (CLOUDS_LAYER_TOP - CLOUDS_LAYER_BOTTOM)) , 0. , 1.);

        if (norY > 1.) return shadow;

        float muE = cloudMapLayer(pos , rd , norY);
        shadow *= exp(-muE * dd);

        dd *= CLOUDS_SHADOW_MARGE_STEP_MULTIPLY;
        d += dd;
     }
    return shadow;
 }

float4 renderCloudLayer(float3 ro , float3 rd , inout float dist) {
    if (rd.y > 0.) {
        return float4 (0 , 0 , 0 , 10);
     }

    ro.xz *= SCENE_SCALE;
    ro.y = 0.;

    float start = CLOUDS_LAYER_TOP / rd.y;
    float end = CLOUDS_LAYER_BOTTOM / rd.y;

    if (start > dist) {
        return float4 (0 , 0 , 0 , 10);
     }

    end = min(end , dist);

    float sundotrd = dot(rd , -SUN_DIR);

    // raymarch 
   float d = start;
   float dD = (end - start) / float(CLOUD_MARCH_STEPS);

   float h = hash13(rd + frac(_Time.y));
   d -= dD * h;

   float scattering = lerp(HenyeyGreenstein(sundotrd , CLOUDS_FORWARD_SCATTERING_G) ,
       HenyeyGreenstein(sundotrd , CLOUDS_BACKWARD_SCATTERING_G) , CLOUDS_SCATTERING_LERP);

   float transmittance = 1.0;
   float3 scatteredLight = float3 (0.0 , 0.0 , 0.0);

   dist = EARTH_RADIUS;

   for (int s = 0; s < CLOUD_MARCH_STEPS; s++) {
       float3 p = ro + d * rd;

       float norY = clamp((p.y - CLOUDS_LAYER_BOTTOM) * (1. / (CLOUDS_LAYER_TOP - CLOUDS_LAYER_BOTTOM)) , 0. , 1.);

       float alpha = cloudMapLayer(p , rd , norY);

       if (alpha > 0.) {
           dist = min(dist , d);
           float3 ambientLight = lerp(CLOUDS_AMBIENT_COLOR_BOTTOM , CLOUDS_AMBIENT_COLOR_TOP , norY);

           float3 S = .7 * (ambientLight + SUN_COLOR * (scattering * volumetricShadowLayer(p , sundotrd))) * alpha;
           float dTrans = exp(-alpha * dD);
           float3 Sint = (S - S * dTrans) * (1. / alpha);
           scatteredLight += transmittance * Sint;
           transmittance *= dTrans;
        }

       if (transmittance <= CLOUDS_MIN_TRANSMITTANCE) break;

       d += dD;
    }

   return float4 (scatteredLight , transmittance);
}

// 
// Main function 
// 
bool resolutionChanged() {
    return floor(pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (0,0) ).r) != floor(_ScreenParams.x);
 }

bool mouseChanged() {
    return iMouse.z * pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (1 , 0) , 1).w < 0.;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     if (fragCoord.y < 1.5) {
         fragColor = saveCamera(_Time.y , fragCoord , iMouse / _ScreenParams.xyxy);
         if (abs(fragCoord.x - 1.5) < 0.5) fragColor = float4 (iMouse);
         if (abs(fragCoord.x - 0.5) < 0.5) fragColor = mouseChanged() ? float4 (0 , 0 , 0 , 0) : float4 (_ScreenParams.xy , 0 , 0);
      }
 else {
 if (letterBox(fragCoord , _ScreenParams.xy , 2.25)) {
      fragColor = float4 (0. , 0. , 0. , 1.);
          return fragColor;
  }
else {
float dist = pointSampleTex2D(_Channel2 , sampler_Channel2 , int2 (fragCoord) , 0).w * SCENE_SCALE;
float4 col = float4 (0 , 0 , 0 , 1);

float3 ro , rd;
  getRay(_Time.y , fragCoord , _ScreenParams.xy , iMouse / _ScreenParams.xyxy , ro , rd);

if (rd.y > 0.) {
    // clouds 
   col = renderClouds(ro , rd , dist);
   float fogAmount = 1. - (.1 + exp(-dist * 0.0001));
   col.rgb = lerp(col.rgb , getSkyColor(rd) * (1. - col.a) , fogAmount);
}
else {
    // cloud layer below horizon 
   col = renderCloudLayer(ro , rd , dist);
   // height based fog , see http: // iquilezles.org / www / articles / fog / fog.htm 
  float fogAmount = HEIGHT_BASED_FOG_C *
       (1. - exp(-dist * rd.y * (INV_SCENE_SCALE * HEIGHT_BASED_FOG_B))) / rd.y;
  col.rgb = lerp(col.rgb , getSkyColor(rd) * (1. - col.a) , clamp(fogAmount , 0. , 1.));
}

if (col.w > 1.) {
    fragColor = float4 (0 , 0 , 0 , 1);
 }
else {
float2 spos = reprojectPos(ro + rd * dist , _ScreenParams.xy , _Channel1 , sampler_Channel1);
float2 rpos = spos * _ScreenParams.xy;

  if (!letterBox(rpos.xy , _ScreenParams.xy , 2.3)
    && !resolutionChanged() && !mouseChanged()) {
    float4 ocol = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , spos ).xyzw;
    col = lerp(ocol , col , 0.05);
 }
fragColor = col;
}
}
}
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