Shader "UmutBebek/URP/ShaderToy/Rainforest 4ttSWf BufferA"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)
            /*_Iteration("Iteration", float) = 1
            _NeighbourPixels("Neighbour Pixels", float) = 1
            _Lod("Lod",float) = 0
            _AR("AR Mode",float) = 0*/
kSunDir("kSunDir", vector) = (-0.624695 , 0.468521 , -0.624695)
kMaxTreeHeight("kMaxTreeHeight", float) = 2.0

    }

    SubShader
    {
        // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
        // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
        // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
        // "UniversalRenderPipeline"
        Tags{"RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            "IgnoreProjector" = "True"}
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

             /*Blend One Zero
            ZWrite Off ZTest Always*/
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
   
float4 kSunDir;
float kMaxTreeHeight;

/*float _Lod;
float _Iteration;
float _NeighbourPixels;
float _AR;*/

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
};

Varyings LitPassVertex(Attributes input)
{
    Varyings output;

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

// Created by inigo quilez - iq / 2016 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 


// Normals are analytical ( true derivatives ) for the terrain and for the clouds , that 
// includes the noise , the fbm and the smoothsteps involved chain derivatives correctly. 
// 
// See here for more info: http: // iquilezles.org / www / articles / morenoise / morenoise.htm 
// 
// Lighting and art composed for this shot / camera 
// 
// The trees are really cheap ( ellipsoids with noise ) , but they kind of do the job in 
// distance and low image resolutions. 
// 
// I used some cheap reprojection technique to smooth out the render , although it creates 
// halows and blurs the image way too much ( I don't have the time now to do the tricks 
// used in TAA ) . Enable the STATIC_CAMERA define to see a sharper image. 
// 
// Lastly , it runs very slow in WebGL ( but runs 2x faster in native GL ) , so I had to make 
// a youtube capture , sorry for that! 
// 
// https: // www.youtube.com / watch?v = VqYROPZrDeU 


// #define STATIC_CAMERA 
#define LOWQUALITY 

 // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
 // general utilities 
 // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 

float sdEllipsoidY(in float3 p , in float2 r)
 {
    float k0 = length(p / r.xyx);
    float k1 = length(p / (r.xyx * r.xyx));
    return k0 * (k0 - 1.0) / k1;
 }

// return smoothstep and its derivative 
float2 smoothstepd(float a , float b , float x)
 {
     if (x < a) return float2 (0.0 , 0.0);
     if (x > b) return float2 (1.0 , 0.0);
    float ir = 1.0 / (b - a);
    x = (x - a) * ir;
    return float2 (x * x * (3.0 - 2.0 * x) , 6.0 * x * (1.0 - x) * ir);
 }

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// hashes 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 

float hash1(float2 p)
 {
    p = 50.0 * frac(p * 0.3183099);
    return frac(p.x * p.y * (p.x + p.y));
 }

float hash1(float n)
 {
    return frac(n * 17.0 * frac(n * 0.3183099));
 }

float2 hash2(float n) { return frac(sin(float2 (n , n + 1.0)) * float2 (43758.5453123 , 22578.1459123)); }


float2 hash2(float2 p)
 {
    const float2 k = float2 (0.3183099 , 0.3678794);
    p = p * k + k.yx;
    return frac(16.0 * k * frac(p.x * p.y * (p.x + p.y)));
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// noises 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 

// value noise , and its analytical derivatives 
float4 noised(in float3 x)
 {
    float3 p = floor(x);
    float3 w = frac(x);

    float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    float n = p.x + 317.0 * p.y + 157.0 * p.z;

    float a = hash1(n + 0.0);
    float b = hash1(n + 1.0);
    float c = hash1(n + 317.0);
    float d = hash1(n + 318.0);
    float e = hash1(n + 157.0);
     float f = hash1(n + 158.0);
    float g = hash1(n + 474.0);
    float h = hash1(n + 475.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return float4 (-1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z) ,
                      2.0 * du * float3 (k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z ,
                                      k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x ,
                                      k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y));
 }

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 w = frac(x);

    float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    float n = p.x + 317.0 * p.y + 157.0 * p.z;

    float a = hash1(n + 0.0);
    float b = hash1(n + 1.0);
    float c = hash1(n + 317.0);
    float d = hash1(n + 318.0);
    float e = hash1(n + 157.0);
     float f = hash1(n + 158.0);
    float g = hash1(n + 474.0);
    float h = hash1(n + 475.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return -1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z);
 }

float3 noised(in float2 x)
 {
    float2 p = floor(x);
    float2 w = frac(x);

    float2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float2 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    float a = hash1(p + float2 (0 , 0));
    float b = hash1(p + float2 (1 , 0));
    float c = hash1(p + float2 (0 , 1));
    float d = hash1(p + float2 (1 , 1));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k4 = a - b - c + d;

    return float3 (-1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k4 * u.x * u.y) ,
                      2.0 * du * float2 (k1 + k4 * u.y ,
                                      k2 + k4 * u.x));
 }

float noise(in float2 x)
 {
    float2 p = floor(x);
    float2 w = frac(x);
    float2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

#if 0 
    p *= 0.3183099;
    float kx0 = 50.0 * frac(p.x);
    float kx1 = 50.0 * frac(p.x + 0.3183099);
    float ky0 = 50.0 * frac(p.y);
    float ky1 = 50.0 * frac(p.y + 0.3183099);

    float a = frac(kx0 * ky0 * (kx0 + ky0));
    float b = frac(kx1 * ky0 * (kx1 + ky0));
    float c = frac(kx0 * ky1 * (kx0 + ky1));
    float d = frac(kx1 * ky1 * (kx1 + ky1));
#else 
    float a = hash1(p + float2 (0 , 0));
    float b = hash1(p + float2 (1 , 0));
    float c = hash1(p + float2 (0 , 1));
    float d = hash1(p + float2 (1 , 1));
#endif 

    return -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// fbm constructions 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 



        // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

       float fbm_4(in float3 x)
        {
           float f = 2.0;
           float s = 0.5;
           float a = 0.0;
           float b = 0.5;
           for (int i = 0; i < 4; i++)
            {
               float n = noise(x);
               a += b * n;
               b *= s;
               x = f * mul(float3x3(0.00, 0.80, 0.60,
                   -0.80, 0.36, -0.48,
                   -0.60, -0.48, 0.64), x);
            }
            return a;
        }

       float4 fbmd_8(in float3 x)
        {
           float f = 1.92;
           float s = 0.5;
           float a = 0.0;
           float b = 0.5;
           float3 d = float3 (0.0 , 0.0 , 0.0);
           float3x3 m = float3x3 (1.0 , 0.0 , 0.0 ,
                          0.0 , 1.0 , 0.0 ,
                          0.0 , 0.0 , 1.0);
           for (int i = 0; i < 7; i++)
            {
               float4 n = noised(x);
               a += b * n.x; // accumulate values 
               d += b * mul(m , n.yzw); // accumulate derivatives 
               b *= s;
               x = f * mul(float3x3(0.00, 0.80, 0.60,
                   -0.80, 0.36, -0.48,
                   -0.60, -0.48, 0.64), x);
               m = f * float3x3(0.00, -0.80, -0.60,
                   0.80, 0.36, -0.48,
                   0.60, -0.48, 0.64) * m;
            }
            return float4 (a , d);
        }

       float fbm_9(in float2 x)
        {
           float f = 1.9;
           float s = 0.55;
           float a = 0.0;
           float b = 0.5;
           for (int i = 0; i < 9; i++)
            {
               float n = noise(x);
               a += b * n;
               b *= s;
               x = f * mul(float2x2(0.80, 0.60,
                   -0.60, 0.80), x);
            }
            return a;
        }

       float3 fbmd_9(in float2 x)
        {
           float f = 1.9;
           float s = 0.55;
           float a = 0.0;
           float b = 0.5;
           float2 d = float2 (0.0 , 0.0);
           float2x2 m = float2x2 (1.0 , 0.0 , 0.0 , 1.0);
           for (int i = 0; i < 9; i++)
            {
               float3 n = noised(x);
               a += b * n.x; // accumulate values 
               d += b * mul(m , n.yz); // accumulate derivatives 
               b *= s;
               x = f * mul(float2x2(0.80, 0.60,
                   -0.60, 0.80), x);
               m = f * float2x2(0.80, -0.60,
                   0.60, 0.80) * m;
            }
            return float3 (a , d);
        }

       float fbm_4(in float2 x)
        {
           float f = 1.9;
           float s = 0.55;
           float a = 0.0;
           float b = 0.5;
           for (int i = 0; i < 4; i++)
            {
               float n = noise(x);
               a += b * n;
               b *= s;
               x = f * mul(float2x2(0.80, 0.60,
                   -0.60, 0.80), x);
            }
            return a;
        }

       // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 

      #define ZEROExtended ( min ( iFrame , 0 ) ) 


       // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
       // specifics to the actual painting 
       // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 


       // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
       // global 
       // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 




      float3 fog(in float3 col , float t)
       {
          float3 fogCol = float3 (0.4 , 0.6 , 1.15);
          return lerp(col , fogCol , 1.0 - exp(-0.000001 * t * t));
       }


      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      // clouds 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

     float4 cloudsMap(in float3 pos)
      {
         float4 n = fbmd_8(pos * 0.003 * float3 (0.6 , 1.0 , 0.6) - float3 (0.1 , 1.9 , 2.8));
         float2 h = smoothstepd(-60.0 , 10.0 , pos.y) - smoothstepd(10.0 , 500.0 , pos.y);
         h.x = 2.0 * n.x + h.x - 1.3;
         return float4 (h.x , 2.0 * n.yzw * float3 (0.6 , 1.0 , 0.6) * 0.003 + float3 (0.0 , h.y , 0.0));
      }

     float cloudsShadow(in float3 ro , in float3 rd , float tmin , float tmax)
      {
          float sum = 0.0;

          // bounding volume!! 
         float tl = (-10.0 - ro.y) / rd.y;
         float th = (300.0 - ro.y) / rd.y;
         if (tl > 0.0) tmin = max(tmin , tl);
         if (th > 0.0) tmax = min(tmax , th);

          float t = tmin;
          for (int i = ZEROExtended; i < 64; i++)
          {
             float3 pos = ro + t * rd;
             float4 denGra = cloudsMap(pos);
             float den = denGra.x;
             float dt = max(0.2 , 0.02 * t);
             if (den > 0.001)
              {
                 float alp = clamp(den * 0.3 * min(dt , tmax - t - dt) , 0.0 , 1.0);
                 sum = sum + alp * (1.0 - sum);
              }
             else
              {
                 dt *= 1.0 + 4.0 * abs(den);
              }
             t += dt;
             if (sum > 0.995 || t > tmax) break;
          }

         return clamp(1.0 - sum , 0.0 , 1.0);
      }

     float4 renderClouds(in float3 ro , in float3 rd , float tmin , float tmax , inout float resT)
      {
         float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);

         // bounding volume!! 
        float tl = (-10.0 - ro.y) / rd.y;
        float th = (300.0 - ro.y) / rd.y;
        if (tl > 0.0) tmin = max(tmin , tl); else return sum;
        /* if ( th > 0.0 ) */ tmax = min(tmax , th);


         float t = tmin;
         float lastT = t;
         float thickness = 0.0;
         #ifdef LOWQUALITY 
         for (int i = ZEROExtended; i < 128; i++)
         #else 
         for (int i = ZEROExtended; i < 300; i++)
         #endif 
          {
             float3 pos = ro + t * rd;
             float4 denGra = cloudsMap(pos);
             float den = denGra.x;
             #ifdef LOWQUALITY 
             float dt = max(0.1 , 0.011 * t);
             #else 
             float dt = max(0.05 , 0.005 * t);
             #endif 
             if (den > 0.001)
              {
                 #ifdef LOWQUALITY 
                 float sha = 1.0;
                 #else 
                 float sha = clamp(1.0 - max(0.0 , cloudsMap(pos + kSunDir * 5.0).x) , 0.0 , 1.0);
                 // sha *= clamp ( pos.y - terrainMap ( ( pos + kSunDir * 5.0 ) .xz ) .x , 0.0 , 1.0 ) ; 
                #endif 
                float3 nor = -normalize(denGra.yzw);
                float dif = clamp(dot(nor , kSunDir) , 0.0 , 1.0) * sha;
                float fre = clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) * sha;
                // lighting 
               float3 lin = float3 (0.70 , 0.80 , 1.00) * 0.9 * (0.6 + 0.4 * nor.y);
                    lin += float3 (0.20 , 0.25 , 0.20) * 0.7 * (0.5 - 0.5 * nor.y);
                    lin += float3 (1.00 , 0.70 , 0.40) * 4.5 * dif * (1.0 - den);
                     lin += float3 (0.80 , 0.70 , 0.50) * 1.3 * pow(fre , 32.0) * (1.0 - den);
                     // color 
                    float3 col = float3 (0.8 , 0.77 , 0.72) * clamp(1.0 - 4.0 * den , 0.0 , 1.0);

                    col *= lin;

                    col = fog(col , t);

                    // front to back blending 
                   float alp = clamp(den * 0.25 * min(dt , tmax - t - dt) , 0.0 , 1.0);
                   col.rgb *= alp;
                   sum = sum + float4 (col , alp) * (1.0 - sum.a);

                   thickness += dt * den;
                   lastT = t;
                }
               else
                {
       #ifdef LOWQUALITY 
                   dt *= 1.0 + 4.0 * abs(den);
       #else 
                   dt *= 0.8 + 2.0 * abs(den);
       #endif 
                }
               t += dt;
               if (sum.a > 0.995 || t > tmax) break;
            }

           resT = lerp(resT , lastT , sum.w);

           if (thickness > 0.0)
                 sum.xyz += float3 (1.00 , 0.60 , 0.40) * 0.2 * pow(clamp(dot(kSunDir , rd) , 0.0 , 1.0) , 32.0) * exp(-0.3 * thickness) * clamp(thickness * 4.0 , 0.0 , 1.0);

           return clamp(sum , 0.0 , 1.0);
        }


     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
     // terrain 
     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

    float2 terrainMap(in float2 p)
     {
        const float sca = 0.0010;
        const float amp = 300.0;

        p *= sca;
        float e = fbm_9(p + float2 (1.0 , -2.0));
        float a = 1.0 - smoothstep(0.12 , 0.13 , abs(e + 0.12)); // flag high - slope areas ( - 0.25 , 0.0 ) 
        e = e + 0.15 * smoothstep(-0.08 , -0.01 , e);
        e *= amp;
        return float2 (e , a);
     }

    float4 terrainMapD(in float2 p)
     {
         const float sca = 0.0010;
        const float amp = 300.0;
        p *= sca;
        float3 e = fbmd_9(p + float2 (1.0 , -2.0));
        float2 c = smoothstepd(-0.08 , -0.01 , e.x);
         e.x = e.x + 0.15 * c.x;
         e.yz = e.yz + 0.15 * c.y * e.yz;
        e.x *= amp;
        e.yz *= amp * sca;
        return float4 (e.x , normalize(float3 (-e.y , 1.0 , -e.z)));
     }

    float3 terrainNormal(in float2 pos)
     {
    #if 1 
        return terrainMapD(pos).yzw;
    #else 
        float2 e = float2 (0.03 , 0.0);
         return normalize(float3 (terrainMap(pos - e.xy).x - terrainMap(pos + e.xy).x ,
                               2.0 * e.x ,
                               terrainMap(pos - e.yx).x - terrainMap(pos + e.yx).x));
    #endif 
     }

    float terrainShadow(in float3 ro , in float3 rd , in float mint)
     {
        float res = 1.0;
        float t = mint;
    #ifdef LOWQUALITY 
        for (int i = ZEROExtended; i < 32; i++)
         {
            float3 pos = ro + t * rd;
            float2 env = terrainMap(pos.xz);
            float hei = pos.y - env.x;
            res = min(res , 32.0 * hei / t);
            if (res < 0.0001) break;
            t += clamp(hei , 1.0 + t * 0.1 , 50.0);
         }
    #else 
        for (int i = ZEROExtended; i < 128; i++)
         {
            float3 pos = ro + t * rd;
            float2 env = terrainMap(pos.xz);
            float hei = pos.y - env.x;
            res = min(res , 32.0 * hei / t);
            if (res < 0.0001) break;
            t += clamp(hei , 0.5 + t * 0.05 , 25.0);
         }
    #endif 
        return clamp(res , 0.0 , 1.0);
     }

    float2 raymarchTerrain(in float3 ro , in float3 rd , float tmin , float tmax)
     {
        // float tt = ( 150.0 - ro.y ) / rd.y ; if ( tt > 0.0 ) tmax = min ( tmax , tt ) ; 

       float dis , th;
       float t2 = -1.0;
       float t = tmin;
       float ot = t;
       float odis = 0.0;
       float odis2 = 0.0;
       for (int i = ZEROExtended; i < 400; i++)
        {
           th = 0.001 * t;

           float3 pos = ro + t * rd;
           float2 env = terrainMap(pos.xz);
           float hei = env.x;

           // tree envelope 
          float dis2 = pos.y - (hei + kMaxTreeHeight * 1.1);
          if (dis2 < th)
           {
              if (t2 < 0.0)
               {
                  t2 = ot + (th - odis2) * (t - ot) / (dis2 - odis2); // linear interpolation for better accuracy 
               }
           }
          odis2 = dis2;

          // terrain 
         dis = pos.y - hei;
         if (dis < th) break;

         ot = t;
         odis = dis;
         t += dis * 0.8 * (1.0 - 0.75 * env.y); // slow down in step areas 
         if (t > tmax) break;
      }

     if (t > tmax) t = -1.0;
     else t = ot + (th - odis) * (t - ot) / (dis - odis); // linear interpolation for better accuracy 
     return float2 (t , t2);
  }

 float4 renderTerrain(in float3 ro , in float3 rd , in float2 tmima , out float teShadow , out float2 teDistance , inout float resT)
  {
     float4 res = float4 (0.0 , 0.0 , 0.0 , 0.0);
     teShadow = 0.0;
     teDistance = float2 (0.0 , 0.0);

     float2 t = raymarchTerrain(ro , rd , tmima.x , tmima.y);
     if (t.x > 0.0)
      {
         float3 pos = ro + t.x * rd;
         float3 nor = terrainNormal(pos.xz);

         // bump map 
        nor = normalize(nor + 0.8 * (1.0 - abs(nor.y)) * 0.8 * fbmd_8(pos * 0.3 * float3 (1.0 , 0.2 , 1.0)).yzw);

        float3 col = float3 (0.18 , 0.11 , 0.10) * .75;
        col = 1.0 * lerp(col , float3 (0.1 , 0.1 , 0.0) * 0.3 , smoothstep(0.7 , 0.9 , nor.y));

        // col *= 1.0 + 2.0 * fbm ( pos * 0.2 * float3 ( 1.0 , 4.0 , 1.0 ) ) ; 

     float sha = 0.0;
     float dif = clamp(dot(nor , kSunDir) , 0.0 , 1.0);
     if (dif > 0.0001)
      {
         sha = terrainShadow(pos + nor * 0.01 , kSunDir , 0.01);
         // if ( sha > 0.0001 ) sha *= cloudsShadow ( pos + nor * 0.01 , kSunDir , 0.01 , 1000.0 ) ; 
        dif *= sha;
     }
    float3 ref = reflect(rd , nor);
     float bac = clamp(dot(normalize(float3 (-kSunDir.x , 0.0 , -kSunDir.z)) , nor) , 0.0 , 1.0) * clamp((pos.y + 100.0) / 100.0 , 0.0 , 1.0);
    float dom = clamp(0.5 + 0.5 * nor.y , 0.0 , 1.0);
    float3 lin = 1.0 * 0.2 * lerp(0.1 * float3 (0.1 , 0.2 , 0.0) , float3 (0.7 , 0.9 , 1.0) , dom); // pow ( float3 ( occ ) , float3 ( 1.5 , 0.7 , 0.5 ) ) ; 
          lin += 1.0 * 5.0 * float3 (1.0 , 0.9 , 0.8) * dif;
          lin += 1.0 * 0.35 * float3 (1.0 , 1.0 , 1.0) * bac;

     col *= lin;

    col = fog(col , t.x);

    teShadow = sha;
    teDistance = t;
    res = float4 (col , 1.0);
    resT = t.x;
 }

return res;
}

 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
 // trees 
 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float treesMap(in float3 p , in float rt , out float oHei , out float oMat , out float oDis)
 {
    oHei = 1.0;
    oDis = 0.1;
    oMat = 0.0;

    float base = terrainMap(p.xz).x;

    float d = 10.0;
    float2 n = floor(p.xz);
    float2 f = frac(p.xz);
    for (int j = 0; j <= 1; j++)
    for (int i = 0; i <= 1; i++)
     {
        float2 g = float2 (float(i) , float(j)) - step(f , float2 (0.5 , 0.5));
        float2 o = hash2(n + g);
        float2 v = hash2(n + g + float2 (13.1 , 71.7));
        float2 r = g - f + o;

        float height = kMaxTreeHeight * (0.4 + 0.8 * v.x);
        float width = 0.9 * (0.5 + 0.2 * v.x + 0.3 * v.y);
        float3 q = float3 (r.x , p.y - base - height * 0.5 , r.y);
        float k = sdEllipsoidY(q , float2 (width , 0.5 * height));

        if (k < d)
         {
            d = k;
            // oMat = hash1 ( o ) ; // frac ( o.x * 7.0 + o.y * 15.0 ) ; 
           oMat = o.x * 7.0 + o.y * 15.0;
           oHei = (p.y - base) / height;
           oHei *= 0.5 + 0.5 * length(q) / width;
        }
    }
   oMat = frac(oMat);

   // distort ellipsoids to make them look like trees ( works only in the distance really ) 
  #ifdef LOWQUALITY 
  if (rt < 350.0)
  #else 
  if (rt < 500.0)
  #endif 
   {
      float s = fbm_4(p * 3.0);
      s = s * s;
      oDis = s;
      #ifdef LOWQUALITY 
      float att = 1.0 - smoothstep(150.0 , 350.0 , rt);
      #else 
      float att = 1.0 - smoothstep(200.0 , 500.0 , rt);
      #endif 
      d += 2.0 * s * att * att;
   }

  return d;
}

