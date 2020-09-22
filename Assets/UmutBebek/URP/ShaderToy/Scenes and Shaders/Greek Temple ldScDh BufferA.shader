Shader "UmutBebek/URP/ShaderToy/Greek Temple ldScDh Buffer A"
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
               return item *= 0.90;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Created by inigo quilez - iq / 2017 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 


// A basic temple model. No global illumination , all cheated and composed to camera: 
// 
// - the terrain is false perspective 
// - there are two different sun directions for foreground and background. 
// - ambient occlusion is mostly painted by hand 
// - bounce lighting is also painted by hand 
// 
// This shader was made as a continuation to a live coding session I did for the students 
// of UPENN. After the initial live coded session I decided to rework it and improve it , 
// and that turned out to be a bit of a pain because when looking for the final look I got 
// trapped in more local m♂inima that I usually do and it took me a while to leave them. 

// TODO: fix black glitches 
// fix usdBox of rhombus with sdElogation operation 


// #define STATICCAM 

float hash1(float2 p)
 {
    p = 50.0 * frac(p * 0.3183099);
    return frac(p.x * p.y * (p.x + p.y));
 }

float hash(uint n)
 {
     n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    // floating pointExtended conversion from http: // iquilezles.org / www / articles / sfrand / sfrand.htm 
    //return uintBitsToFloat((n >> 9U) | 0x3f800000U) - 1.0;
    return float(((n >> 9U) | 0x3f800000U)) - 1.0;
}

float2 hash2(float n) { return frac(sin(float2 (n , n + 1.0)) * float2 (43758.5453123 , 22578.1459123)); }

float noise(in float2 x)
 {
    int2 p = int2 (floor(x));
    float2 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
     int2 uv = p.xy;
     float rgA = pointSampleTex2D(_Channel1 , sampler_Channel1 , (uv + int2 (0 , 0)) & 255 ).x;
    float rgB = pointSampleTex2D(_Channel1 , sampler_Channel1 , (uv + int2 (1 , 0)) & 255 ).x;
    float rgC = pointSampleTex2D(_Channel1 , sampler_Channel1 , (uv + int2 (0 , 1)) & 255 ).x;
    float rgD = pointSampleTex2D(_Channel1 , sampler_Channel1 , (uv + int2 (1 , 1)) & 255 ).x;
    return lerp(lerp(rgA , rgB , f.x) ,
                lerp(rgC , rgD , f.x) , f.y);
 }

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }

float fbm4(in float3 p)
 {
    float n = 0.0;
    n += 1.000 * noise(p * 1.0);
    n += 0.500 * noise(p * 2.0);
    n += 0.250 * noise(p * 4.0);
    n += 0.125 * noise(p * 8.0);
    return n;
 }

float fbm6(in float3 p)
 {
    float n = 0.0;
    n += 1.00000 * noise(p * 1.0);
    n += 0.50000 * noise(p * 2.0);
    n += 0.25000 * noise(p * 4.0);
    n += 0.12500 * noise(p * 8.0);
    n += 0.06250 * noise(p * 16.0);
    n += 0.03125 * noise(p * 32.0);
    return n;
 }

float fbm6(in float2 p)
 {
    float n = 0.0;
    n += 1.00000 * noise(p * 1.0);
    n += 0.50000 * noise(p * 2.0);
    n += 0.25000 * noise(p * 4.0);
    n += 0.12500 * noise(p * 8.0);
    n += 0.06250 * noise(p * 16.0);
    n += 0.03125 * noise(p * 32.0);
    return n;
 }

float fbm4(in float2 p)
 {
    float n = 0.0;
    n += 1.00000 * noise(p * 1.0);
    n += 0.50000 * noise(p * 2.0);
    n += 0.25000 * noise(p * 4.0);
    n += 0.12500 * noise(p * 8.0);
    return n;
 }

float ndot(float2 a , float2 b) { return a.x * b.x - a.y * b.y; }

float sdRhombus(in float2 p , in float2 b , in float r)
 {
    float2 q = abs(p);
    float h = clamp((-2.0 * ndot(q , b) + ndot(b , b)) / dot(b , b) , -1.0 , 1.0);
    float d = length(q - 0.5 * b * float2 (1.0 - h , 1.0 + h));
    d *= sign(q.x * b.y + q.y * b.x - b.x * b.y);
     return d - r;
 }

