Shader "UmutBebek/URP/ShaderToy/Canyon MdBGzG"
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

           // Created by inigo quilez - iq / 2014 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

//#define LOWDETAIL 
#define HIGH_QUALITY_NOISE 

float noise1(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
#ifndef HIGH_QUALITY_NOISE 
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (uv + 0.5) / 256.0 , 0.0).yx;
#else 
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z);
     float2 rg1 = SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (uv + float2 (0.5 , 0.5)) / 256.0 , 0.0).yx;
     float2 rg2 = SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (uv + float2 (1.5 , 0.5)) / 256.0 , 0.0).yx;
     float2 rg3 = SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (uv + float2 (0.5 , 1.5)) / 256.0 , 0.0).yx;
     float2 rg4 = SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (uv + float2 (1.5 , 1.5)) / 256.0 , 0.0).yx;
     float2 rg = lerp(lerp(rg1 , rg2 , f.x) , lerp(rg3 , rg4 , f.x) , f.y);
#endif 
     return lerp(rg.x , rg.y , f.z);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
static const float3x3 m = float3x3 (0.00 , 0.80 , 0.60 ,
                     -0.80 , 0.36 , -0.48 ,
                     -0.60 , -0.48 , 0.64);

float displacement(float3 p)
 {
    float f;
    f = 0.5000 * noise1(p); p = mul(m , p) * 2.02;
    f += 0.2500 * noise1(p); p = mul(m , p) * 2.03;
    f += 0.1250 * noise1(p); p = mul(m , p) * 2.01;
     #ifndef LOWDETAIL 
    f += 0.0625 * noise1(p);
     #endif 
    return f;
 }

float4 texcube(Texture2D sam, SamplerState samp, in float3 p , in float3 n)
 {
     float4 x = SAMPLE_TEXTURE2D(sam , samp, p.yz);
     float4 y = SAMPLE_TEXTURE2D(sam , samp, p.zx);
     float4 z = SAMPLE_TEXTURE2D(sam , samp, p.xy);
     return (x * abs(n.x) + y * abs(n.y) + z * abs(n.z)) / (abs(n.x) + abs(n.y) + abs(n.z));
 }


float4 textureGood(Texture2D sam, SamplerState samp, float2 uv , float lo)
 {
    uv = uv * 1024.0 - 0.5;
    float2 iuv = floor(uv);
    float2 f = frac(uv);
     float4 rg1 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (0.5 , 0.5)) / 1024.0 , lo);
     float4 rg2 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (1.5 , 0.5)) / 1024.0 , lo);
     float4 rg3 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (0.5 , 1.5)) / 1024.0 , lo);
     float4 rg4 = SAMPLE_TEXTURE2D_LOD(sam , samp, (iuv + float2 (1.5 , 1.5)) / 1024.0 , lo);
     return lerp(lerp(rg1 , rg2 , f.x) , lerp(rg3 , rg4 , f.x) , f.y);
 }
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float terrain(in float2 q)
 {
     float th = smoothstep(0.0 , 0.7 , SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.001 * q , 0.0).x);
    float rr = smoothstep(0.1 , 0.5 , SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , 2.0 * 0.03 * q , 0.0).y);
     float h = 1.9;
     #ifndef LOWDETAIL 
     h += -0.15 + (1.0 - 0.6 * rr) * (1.5 - 1.0 * th) * 0.3 * (1.0 - SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.04 * q * float2 (1.2 , 0.5) , 0.0).x);
     #endif 
     h += th * 7.0;
    h += 0.3 * rr;
    return -h;
 }

float terrain2(in float2 q)
 {
     float th = smoothstep(0.0 , 0.7 , textureGood(_Channel0 , sampler_Channel0 , 0.001 * q , 0.0).x);
    float rr = smoothstep(0.1 , 0.5 , textureGood(_Channel1 , sampler_Channel1 , 2.0 * 0.03 * q , 0.0).y);
     float h = 1.9;
     h += th * 7.0;
    return -h;
 }


