Shader "UmutBebek/URP/ShaderToy/Planet Shadertoy 4tjGRh"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

DEG_TO_RAD("DEG_TO_RAD", float) = 0
MAX1("MAX1", float) = 10000.0
EARTH_RADIUS("EARTH_RADIUS", float) = 1000.
EARTH_ATMOSPHERE("EARTH_ATMOSPHERE", float) = 5.
EARTH_CLOUDS("EARTH_CLOUDS", float) = 1.
RING_INNER_RADIUS("RING_INNER_RADIUS", float) = 1500.
RING_OUTER_RADIUS("RING_OUTER_RADIUS", float) = 2300.
RING_HEIGHT("RING_HEIGHT", float) = 2.

SEA_NUM_STEPS("SEA_NUM_STEPS", int) = 7
TERRAIN_NUM_STEPS("TERRAIN_NUM_STEPS", int) = 140
ASTEROID_NUM_STEPS("ASTEROID_NUM_STEPS", int) = 11
ASTEROID_NUM_BOOL_SUB("ASTEROID_NUM_BOOL_SUB", int) = 7
RING_VOXEL_STEPS("RING_VOXEL_STEPS", int) = 25
ASTEROID_MAX_DISTANCE("ASTEROID_MAX_DISTANCE", float) = 1.1
FBM_STEPS("FBM_STEPS", int) = 4
ATMOSPHERE_NUM_OUT_SCATTER("ATMOSPHERE_NUM_OUT_SCATTER", int) = 5
ATMOSPHERE_NUM_IN_SCATTER("ATMOSPHERE_NUM_IN_SCATTER", int) = 7

SUN_DIRECTION("SUN_DIRECTION", vector) = (.940721 , .28221626 , .18814417)
SUN_COLOR("SUN_COLOR", vector) = (.3 , .21 , .165)
m2("m2", vector) = (0.80 , -0.60 , 0.60 , 0.80)
ASTEROID_TRESHOLD("ASTEROID_TRESHOLD", float) = 0.001
ASTEROID_EPSILON("ASTEROID_EPSILON", float) = 0
ASTEROID_DISPLACEMENT("ASTEROID_DISPLACEMENT", float) = 0.1
ASTEROID_RADIUS("ASTEROID_RADIUS", float) = 0.13
RING_COLOR_1("RING_COLOR_1", vector) = (0.42 , 0.3 , 0.2)
RING_COLOR_2("RING_COLOR_2", vector) = (0.41 , 0.51 , 0.52)
RING_DETAIL_DISTANCE("RING_DETAIL_DISTANCE", float) = 40.
RING_VOXEL_STEP_SIZE("RING_VOXEL_STEP_SIZE", float) = .03
ATMOSPHERE_K_R("ATMOSPHERE_K_R", float) = 0.166
ATMOSPHERE_K_M("ATMOSPHERE_K_M", float) = 0.0025
ATMOSPHERE_E("ATMOSPHERE_E", float) = 12.3
ATMOSPHERE_C_R("ATMOSPHERE_C_R", vector) = (0.3 , 0.7 , 1.0)
ATMOSPHERE_G_M("ATMOSPHERE_G_M", float) = -0.85
ATMOSPHERE_SCALE_H("ATMOSPHERE_SCALE_H", float) = 0
ATMOSPHERE_SCALE_L("ATMOSPHERE_SCALE_L", float) = 0
ATMOSPHERE_FNUM_OUT_SCATTER("ATMOSPHERE_FNUM_OUT_SCATTER", float) = 0
ATMOSPHERE_FNUM_IN_SCATTER("ATMOSPHERE_FNUM_IN_SCATTER", float) = 0
ATMOSPHERE_NUM_OUT_SCATTER_LOW("ATMOSPHERE_NUM_OUT_SCATTER_LOW", int) = 2
ATMOSPHERE_NUM_IN_SCATTER_LOW("ATMOSPHERE_NUM_IN_SCATTER_LOW", int) = 4
ATMOSPHERE_FNUM_OUT_SCATTER_LOW("ATMOSPHERE_FNUM_OUT_SCATTER_LOW", float) = 0
ATMOSPHERE_FNUM_IN_SCATTER_LOW("ATMOSPHERE_FNUM_IN_SCATTER_LOW", float) = 0
SEA_ITER_GEOMETRY("SEA_ITER_GEOMETRY", int) = 3
SEA_ITER_FRAGMENT("SEA_ITER_FRAGMENT", int) = 5
SEA_EPSILON("SEA_EPSILON", float) = 0
SEA_HEIGHT("SEA_HEIGHT", float) = 0.6
SEA_CHOPPY("SEA_CHOPPY", float) = 4.0
SEA_SPEED("SEA_SPEED", float) = 0.8
SEA_FREQ("SEA_FREQ", float) = 0.16
SEA_BASE("SEA_BASE", vector) = (0.1 , 0.19 , 0.22)
SEA_WATER_COLOR("SEA_WATER_COLOR", vector) = (0.8 , 0.9 , 0.6)
sea_octave_m("sea_octave_m", vector) = (1.6 , 1.2 , -1.2 , 1.6)
terrainM2("terrainM2", vector) = (1.6 , -1.2 , 1.2 , 1.6)
llamelScale("llamelScale", float) = 5.

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
float DEG_TO_RAD;
float MAX1;
float EARTH_RADIUS;
float EARTH_ATMOSPHERE;
float EARTH_CLOUDS;
float RING_INNER_RADIUS;
float RING_OUTER_RADIUS;
float RING_HEIGHT;

int SEA_NUM_STEPS;
int TERRAIN_NUM_STEPS;
int ASTEROID_NUM_STEPS;
int ASTEROID_NUM_BOOL_SUB;
int RING_VOXEL_STEPS;
float ASTEROID_MAX_DISTANCE;
int FBM_STEPS;
int ATMOSPHERE_NUM_OUT_SCATTER;
int ATMOSPHERE_NUM_IN_SCATTER;

float4 SUN_DIRECTION;
float4 SUN_COLOR;
float4 m2;
float ASTEROID_TRESHOLD;
float ASTEROID_EPSILON;
float ASTEROID_DISPLACEMENT;
float ASTEROID_RADIUS;
float4 RING_COLOR_1;
float4 RING_COLOR_2;
float RING_DETAIL_DISTANCE;
float RING_VOXEL_STEP_SIZE;
float ATMOSPHERE_K_R;
float ATMOSPHERE_K_M;
float ATMOSPHERE_E;
float4 ATMOSPHERE_C_R;
float ATMOSPHERE_G_M;
float ATMOSPHERE_SCALE_H;
float ATMOSPHERE_SCALE_L;
float ATMOSPHERE_FNUM_OUT_SCATTER;
float ATMOSPHERE_FNUM_IN_SCATTER;
int ATMOSPHERE_NUM_OUT_SCATTER_LOW;
int ATMOSPHERE_NUM_IN_SCATTER_LOW;
float ATMOSPHERE_FNUM_OUT_SCATTER_LOW;
float ATMOSPHERE_FNUM_IN_SCATTER_LOW;
int SEA_ITER_GEOMETRY;
int SEA_ITER_FRAGMENT;
float SEA_EPSILON;
float SEA_HEIGHT;
float SEA_CHOPPY;
float SEA_SPEED;
float SEA_FREQ;
float4 SEA_BASE;
float4 SEA_WATER_COLOR;
float4 sea_octave_m;
float4 terrainM2;
float llamelScale;


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

                   float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
                   {
                       //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
                       float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
                       return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
                   }

                   // Planet Shadertoy. Created by Reinder Nijhoff 2015 
// Creative Commons Attribution - NonCommercial - ShareAlike 4.0 International License. 
// @reindernijhoff 
// 
// https: // www.shadertoy.com / view / 4tjGRh 
// 
// It uses code from the following shaders: 
// 
// Wet stone by TDM 
// Atmospheric Scattering by GLtracy 
// Seascape by TDM 
// Elevated and Terrain Tubes by IQ 
// LLamels by Eiffie 
// Lens flare by Musk 
// 