float usdBox(in float3 p , in float3 b)
 {
    return length(max(abs(p) - b , 0.0));
 }

float sdBox(float3 p , float3 b)
 {
  float3 d = abs(p) - b;
  return min(max(d.x , max(d.y , d.z)) , 0.0) + length(max(d , 0.0));
 }

float sdBox(float p , float b)
 {
  return abs(p) - b;
 }

float2 opRepLim(in float2 p , in float s , in float2 lim)
 {
    return p - s * clamp(round(p / s) , -lim , lim);
 }

float2 opRepLim(in float2 p , in float s , in float2 limmin , in float2 limmax)
 {
    return p - s * clamp(round(p / s) , -limmin , limmax);
 }

float4 textureGood(Texture2D sam, SamplerState samp, in float2 uv)
 {
    uv = uv * 1024.0 - 0.5;
    float2 iuv = floor(uv);
    float2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);
     float4 rg1 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (0.5 , 0.5)) / 1024.0 , 0.0);
     float4 rg2 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (1.5 , 0.5)) / 1024.0 , 0.0);
     float4 rg3 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (0.5 , 1.5)) / 1024.0 , 0.0);
     float4 rg4 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (1.5 , 1.5)) / 1024.0 , 0.0);
     return lerp(lerp(rg1 , rg2 , f.x) , lerp(rg3 , rg4 , f.x) , f.y);
 }

#define ZEROExtended ( min ( iFrame , 0 ) ) 

// -- -- -- -- -- -- 

float terrain(in float2 p)
 {
    float h = 90.0 * textureGood(_Channel2 , sampler_Channel2 , p.yx * 0.0001 + 0.35 + float2 (0.02 , 0.05)).x - 70.0 + 5.0;
    h = lerp(h , -7.2 , 1.0 - smoothstep(16.0 , 60.0 , length(p)));
    h -= 7.0 * textureGood(_Channel2 , sampler_Channel2 , p * 0.002).x;
    float d = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p * 0.01 , 0.0).x;
    h -= 1.0 * d * d * d;
    return h;
 }

static const float ocean = -25.0;