float4 map(in float3 p)
 {
     float h = terrain(p.xz);
     float dis = displacement(0.25 * p * float3 (1.0 , 4.0 , 1.0));
     dis *= 3.0;
     return float4 ((dis + p.y - h) * 0.25 , p.x , h , 0.0);
 }

float4 intersect(in float3 ro , in float3 rd , in float tmax)
 {
    float t = 0.1;
    float3 res = float3 (0.0 , 0.0 , 0.0);
    for (int i = 0; i < 256; i++)
     {
         float4 tmp = map(ro + rd * t);
        res = tmp.ywz;
        t += tmp.x;
        if (tmp.x < (0.001 * t) || t > tmax) break;
     }

    return float4 (t , res);
 }

float3 calcNormal(in float3 pos , in float t)
 {
    float2 eps = float2 (0.005 * t , 0.0);
     return normalize(float3 (
           map(pos + eps.xyy).x - map(pos - eps.xyy).x ,
           map(pos + eps.yxy).x - map(pos - eps.yxy).x ,
           map(pos + eps.yyx).x - map(pos - eps.yyx).x));
 }

float softshadow(in float3 ro , in float3 rd , float mint , float k)
 {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 50; i++)
     {
        float h = map(ro + rd * t).x;
        res = min(res , k * h / t);
          t += clamp(h , 0.5 , 1.0);
          if (h < 0.001) break;
     }
    return clamp(res , 0.0 , 1.0);
 }

// Oren - Nayar 
float Diffuse(in float3 l , in float3 n , in float3 v , float r)
 {

    float r2 = r * r;
    float a = 1.0 - 0.5 * (r2 / (r2 + 0.57));
    float b = 0.45 * (r2 / (r2 + 0.09));

    float nl = dot(n , l);
    float nv = dot(n , v);

    float ga = dot(v - n * nv , n - n * nl);

     return max(0.0 , nl) * (a + b * max(0.0 , ga) * sqrt((1.0 - nv * nv) * (1.0 - nl * nl)) / max(nl , nv));
 }