#define HIGH_QUALITY 

    #define DISPLAY_LLAMEL 
    #define DISPLAY_CLOUDS 
    #define DISPLAY_CLOUDS_DETAIL 
    #define DISPLAY_TERRAIN_DETAIL 



float time;

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Noise functions 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float hash(const in float n) {
    return frac(sin(n) * 43758.5453123);
 }
float hash(const in float2 p) {
     float h = dot(p , float2 (127.1 , 311.7));
    return frac(sin(h) * 43758.5453123);
 }
float hash(const in float3 p) {
     float h = dot(p , float3 (127.1 , 311.7 , 758.5453123));
    return frac(sin(h) * 43758.5453123);
 }
float3 hash31(const in float p) {
     float3 h = float3 (1275.231 , 4461.7 , 7182.423) * p;
    return frac(sin(h) * 43758.543123);
 }
float3 hash33(const in float3 p) {
    return float3 (hash(p) , hash(p.zyx) , hash(p.yxz));
 }

float noise(const in float p) {
    float i = floor(p);
    float f = frac(p);
     float u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * lerp(hash(i + 0.) , hash(i + 1.) , u);
 }

float noise(const in float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
     float2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * lerp(lerp(hash(i + float2 (0.0 , 0.0)) ,
                     hash(i + float2 (1.0 , 0.0)) , u.x) ,
                lerp(hash(i + float2 (0.0 , 1.0)) ,
                     hash(i + float2 (1.0 , 1.0)) , u.x) , u.y);
 }
float noise(const in float3 x) {
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0 + 113.0 * p.z;
    return lerp(lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                   lerp(hash(n + 157.0) , hash(n + 158.0) , f.x) , f.y) ,
               lerp(lerp(hash(n + 113.0) , hash(n + 114.0) , f.x) ,
                   lerp(hash(n + 270.0) , hash(n + 271.0) , f.x) , f.y) , f.z);
 }

float tri(const in float2 p) {
    return 0.5 * (cos(6.2831 * p.x) + cos(6.2831 * p.y));

 }



float fbm(in float2 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p = m2 * p * 2.02;
    f += 0.2500 * noise(p); p = m2 * p * 2.03;
    f += 0.1250 * noise(p);

#ifndef LOW_QUALITY 
#ifndef VERY_LOW_QUALITY 
    p = m2 * p * 2.01;
    f += 0.0625 * noise(p);
#endif 
#endif 
    return f / 0.9375;
 }

float fbm(const in float3 p , const in float a , const in float f) {
    float ret = 0.0;
    float amp = 1.0;
    float frq = 1.0;
    for (int i = 0; i < FBM_STEPS; i++) {
        float n = pow(noise(p * frq) , 2.0);
        ret += n * amp;
        frq *= f;
        amp *= a * (pow(n , 0.2));
     }
    return ret;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Lightning functions 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float diffuse(const in float3 n , const in float3 l) {
    return clamp(dot(n , l) , 0. , 1.);
 }

float specular(const in float3 n , const in float3 l , const in float3 e , const in float s) {
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e , n) , l) , 0.0) , s) * nrm;
 }

