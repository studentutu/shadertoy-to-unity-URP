Shader "UmutBebek/URP/ShaderToy/Grid of Cylinders 4dSGW1"
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

           // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 


// Try 4 , 15 , 30 samples if yo have a powerful machine 

#if HW_PERFORMANCE == 0 
#define VIS_SAMPLES 1 
#else 
#define VIS_SAMPLES 4 
#endif 


float hash1(float n) { return frac(43758.5453123 * sin(n)); }
float hash1(float2 n) { return frac(43758.5453123 * sin(dot(n , float2 (1.0 , 113.0)))); }
float2 hash2(float n) { return frac(43758.5453123 * sin(float2 (n , n + 1.0))); }

float gAnimTime;
float map(float2 p)
 {
     float f = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p / _ScreenParams.xy , 0.0).x;

     f *= sqrt(SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (0.03 * p + 2.0 * gAnimTime) / 256.0 , 0.0).x);
     return 22.0 * f;
 }

float3 calcNormal(in float3 pos , in float ic)
 {
     return lerp(normalize(float3 (pos.x , 0.0 , pos.z)) , float3 (0.0 , 1.0 , 0.0) , ic);
 }

float4 castRay(in float3 ro , in float3 rd)
 {
     float2 pos = floor(ro.xz);
     float2 ri = 1.0 / rd.xz;
     float2 rs = sign(rd.xz);
     float2 ris = ri * rs;
     float2 dis = (pos - ro.xz + 0.5 + rs * 0.5) * ri;

     float4 res = float4 (-1.0 , 0.0 , 0.0 , 0.0);

     // traverse regular grid ( in 2D ) 
     float2 mm = float2 (0.0 , 0.0);
     for (int i = 0; i < 200; i++)
      {

          float ma = map(pos);

          // intersect capped cylinder 
           float3 ce = float3 (pos.x + 0.5 , 0.0 , pos.y + 0.5);
           float3 rc = ro - ce;
           float a = dot(rd.xz , rd.xz);
           float b = dot(rc.xz , rd.xz);
           float c = dot(rc.xz , rc.xz) - 0.249;
           float h = b * b - a * c;
           if (h >= 0.0)
            {
               // cylinder 
                 float s = (-b - sqrt(h)) / a;
                 if (s > 0.0 && (ro.y + s * rd.y) < ma)
                  {
                      res = float4 (s , 0.0 , pos);
                     break;
                  }
                 // cap 
                   s = (ma - ro.y) / rd.y;
                   if (s > 0.0 && (s * s * a + 2.0 * s * b + c) < 0.0)
                    {
                        res = float4 (s , 1.0 , pos);
                        break;
                    }
               }

           // step to next cell 
            mm = step(dis.xy , dis.yx);
            dis += mm * ris;
          pos += mm * rs;
        }


       return res;
   }

  float castShadowRay(in float3 ro , in float3 rd)
   {
       float2 pos = floor(ro.xz);
       float2 ri = 1.0 / rd.xz;
       float2 rs = sign(rd.xz);
       float2 ris = ri * rs;
       float2 dis = (pos - ro.xz + 0.5 + rs * 0.5) * ri;
       float t = -1.0;
       float res = 1.0;

       // first step we check noching 
       float2 mm = step(dis.xy , dis.yx);
       dis += mm * ris;
      pos += mm * rs;

      // traverse regular grid ( 2D ) 
      for (int i = 0; i < 16; i++)
       {
           float ma = map(pos);

           // test capped cylinder 
            float3 ce = float3 (pos.x + 0.5 , 0.0 , pos.y + 0.5);
            float3 rc = ro - ce;
            float a = dot(rd.xz , rd.xz);
            float b = dot(rc.xz , rd.xz);
            float c = dot(rc.xz , rc.xz) - 0.249;
            float h = b * b - a * c;
            if (h >= 0.0)
             {
                 float t = (-b - sqrt(h)) / a;
                 if ((ro.y + t * rd.y) < ma)
                  {
                      res = 0.0;
                     break;
                  }
             }
            mm = step(dis.xy , dis.yx);
            dis += mm * ris;
          pos += mm * rs;
        }

       return res;
   }

  float3 cameraPath(float t)
   {
      // procedural path 
     float2 p = 200.0 * sin(0.01 * t * float2 (1.2 , 1.0) + float2 (0.1 , 0.9));
           p += 100.0 * sin(0.02 * t * float2 (1.1 , 1.3) + float2 (1.0 , 4.5));
      float y = 15.0 + 4.0 * sin(0.05 * t);

      // collision 
     float h;
     h = map(p + float2 (-1.0 , 0.0));
     h += map(p + float2 (1.0 , 0.0));
     h += map(p + float2 (0.0 , 1.0));
     h += map(p + float2 (0.0 , -1.0));
     h /= 4.0;
     h += 5.0;
     y = max(y , h);

     return float3 (p.x , y , p.y);
 }