float3 temple(in float3 p)
 {
    float3 op = p;
    float3 res = float3 (-1.0 , -1.0 , 0.5);

    p.y += 2.0;

    // bounding box 
   float bbox = usdBox(p , float3 (15.0 , 12.0 , 15.0) * 1.5);
   if (bbox > 5.0) return float3 (bbox + 1.0 , -1.0 , 0.5);
   float3 q = p; q.xz = opRepLim(q.xz , 4.0 , float2 (4.0 , 2.0));

   // columns 
  float2 id = floor((p.xz + 2.0) / 4.0);

  float d = length(q.xz) - 0.9 + 0.05 * p.y;
  d = max(d , p.y - 6.0);
  d = max(d , -p.y - 5.0);
  d -= 0.05 * pow(0.5 + 0.5 * sin(atan2(q.x , q.z) * 16.0) , 2.0);
  d -= 0.15 * pow(0.5 + 0.5 * sin(q.y * 3.0 + 0.6) , 0.12) - 0.15;
  res.z = hash1(id + 11.0 * floor(0.25 + (q.y * 3.0 + 0.6) / 6.2831));
  d *= 0.85;

   {
  float3 qq = float3 (q.x , abs(q.y - 0.3) - 5.5 , q.z);
  d = min(d , sdBox(qq , float3 (1.4 , 0.2 , 1.4) + sign(q.y - 0.3) * float3 (0.1 , 0.05 , 0.1)) - 0.1); // base 
   }

  d = max(d , -sdBox(p , float3 (14.0 , 10.0 , 6.0))); // clip in 

   // floor 
  float ra = 0.15 * hash1(id + float2 (1.0 , 3.0));
   q = p; q.xz = opRepLim(q.xz , 4.0 , float2 (4.0 , 3.0));
  float b = sdBox(q - float3 (0.0 , -6.0 + 0.1 - ra , 0.0) , float3 (2.0 , 0.5 , 2.0) - 0.15 - ra) - 0.15;
  b *= 0.5;
  if (b < d) { d = b; res.z = hash1(id); }

  p.xz -= 2.0;
  id = floor((p.xz + 2.0) / 4.0);
  ra = 0.15 * hash1(id + float2 (1.0 , 3.0) + 23.1);
  q = p; q.xz = opRepLim(q.xz , 4.0 , float2 (5.0 , 4.0) , float2 (5.0 , 3.0));
   b = sdBox(q - float3 (0.0 , -7.0 - ra , 0.0) , float3 (2.0 , 0.6 , 2.0) - 0.15 - ra) - 0.15;
  b *= 0.8;
  if (b < d) { d = b; res.z = hash1(id + 13.5); }
  p.xz += 2.0;

  id = floor((p.xz + 2.0) / 4.0);
  ra = 0.15 * hash1(id + float2 (1.0 , 3.0) + 37.7);
  q = p; q.xz = opRepLim(q.xz , 4.0 , float2 (5.0 , 4.0));
   b = sdBox(q - float3 (0.0 , -8.0 - ra - 1.0 , 0.0) , float3 (2.0 , 0.6 + 1.0 , 2.0) - 0.15 - ra) - 0.15;
  b *= 0.5;
  if (b < d) { d = b; res.z = hash1(id * 7.0 + 31.1); }


  // roof 
 q = float3 (mod(p.x + 2.0 , 4.0) - 2.0 , p.y , mod(p.z + 0.0 , 4.0) - 2.0);
 b = sdBox(q - float3 (0.0 , 7.0 , 0.0) , float3 (1.95 , 1.0 , 1.95) - 0.15) - 0.15;
 b = max(b , sdBox(p - float3 (0.0 , 7.0 , 0.0) , float3 (18.0 , 1.0 , 10.0)));
 if (b < d) { d = b; res.z = hash1(floor((p.xz + float2 (2.0 , 0.0)) / 4.0) + 31.1); }

 q = float3 (mod(p.x + 0.5 , 1.0) - 0.5 , p.y , mod(p.z + 0.5 , 1.0) - 0.5);
 b = sdBox(q - float3 (0.0 , 8.0 , 0.0) , float3 (0.45 , 0.5 , 0.45) - 0.02) - 0.02;
 b = max(b , sdBox(p - float3 (0.0 , 8.0 , 0.0) , float3 (19.0 , 0.2 , 11.0)));
 // q = p + float3 ( 0.0 , 0.0 , - 0.5 ) ; q.xz = opRepLim ( q.xz , 1.0 , float2 ( 19.0 , 10.0 ) ) ; 
// b = sdBox ( q - float3 ( 0.0 , 8.0 , 0.0 ) , float3 ( 0.45 , 0.2 , 0.45 ) - 0.02 ) - 0.02 ; 
if (b < d) { d = b; res.z = hash1(floor((p.xz + 0.5) / 1.0) + 7.8); }



b = sdRhombus(p.yz - float2 (8.2 , 0.0) , float2 (3.0 , 11.0) , 0.05);
q = float3 (mod(p.x + 1.0 , 2.0) - 1.0 , p.y , mod(p.z + 1.0 , 2.0) - 1.0);
b = max(b , -sdBox(float3 (abs(p.x) - 20.0 , p.y , q.z) - float3 (0.0 , 8.0 , 0.0) , float3 (2.0 , 5.0 , 0.1)) - 0.02);

b = max(b , -p.y + 8.2);
b = max(b , usdBox(p - float3 (0.0 , 8.0 , 0.0) , float3 (19.0 , 12.0 , 11.0)));
float c = sdRhombus(p.yz - float2 (8.3 , 0.0) , float2 (2.25 , 8.5) , 0.05);
c = max(c , sdBox(abs(p.x) - 19.0 , 2.0));
b = max(b , -c);


d = min(d , b);

d = max(d , -sdBox(p - float3 (0.0 , 9.5 , 0.0) , float3 (15.0 , 4.0 , 9.0)));


d -= 0.02 * smoothstep(0.5 , 1.0 , fbm4(p.zxy));
d -= 0.01 * smoothstep(0.4 , 0.8 , fbm4(op * 3.0));
d += 0.005;

res = float3 (d , 1.0 , res.z);

return res;
}

float3 map(in float3 p)
 {
    float3 res = temple(p);

     {
        float h = terrain(p.xz);
        float m = p.y - h;
        m *= 0.35;
        if (m < res.x) res = float3 (m , 2.0 , 0.0);
     }


     {
        float w = p.y + 25.0;
        if (w < res.x) res = float3 (w , 3.0 , 0.0);
     }

    return res;
 }