float fresnel(const in float3 n , const in float3 e , float s) {
    return pow(clamp(1. - dot(n , e) , 0. , 1.) , s);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Math functions 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float2 rotate(float angle , float2 v) {
    return float2 (cos(angle) * v.x + sin(angle) * v.y , cos(angle) * v.y - sin(angle) * v.x);
 }

float boolSub(float a , float b) {
    return max(a , -b);
 }
float sphere(float3 p , float r) {
     return length(p) - r;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Intersection functions ( by iq ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float3 nSphere(in float3 pos , in float4 sph) {
    return (pos - sph.xyz) / sph.w;
 }

float iSphere(in float3 ro , in float3 rd , in float4 sph) {
     float3 oc = ro - sph.xyz;
     float b = dot(oc , rd);
     float c = dot(oc , oc) - sph.w * sph.w;
     float h = b * b - c;
     if (h < 0.0) return -1.0;
     return -b - sqrt(h);
 }

float iCSphereF(float3 p , float3 dir , float r) {
     float b = dot(p , dir);
     float c = dot(p , p) - r * r;
     float d = b * b - c;
     if (d < 0.0) return -MAX1;
     return -b + sqrt(d);
 }

float2 iCSphere2(float3 p , float3 dir , float r) {
     float b = dot(p , dir);
     float c = dot(p , p) - r * r;
     float d = b * b - c;
     if (d < 0.0) return float2 (MAX1 , -MAX1);
     d = sqrt(d);
     return float2 (-b - d , -b + d);
 }

float3 nPlane(in float3 ro , in float4 obj) {
    return obj.xyz;
 }

float iPlane(in float3 ro , in float3 rd , in float4 pla) {
    return (-pla.w - dot(pla.xyz , ro)) / dot(pla.xyz , rd);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Wet stone by TDM 
// 
// https: // www.shadertoy.com / view / ldSSzV 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 









float asteroidRock(const in float3 p , const in float3 id) {
    float d = sphere(p , ASTEROID_RADIUS);
    for (int i = 0; i < ASTEROID_NUM_BOOL_SUB; i++) {
        float ii = float(i) + id.x;
        float r = (ASTEROID_RADIUS * 2.5) + ASTEROID_RADIUS * hash(ii);
        float3 v = normalize(hash31(ii) * 2.0 - 1.0);
         d = boolSub(d , sphere(p + v * r , r * 0.8));
     }
    return d;
 }

float asteroidMap(const in float3 p , const in float3 id) {
    float d = asteroidRock(p , id) + noise(p * 4.0) * ASTEROID_DISPLACEMENT;
    return d;
 }

float asteroidMapDetailed(const in float3 p , const in float3 id) {
    float d = asteroidRock(p , id) + fbm(p * 4.0 , 0.4 , 2.96) * ASTEROID_DISPLACEMENT;
    return d;
 }

void asteroidTransForm(inout float3 ro , const in float3 id) {
    float xyangle = (id.x - .5) * time * 2.;
    ro.xy = rotate(xyangle , ro.xy);

    float yzangle = (id.y - .5) * time * 2.;
    ro.yz = rotate(yzangle , ro.yz);
 }

void asteroidUnTransForm(inout float3 ro , const in float3 id) {
    float yzangle = (id.y - .5) * time * 2.;
    ro.yz = rotate(-yzangle , ro.yz);

    float xyangle = (id.x - .5) * time * 2.;
    ro.xy = rotate(-xyangle , ro.xy);
 }

float3 asteroidGetNormal(float3 p , float3 id) {
    asteroidTransForm(p , id);

    float3 n;
    n.x = asteroidMapDetailed(float3 (p.x + ASTEROID_EPSILON , p.y , p.z) , id);
    n.y = asteroidMapDetailed(float3 (p.x , p.y + ASTEROID_EPSILON , p.z) , id);
    n.z = asteroidMapDetailed(float3 (p.x , p.y , p.z + ASTEROID_EPSILON) , id);
    n = normalize(n - asteroidMapDetailed(p , id));

    asteroidUnTransForm(n , id);
    return n;
 }

float2 asteroidSpheretracing(float3 ori , float3 dir , float3 id) {
    asteroidTransForm(ori , id);
    asteroidTransForm(dir , id);

    float2 td = float2 (0 , 1);
    for (int i = 0; i < ASTEROID_NUM_STEPS && abs(td.y) > ASTEROID_TRESHOLD; i++) {
        td.y = asteroidMap(ori + dir * td.x , id);
        td.x += td.y;
     }
    return td;
 }

float3 asteroidGetStoneColor(float3 p , float c , float3 l , float3 n , float3 e) {
     return lerp(diffuse(n , l) * RING_COLOR_1 * SUN_COLOR , SUN_COLOR * specular(n , l , e , 3.0) , .5 * fresnel(n , e , 5.));
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Ring ( by me ; ) ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 




float3 ringShadowColor(const in float3 ro) {
    if (iSphere(ro , SUN_DIRECTION , float4 (0. , 0. , 0. , EARTH_RADIUS)) > 0.) {
        return float3 (0. , 0. , 0.);
     }
    return float3 (1. , 1. , 1.);
 }

bool ringMap(const in float3 ro) {
    return ro.z < RING_HEIGHT / RING_VOXEL_STEP_SIZE && hash(ro) < .5;
 }

float4 renderRingNear(const in float3 ro , const in float3 rd) {
    // find startpoint 
       float d1 = iPlane(ro , rd , float4 (0. , 0. , 1. , RING_HEIGHT));
       float d2 = iPlane(ro , rd , float4 (0. , 0. , 1. , -RING_HEIGHT));

       float d = min(max(d1 , 0.) , max(d2 , 0.));

       if ((d1 < 0. && d2 < 0.) || d > ASTEROID_MAX_DISTANCE) {
           return float4 (0. , 0. , 0. , 0.);
        }
   else {
   float3 ros = ro + rd * d;

   // avoid precision problems.. 
  float2 mroxy = mod(ros.xy , float2 (10., 10.));
  float2 roxy = ros.xy - mroxy;
  ros.xy -= roxy;
  ros /= RING_VOXEL_STEP_SIZE;
  // ros.xy -= float2 ( .013 , .112 ) * time * .5 ; 

 float3 pos = floor(ros);
 float3 ri = 1.0 / rd;
 float3 rs = sign(rd);
 float3 dis = (pos - ros + 0.5 + rs * 0.5) * ri;

 float alpha = 0. , dint;
 float3 offset = float3 (0 , 0 , 0) , id , asteroidro;
 float2 asteroid = float2 (0 , 0);

 for (int i = 0; i < RING_VOXEL_STEPS; i++) {
     if (ringMap(pos)) {
         id = hash33(pos);
         offset = id * (1. - 2. * ASTEROID_RADIUS) + ASTEROID_RADIUS;
         dint = iSphere(ros , rd , float4 (pos + offset , ASTEROID_RADIUS));

         if (dint > 0.) {
             asteroidro = ros + rd * dint - (pos + offset);
             asteroid = asteroidSpheretracing(asteroidro , rd , id);

             if (asteroid.y < .1) {
                 alpha = 1.;
                 break;
              }
          }

      }
     float3 mm = step(dis.xyz , dis.yxy) * step(dis.xyz , dis.zzx);
     dis += mm * rs * ri;
     pos += mm * rs;
  }

 if (alpha > 0.) {
     float3 intersection = ros + rd * (asteroid.x + dint);
     float3 n = asteroidGetNormal(asteroidro + rd * asteroid.x , id);

     float3 col = asteroidGetStoneColor(intersection , .1 , SUN_DIRECTION , n , rd);

     intersection *= RING_VOXEL_STEP_SIZE;
     intersection.xy += roxy;
     // col *= ringShadowColor ( intersection ) ; 

      return float4 (col , 1. - smoothstep(0.4 * ASTEROID_MAX_DISTANCE , 0.5 * ASTEROID_MAX_DISTANCE , distance(intersection , ro)));
   }
else {
return float4 (0. , 0. , 0. , 0.);
}
}
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Ring ( by me ; ) ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float renderRingFarShadow(const in float3 ro , const in float3 rd) {
    // intersect plane 
   float d = iPlane(ro , rd , float4 (0. , 0. , 1. , 0.));

   if (d > 0.) {
        float3 intersection = ro + rd * d;
       float l = length(intersection.xy);

       if (l > RING_INNER_RADIUS && l < RING_OUTER_RADIUS) {
           return .5 + .5 * (.2 + .8 * noise(l * .07)) * (.5 + .5 * noise(intersection.xy));
        }
else {
return 0.;
}
}
else {
 return 0.;
}
}

float4 renderRingFar(const in float3 ro , const in float3 rd , inout float maxd) {
    // intersect plane 
   float d = iPlane(ro , rd , float4 (0. , 0. , 1. , 0.));

   if (d > 0. && d < maxd) {
       maxd = d;
        float3 intersection = ro + rd * d;
       float l = length(intersection.xy);

       if (l > RING_INNER_RADIUS && l < RING_OUTER_RADIUS) {
           float dens = .5 + .5 * (.2 + .8 * noise(l * .07)) * (.5 + .5 * noise(intersection.xy));
           float3 col = lerp(RING_COLOR_1 , RING_COLOR_2 , abs(noise(l * 0.2))) * abs(dens) * 1.5;

           col *= ringShadowColor(intersection);
             col *= .8 + .3 * diffuse(float3 (0 , 0 , 1) , SUN_DIRECTION);
              col *= SUN_COLOR;
           return float4 (col , dens);
        }
else {
return float4 (0. , 0. , 0. , 0.);
}
}
else {
 return float4 (0. , 0. , 0. , 0.);
}
}

float4 renderRing(const in float3 ro , const in float3 rd , inout float maxd) {
    float4 far = renderRingFar(ro , rd , maxd);
    float l = length(ro.xy);

    if (abs(ro.z) < RING_HEIGHT + RING_DETAIL_DISTANCE
        && l < RING_OUTER_RADIUS + RING_DETAIL_DISTANCE
        && l > RING_INNER_RADIUS - RING_DETAIL_DISTANCE) {

         float d = iPlane(ro , rd , float4 (0. , 0. , 1. , 0.));
        float detail = lerp(.5 * noise(frac(ro.xy + rd.xy * d) * 92.1) + .25 , 1. , smoothstep(0. , RING_DETAIL_DISTANCE , d));
        far.xyz *= detail;
     }

    // are asteroids neaded ? 
  if (abs(ro.z) < RING_HEIGHT + ASTEROID_MAX_DISTANCE
      && l < RING_OUTER_RADIUS + ASTEROID_MAX_DISTANCE
      && l > RING_INNER_RADIUS - ASTEROID_MAX_DISTANCE) {

      float4 near = renderRingNear(ro , rd);
      far = lerp(far , near , near.w);
      maxd = 0.;
   }

  return far;
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Stars ( by me ; ) ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float4 renderStars(const in float3 rd) {
     float3 rds = rd;
     float3 col = float3 (0 , 0 , 0);
    float v = 1.0 / (2. * (1. + rds.z));

    float2 xy = float2 (rds.y * v , rds.x * v);
    float s = noise(rds * 134.);

    s += noise(rds * 470.);
    s = pow(s , 19.0) * 0.00001;
    if (s > 0.5) {
        float3 backStars = float3 (s, s, s) * .5 * float3 (0.95 , 0.8 , 0.9);
        col += backStars;
     }
     return float4 (col , 1);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Atmospheric Scattering by GLtracy 
// 
// https: // www.shadertoy.com / view / lslXDr 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 


















float atmosphericPhaseMie(float g , float c , float cc) {
     float gg = g * g;
     float a = (1.0 - gg) * (1.0 + cc);
     float b = 1.0 + gg - 2.0 * g * c;

     b *= sqrt(b);
     b *= 2.0 + gg;

     return 1.5 * a / b;
 }

float atmosphericPhaseReyleigh(float cc) {
     return 0.75 * (1.0 + cc);
 }

float atmosphericDensity(float3 p) {
     return exp(-(length(p) - EARTH_RADIUS) * ATMOSPHERE_SCALE_H);
 }

float atmosphericOptic(float3 p , float3 q) {
     float3 step = (q - p) / ATMOSPHERE_FNUM_OUT_SCATTER;
     float3 v = p + step * 0.5;

     float sum = 0.0;
     for (int i = 0; i < ATMOSPHERE_NUM_OUT_SCATTER; i++) {
          sum += atmosphericDensity(v);
          v += step;
      }
     sum *= length(step) * ATMOSPHERE_SCALE_L;

     return sum;
 }

float4 atmosphericInScatter(float3 o , float3 dir , float2 e , float3 l) {
     float len = (e.y - e.x) / ATMOSPHERE_FNUM_IN_SCATTER;
     float3 step = dir * len;
     float3 p = o + dir * e.x;
     float3 v = p + dir * (len * 0.5);

    float sumdensity = 0.;
     float3 sum = float3 (0.0 , 0.0 , 0.0);

    for (int i = 0; i < ATMOSPHERE_NUM_IN_SCATTER; i++) {
        float3 u = v + l * iCSphereF(v , l , EARTH_RADIUS + EARTH_ATMOSPHERE);
          float n = (atmosphericOptic(p , v) + atmosphericOptic(v , u)) * (PI * 4.0);
          float dens = atmosphericDensity(v);

         float m = MAX1;
          sum += dens * exp(-n * (ATMOSPHERE_K_R * ATMOSPHERE_C_R + ATMOSPHERE_K_M))
               * (1. - renderRingFarShadow(u , SUN_DIRECTION));
           sumdensity += dens;

          v += step;
      }
     sum *= len * ATMOSPHERE_SCALE_L;

     float c = dot(dir , -l);
     float cc = c * c;

     return float4 (sum * (ATMOSPHERE_K_R * ATMOSPHERE_C_R * atmosphericPhaseReyleigh(cc) +
                         ATMOSPHERE_K_M * atmosphericPhaseMie(ATMOSPHERE_G_M , c , cc)) * ATMOSPHERE_E ,
                          clamp(sumdensity * len * ATMOSPHERE_SCALE_L , 0. , 1.));
 }

float atmosphericOpticLow(float3 p , float3 q) {
     float3 step = (q - p) / ATMOSPHERE_FNUM_OUT_SCATTER_LOW;
     float3 v = p + step * 0.5;

     float sum = 0.0;
     for (int i = 0; i < ATMOSPHERE_NUM_OUT_SCATTER_LOW; i++) {
          sum += atmosphericDensity(v);
          v += step;
      }
     sum *= length(step) * ATMOSPHERE_SCALE_L;

     return sum;
 }

float3 atmosphericInScatterLow(float3 o , float3 dir , float2 e , float3 l) {
     float len = (e.y - e.x) / ATMOSPHERE_FNUM_IN_SCATTER_LOW;
     float3 step = dir * len;
     float3 p = o + dir * e.x;
     float3 v = p + dir * (len * 0.5);

     float3 sum = float3 (0.0 , 0.0 , 0.0);

    for (int i = 0; i < ATMOSPHERE_NUM_IN_SCATTER_LOW; i++) {
          float3 u = v + l * iCSphereF(v , l , EARTH_RADIUS + EARTH_ATMOSPHERE);
          float n = (atmosphericOpticLow(p , v) + atmosphericOpticLow(v , u)) * (PI * 4.0);
         float m = MAX1;
          sum += atmosphericDensity(v) * exp(-n * (ATMOSPHERE_K_R * ATMOSPHERE_C_R + ATMOSPHERE_K_M));
          v += step;
      }
     sum *= len * ATMOSPHERE_SCALE_L;

     float c = dot(dir , -l);
     float cc = c * c;

     return sum * (ATMOSPHERE_K_R * ATMOSPHERE_C_R * atmosphericPhaseReyleigh(cc) +
                   ATMOSPHERE_K_M * atmosphericPhaseMie(ATMOSPHERE_G_M , c , cc)) * ATMOSPHERE_E;
 }

float4 renderAtmospheric(const in float3 ro , const in float3 rd , inout float d) {
    // inside or outside atmosphere? 
   float2 e = iCSphere2(ro , rd , EARTH_RADIUS + EARTH_ATMOSPHERE);
    float2 f = iCSphere2(ro , rd , EARTH_RADIUS);

   if (length(ro) <= EARTH_RADIUS + EARTH_ATMOSPHERE) {
       if (d < e.y) {
           e.y = d;
        }
         d = e.y;
        e.x = 0.;

        if (iSphere(ro , rd , float4 (0 , 0 , 0 , EARTH_RADIUS)) > 0.) {
            d = iSphere(ro , rd , float4 (0 , 0 , 0 , EARTH_RADIUS));
          }
    }
else {
 if (iSphere(ro , rd , float4 (0 , 0 , 0 , EARTH_RADIUS + EARTH_ATMOSPHERE)) < 0.) return float4 (0. , 0. , 0. , 0.);

if (e.x > e.y) {
     d = MAX1;
       return float4 (0. , 0. , 0. , 0.);
   }
  d = e.y = min(e.y , f.x);
}
return atmosphericInScatter(ro , rd , e , SUN_DIRECTION);
}

float3 renderAtmosphericLow(const in float3 ro , const in float3 rd) {
    float2 e = iCSphere2(ro , rd , EARTH_RADIUS + EARTH_ATMOSPHERE);
    e.x = 0.;
    return atmosphericInScatterLow(ro , rd , e , SUN_DIRECTION);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Seascape by TDM 
// 
// https: // www.shadertoy.com / view / Ms2SD1 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 





#define SEA_EPSILON_NRM ( 0.1 / _ScreenParams.x ) 






float SEA_TIME;


float seaOctave(in float2 uv , const in float choppy) {
    uv += noise(uv);
    float2 wv = 1.0 - abs(sin(uv));
    float2 swv = abs(cos(uv));
    wv = lerp(wv , swv , wv);
    return pow(1.0 - pow(wv.x * wv.y , 0.65) , choppy);
 }

float seaMap(const in float3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    float2 uv = p.xz; uv.x *= 0.75;

    float d , h = 0.0;
    for (int i = 0; i < SEA_ITER_GEOMETRY; i++) {
         d = seaOctave((uv + SEA_TIME) * freq , choppy);
         d += seaOctave((uv - SEA_TIME) * freq , choppy);
        h += d * amp;
         uv *= sea_octave_m; freq *= 1.9; amp *= 0.22;
        choppy = lerp(choppy , 1.0 , 0.2);
     }
    return p.y - h;
 }

float seaMapHigh(const in float3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    float2 uv = p.xz; uv.x *= 0.75;

    float d , h = 0.0;
    for (int i = 0; i < SEA_ITER_FRAGMENT; i++) {
         d = seaOctave((uv + SEA_TIME) * freq , choppy);
         d += seaOctave((uv - SEA_TIME) * freq , choppy);
        h += d * amp;
         uv *= sea_octave_m; freq *= 1.9; amp *= 0.22;
        choppy = lerp(choppy , 1.0 , 0.2);
     }
    return p.y - h;
 }

float3 seaGetColor(const in float3 n , float3 eye , const in float3 l , const in float att ,
                  const in float3 sunc , const in float3 upc , const in float3 reflected) {
    float3 refracted = SEA_BASE * upc + diffuse(n , l) * SEA_WATER_COLOR * 0.12 * sunc;
    float3 color = lerp(refracted , reflected , fresnel(n , -eye , 3.) * .65);

    color += upc * SEA_WATER_COLOR * (att * 0.18);
    color += sunc * float3 (specular(n, l, eye, 60.0), specular(n, l, eye, 60.0), specular(n, l, eye, 60.0));

    return color;
 }

float3 seaGetNormal(const in float3 p , const in float eps) {
    float3 n;
    n.y = seaMapHigh(p);
    n.x = seaMapHigh(float3 (p.x + eps , p.y , p.z)) - n.y;
    n.z = seaMapHigh(float3 (p.x , p.y , p.z + eps)) - n.y;
    n.y = eps;
    return normalize(n);
 }

float seaHeightMapTracing(const in float3 ori , const in float3 dir , out float3 p) {
    float tm = 0.0;
    float tx = 1000.0;
    float hx = seaMap(ori + dir * tx);
    if (hx > 0.0) return tx;
    float hm = seaMap(ori + dir * tm);
    float tmid = 0.0;
    for (int i = 0; i < SEA_NUM_STEPS; i++) {
        tmid = lerp(tm , tx , hm / (hm - hx));
        p = ori + dir * tmid;
         float hmid = seaMap(p);
          if (hmid < 0.0) {
             tx = tmid;
            hx = hmid;
         }
else {
tm = tmid;
hm = hmid;
}
}
return tmid;
}

float3 seaTransform(in float3 x) {
    x.yz = rotate(0.8 , x.yz);
    return x;
 }

float3 seaUntransform(in float3 x) {
    x.yz = rotate(-0.8 , x.yz);
    return x;
 }

void renderSea(const in float3 ro , const in float3 rd , inout float3 n , inout float att) {
    float3 p ,
    rom = seaTransform(ro) ,
    rdm = seaTransform(rd);

    rom.y -= EARTH_RADIUS;
    rom *= 1000.;
    rom.xz += float2 (3.1 , .2) * time;

    SEA_TIME = time * SEA_SPEED;

    seaHeightMapTracing(rom , rdm , p);
    float squareddist = dot(p - rom , p - rom);
    n = seaGetNormal(p , squareddist * SEA_EPSILON_NRM);

    n = seaUntransform(n);

    att = clamp(SEA_HEIGHT + p.y , 0. , 1.);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Terrain based on Elevated and Terrain Tubes by IQ 
// 
// https: // www.shadertoy.com / view / MdX3Rr 
// https: // www.shadertoy.com / view / 4sjXzG 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

#ifndef HIDE_TERRAIN 



float terrainLow(float2 p) {
    p *= 0.0013;

    float s = 1.0;
     float t = 0.0;
     for (int i = 0; i < 2; i++) {
        t += s * tri(p);
          s *= 0.5 + 0.1 * t;
        p = 0.97 * terrainM2 * p + (t - 0.5) * 0.12;
      }
     return t * 33.0;
 }

float terrainMed(float2 p) {
    p *= 0.0013;

    float s = 1.0;
     float t = 0.0;
     for (int i = 0; i < 6; i++) {
        t += s * tri(p);
          s *= 0.5 + 0.1 * t;
        p = 0.97 * terrainM2 * p + (t - 0.5) * 0.12;
      }

    return t * 33.0;
 }

float terrainHigh(float2 p) {
    float2 q = p;
    p *= 0.0013;

    float s = 1.0;
     float t = 0.0;
     for (int i = 0; i < 7; i++) {
        t += s * tri(p);
          s *= 0.5 + 0.1 * t;
        p = 0.97 * terrainM2 * p + (t - 0.5) * 0.12;
      }

    t += t * 0.015 * fbm(q);
     return t * 33.0;
 }

float terrainMap(const in float3 pos) {
     return pos.y - terrainMed(pos.xz);
 }

float terrainMapH(const in float3 pos) {
    float y = terrainHigh(pos.xz);
    float h = pos.y - y;
    return h;
 }

float terrainIntersect(in float3 ro , in float3 rd , in float tmin , in float tmax) {
    float t = tmin;
     for (int i = 0; i < TERRAIN_NUM_STEPS; i++) {
        float3 pos = ro + t * rd;
        float res = terrainMap(pos);
        if (res < (0.001 * t) || t > tmax) break;
        t += res * .9;
      }

     return t;
 }

float terrainCalcShadow(in float3 ro , in float3 rd) {
     float2 eps = float2 (150.0 , 0.0);
    float h1 = terrainMed(ro.xz);
    float h2 = terrainLow(ro.xz);

    float d1 = 10.0;
    float d2 = 80.0;
    float d3 = 200.0;
    float s1 = clamp(1.0 * (h1 + rd.y * d1 - terrainMed(ro.xz + d1 * rd.xz)) , 0.0 , 1.0);
    float s2 = clamp(0.5 * (h1 + rd.y * d2 - terrainMed(ro.xz + d2 * rd.xz)) , 0.0 , 1.0);
    float s3 = clamp(0.2 * (h2 + rd.y * d3 - terrainLow(ro.xz + d3 * rd.xz)) , 0.0 , 1.0);

    return min(min(s1 , s2) , s3);
 }
float3 terrainCalcNormalHigh(in float3 pos , float t) {
    float2 e = float2 (1.0 , -1.0) * 0.001 * t;

    return normalize(e.xyy * terrainMapH(pos + e.xyy) +
                           e.yyx * terrainMapH(pos + e.yyx) +
                           e.yxy * terrainMapH(pos + e.yxy) +
                           e.xxx * terrainMapH(pos + e.xxx));
 }

float3 terrainCalcNormalMed(in float3 pos , float t) {
     float e = 0.005 * t;
    float2 eps = float2 (e , 0.0);
    float h = terrainMed(pos.xz);
    return normalize(float3 (terrainMed(pos.xz - eps.xy) - h , e , terrainMed(pos.xz - eps.yx) - h));
 }

float3 terrainTransform(in float3 x) {
    x.zy = rotate(-.83 , x.zy);
    return x;
 }

float3 terrainUntransform(in float3 x) {
    x.zy = rotate(.83 , x.zy);
    return x;
 }


float llamelTime;


float3 llamelPosition() {
    llamelTime = time * 2.5;
    float2 pos = float2 (-400. , 135. - llamelTime * 0.075 * llamelScale);
    return float3 (pos.x , terrainMed(pos) , pos.y);
 }

float3 terrainShade(const in float3 col , const in float3 pos , const in float3 rd , const in float3 n , const in float spec ,
                   const in float3 sunc , const in float3 upc , const in float3 reflc) {
     float3 sunDirection = terrainTransform(SUN_DIRECTION);
    float dif = diffuse(n , sunDirection);
    float bac = diffuse(n , float3 (-sunDirection.x , sunDirection.y , -sunDirection.z));
    float sha = terrainCalcShadow(pos , sunDirection);
    float amb = clamp(n.y , 0.0 , 1.0);

    float3 lin = float3 (0.0 , 0.0 , 0.0);
    lin += 2. * dif * sunc * float3 (sha , sha * sha * 0.1 + 0.9 * sha , sha * sha * 0.2 + 0.8 * sha);
    lin += 0.2 * amb * upc;
    lin += 0.08 * bac * clamp(float3 (1. , 1. , 1.) - sunc , float3 (0. , 0. , 0.) , float3 (1. , 1. , 1.));
    return lerp(col * lin * 3. , reflc , spec * fresnel(n , -terrainTransform(rd) , 5.0));
 }

float3 terrainGetColor(const in float3 pos , const in float3 rd , const in float t , const in float3 sunc , const in float3 upc , const in float3 reflc) {
    float3 nor = terrainCalcNormalHigh(pos , t);
    float3 sor = terrainCalcNormalMed(pos , t);

    float spec = 0.005;

#ifdef DISPLAY_TERRAIN_DETAIL 
    float no = noise(5. * fbm(1.11 * pos.xz));
#else 
    const float no = 0.;
#endif 
    float r = .5 + .5 * fbm(.95 * pos.xz);
     float3 col = (r * 0.25 + 0.75) * 0.9 * lerp(float3 (0.08 , 0.07 , 0.07) , float3 (0.10 , 0.09 , 0.08) , noise(0.4267 * float2 (pos.x * 2. , pos.y * 9.8)) + .01 * no);
    col = lerp(col , 0.20 * float3 (0.45 , .30 , 0.15) * (0.50 + 0.50 * r) , smoothstep(0.825 , 0.925 , nor.y + .025 * no));
     col = lerp(col , 0.15 * float3 (0.30 , .30 , 0.10) * (0.25 + 0.75 * r) , smoothstep(0.95 , 1.0 , nor.y + .025 * no));
    col *= .88 + .12 * no;

    float s = nor.y + 0.03 * pos.y + 0.35 * fbm(0.05 * pos.xz) - .35;
    float sf = fwidth(s) * 1.5;
    s = smoothstep(0.84 - sf , 0.84 + sf , s);
    col = lerp(col , 0.29 * float3 (0.62 , 0.65 , 0.7) , s);
    nor = lerp(nor , sor , 0.7 * smoothstep(0.9 , 0.95 , s));
    spec = lerp(spec , 0.45 , smoothstep(0.9 , 0.95 , s));

        col = terrainShade(col , pos , rd , nor , spec , sunc , upc , reflc);

#ifdef DISPLAY_LLAMEL 
    col *= clamp(distance(pos.xz , llamelPosition().xz) * 0.4 , 0.4 , 1.);
#endif 

    return col;
 }

float3 terrainTransformRo(const in float3 ro) {
    float3 rom = terrainTransform(ro);
    rom.y -= EARTH_RADIUS - 100.;
    rom.xz *= 5.;
    rom.xz += float2 (-170. , 50.) + float2 (-4. , .4) * time;
    rom.y += (terrainLow(rom.xz) - 86.) * clamp(1. - 1. * (length(ro) - EARTH_RADIUS) , 0. , 1.);
    return rom;
 }

float4 renderTerrain(const in float3 ro , const in float3 rd , inout float3 intersection , inout float3 n) {
    float3 p ,
    rom = terrainTransformRo(ro) ,
    rdm = terrainTransform(rd);

    float tmin = 10.0;
    float tmax = 3200.0;

    float res = terrainIntersect(rom , rdm , tmin , tmax);

    if (res > tmax) {
        res = -1.;
     }
else {
float3 pos = rom + rdm * res;
n = terrainCalcNormalMed(pos , res);
n = terrainUntransform(n);

intersection = ro + rd * res / 100.;
}
return float4 (res , rom + rdm * res);
}

#endif 

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// LLamels by Eiffie 
// 
// https: // www.shadertoy.com / view / ltsGz4 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
#ifdef DISPLAY_LLAMEL 
float llamelMapSMin(const in float a , const in float b , const in float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0); return b + h * (a - b - k + k * h);
 }

float llamelMapLeg(float3 p , float3 j0 , float3 j3 , float3 l , float4 r , float3 rt) { // z joint with tapered legs 
     float lx2z = l.x / (l.x + l.z) , h = l.y * lx2z;
     float3 u = (j3 - j0) * lx2z , q = u * (0.5 + 0.5 * (l.x * l.x - h * h) / dot(u , u));
     q += sqrt(max(0.0 , l.x * l.x - dot(q , q))) * normalize(cross(u , rt));
     float3 j1 = j0 + q , j2 = j3 - q * (1.0 - lx2z) / lx2z;
     u = p - j0; q = j1 - j0;
     h = clamp(dot(u , q) / dot(q , q) , 0.0 , 1.0);
     float d = length(u - q * h) - r.x - (r.y - r.x) * h;
     u = p - j1; q = j2 - j1;
     h = clamp(dot(u , q) / dot(q , q) , 0.0 , 1.0);
     d = min(d , length(u - q * h) - r.y - (r.z - r.y) * h);
     u = p - j2; q = j3 - j2;
     h = clamp(dot(u , q) / dot(q , q) , 0.0 , 1.0);
     return min(d , length(u - q * h) - r.z - (r.w - r.z) * h);
 }

float llamelMap(in float3 p) {
     const float3 rt = float3 (0.0 , 0.0 , 1.0);
     p.y += 0.25 * llamelScale;
    p.xz -= 0.5 * llamelScale;
    p.xz = float2 (-p.z , p.x);
    float3 pori = p;

    p /= llamelScale;

     float2 c = floor(p.xz);
     p.xz = frac(p.xz) - float2 (0.5 , 0.5);
    p.y -= p.x * .04 * llamelScale;
     float sa = sin(c.x * 2.0 + c.y * 4.5 + llamelTime * 0.05) * 0.15;

    float b = 0.83 - abs(p.z);
     float a = c.x + 117.0 * c.y + sign(p.x) * 1.57 + sign(p.z) * 1.57 + llamelTime , ca = cos(a);
     float3 j0 = float3 (sign(p.x) * 0.125 , ca * 0.01 , sign(p.z) * 0.05) , j3 = float3 (j0.x + sin(a) * 0.1 , max(-0.25 + ca * 0.1 , -0.25) , j0.z);
     float dL = llamelMapLeg(p , j0 , j3 , float3 (0.08 , 0.075 , 0.12) , float4 (0.03 , 0.02 , 0.015 , 0.01) , rt * sign(p.x));
     p.y -= 0.03;
     float dB = (length(p.xyz * float3 (1.0 , 1.75 , 1.75)) - 0.14) * 0.75;
     a = c.x + 117.0 * c.y + llamelTime; ca = cos(a); sa *= 0.4;
     j0 = float3 (0.125 , 0.03 + abs(ca) * 0.03 , ca * 0.01) , j3 = float3 (0.3 , 0.07 + ca * sa , sa);
     float dH = llamelMapLeg(p , j0 , j3 , float3 (0.075 , 0.075 , 0.06) , float4 (0.03 , 0.035 , 0.03 , 0.01) , rt);
     dB = llamelMapSMin(min(dL , dH) , dB , clamp(0.04 + p.y , 0.0 , 1.0));
     a = max(abs(p.z) , p.y) + 0.05;
     return max(min(dB , min(a , b)) , length(pori.xz - float2 (0.5 , 0.5) * llamelScale) - .5 * llamelScale);
 }

float3 llamelGetNormal(in float3 ro) {
    float2 e = float2 (1.0 , -1.0) * 0.001;

    return normalize(e.xyy * llamelMap(ro + e.xyy) +
                           e.yyx * llamelMap(ro + e.yyx) +
                           e.yxy * llamelMap(ro + e.yxy) +
                           e.xxx * llamelMap(ro + e.xxx));
 }

float4 renderLlamel(in float3 ro , const in float3 rd , const in float3 sunc , const in float3 upc , const in float3 reflc) {
    ro -= llamelPosition();
     float t = .1 * hash(rd.xy) , d , dm = 10.0 , tm;
     for (int i = 0; i < 36; i++) {
          t += d = llamelMap(ro + rd * t);
          if (d < dm) { dm = d; tm = t; }
          if (t > 1000.0 || d < 0.00001) break;
      }
     dm = max(0.0 , dm);
    if (dm < .02) {
        float3 col = float3 (0.45 , .30 , 0.15) * .2;
        float3 pos = ro + rd * tm;
        float3 nor = llamelGetNormal(pos);
        col = terrainShade(col , pos , rd , nor , .01 , sunc , upc , reflc);
        return float4 (col , clamp(1. - (dm - 0.01) / 0.01 , 0. , 1.));
     }

    return float4 (0. , 0. , 0. , 0.);
 }
#endif 

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Clouds ( by me ; ) ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float4 renderClouds(const in float3 ro , const in float3 rd , const in float d , const in float3 n , const in float land ,
                   const in float3 sunColor , const in float3 upColor , inout float shadow) {
     float3 intersection = ro + rd * d;
    float3 cint = intersection * 0.009;
    float rot = -.2 * length(cint.xy) + .6 * fbm(cint * .4 , 0.5 , 2.96) + .05 * land;

    cint.xy = rotate(rot , cint.xy);

    float3 cdetail = mod(intersection * 3.23 , float3 (50., 50., 50.));
    cdetail.xy = rotate(.25 * rot , cdetail.xy);

    float clouds = 1.3 * (fbm(cint * (1. + .02 * noise(intersection)) , 0.5 , 2.96) + .4 * land - .3);

#ifdef DISPLAY_CLOUDS_DETAIL 
    if (d < 200.) {
        clouds += .3 * (fbm(cdetail , 0.5 , 2.96) - .5) * (1. - smoothstep(0. , 200. , d));
     }
#endif 

    shadow = clamp(1. - clouds , 0. , 1.);

    clouds = clamp(clouds , 0. , 1.);
    clouds *= clouds;
    clouds *= smoothstep(0. , 0.4 , d);

    float3 clbasecolor = float3 (1. , 1. , 1.);
    float3 clcol = .1 * clbasecolor * sunColor * 
        float3 (specular(n , SUN_DIRECTION , rd , 36.0), specular(n, SUN_DIRECTION, rd, 36.0), specular(n, SUN_DIRECTION, rd, 36.0));
    clcol += .3 * clbasecolor * sunColor;
    clcol += clbasecolor * (diffuse(n , SUN_DIRECTION) * sunColor + upColor);

    return float4 (clcol , clouds);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Planet ( by me ; ) ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float4 renderPlanet(const in float3 ro , const in float3 rd , const in float3 up , inout float maxd) {
    float d = iSphere(ro , rd , float4 (0. , 0. , 0. , EARTH_RADIUS));

    float3 intersection = ro + rd * d;
    float3 n = nSphere(intersection , float4 (0. , 0. , 0. , EARTH_RADIUS));
    float4 res;

#ifndef HIDE_TERRAIN 
    bool renderTerrainDetail = length(ro) < EARTH_RADIUS + EARTH_ATMOSPHERE &&
                                    dot(terrainUntransform(float3 (0. , 1. , 0.)) , normalize(ro)) > .9996;
#endif 
    bool renderSeaDetail = d < 1. && dot(seaUntransform(float3 (0. , 1. , 0.)) , normalize(ro)) > .9999;
    float mixDetailColor = 0.;

     if (d < 0. || d > maxd) {
#ifndef HIDE_TERRAIN 
        if (renderTerrainDetail) {
                 intersection = ro;
            n = normalize(ro);
         }
else {
 return float4 (0 , 0 , 0 , 0);
}
#else 
           return float4 (0. , 0. , 0. , 0.);
#endif 
      }
    if (d > 0.) {
         maxd = d;
     }
    float att = 0.;

    if (dot(n , SUN_DIRECTION) < -0.1) return float4 (0. , 0. , 0. , 1.);

    float dm = MAX1 , e = 0.;
    float3 col , detailCol , nDetail;

    // normal and intersection 
#ifndef HIDE_TERRAIN 
    if (renderTerrainDetail) {
        res = renderTerrain(ro , rd , intersection , nDetail);
        if (res.x < 0. && d < 0.) {
             return float4 (0 , 0 , 0 , 0);
         }
        if (res.x >= 0.) {
            maxd = pow(res.x / 4000. , 4.) * 50.;
            e = -10.;
         }
        mixDetailColor = 1. - smoothstep(.75 , 1. , (length(ro) - EARTH_RADIUS) / EARTH_ATMOSPHERE);
        n = normalize(lerp(n , nDetail , mixDetailColor));
     }
else
#endif 
    if (renderSeaDetail) {
        float attsea , mf = smoothstep(.5 , 1. , d);

        renderSea(ro , rd , nDetail , attsea);

        n = normalize(lerp(nDetail , n , mf));
        att = lerp(attsea , att , mf);
     }
else {
e = fbm(.003 * intersection + float3 (1. , 1. , 1.) , 0.4 , 2.96) + smoothstep(.85 , .95 , abs(intersection.z / EARTH_RADIUS));
#ifndef HIDE_TERRAIN 
        if (d < 1500.) {
            e += (-.03 + .06 * fbm(intersection * 0.1 , 0.4 , 2.96)) * (1. - d / 1500.);
         }
#endif 
     }

    float3 sunColor = .25 * renderAtmosphericLow(intersection , SUN_DIRECTION).xyz;
    float3 upColor = 2. * renderAtmosphericLow(intersection , n).xyz;
    float3 reflColor = renderAtmosphericLow(intersection , reflect(rd , n)).xyz;

    // color 
#ifndef HIDE_TERRAIN 
    if (renderTerrainDetail) {
        detailCol = col = terrainGetColor(res.yzw , rd , res.x , sunColor , upColor , reflColor);
          d = 0.;
     }
#endif 

    if (mixDetailColor < 1.) {
        if (e < .45) {
            // sea 
           col = seaGetColor(n , rd , SUN_DIRECTION , att , sunColor , upColor , reflColor);
        }
else {
            // planet ( land ) far 
           float land1 = max(0.1 , fbm(intersection * 0.0013 , 0.4 , 2.96));
           float land2 = max(0.1 , fbm(intersection * 0.0063 , 0.4 , 2.96));
           float iceFactor = abs(pow(intersection.z / EARTH_RADIUS , 13.0)) * e;

           float3 landColor1 = float3 (0.43 , 0.65 , 0.1) * land1;
           float3 landColor2 = RING_COLOR_1 * land2;
           float3 mixedLand = (landColor1 + landColor2) * 0.5;
           float3 finalLand = lerp(mixedLand , float3 (7.0 , 7.0 , 7.0) * land1 * 1.5 , max(iceFactor + .02 * land2 - .02 , 0.));

           col = (diffuse(n , SUN_DIRECTION) * sunColor + upColor) * finalLand * .75;
#ifdef HIGH_QUALITY 
            col *= (.5 + .5 * fbm(intersection * 0.23 , 0.4 , 2.96));
#endif 
         }
     }

    if (mixDetailColor > 0.) {
        col = lerp(col , detailCol , mixDetailColor);
     }

#ifdef DISPLAY_LLAMEL 
    if (renderTerrainDetail) {
        float3 rom = terrainTransformRo(ro) ,
        rdm = terrainTransform(rd);
        d = iSphere(rom , rdm , float4 (llamelPosition() , llamelScale * 3.));
        if (d > 0.) {
            float4 llamel = renderLlamel(rom + rdm * d , rdm , sunColor , upColor , reflColor);
            col = lerp(col , llamel.rgb , llamel.a);
         }
     }
#endif 

    d = iSphere(ro , rd , float4 (0. , 0. , 0. , EARTH_RADIUS + EARTH_CLOUDS));
    if (d > 0.) {
        float shadow;
          float4 clouds = renderClouds(ro , rd , d , n , e , sunColor , upColor , shadow);
        col *= shadow;
        col = lerp(col , clouds.rgb , clouds.w);
     }

    float m = MAX1;
    col *= (1. - renderRingFarShadow(ro + rd * d , SUN_DIRECTION));

      return float4 (col , 1.);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Lens flare by musk 
// 
// https: // www.shadertoy.com / view / 4sX3Rs 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float3 lensFlare(const in float2 uv , const in float2 pos) {
     float2 main = uv - pos;
     float2 uvd = uv * (length(uv));

     float f0 = 1.5 / (length(uv - pos) * 16.0 + 1.0);

     float f1 = max(0.01 - pow(length(uv + 1.2 * pos) , 1.9) , .0) * 7.0;

     float f2 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.8 * pos) , 2.0)) , .0) * 00.25;
     float f22 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.85 * pos) , 2.0)) , .0) * 00.23;
     float f23 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.9 * pos) , 2.0)) , .0) * 00.21;

     float2 uvx = lerp(uv , uvd , -0.5);

     float f4 = max(0.01 - pow(length(uvx + 0.4 * pos) , 2.4) , .0) * 6.0;
     float f42 = max(0.01 - pow(length(uvx + 0.45 * pos) , 2.4) , .0) * 5.0;
     float f43 = max(0.01 - pow(length(uvx + 0.5 * pos) , 2.4) , .0) * 3.0;

     float3 c = float3 (.0 , .0 , .0);

     c.r += f2 + f4; c.g += f22 + f42; c.b += f23 + f43;
     c = c * .5 - float3 (length(uvd) * .05, length(uvd) * .05, length(uvd) * .05);
     c += float3 (f0, f0, f0);

     return c;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// cameraPath 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float3 pro , pta , pup;
