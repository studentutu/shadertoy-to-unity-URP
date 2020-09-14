Shader "UmutBebek/URP/ShaderToy/Fish swimming ldj3Dm"
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

float hash1(float n) { return frac(sin(n) * 43758.5453123); }

float noise1(in float x)
 {
    float p = floor(x);
    float f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(hash1(p + 0.0) , hash1(p + 1.0) , f);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float2 sd2Segment(float3 a , float3 b , float3 p)
 {
     float3 pa = p - a;
     float3 ba = b - a;
     float t = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.0);
     float3 v = pa - ba * t;
     return float2 (dot(v , v) , t);
 }

float sdBox(float3 p , float3 b)
 {
  float3 d = abs(p) - b;
  return min(max(d.x , max(d.y , d.z)) , 0.0) + length(max(d , 0.0));
 }

float smin(float a , float b , float k)
 {
     float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
     return lerp(b , a , h) - k * h * (1.0 - h);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

float3 fishPos;
float fishTime;

float3 sdFish(float3 p)
 {
    float3 res = float3 (1000.0 , 0.0 , 0.0);

     p -= fishPos;

     if (dot(p , p) > 16.0) return float3 (5.0, 5.0, 5.0); 

     p *= float3 (1.2 , 0.8 , 1.2);
     float3 q = p;

    float3 a = float3 (0.0 , 0.0 , 0.0);


    a.x -= 0.25 * sin(8.0 * 0.2 * fishTime);
     float3 oa = a;

     float or = 0.0;
     float th = 0.0;
     float hm = 0.0;

     #define NUMI 7 
     #define NUMF 7.0 
     float3 p1 = a; float3 d1 = float3 (0.0 , 0.0 , 0.0);
     float3 p2 = a; float3 d2 = float3 (0.0 , 0.0 , 0.0);
     float3 mp = a;
     for (int i = 0; i < NUMI; i++)
      {
          float ih = float(i) / NUMF;

          float an = or + 1.0 * (0.2 + 0.8 * ih) * sin(3.0 * ih - 2.0 * fishTime);
          float ll = 0.26;
          if (i == (NUMI - 1)) ll = 0.4;
          float3 b = a + ll * float3 (sin(an) , 0.0 , cos(an)) * (16.0 / NUMF);

          float2 dis = sd2Segment(a , b , p);

          if (dis.x < res.x) { res = float3 (dis.x , ih + dis.y / NUMF , 0.0); mp = a + (b - a) * dis.y; }

          if (i == 1) { p1 = a; d1 = b - a; }

          a = b;
      }
     float h = res.y;
     float ra = 0.04 + h * (1.0 - h) * (1.0 - h) * 2.7;

     // tail 
    p.y /= 1.0 + 14.0 * (1.0 - smoothstep(0.0 , 0.13 , 1.0 - h));
   p.z += 0.08 * (1.0 - clamp(abs(p.y) / 0.075 , 0.0 , 1.0)) * (1.0 - smoothstep(0.0 , 0.1 , 1.0 - h));
    res.x = 0.75 * (distance(p , mp) - ra);

    // mouth 
   float d3 = 0.75 * (length((p - oa) * float3 (0.5 , 2.0 , 1.0)) - 0.12);
   res.x = max(-d3 , res.x);

   // upper central fin 
  float fh = smoothstep(0.15 , 0.2 , h) - smoothstep(0.25 , 0.8 , h);
  fh -= 0.2 * pow(0.5 + 0.5 * sin(210.0 * h) , 0.2) * fh;
  d3 = length(p.xz - mp.xz) - 0.01;
 d3 = max(d3 , p.y - (mp.y + ra + 0.2 * fh));
  d3 = max(d3 , -p.y - 0.0);
  res.x = min(res.x , d3);

  // fins 
 d1.xz = normalize(d1.xz);

 float flap = 0.7 + 0.3 * sin(2.0 * 8.0 * 0.2 * fishTime);
float2 dd = normalize(d1.xz + sign((p - p1).x) * flap * d1.zx * float2 (-1.0 , 1.0));
 float2x2 mm = float2x2 (dd.y , dd.x , -dd.x , dd.y);
 float3 sq = p - p1;
 sq.xz = mul(mm , sq.xz);
 sq.y += 0.2;
 sq.x += -0.15;
 float d = length((sq - float3 (0.5 , 0.0 , 0.0)) * float3 (1.0 , 2.0 , 1.0)) - 0.3;
 d = 0.5 * max(d , sdBox(sq , float3 (1.0 , 1.0 , 0.01)));
if (d < res.x) res.z = smoothstep(0.2 , 0.7 , sq.x);
 res.x = smin(d , res.x , 0.05);

 sq = p - p1;
 sq.xz = mul(mm , sq.xz);
 sq.y += 0.2;
 sq.x += 0.15;
 d = length((sq - float3 (-0.5 , 0.0 , 0.0)) * float3 (1.0 , 2.0 , 1.0)) - 0.3;
 d = 0.5 * max(d , sdBox(sq , float3 (1.0 , 1.0 , 0.01)));
if (d < res.x) res.z = smoothstep(0.2 , 0.7 , sq.x);
 res.x = smin(d , res.x , 0.05);

 return res;

}

float3 sdSeaBed(in float3 p)
 {
     float h = 1.0;
     float3 q = p;
     float th = smoothstep(0.1 , 0.4 , SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.002 * q.xz , 0.0).x);
    float rr = smoothstep(0.2 , 0.5 , SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , 2.0 * 0.02 * q.xz , 0.0).y);
     h = 0.9 + (1.0 - 0.6 * rr) * (1.5 - 1.0 * th) * 0.1 * (1.0 - SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.1 * q.xz , 0.0).x);
     h += th * 1.25;
    h -= 0.24 * rr;
     h *= 0.75;
    return float3 ((p.y + h) * 0.3 , p.x , 0.0);

 }