// http: // iquilezles.org / www / articles / normalsSDF / normalsSDF.htm 
float3 calcNormal(in float3 p , in float t)
 {
#if 0 
    float e = 0.001 * t;

    float2 h = float2 (1.0 , -1.0) * 0.5773;
    return normalize(h.xyy * map(p + h.xyy * e).x +
                           h.yyx * map(p + h.yyx * e).x +
                           h.yxy * map(p + h.yxy * e).x +
                           h.xxx * map(p + h.xxx * e).x);
#else 
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map ( ) 4 times 
   float3 n = float3 (0.0 , 0.0 , 0.0);
   for (int i = ZEROExtended; i < 4; i++)
    {
       float3 e = 0.5773 * (2.0 * float3 ((((i + 3) >> 1) & 1) , ((i >> 1) & 1) , (i & 1)) - 1.0);
       n += e * map(p + e * 0.001 * t).x;
    }
   return normalize(n);
#endif 
 }

float3 intersect(in float3 ro , in float3 rd)
 {
    float2 ma = float2 (0.0 , 0.0);

    float3 res = float3 (-1.0, -1.0, -1.0);

    float tmax = 1000.0;

    float tp = (ocean - ro.y) / rd.y;
    if (tp > 0.0)
     {
        tmax = tp;
        res = float3 (tp , 3.0 , 0.0);
     }

    float t = 10.0;
    for (int i = 0; i < 256; i++)
     {
        float3 pos = ro + t * rd;
        float3 h = map(pos);
        if (h.x < (0.0001 * t) || t > tmax) break;
        t += h.x;

        ma = h.yz;
     }

    if (t < tmax)
     {
         res = float3 (t , ma);
     }

    return res;
 }

float4 textureBox(in Texture2D tex, SamplerState samp, in float3 pos , in float3 nor)
 {
    float4 cx = SAMPLE_TEXTURE2D(tex , samp, pos.yz);
    float4 cy = SAMPLE_TEXTURE2D(tex , samp, pos.xz);
    float4 cz = SAMPLE_TEXTURE2D(tex , samp, pos.xy);
    float3 m = nor * nor;
    return (cx * m.x + cy * m.y + cz * m.z) / (m.x + m.y + m.z);
 }

float calcShadow(in float3 ro , in float3 rd , float k)
 {
    float res = 1.0;

    float t = 0.01;
    for (int i = 0; i < 128; i++)
     {
        float3 pos = ro + t * rd;
        float h = map(pos).x;
        res = min(res , k * max(h , 0.0) / t);
        if (res < 0.0001) break;
        t += clamp(h , 0.01 , 0.5);
     }

    return res;
 }

float calcOcclusion(in float3 pos , in float3 nor , float ra)
 {
    float occ = 0.0;
    for (int i = ZEROExtended; i < 32; i++)
     {
        float h = 0.01 + 4.0 * pow(float(i) / 31.0 , 2.0);
        float2 an = hash2(ra + float(i) * 13.1) * float2 (3.14159 , 6.2831);
        float3 dir = float3 (sin(an.x) * sin(an.y) , sin(an.x) * cos(an.y) , cos(an.x));
        dir *= sign(dot(dir , nor));
        occ += clamp(5.0 * map(pos + h * dir).x / h , -1.0 , 1.0);
     }
    return clamp(occ / 32.0 , 0.0 , 1.0);
 }


static float3 sunLig = normalize(float3 (0.7 , 0.1 , 0.4));

float3 skyColor(in float3 ro , in float3 rd)
 {
    float3 col = float3 (0.3 , 0.4 , 0.5) * 0.3 - 0.3 * rd.y;

    float t = (1000.0 - ro.y) / rd.y;
    if (t > 0.0)
     {
        float2 uv = (ro + t * rd).xz;
        float cl = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , .000003 * uv.yx).x;
        cl = smoothstep(0.3 , 0.7 , cl);
        col = lerp(col , float3 (0.3 , 0.2 , 0.1) , 0.1 * cl);
     }

    col = lerp(col , float3 (0.2 , 0.25 , 0.30) * 0.5 , exp(-30.0 * rd.y));

    float sd = pow(clamp(0.25 + 0.75 * dot(sunLig , rd) , 0.0 , 1.0) , 4.0);
    col = lerp(col , float3 (1.2 , 0.30 , 0.05) / 1.2 , sd * exp(-abs((60.0 - 50.0 * sd) * rd.y)));

    return col;
 }