float dro , dta , dup;

void camint(inout float3 ret , const in float t , const in float duration , const in float3 dest , inout float3 prev , inout float prevt) {
    if (t >= prevt && t <= prevt + duration) {
         ret = lerp(prev , dest , smoothstep(prevt , prevt + duration , t));
     }
    prev = dest;
    prevt += duration;
 }

void cameraPath(in float t , out float3 ro , out float3 ta , out float3 up) {
#ifndef HIDE_TERRAIN 
    time = t = mod(t , 92.);
#else 
    time = t = mod(t , 66.);
#endif 
    dro = dta = dup = 0.;

    pro = ro = float3 (900. , 7000. , 1500.);
    pta = ta = float3 (0. , 0. , 0.);
    pup = up = float3 (0. , 0.4 , 1.);

    camint(ro , t , 5. , float3 (-4300. , -1000. , 500.) , pro , dro);
    camint(ta , t , 5. , float3 (0. , 0. , 0.) , pta , dta);
    camint(up , t , 7. , float3 (0. , 0.1 , 1.) , pup , dup);

    camint(ro , t , 3. , float3 (-1355. , 1795. , 1.2) , pro , dro);
    camint(ta , t , 1. , float3 (0. , 300. , -600.) , pta , dta);
    camint(up , t , 6. , float3 (0. , 0.1 , 1.) , pup , dup);

    camint(ro , t , 10. , float3 (-1355. , 1795. , 1.2) , pro , dro);
    camint(ta , t , 14. , float3 (0. , 100. , 600.) , pta , dta);
    camint(up , t , 13. , float3 (0. , 0.3 , 1.) , pup , dup);

    float3 roe = seaUntransform(float3 (0. , EARTH_RADIUS + 0.004 , 0.));
    float3 upe = seaUntransform(float3 (0. , 1. , 0.));

    camint(ro , t , 7. , roe , pro , dro);
    camint(ta , t , 7. , float3 (EARTH_RADIUS + 0. , EARTH_RADIUS - 500. , 500.) , pta , dta);
    camint(up , t , 6. , upe , pup , dup);

    camint(ro , t , 17. , roe , pro , dro);
    camint(ta , t , 17. , float3 (EARTH_RADIUS + 500. , EARTH_RADIUS + 1300. , -100.) , pta , dta);
    camint(up , t , 18. , float3 (.0 , 1. , 1.) , pup , dup);

    camint(ro , t , 11. , float3 (3102. , 0. , 1450.) , pro , dro);
    camint(ta , t , 4. , float3 (0. , -100. , 0.) , pta , dta);
    camint(up , t , 8. , float3 (0. , 0.15 , 1.) , pup , dup);
#ifndef HIDE_TERRAIN 
    roe = terrainUntransform(float3 (0. , EARTH_RADIUS + 0.004 , 0.));
    upe = terrainUntransform(float3 (0. , 1. , 0.));

    camint(ro , t , 7. , roe , pro , dro);
    camint(ta , t , 12. , float3 (-EARTH_RADIUS , EARTH_RADIUS + 200. , 100.) , pta , dta);
    camint(up , t , 2. , upe , pup , dup);

    roe = terrainUntransform(float3 (0. , EARTH_RADIUS + 0.001 , 0.));
    camint(ro , t , 17. , roe , pro , dro);
    camint(ta , t , 18. , roe + float3 (5000. , EARTH_RADIUS - 100. , -2000.) , pta , dta);
    camint(up , t , 18. , float3 (.0 , 1. , 1.) , pup , dup);

    roe = terrainUntransform(float3 (0. , EARTH_RADIUS + 1.8 , 0.));
    camint(ro , t , 4. , roe , pro , dro);
    camint(ta , t , 4.5 , roe + float3 (EARTH_RADIUS , EARTH_RADIUS + 2000. , -30.) , pta , dta);
    camint(up , t , 4. , float3 (.0 , 1. , 1.) , pup , dup);
#endif 
    camint(ro , t , 10. , float3 (900. , 7000. , 1500.) , pro , dro);
    camint(ta , t , 2. , float3 (0. , 0. , 0.) , pta , dta);
    camint(up , t , 10. , float3 (0. , 0.4 , 1.) , pup , dup);

    up = normalize(up);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// mainImage 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
DEG_TO_RAD = (PI / 180.0);
ATMOSPHERE_SCALE_H = 4.0 / (EARTH_ATMOSPHERE);
ATMOSPHERE_SCALE_L = 1.0 / (EARTH_ATMOSPHERE);
ATMOSPHERE_FNUM_OUT_SCATTER = (ATMOSPHERE_NUM_OUT_SCATTER);
ATMOSPHERE_FNUM_IN_SCATTER = (ATMOSPHERE_NUM_IN_SCATTER);
ATMOSPHERE_FNUM_OUT_SCATTER_LOW = (ATMOSPHERE_NUM_OUT_SCATTER_LOW);
ATMOSPHERE_FNUM_IN_SCATTER_LOW = (ATMOSPHERE_NUM_IN_SCATTER_LOW);
ASTEROID_EPSILON = 1e-6;
SEA_EPSILON = 1e-3;
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.xy;

     float2 p = -1.0 + 2.0 * (fragCoord.xy) / _ScreenParams.xy;
     p.x *= _ScreenParams.x / _ScreenParams.y;

     float3 col;

     // black bands 
        float2 bandy = float2 (.1 , .9);
        if (uv.y < bandy.x || uv.y > bandy.y) {
            col = float3 (0. , 0. , 0.);
         }
    else {
            // camera 
           float3 ro , ta , up;
           cameraPath(_Time.y * .7 , ro , ta , up);

           float3 ww = normalize(ta - ro);
           float3 uu = normalize(cross(ww , up));
           float3 vv = normalize(cross(uu , ww));
           float3 rd = normalize(-p.x * uu + p.y * vv + 2.2 * ww);

           float maxd = MAX1;
           col = renderStars(rd).xyz;

           float4 planet = renderPlanet(ro , rd , up , maxd);
           if (planet.w > 0.) col.xyz = planet.xyz;

           float atmosphered = maxd;
           float4 atmosphere = .85 * renderAtmospheric(ro , rd , atmosphered);
           col = col * (1. - atmosphere.w) + atmosphere.xyz;

           float4 ring = renderRing(ro , rd , maxd);
           if (ring.w > 0. && atmosphered < maxd) {
              ring.xyz = ring.xyz * (1. - atmosphere.w) + atmosphere.xyz;
            }
           col = col * (1. - ring.w) + ring.xyz;

   #ifdef DISPLAY_CLOUDS 
           float lro = length(ro);
           if (lro < EARTH_RADIUS + EARTH_CLOUDS * 1.25) {
               float3 sunColor = 2. * renderAtmosphericLow(ro , SUN_DIRECTION);
               float3 upColor = 4. * renderAtmosphericLow(ro , float3 (-SUN_DIRECTION.x , SUN_DIRECTION.y , -SUN_DIRECTION.z));

               if (lro < EARTH_RADIUS + EARTH_CLOUDS) {
                   // clouds 
                  float d = iCSphereF(ro , rd , EARTH_RADIUS + EARTH_CLOUDS);
                  if (d < maxd) {
                      float shadow;
                      float4 clouds = renderClouds(ro , rd , d , normalize(ro) , 0. , sunColor , upColor , shadow);
                      clouds.w *= 1. - smoothstep(0.8 * EARTH_CLOUDS , EARTH_CLOUDS , lro - EARTH_RADIUS);
                      col = lerp(col , clouds.rgb , clouds.w * (1. - smoothstep(10. , 30. , d)));
                   }
               }
              float offset = lro - EARTH_RADIUS - EARTH_CLOUDS;
              col = lerp(col , .5 * sunColor , .15 * abs(noise(offset * 100.)) * clamp(1. - 4. * abs(offset) / EARTH_CLOUDS , 0. , 1.));
           }
  #endif 

           // post processing 
          col = pow(clamp(col , 0.0 , 1.0) , float3 (0.4545, 0.4545, 0.4545));
          col *= float3 (1. , 0.99 , 0.95);
          col = clamp(1.06 * col - 0.03 , 0. , 1.);

          float2 sunuv = 2.7 * float2 (dot(SUN_DIRECTION , -uu) , dot(SUN_DIRECTION , vv));
          float flare = dot(SUN_DIRECTION , normalize(ta - ro));
          col += float3 (1.4 , 1.2 , 1.0) * lensFlare(p , sunuv) * clamp(flare + .3 , 0. , 1.);

          uv.y = (uv.y - bandy.x) * (1. / (bandy.y - bandy.x));
          col *= 0.5 + 0.5 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) , 0.1);
       }
      fragColor = float4 (col , 1.0);
      fragColor.xyz -= 0.15;
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