float3 cpath(float t)
 {
     float3 pos = float3 (0.0 , 0.0 , 95.0 + t);

     float a = smoothstep(5.0 , 20.0 , t);
     pos.xz += a * 150.0 * cos(float2 (5.0 , 6.0) + 1.0 * 0.01 * t);
     pos.xz -= a * 150.0 * cos(float2 (5.0 , 6.0));
     pos.xz += a * 50.0 * cos(float2 (0.0 , 3.5) + 6.0 * 0.01 * t);
     pos.xz -= a * 50.0 * cos(float2 (0.0 , 3.5));

     return pos;
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
      float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;
     float2 m = float2 (0.0 , 0.0);
      if (iMouse.z > 0.0) m = iMouse.xy / _ScreenParams.xy;


      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
      // camera 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

      float an = 0.5 * (_Time.y - 5.0); // + 12.0 * ( m.x - 0.5 ) ; 
      float3 ro = cpath(an + 0.0);
      float3 ta = cpath(an + 10.0 * 1.0);
      ta = lerp(ro + float3 (0.0 , 0.0 , 1.0) , ta , smoothstep(5.0 , 25.0 , an));
     ro.y = terrain2(ro.xz) - 0.5;
      ta.y = ro.y - 0.1;
      ta.xy += step(0.01 , m.x) * (m.xy - 0.5) * 4.0 * float2 (-1.0 , 1.0);
      float rl = -0.1 * cos(0.05 * 6.2831 * an);
      // camera to world transform 
     float3x3 cam = setCamera(ro , ta , rl);

     // ray 
     float3 rd = normalize(mul(cam , float3 (p.xy , 2.0)));

     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
      // render 
     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

     float3 klig = normalize(float3 (-1.0 , 0.19 , 0.4));

     float sun = clamp(dot(klig , rd) , 0.0 , 1.0);

     float3 hor = lerp(1.2 * float3 (0.70 , 1.0 , 1.0) , float3 (1.5 , 0.5 , 0.05) , 0.25 + 0.75 * sun);

    float3 col = lerp(float3 (0.2 , 0.6 , .9) , hor , exp(-(4.0 + 2.0 * (1.0 - sun)) * max(0.0 , rd.y - 0.1)));
    col *= 0.5;
     col += 0.8 * float3 (1.0 , 0.8 , 0.7) * pow(sun , 512.0);
     col += 0.2 * float3 (1.0 , 0.4 , 0.2) * pow(sun , 32.0);
     col += 0.1 * float3 (1.0 , 0.4 , 0.2) * pow(sun , 4.0);

     float3 bcol = col;

     // clouds 
    float pt = (1000.0 - ro.y) / rd.y;
    if (pt > 0.0)
     {
       float3 spos = ro + pt * rd;
       float clo = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 0.00006 * spos.xz).x;
       float3 cloCol = lerp(float3 (0.4 , 0.5 , 0.6) , float3 (1.3 , 0.6 , 0.4) , pow(sun , 2.0)) * (0.5 + 0.5 * clo);
       col = lerp(col , cloCol , 0.5 * smoothstep(0.4 , 1.0 , clo));
     }


    // raymarch 
  float tmax = 120.0;

  // bounding plane 
 float bt = (0.0 - ro.y) / rd.y;
  if (bt > 0.0) tmax = min(tmax , bt);

 float4 tmat = intersect(ro , rd , tmax);
 if (tmat.x < tmax)
  {
     // geometry 
    float3 pos = ro + tmat.x * rd;
    float3 nor = calcNormal(pos , tmat.x);
      float3 ref = reflect(rd , nor);

      float occ = smoothstep(0.0 , 1.5 , pos.y + 11.5) * (1.0 - displacement(0.25 * pos * float3 (1.0 , 4.0 , 1.0)));

      // materials 
     float4 mate = float4 (0.5 , 0.5 , 0.5 , 0.0);

     // if ( tmat.z < 0.5 ) 
     {
         float3 uvw = 1.0 * pos;

         float3 bnor;
         float be = 1.0 / 1024.0;
         float bf = 0.4;
         bnor.x = texcube(_Channel0 , sampler_Channel0 , bf * uvw + float3 (be , 0.0 , 0.0) , nor).x - texcube(_Channel0 , sampler_Channel0 , bf * uvw - float3 (be , 0.0 , 0.0) , nor).x;
         bnor.y = texcube(_Channel0 , sampler_Channel0 , bf * uvw + float3 (0.0 , be , 0.0) , nor).x - texcube(_Channel0 , sampler_Channel0 , bf * uvw - float3 (0.0 , be , 0.0) , nor).x;
         bnor.z = texcube(_Channel0 , sampler_Channel0 , bf * uvw + float3 (0.0 , 0.0 , be) , nor).x - texcube(_Channel0 , sampler_Channel0 , bf * uvw - float3 (0.0 , 0.0 , be) , nor).x;
         bnor = normalize(bnor);
         float amo = 0.2 + 0.25 * (1.0 - smoothstep(0.6 , 0.7 , nor.y));
         nor = normalize(nor + amo * (bnor - nor * dot(bnor , nor)));

         float3 te = texcube(_Channel0 , sampler_Channel0 , 0.15 * uvw , nor).xyz;
         te = 0.05 + te;
         mate.xyz = 0.6 * te;
         mate.w = 1.5 * (0.5 + 0.5 * te.x);
         float th = smoothstep(0.1 , 0.4 , texcube(_Channel0 , sampler_Channel0 , 0.002 * uvw , nor).x);
         float3 dcol = lerp(float3 (0.2 , 0.3 , 0.0) , 0.4 * float3 (0.65 , 0.4 , 0.2) , 0.2 + 0.8 * th);
         mate.xyz = lerp(mate.xyz , 2.0 * dcol , th * smoothstep(0.0 , 1.0 , nor.y));
         mate.xyz *= 0.5;
         float rr = smoothstep(0.2 , 0.4 , texcube(_Channel1 , sampler_Channel1 , 2.0 * 0.02 * uvw , nor).y);
         mate.xyz *= lerp(float3 (1.0 , 1.0 , 1.0) , 1.5 * float3 (0.25 , 0.24 , 0.22) * 1.5 , rr);
         mate.xyz *= 1.5 * pow(texcube(_Channel3 , sampler_Channel3 , 8.0 * uvw , nor).xyz , float3 (0.5 , 0.5 , 0.5));
      mate = lerp(mate , float4 (0.7 , 0.7 , 0.7 , .0) , smoothstep(0.8 , 0.9 , nor.y + nor.x * 0.6 * te.x * te.x));


         mate.xyz *= 1.5;
     }

    float3 blig = normalize(float3 (-klig.x , 0.0 , -klig.z));
    float3 slig = float3 (0.0 , 1.0 , 0.0);

    // lighting 
 float sky = 0.0;
 sky += 0.2 * Diffuse(normalize(float3 (0.0 , 1.0 , 0.0)) , nor , -rd , 1.0);
 sky += 0.2 * Diffuse(normalize(float3 (3.0 , 1.0 , 0.0)) , nor , -rd , 1.0);
 sky += 0.2 * Diffuse(normalize(float3 (-3.0 , 1.0 , 0.0)) , nor , -rd , 1.0);
 sky += 0.2 * Diffuse(normalize(float3 (0.0 , 1.0 , 3.0)) , nor , -rd , 1.0);
 sky += 0.2 * Diffuse(normalize(float3 (0.0 , 1.0 , -3.0)) , nor , -rd , 1.0);
   float dif = Diffuse(klig , nor , -rd , 1.0);
   float bac = Diffuse(blig , nor , -rd , 1.0);


   float sha = 0.0; if (dif > 0.001) sha = softshadow(pos + 0.01 * nor , klig , 0.005 , 64.0);
 float spe = mate.w * pow(clamp(dot(reflect(rd , nor) , klig) , 0.0 , 1.0) , 2.0) * clamp(dot(nor , klig) , 0.0 , 1.0);

 // lights 
float3 lin = float3 (0.0 , 0.0 , 0.0);
lin += 7.0 * dif * float3 (1.20 , 0.50 , 0.25) * float3 (sha , sha * 0.5 + 0.5 * sha * sha , sha * sha);
lin += 1.0 * sky * float3 (0.10 , 0.50 , 0.70) * occ;
lin += 2.0 * bac * float3 (0.30 , 0.15 , 0.15) * occ;
lin += 0.5 * float3 (spe, spe, spe)*sha * occ;

// surface - light interacion 
col = mate.xyz * lin;

// fog 
bcol = 0.7 * lerp(float3 (0.2 , 0.5 , 1.0) * 0.82 , bcol , 0.15 + 0.8 * sun); col = lerp(col , bcol , 1.0 - exp(-0.02 * tmat.x));
}


col += 0.15 * float3 (1.0 , 0.9 , 0.6) * pow(sun , 6.0);

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// postprocessing 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
col *= 1.0 - 0.25 * pow(1.0 - clamp(dot(cam[2] , klig) , 0.0 , 1.0) , 3.0);

 col = pow(clamp(col , 0.0 , 1.0) , float3 (0.45 , 0.45 , 0.45));

 col *= float3 (1.1 , 1.0 , 1.0);
 col = col * col * (3.0 - 2.0 * col);
 col = pow(col , float3 (0.9 , 1.0 , 1.0));

 col = lerp(col , float3 (dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333))) , 0.4);
 col = col * 0.5 + 0.5 * col * col * (3.0 - 2.0 * col);

 col *= 0.3 + 0.7 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

col *= smoothstep(0.0 , 2.5 , _Time.y);

 fragColor = float4 (col , 1.0);
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