float3 doBumpMap(in float3 pos , in float3 nor)
 {
    float e = 0.002;
    float b = 0.015;

     float ref = fbm6(4.0 * pos);
    float3 gra = -b * float3 (fbm6(4.0 * float3 (pos.x + e , pos.y , pos.z)) - ref ,
                        fbm6(4.0 * float3 (pos.x , pos.y + e , pos.z)) - ref ,
                        fbm6(4.0 * float3 (pos.x , pos.y , pos.z + e)) - ref) / e;

     float3 tgrad = gra - nor * dot(nor , gra);
    return normalize(nor - tgrad);
 }

float3 doBumpMapGrass(in float2 pos , in float3 nor , out float hei)
 {
    float e = 0.002;
    float b = 0.03;

     float ref = fbm6(4.0 * pos);
    hei = ref;

    float3 gra = -b * float3 (fbm6(4.0 * float2 (pos.x + e , pos.y)) - ref ,
                        e ,
                        fbm6(4.0 * float2 (pos.x , pos.y + e)) - ref) / e;

     float3 tgrad = gra - nor * dot(nor , gra);
    return normalize(nor - tgrad);
 }

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float isThumbnail = step(_ScreenParams.x , 499.0);

     float2 o = (1.0 - isThumbnail) * (hash2(float(iFrame)) - 0.5);

      float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + o)) / _ScreenParams.y;

     uint2 px = uint2(fragCoord);
     float ran = hash(px.x + 1920U * px.y + (1920U * 1080U) * uint (iFrame * 0));

     #ifdef STATICCAM 
     float an = -0.96;
     #else 
     float an = -0.96 + sin(_Time.y * 0.25) * 0.1;
     #endif 
     float ra = 70.0;
     float fl = 3.0;
     float3 ta = float3 (0.0 , -3.0 , -23.0);
     float3 ro = ta + float3 (ra * sin(an) , 10.0 , ra * cos(an));
     float3x3 ca = setCamera(ro , ta , 0.0);
     float3 rd = mul(ca , normalize(float3 (p.xy , fl)));


     float3 col = float3 (0.0 , 0.0 , 0.0);

     col = skyColor(ro , rd);

     float resT = 10000.0;
     float3 res = intersect(ro , rd);
     if (res.y > 0.0)
      {
         float t = res.x;
         resT = t;
         float3 pos = ro + t * rd;
         float3 nor = calcNormal(pos , t);

         float fre = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 5.0);
           float foc = 1.0;

         float3 mate = float3 (0.2 , 0.2 , 0.2);
         float2 mspe = float2 (0.0 , 0.0);
         float mbou = 0.0;
         float mter = 0.0;
         if (res.y < 1.5)
          {
             float3 te = textureBox(_Channel0 , sampler_Channel0 , pos * 0.05 , nor).xyz;
             // mate = float3 ( 0.12 , 0.08 , 0.05 ) + 0.15 * te ; 
            mate = float3 (0.14 , 0.10 , 0.07) + 0.1 * te;
            mate *= 0.8 + 0.4 * res.z;
            mate *= 1.15;
            mspe = float2 (1.0 , 8.0);
            mbou = 1.0;

            nor = doBumpMap(pos , nor);

            foc = 0.7 + 0.3 * smoothstep(0.4 , 0.7 , fbm4(3.0 * pos));

            float ho = 1.0;
            if (pos.y > -7.5) ho *= smoothstep(0.0 , 5.0 , (pos.y + 7.5));
            ho = lerp(0.1 + ho * 0.3 , 1.0 , clamp(0.6 + 0.4 * dot(normalize(nor.xz * float2 (0.5 , 1.0)) , normalize(pos.xz * float2 (0.5 , 1.0))) + 1.0 * nor.y * nor.y , 0.0 , 1.0));
            foc *= ho;
            foc *= 0.4 + 0.6 * smoothstep(2.0 , 15.0 , length(pos * float3 (0.5 , 0.25 , 1.0)));
            float rdis = clamp(-0.15 * max(sdRhombus(pos.yz - float2 (8.3 , 0.0) + float2 (2.0 , 0.0) , float2 (2.25 , 8.5) , 0.05) , -(pos.y - 8.3 + 2.0)) , 0.0 , 1.0);
            if (rdis > 0.0001) foc = 0.1 + sqrt(rdis);
               if (pos.y < 5.8) foc *= 0.6 + 0.4 * smoothstep(0.0 , 1.5 , -(pos.y - 5.8));
            if (pos.y < 3.4) foc *= 0.6 + 0.4 * smoothstep(0.0 , 2.5 , -(pos.y - 3.4));

            foc *= 0.8;
         }
        else if (res.y < 2.5)
         {
            mate = float3 (0.95 , 0.9 , 0.85) * 0.4 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , pos.xz * 0.015).xyz;
            mate *= 0.25 + 0.75 * smoothstep(-25.0 , -24.0 , pos.y);
            mate *= 0.32;
               float h;
            float3 mor = doBumpMapGrass(pos.xz , nor , h);
            mspe = float2 (2.5 , 4.0);
            float is_grass = smoothstep(0.9 , 0.95 , mor.y);

            mate = lerp(mate , float3 (0.15 , 0.1 , 0.0) * 0.8 * 0.7 + h * h * h * float3 (0.12 , 0.1 , 0.05) * 0.15 , is_grass);
            mspe = lerp(mspe , float2 (0.5 , 4.0) , is_grass);
            nor = mor;
            mter = 1.0;
         }
          else
         {
            mate = float3 (0.1 , 0.21 , 0.25) * 0.45;
            mate += 2.0 * float3 (0.01 , 0.03 , 0.03) * (1.0 - smoothstep(0.0 , 10.0 , pos.y - terrain(pos.xz)));
            mate *= 0.4;
            float foam = (1.0 - smoothstep(0.0 , 1.0 , pos.y - terrain(pos.xz)));
            foam *= smoothstep(0.35 , 0.5 , SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , pos.xz * 0.07).x);
            mate += float3 (0.08 , 0.08 , 0.08) * foam;
            mspe = float2 (0.5 , 8.0);

            float2 e = float2 (0.01 , 0.0);
            float ho = fbm4((pos.xz) * float2 (2.0 , 0.5));
            float hx = fbm4((pos.xz + e.xy) * float2 (2.0 , 0.5));
            float hy = fbm4((pos.xz + e.yx) * float2 (2.0 , 0.5));
            float sm = (1.0 - smoothstep(0.0 , 4.0 , pos.y - terrain(pos.xz)));
            sm *= 0.02 + 0.03 * foam;
            ho *= sm;
            hx *= sm;
            hy *= sm;

            nor = normalize(float3 (ho - hx , e.x , ho - hy));
         }

        float occ = 0.33 + 0.5 * nor.y;
        occ = calcOcclusion(pos , nor , ran) * foc;

        float lf = 1.0 - smoothstep(30.0 , 80.0 , length(pos.z));
        float3 lig = normalize(float3 (sunLig.x , sunLig.y + 0.245 * lf , sunLig.z));
        float3 ligbak = normalize(float3 (-lig.x , 0.0 , -lig.z));
        float dif = clamp(dot(nor , lig) , 0.0 , 1.0);
        float sha = calcShadow(pos + nor * 0.001 , lig , 32.0);
              dif *= sha;
        float amb = (0.8 + 0.2 * nor.y);
              amb = lerp(amb , amb * (0.5 + 0.5 * smoothstep(-8.0 , -1.0 , pos.y)) , mbou);

        float3 qos = pos / 1.5 - float3 (0.0 , 1.0 , 0.0);

        float bak = clamp(0.4 + 0.6 * dot(nor , ligbak) , 0.0 , 1.0);
              bak *= 0.6 + 0.4 * smoothstep(-8.0 , -1.0 , qos.y);


        float bou = 0.3 * clamp(0.7 - 0.3 * nor.y , 0.0 , 1.0);
              bou *= smoothstep(8.0 , 0.0 , qos.y + 6.0) * smoothstep(-6.7 , -6.4 , qos.y);
              bou *= (0.7 * smoothstep(3.0 , 1.0 , length((qos.xz - float2 (1.0 , 6.0)) * float2 (0.2 , 1.0))) +
                      smoothstep(5.0 , 1.0 , length((qos.xz - float2 (5.0 , -3.0)) * float2 (0.4 , 1.0))));


        bou += 0.1 * smoothstep(5.0 , 1.0 , length((qos - float3 (-5.0 , 0.0 , -5.0)) * float3 (0.7 , 0.8 , 1.5)));

        float3 hal = normalize(lig - rd);
        float spe = pow(clamp(dot(nor , hal) , 0.0 , 1.0) , mspe.y) * (0.1 + 0.9 * fre) * sha * (0.5 + 0.5 * occ);

        col = float3 (0.0 , 0.0 , 0.0);
        col += amb * 1.0 * float3 (0.15 , 0.25 , 0.35) * occ * (1.0 + mter);
        col += dif * 5.0 * float3 (0.90 , 0.55 , 0.35);
        col += bak * 1.7 * float3 (0.10 , 0.11 , 0.12) * occ * mbou;
        col += bou * 3.0 * float3 (1.00 , 0.50 , 0.15) * occ * mbou;
        col += spe * 6.0 * mspe.x * occ;

        col *= mate;

        float3 fogcol = float3 (0.1 , 0.125 , 0.15);
        float sd = pow(clamp(0.25 + 0.75 * dot(lig , rd) , 0.0 , 1.0) , 4.0);
         fogcol = lerp(fogcol , float3 (1.0 , 0.25 , 0.042) , sd * exp(-abs((60.0 - 50.0 * sd) * abs(rd.y))));

        float fog = 1.0 - exp(-0.0013 * t);
        col *= 1.0 - 0.5 * fog;
        col = lerp(col , fogcol , fog);
     }

    col = max(col , 0.0);

    col += 0.15 * float3 (1.0 , 0.8 , 0.7) * pow(clamp(dot(rd , sunLig) , 0.0 , 1.0) , 6.0);

    col = 1.2 * col / (1.0 + col);

    col = sqrt(col);


    col = clamp(1.9 * col - 0.1 , 0.0 , 1.0);
    col = col * 0.1 + 0.9 * col * col * (3.0 - 2.0 * col);
    col = pow(col , float3 (0.76 , 0.98 , 1.0));


    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
     // reproject from previous frame and average 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    #ifdef STATICCAM 
       float3 ocol = pointSampleTex2D(_Channel3 , sampler_Channel3 , int2 (fragCoord - 0.5) ).xyz;
       if (iFrame == 0) ocol = col;
       col = lerp(ocol , col , 0.05);
       fragColor = float4 (col , 1.0);
   #else 
       float4x4 oldCam = float4x4 (pointSampleTex2D(_Channel3 , sampler_Channel3 , int2 (0 , 0) ) ,
                           pointSampleTex2D(_Channel3 , sampler_Channel3 , int2 (1 , 0) ) ,
                           pointSampleTex2D(_Channel3 , sampler_Channel3 , int2 (2 , 0) ) ,
                           0.0 , 0.0 , 0.0 , 1.0);

       // world space 
      float4 wpos = float4 (ro + rd * resT , 1.0);
      // camera space 
     float3 cpos = (mul(wpos , oldCam)).xyz; // note inverse multiply 
      // ndc space 
     float2 npos = fl * cpos.xy / cpos.z;
     // screen space 
    float2 spos = 0.5 + 0.5 * npos * float2 (_ScreenParams.y / _ScreenParams.x , 1.0);
    // undo dither 
   spos -= o / _ScreenParams.xy;
   // raster space 
  float2 rpos = spos * _ScreenParams.xy;

  if ((rpos.y < 1.0 && rpos.x < 3.0) || (isThumbnail > 0.5))
   {
   }
  else
   {
      float4 data = SAMPLE_TEXTURE2D_LOD(_Channel3 , sampler_Channel3 , spos , 0.0);
      float3 ocol = data.xyz;
      float dt = abs(data.w - resT) / resT;
      if (iFrame == 0) ocol = col;
      col = lerp(ocol , col , 0.1 + 0.5 * smoothstep(0.1 , 0.2 , dt));
   }

  if (fragCoord.y < 1.0 && fragCoord.x < 3.0)
   {
      if (abs(fragCoord.x - 2.5) < 0.5) fragColor = float4 (ca[2] , -dot(ca[2] , ro));
      if (abs(fragCoord.x - 1.5) < 0.5) fragColor = float4 (ca[1] , -dot(ca[1] , ro));
      if (abs(fragCoord.x - 0.5) < 0.5) fragColor = float4 (ca[0] , -dot(ca[0] , ro));
   }
  else
   {
      fragColor = float4 (col , resT);
   }
#endif 
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