float treesShadow(in float3 ro , in float3 rd)
 {
    float res = 1.0;
    float t = 0.02;
#ifdef LOWQUALITY 
    for (int i = ZEROExtended; i < 50; i++)
     {
        float kk1 , kk2 , kk3;
        float h = treesMap(ro + rd * t , t , kk1 , kk2 , kk3);
        res = min(res , 32.0 * h / t);
        t += h;
        if (res < 0.001 || t > 20.0) break;
     }
#else 
    for (int i = ZEROExtended; i < 150; i++)
     {
        float kk1 , kk2 , kk3;
        float h = treesMap(ro + rd * t , t , kk1 , kk2 , kk3);
        res = min(res , 32.0 * h / t);
        t += h;
        if (res < 0.001 || t > 120.0) break;
     }
#endif 
    return clamp(res , 0.0 , 1.0);
 }

float3 treesNormal(in float3 pos , in float t)
 {
    float kk1 , kk2 , kk3;
#if 0 
    const float eps = 0.005;
    float2 e = float2 (1.0 , -1.0) * 0.5773 * eps;
    return normalize(e.xyy * treesMap(pos + e.xyy , t , kk1 , kk2 , kk3) +
                      e.yyx * treesMap(pos + e.yyx , t , kk1 , kk2 , kk3) +
                      e.yxy * treesMap(pos + e.yxy , t , kk1 , kk2 , kk3) +
                      e.xxx * treesMap(pos + e.xxx , t , kk1 , kk2 , kk3));
#else 
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map ( ) 4 times 
   float3 n = float3 (0.0 , 0.0 , 0.0);
   for (int i = ZEROExtended; i < 4; i++)
    {
       float3 e = 0.5773 * (2.0 * float3 ((((i + 3) >> 1) & 1) , ((i >> 1) & 1) , (i & 1)) - 1.0);
       n += e * treesMap(pos + 0.005 * e , t , kk1 , kk2 , kk3);
    }
   return normalize(n);
#endif 
 }