float4 map(in float3 p)
 {
    float4 d1 = float4 (sdSeaBed(p) , 0.0);
     float4 d2 = float4 (sdFish(p) , 1.0);
    return (d2.x < d1.x) ? d2 : d1;
 }

float4 intersect(in float3 ro , in float3 rd)
 {
     static const float maxd = 20.0;
     static const float precis = 0.001;
    float h = precis * 3.0;
    float t = 0.0;
    float m = 0.0;
     float l = 0.0;
     float r = 0.0;
    for (int i = 0; i < 80; i++)
     {
         float4 res = map(ro + rd * t);
        if (h < precis || t > maxd) break;
        h = res.x;
          l = res.y;
          r = res.z;
        m = res.w;
          t += h;
     }

    if (t > maxd) m = -1.0;
    return float4 (t , l , m , r);
 }

float3 calcNormal(in float3 pos , in float e)
 {
    float3 eps = float3 (e , 0.0 , 0.0);
     return normalize(float3 (
           map(pos + eps.xyy).x - map(pos - eps.xyy).x ,
           map(pos + eps.yxy).x - map(pos - eps.yxy).x ,
           map(pos + eps.yyx).x - map(pos - eps.yyx).x));
 }

float softshadow(in float3 ro , in float3 rd , float mint , float k)
 {
    float res = 1.0;
    float t = mint;
     float h = 1.0;
    for (int i = 0; i < 40; i++)
     {
        h = map(ro + rd * t).x;
        res = min(res , smoothstep(0.0 , 1.0 , k * h / t));
          t += clamp(h , 0.05 , 0.5);
          if (h < 0.0001) break;
     }
    return clamp(res , 0.0 , 1.0);
 }