float4 texcyl(Texture2D sam, SamplerState samp, in float3 p , in float3 n)
 {
     float4 x = SAMPLE_TEXTURE2D(sam , samp, float2 (p.y , 0.5 + 0.5 * atan2(n.x , n.z) / 3.14));
     float4 y = SAMPLE_TEXTURE2D(sam , samp, p.xz);
     return lerp(x , y , abs(n.y));
 }

float3 desat(in float3 col , float a)
 {
    return lerp(col , float3 (dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333)), dot(col, float3 (0.333, 0.333, 0.333))) , a);
 }

float3 lig = normalize(float3 (-0.7 , 0.25 , 0.6));

float3 render(in float3 ro , in float3 rd)
 {
    // background color 
     float sun = clamp(dot(rd , lig) , 0.0 , 1.0);

     float3 bgcol = float3 (0.9 , 0.9 , 0.8) + 0.3 * pow(sun , 4.0) * float3 (1.0 , 1.0 , 0.0);

     // raytrace 
    float3 col = bgcol;
      float4 res = castRay(ro , rd);
    float2 vos = res.zw;
    float t = res.x;
    if (t > 0.0)
     {
        float3 pos = ro + rd * t;
           float id = hash1(vos);
           float3 nor = calcNormal(frac(pos) - 0.5 , res.y);
           float h = map(vos);

           // material color 
             float3 mate1 = 0.5 + 0.45 * sin(3.14 * id + 0.8 + float3 (0.0 , 0.5 , 1.0));
             float3 mate2 = 0.5 + 0.45 * sin(6.28 * id + float3 (0.0 , 0.5 , 1.0));
             float3 mate = lerp(mate1 , mate2 , smoothstep(9.0 , 11.0 , h));

             float3 uvw = pos - float3 (0.0 , h , 0.0);
             float3 tex = texcyl(_Channel3 , sampler_Channel3 , 0.2 * uvw + 13.1 * hash1(id) , nor).xyz;
             mate *= 0.2 + 4.0 * pow(desat(tex , 0.3) , float3 (2.0, 2.0, 2.0));
          mate *= 1.5 * sqrt(SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , pos.xz / _ScreenParams.xy).xyz);
          mate *= 0.02 + 0.98 * smoothstep(0.1 , 0.11 , hash1(id));

          // material cheap / wrong bump 
         float3 bn = -1.0 + 2.0 * texcyl(_Channel1 , sampler_Channel1 , 0.2 * uvw * float3 (1.0 , 0.2 , 1.0) + 13.1 * hash1(id) , nor).xyz;
         // nor = normalize ( nor + 0.45 * bn * ( 1.0 - 0.5 * nor.y ) ) ; 

            // procedural occlusion 
           float occ = nor.y * 0.75;
           occ += 0.5 * clamp(nor.x , 0.0 , 1.0) * smoothstep(-0.5 , 0.5 , pos.y - map(vos + float2 (1.0 , 0.0)));
           occ += 0.5 * clamp(-nor.x , 0.0 , 1.0) * smoothstep(-0.5 , 0.5 , pos.y - map(vos + float2 (-1.0 , 0.0)));
           occ += 0.5 * clamp(nor.z , 0.0 , 1.0) * smoothstep(-0.5 , 0.5 , pos.y - map(vos + float2 (0.0 , 1.0)));
           occ += 0.5 * clamp(-nor.z , 0.0 , 1.0) * smoothstep(-0.5 , 0.5 , pos.y - map(vos + float2 (0.0 , -1.0)));
           occ = 0.2 + 0.8 * occ;
           occ *= pow(clamp((0.1 + pos.y) / (0.1 + map(floor(pos.xz))) , 0.0 , 1.0) , 2.0);
           occ = occ * 0.5 + 0.5 * occ * occ;
           float rim = pow(clamp(1.0 + dot(rd , nor) , 0.0 , 1.0) , 5.0);

           // -- -- -- -- -- -- - 
           // lighitng 
           // -- -- -- -- -- -- - 
             float amb = 1.0;
             // -- -- -- -- -- -- - 
               float bac = clamp(dot(nor , normalize(float3 (-lig.x , 0.0 , -lig.z))) , 0.0 , 1.0) * clamp(1.0 - pos.y / 20.0 , 0.0 , 1.0); ;
               // -- -- -- -- -- -- - 
                 float sha = 0.0;
                 float dif = dot(nor , lig);
                 if (dif < 0.0) dif = 0.0; else sha = castShadowRay(pos , lig);
              float spe = pow(clamp(dot(lig , reflect(rd , nor)) , 0.0 , 1.0) , 3.0);
              // -- -- -- -- -- -- - 
                float3 lin = 3.00 * float3 (1.0 , 1.0 , 1.0) * 0.7 * sqrt(dif) * sha;
                     lin += 0.40 * float3 (0.4 , 1.0 , 1.7) * amb * occ;
                     lin += 0.60 * float3 (0.8 , 0.5 , 0.3) * bac * occ;

                col = mate * lin + tex.x * 1.5 * float3 (1.0 , 1.0 , 1.0) * (0.3 + 0.7 * rim) * spe * dif * sha;

                // tone mapping 
                  col *= 1.1 + 0.5 * dot(rd , lig);

                  // fog 
                 float ff = 1.0 - smoothstep(0.0 , 1.0 , pow(t / 160.0 , 1.8));
                    col = lerp(col , bgcol , 1.0 - ff);
                }
               col += 0.2 * pow(sun , 8.0) * float3 (1.0 , 0.7 , 0.2);

         return col;
      }

     half4 LitPassFragment(Varyings input) : SV_Target  {
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
     half4 fragColor = half4 (1 , 1 , 1 , 1);
     float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     // inputs 
     float2 q = fragCoord.xy / _ScreenParams.xy;

    float2 mo = iMouse.xy / _ScreenParams.xy;
    if (iMouse.w <= 0.00001) mo = float2 (0.0 , 0.0);

    gAnimTime = _Time.y;

    // montecarlo 
   float3 tot = float3 (0.0 , 0.0 , 0.0);
  #if VIS_SAMPLES < 2 
   int a = 0;
    {
      float2 p = -1.0 + 2.0 * (fragCoord.xy) / _ScreenParams.xy;
      p.x *= _ScreenParams.x / _ScreenParams.y;
      float time = 4.0 * _Time.y + 50.0 * mo.x;
  #else 
   for (int a = 0; a < VIS_SAMPLES; a++)
    {
        float4 rr = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , (fragCoord.xy + floor(256.0 * hash2(float(a)))) / _ScreenParams.xy);
      float2 p = -1.0 + 2.0 * (fragCoord.xy + rr.xz) / _ScreenParams.xy;
      p.x *= _ScreenParams.x / _ScreenParams.y;
        #if VIS_SAMPLES > 3 
      float time = 4.0 * (_Time.y + 1.0 * (0.4 / 24.0) * rr.w) + 50.0 * mo.x;
        #else 
      float time = 4.0 * (_Time.y) + 50.0 * mo.x;
        #endif 
  #endif 

      // camera 
   float3 ro = cameraPath(time);
   float3 ta = cameraPath(time + 5.0); ta.y = ro.y - 5.5;
   float cr = 0.2 * cos(0.1 * time * 0.5);

   // build ray 
  float3 ww = normalize(ta - ro);
  float3 uu = normalize(cross(float3 (sin(cr) , cos(cr) , 0.0) , ww));
  float3 vv = normalize(cross(ww , uu));
  float r2 = p.x * p.x * 0.32 + p.y * p.y;
  p *= (7.0 - sqrt(37.5 - 11.5 * r2)) / (r2 + 1.0);
  float3 rd = normalize(p.x * uu + p.y * vv + 2.5 * ww);

  // dof 
 #if VIS_SAMPLES > 2 
 float3 fp = ro + rd * 17.0;
 ro += (uu * (-1.0 + 2.0 * rr.y) + vv * (-1.0 + 2.0 * rr.w)) * 0.035;
 rd = normalize(fp - ro);
 #endif 


 float3 col = render(ro , rd);

   tot += col;
}
tot /= float(VIS_SAMPLES);


// gamma 
tot = pow(clamp(tot , 0.0 , 1.0) , float3 (0.45 , 0.45 , 0.45));

// vignetting 
tot *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

fragColor = float4 (tot , 1.0);
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