float3 treesShade(in float3 pos , in float3 tnor , in float3 enor , in float hei , in float mid , in float dis , in float rt , in float3 rd , float terrainShadow)
 {
    float3 nor = normalize(tnor + 2.5 * enor);

    // -- - lighting -- - 
   float sha = terrainShadow;
   float3 ref = reflect(rd , nor);
   float occ = clamp(hei , 0.0 , 1.0) * pow(1.0 - 2.0 * dis , 3.0);
   float dif = clamp(0.1 + 0.9 * dot(nor , kSunDir) , 0.0 , 1.0);
   if (dif > 0.0001 && terrainShadow > 0.001)
    {
       // sha *= clamp ( 10.0 * dot ( tnor , kSunDir ) , 0.0 , 1.0 ) * pow ( clamp ( 1.0 - 13.0 * dis , 0.0 , 1.0 ) , 4.0 ) ; // treesShadow ( pos + nor * 0.1 , kSunDir ) ; // only cast in non - terrain - occluded areas 
      sha *= treesShadow(pos + nor * 0.1 , kSunDir); // only cast in non - terrain - occluded areas 
   }
  float dom = clamp(0.5 + 0.5 * nor.y , 0.0 , 1.0);
  float fre = clamp(1.0 + dot(nor , rd) , 0.0 , 1.0);
  float spe = pow(clamp(dot(ref , kSunDir) , 0.0 , 1.0) , 9.0) * dif * sha * (0.2 + 0.8 * pow(fre , 5.0)) * occ;

  // -- - lights -- - 
 float3 lin = 1.0 * 0.5 * lerp(0.1 * float3 (0.1 , 0.2 , 0.0) , float3 (0.6 , 1.0 , 1.0) , dom * occ);
        #ifdef SOFTTREES 
      lin += 1.0 * 15.0 * float3 (1.0 , 0.9 , 0.8) * dif * occ * sha;
        #else 
      lin += 1.0 * 10.0 * float3 (1.0 , 0.9 , 0.8) * dif * occ * sha;
        #endif 
      lin += 1.0 * 0.5 * float3 (0.9 , 1.0 , 0.8) * pow(fre , 3.0) * occ;
      lin += 1.0 * 0.05 * float3 (0.15 , 0.4 , 0.1) * occ;

      // -- - material -- - 
     float brownAreas = fbm_4(pos.zx * 0.03);
     float3 col = float3 (0.08 , 0.09 , 0.02);
           col = lerp(col , float3 (0.09 , 0.07 , 0.02) , smoothstep(0.2 , 1.0 , mid));
          col = lerp(col , float3 (0.06 , 0.05 , 0.01) * 1.1 , 1.0 - smoothstep(0.9 , 0.91 , enor.y));
          col = lerp(col , float3 (0.25 , 0.16 , 0.01) * 0.15 , 0.7 * smoothstep(0.1 , 0.3 , brownAreas) * smoothstep(0.5 , 0.8 , enor.y));
          col *= 1.6;

          // -- - brdf * material -- - 
         col *= lin;
         col += spe * 1.2 * float3 (1.0 , 1.1 , 2.5);

         // -- - fog -- - 
        col = fog(col , rt);

        return col;
     }

    float4 renderTrees(in float3 ro , in float3 rd , float tmin , float tmax , float terrainShadow , inout float resT)
     {
        // if ( tmin > 300.0 ) return float4 ( 0.0 , 0.0 , 0.0 , 0.0 ) ; 
      float t = tmin;
      float hei , mid , displa;

      for (int i = ZEROExtended; i < 64; i++)
       {
          float3 pos = ro + t * rd;
          float dis = treesMap(pos , t , hei , mid , displa);
          if (dis < (0.00025 * t)) break;
          t += dis;
          if (t > tmax) return float4 (0.0 , 0.0 , 0.0 , 0.0);
       }

      float3 pos = ro + t * rd;

      float3 enor = terrainNormal(pos.xz);
      float3 tnor = treesNormal(pos , t);

      float3 col = treesShade(pos , tnor , enor , hei , mid , displa , t , rd , terrainShadow);
       resT = t;

      return float4 (col , 1.0);
   }


    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    // sky 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

   float3 renderSky(in float3 ro , in float3 rd)
    {
       // background sky 
      float3 col = 0.9 * float3 (0.4 , 0.65 , 1.0) - rd.y * float3 (0.4 , 0.36 , 0.4);

      // clouds 
     float t = (1000.0 - ro.y) / rd.y;
     if (t > 0.0)
      {
         float2 uv = (ro + t * rd).xz;
         float cl = fbm_9(uv * 0.002);
         float dl = smoothstep(-0.2 , 0.6 , cl);
         col = lerp(col , float3 (1.0 , 1.0 , 1.0) , 0.4 * dl);
      }

     // sun glare 
   float sun = clamp(dot(kSunDir , rd) , 0.0 , 1.0);
   col += 0.6 * float3 (1.0 , 0.6 , 0.3) * pow(sun , 32.0);

    return col;
}


   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   // main image making function 
   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

  half4 LitPassFragment(Varyings input) : SV_Target  {
  half4 fragColor = half4 (1 , 1 , 1 , 1);
  
  float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 o = hash2(float(iFrame)) - 0.5;

      float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + o)) / _ScreenParams.y;

      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      // setup 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

      // camera 
     #ifdef STATIC_CAMERA 
     float3 ro = float3 (0.0 , -99.25 , 5.0);
     float3 ta = float3 (0.0 , -99.0 , 0.0);
      #else 
     float time = _Time.y;
     float3 ro = float3 (0.0 , -99.25 , 5.0) + float3 (10.0 * sin(0.02 * time) , 0.0 , -10.0 * sin(0.2 + 0.031 * time));
     float3 ta = float3 (0.0 , -98.25 , -45.0 + ro.z);
     #endif 

     // ray 
    float3x3 ca = setCamera(ro , ta , 0.0);
    float3 rd = mul(ca , normalize(float3 (p.xy , 1.5)));

     float resT = 1000.0;

     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
     // sky 
     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

    float3 col = renderSky(ro , rd);

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    // terrain 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   float2 teDistance;
   float teShadow;

   float2 tmima = float2 (15.0 , 1000.0);
    {
       float4 res = renderTerrain(ro , rd , tmima , teShadow , teDistance , resT);
       col = col * (1.0 - res.w) + res.xyz;
    }

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    // trees 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   if (teDistance.y > 0.0)
    {
       tmima = float2 (teDistance.y , (teDistance.x > 0.0) ? teDistance.x : tmima.y);
       float4 res = renderTrees(ro , rd , tmima.x , tmima.y , teShadow , resT);
       col = col * (1.0 - res.w) + res.xyz;
    }

   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   // clouds 
   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   {
      float4 res = renderClouds(ro , rd , 0.0 , (teDistance.x > 0.0) ? teDistance.x : tmima.y , resT);
      col = col * (1.0 - res.w) + res.xyz;
   }

   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   // final 
   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

   // sun glare 
  float sun = clamp(dot(kSunDir , rd) , 0.0 , 1.0);
  col += 0.25 * float3 (1.0 , 0.4 , 0.2) * pow(sun , 4.0);

  // gamma 
 col = sqrt(col);

 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
 // color grading 
 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

