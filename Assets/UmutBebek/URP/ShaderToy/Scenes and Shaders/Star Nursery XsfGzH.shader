Shader "UmutBebek/URP/ShaderToy/Star Nursery XsfGzH"
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

           // Built from the basics of'Clouds' Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// Edited by Dave Hoskins into "Star Nursery" 
// V.1.1 Some speed up in the ray - marching loop. 
// V.1.2 Added Shadertoy's fast 3D noise for better , smaller step size. 

static float3x3 m = float3x3 (0.30 , 0.90 , 0.60 ,
               -0.90 , 0.36 , -0.48 ,
               -0.60 , -0.48 , 0.34);
#define time ( _Time.y + 46.0 ) 

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float hash(float n)
 {
    return frac(sin(n) * 43758.5453123);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float noise(in float2 x)
 {
    float2 p = floor(x);
    float2 f = frac(x);

    f = f * f * (3.0 - 2.0 * f);

    float n = p.x + p.y * 57.0;

    float res = lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                    lerp(hash(n + 57.0) , hash(n + 58.0) , f.x) , f.y);

    return res;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float noise(in float3 x)
 {
    #if 0 

    // 3D SAMPLE_TEXTURE2D 
   return SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , x * .03).x * 1.05;

    #else 

    // Use 2D texture... 
   float3 p = floor(x);
   float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);

    float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
    float2 rg = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 ).yx;
    return lerp(rg.x , rg.y , f.z);

   #endif 
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float fbm(float3 p)
 {
    float f;
    f = 1.600 * noise(p); p = mul(m , p) * 2.02;
    f += 0.3500 * noise(p); p = mul(m , p) * 2.33;
    f += 0.2250 * noise(p); p = mul(m , p) * 2.03;
    f += 0.0825 * noise(p); p = mul(m , p) * 2.01;
    return f;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float4 map(in float3 p)
 {
     float d = 0.01 - p.y;

     float f = fbm(p * 1.0 - float3 (.4 , 0.3 , -0.3) * time);
     d += 4.0 * f;

     d = clamp(d , 0.0 , 1.0);

     float4 res = float4 (d, d, d, d);
     res.w = pow(res.y , .1);

     res.xyz = lerp(.7 * float3 (1.0 , 0.4 , 0.2) , float3 (0.2 , 0.0 , 0.2) , res.y * 1.);
     res.xyz = res.xyz + pow(abs(.95 - f) , 26.0) * 1.85;
     return res;
 }


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
static float3 sundir = float3 (1.0 , 0.4 , 0.0);
float4 raymarch(in float3 ro , in float3 rd)
 {
     float4 sum = float4 (0 , 0 , 0 , 0);

     float t = 0.0;
     float3 pos = float3 (0.0 , 0.0 , 0.0);
     for (int i = 0; i < 100; i++)
      {
          if (sum.a > 0.8 || pos.y > 9.0 || pos.y < -2.0) continue;
          pos = ro + t * rd;

          float4 col = map(pos);

          // Accumulate the alpha with the colour... 
         col.a *= 0.08;
         col.rgb *= col.a;

         sum = sum + col * (1.0 - sum.a);
        t += max(0.1 , 0.04 * t);
     }
    sum.xyz /= (0.003 + sum.w);

    return clamp(sum , 0.0 , 1.0);
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;
     float2 mo = (-1.0 + 2.0 + iMouse.xy) / _ScreenParams.xy;

     // Camera code... 
    float3 ro = 5.6 * normalize(float3 (cos(2.75 - 3.0 * mo.x) , .4 - 1.3 * (mo.y - 2.4) , sin(2.75 - 2.0 * mo.x)));
     float3 ta = float3 (.0 , 5.6 , 2.4);
    float3 ww = normalize(ta - ro);
    float3 uu = normalize(cross(float3 (0.0 , 1.0 , 0.0) , ww));
    float3 vv = normalize(cross(ww , uu));
    float3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww);

    // Ray march into the clouds adding up colour... 
  float4 res = raymarch(ro , rd);


   float sun = clamp(dot(sundir , rd) , 0.0 , 2.0);
   float3 col = lerp(float3 (.3 , 0.0 , 0.05) , float3 (0.2 , 0.2 , 0.3) , sqrt(max(rd.y , 0.001)));
   col += .4 * float3 (.4 , .2 , 0.67) * sun;
   col = clamp(col , 0.0 , 1.0);
   col += 0.43 * float3 (.4 , 0.4 , 0.2) * pow(sun , 21.0);

   // Do the stars... 
  float v = 1.0 / (2. * (1. + rd.z));
  float2 xy = float2 (rd.y * v , rd.x * v);
 rd.z += time * .002;
 float s = noise(rd.xz * 134.0);
  s += noise(rd.xz * 370.);
  s += noise(rd.xz * 870.);
  s = pow(s , 19.0) * 0.00000001 * max(rd.y , 0.0);
  if (s > 0.0)
   {
       float3 backStars = float3 ((1.0 - sin(xy.x * 20.0 + time * 13.0 * rd.x + xy.y * 30.0)) * .5 * s , s , s);
       col += backStars;
   }

  // Mix in the clouds... 
 col = lerp(col , res.xyz , res.w * 1.3);

 #define CONTRAST 1.1 
 #define SATURATION 1.15 
 #define BRIGHTNESS 1.03 
 col = lerp(float3 (.5 , .5 , .5) , lerp(float3 (dot(float3 (.2125, .7154, .0721), col * BRIGHTNESS), dot(float3 (.2125, .7154, .0721), col * BRIGHTNESS), dot(float3 (.2125, .7154, .0721), col * BRIGHTNESS)) , col * BRIGHTNESS , SATURATION) , CONTRAST);

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