float3 lig = normalize(float3 (0.9 , 0.35 , -0.2));

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;
     float2 m = float2 (0.5 , 0.5);
      if (iMouse.z > 0.0) m = iMouse.xy / _ScreenParams.xy;


      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
      // animate 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

      fishTime = _Time.y + 3.5 * noise1(0.2 * _Time.y);

      fishPos = float3 (0.0 , 0.0 , -0.7 * fishTime);

      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
      // camera 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

      float an = 1.5 + 0.1 * _Time.y - 12.0 * (m.x - 0.5);

      float3 ta = fishPos - float3 (0.0 , 0.0 , -2.0); // float3 ( 0.0 , 1.0 , 2.0 ) ; 
      float3 ro = ta + float3 (4.0 * sin(an) , 4.0 , 4.0 * cos(an));

      // shake 
      ro += 0.01 * sin(4.0 * _Time.y * float3 (1.1 , 1.2 , 1.3) + float3 (3.0 , 0.0 , 1.0));
      ta += 0.01 * sin(4.0 * _Time.y * float3 (1.7 , 1.5 , 1.6) + float3 (1.0 , 2.0 , 1.0));

      // camera matrix 
     float3 ww = normalize(ta - ro);
     float3 uu = normalize(cross(ww , float3 (0.0 , 1.0 , 0.0)));
     float3 vv = normalize(cross(uu , ww));

     // create view ray 
   p.x += 0.012 * sin(3.0 * sin(4.0 * p.y + 0.5 * _Time.y) + 4.0 * p.x + 0.5 * _Time.y);
    float3 rd = normalize(p.x * uu + p.y * vv + 2.5 * ww);

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
     // render 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

    float3 col = float3 (0.4 , 0.6 , 0.8);
    float3 bcol = col;

    float pt = (1.0 - ro.y) / rd.y;

    float3 oro = ro;
    if (pt > 0.0) ro = ro + rd * pt;

    // raymarch 
  float4 tmat = intersect(ro , rd);
  if (tmat.z > -0.5)
   {
        float eps = 0.01 + 0.03 * step(0.5 , tmat.z);
        // geometry 
       float3 pos = ro + tmat.x * rd;
       float3 nor = calcNormal(pos , eps);
         float3 ref = reflect(rd , nor);

         // materials 
          float4 mate = float4 (0.5 , 0.5 , 0.5 , 0.0);

          if (tmat.z < 0.5)
           {
               float3 te = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 0.1 * pos.xz).xyz;
               te = 0.05 + te;

               mate.xyz = 0.6 * te;
               mate.w = 5.0 * (0.5 + 0.5 * te.x);


               float th = smoothstep(0.1 , 0.4 , SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 0.002 * pos.xz).x);
               float3 dcol = lerp(float3 (0.1 , 0.1 , 0.0) , 0.4 * float3 (0.65 , 0.4 , 0.2) , 0.2 + 0.8 * th);

               mate.xyz = lerp(mate.xyz * 0.5 , dcol , th * smoothstep(0.0 , 1.0 , nor.y));

               float rr = smoothstep(0.2 , 0.4 , SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , 2.0 * 0.02 * pos.xz).y);
               mate.xyz *= lerp(float3 (1.0 , 1.0 , 1.0) , float3 (0.2 , 0.2 , 0.2) * 1.5 , rr);

               mate.xyz *= 1.5;
           }
          else
           {
               mate.w = 8.0;
               mate.xyz = 1.0 * float3 (0.24 , 0.17 , 0.22);

               float3 te = 0.8 + 2.2 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (2.0 * tmat.y , pos.y)).xyz;
               mate.xyz *= te;

               // belly / backfin 
              float iscola = smoothstep(0.0 , 0.2 , 1.0 - tmat.y);
              mate.xyz = lerp(mate.xyz , lerp(float3 (te.x * 0.5 + 1.5, te.x * 0.5 + 1.5, te.x * 0.5 + 1.5) ,
                                                   lerp(1.0 + 0.5 * sin(150.0 * pos.y - sign(pos.y) * tmat.y * 300.0) , 1.0 , smoothstep(0.0 , 0.1 , 1.0 - tmat.y)) * float3 (2.6 , 1.5 , 1.0) * 0.9 + 1.0 * float3 (2.0 , 1.0 , 0.5) * (1.0 - smoothstep(0.0 , 0.09 , 1.0 - tmat.y)) ,
                                                   1.0 - iscola) * 0.5 , smoothstep(-0.4 , 0.0 , -nor.y));

              // stripes 
             mate.xyz = lerp(mate.xyz , (te.x + 0.5) * 1.0 * float3 (0.5 , 0.5 , 0.5) , 0.75 * smoothstep(0.5 , 1.0 , sin(1.0 * te.x + tmat.y * 100.0 + 13.0 * nor.y)) * smoothstep(0.0 , 0.5 , nor.y));

             // escamas 
            float ll = clamp((tmat.y - 0.2) / (0.8 - 0.2) , 0.0 , 1.0);
            float ha = 1.0 - 4.0 * ll * (1.0 - ll);
            float pa = smoothstep(-1.0 + 2.0 * ha , 1.0 , sin(50.0 * pos.y)) * smoothstep(-1.0 , 0.0 , sin(560.0 * tmat.y));
            pa *= 1.0 - smoothstep(0.1 , 0.2 , nor.y);
            mate.xyz *= 0.5 + 0.5 * float3 (1.0 , 1.0 , 1.0) * (1.0 - pa);

            // eye 
           float r = length(float2 (5.0 * tmat.y , pos.y) - float2 (0.5 , 0.13));
           r /= 1.2;
           mate.xyz = lerp(mate.xyz , float3 (1.5, 1.5, 1.5) * clamp(1.0 - r * 4.0 , 0.0 , 1.0) , 0.5 * (1.0 - smoothstep(0.08 , 0.09 , r)));
           mate.xyz *= smoothstep(0.03 , 0.05 , r);
           mate.xyz += float3 (4.0, 4.0, 4.0) * (1.0 - smoothstep(0.0 , 0.1 , r)) * pow(SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , 4.0 * float2 (0.2 * fishPos.z + 4.0 * tmat.y , pos.y)).x , 2.0);
           r = length(float2 (5.0 * tmat.y , pos.y) - float2 (0.48 , 0.14));
           mate.xyz = lerp(mate.xyz , float3 (2.0, 2.0, 2.0) , (1.0 - smoothstep(0.0 , 0.02 , r)));

           // mouth 
          float3 oa = fishPos;
        oa.x -= 0.25 * sin(8.0 * 0.2 * fishTime);
          mate.xyz *= 0.1 + 0.9 * step(0.0 , length((pos - oa + float3 (0.0 , 0.0 , -0.02)) * float3 (1.5 , 2.0 , 1.0)) - 0.14);

          // top fin 
       float fh = smoothstep(0.15 , 0.2 , tmat.y) - smoothstep(0.25 , 0.8 , tmat.y);
       float ra = 0.04 + tmat.y * (1.0 - tmat.y) * (1.0 - tmat.y) * 2.7;
         float vv = clamp((pos.y - ra - 0.1) / 0.2 , 0.0 , 1.0);
         float3 fincol = lerp(1.0 + 0.5 * sin(520.0 * tmat.y) , 1.0 , vv) * lerp(float3 (0.8 , 0.2 , 0.2) , float3 (1.5 , 1.4 , 1.5) , vv);
      mate.xyz = lerp(mate.xyz , fincol , fh * smoothstep(0.0 , 0.05 , pos.y - ra - 0.1));

      // side fins 
     float isFin = tmat.w;
     fincol = 0.5 * float3 (3.0 , 2.0 , 2.0) * lerp(1.0 + 0.2 * sin(150.0 * pos.y) , 1.0 , 0.0);
  mate.xyz = lerp(mate.xyz , fincol , isFin);

     mate.xyz *= 0.17;
 }

          // lighting 
       float sky = clamp(nor.y , 0.0 , 1.0);
         float bou = clamp(-nor.y , 0.0 , 1.0);
         float dif = max(dot(nor , lig) , 0.0);
       float bac = max(0.3 + 0.7 * dot(nor , -float3 (lig.x , 0.0 , lig.z)) , 0.0);
         float sha = 0.0; if (dif > 0.001) sha = softshadow(pos + 0.01 * nor , lig , 0.0005 , 32.0);
       float fre = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 5.0);
       float spe = max(0.0 , pow(clamp(dot(lig , reflect(rd , nor)) , 0.0 , 1.0) , mate.w)) * mate.w;
         float sss = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 3.0);

         // lights 
        float3 lin = float3 (0.0 , 0.0 , 0.0);
        float cc = 0.55 * SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 1.8 * 0.02 * pos.xz + 0.007 * _Time.y * float2 (1.0 , 0.0)).x;
              cc += 0.25 * SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 1.8 * 0.04 * pos.xz + 0.011 * _Time.y * float2 (0.0 , 1.0)).x;
              cc += 0.10 * SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 1.8 * 0.08 * pos.xz + 0.014 * _Time.y * float2 (-1.0 , -1.0)).x;
        cc = 0.6 * (1.0 - smoothstep(0.0 , 0.025 , abs(cc - 0.4))) +
              0.4 * (1.0 - smoothstep(0.0 , 0.150 , abs(cc - 0.4)));
        dif *= 1.0 + 2.0 * cc;

        lin += 3.5 * dif * float3 (1.00 , 1.00 , 1.00) * sha;
        lin += 3.0 * sky * float3 (0.10 , 0.20 , 0.35);
        lin += 1.0 * bou * float3 (0.20 , 0.20 , 0.20);
        lin += 2.0 * bac * float3 (0.50 , 0.60 , 0.70);
      lin += 2.0 * sss * float3 (0.20 , 0.20 , 0.20) * (0.2 + 0.8 * dif * sha) * mate.w;
        lin += 2.0 * spe * float3 (1.0 , 1.0 , 1.0) * sha * (0.3 + 0.7 * fre);

        // surface - light interacion 
       col = mate.xyz * lin;

       // fog 
      tmat.x = max(0.0 , tmat.x - 1.3); col *= 0.65;
      float hh = 1.0 - exp(-0.2 * tmat.x);
      col = col * (1.0 - hh) * (1.0 - hh) + 1.25 * float3 (0.0 , 0.12 , 0.2) * hh;
  }

  // foam 
  float2 uv = (oro + rd * pt).xz;
  float sur = SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , 0.06 * uv).x;
  sur = smoothstep(0.5 , 1.0 , sur) * 0.5 + 0.5 * sur * sur * smoothstep(0.2 , 1.0 , SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 1.0 * uv).x);
  col = lerp(col , float3 (1.0 , 1.0 , 1.0) , 0.5 * sur);

  // sun specular 
 float sun = clamp(dot(lig , reflect(rd , float3 (0.0 , 1.0 , 0.0))) , 0.0 , 1.0);
 col += 0.2 * float3 (1.0 , 0.95 , 0.9) * pow(sun , 16.0);
 col += 0.5 * float3 (1.0 , 0.95 , 0.9) * pow(sun , 96.0);

 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
 // postprocessing 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

col = pow(clamp(col , 0.0 , 1.0) , float3 (0.45 , 0.45 , 0.45));

col = lerp(col , float3 (dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333))) , -0.5);

 col = 0.5 * col + 0.5 * col * col * (3.0 - 2.0 * col);

 col *= 0.2 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

 col *= smoothstep(0.0 , 1.0 , _Time.y);

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