col = col * 0.15 + 0.85 * col * col * (3.0 - 2.0 * col); // contrast 
col = pow(col , float3 (1.0 , 0.92 , 1.0)); // soft greenExtended 
col *= float3 (1.02 , 0.99 , 0.99); // tint redExtended 
col.z = (col.z + 0.1) / 1.1; // bias blueExtended 
col = lerp(col , col.yyy , 0.15); // desaturate 

col = clamp(col , 0.0 , 1.0);


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
 // reproject from previous frame and average 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float4x4 oldCam = float4x4 (SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , float2 (0.5 , 0.5) / _ScreenParams.xy , 0.0) ,
                    SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , float2 (1.5 , 0.5) / _ScreenParams.xy , 0.0) ,
                    SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , float2 (2.5 , 0.5) / _ScreenParams.xy , 0.0) ,
                    0.0 , 0.0 , 0.0 , 1.0);

// world space 
float4 wpos = float4 (ro + rd * resT , 1.0);
// camera space 
float3 cpos = (mul(wpos , oldCam)).xyz; // note inverse multiply 
 // ndc space 
float2 npos = 1.5 * cpos.xy / cpos.z;
// screen space 
float2 spos = 0.5 + 0.5 * npos * float2 (_ScreenParams.y / _ScreenParams.x , 1.0);
// undo dither 
spos -= o / _ScreenParams.xy;
// raster space 
float2 rpos = spos * _ScreenParams.xy;

if (rpos.y < 1.0 && rpos.x < 3.0)
 {
 }
 else
 {
    float3 ocol = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , spos , 0.0).xyz;
     if (iFrame == 0) ocol = col;
    col = lerp(ocol , col , 0.1);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

if (fragCoord.y < 1.0 && fragCoord.x < 3.0)
{
   if (abs(fragCoord.x - 2.5) < 0.5) fragColor = float4 (ca[2] , -dot(ca[2] , ro));
   if (abs(fragCoord.x - 1.5) < 0.5) fragColor = float4 (ca[1] , -dot(ca[1] , ro));
   if (abs(fragCoord.x - 0.5) < 0.5) fragColor = float4 (ca[0] , -dot(ca[0] , ro));
}
else
 {
    fragColor = float4 (col , 1.0);
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