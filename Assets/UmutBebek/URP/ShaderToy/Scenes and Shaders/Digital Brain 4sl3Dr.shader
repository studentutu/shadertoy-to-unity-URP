Shader "UmutBebek/URP/ShaderToy/Digital Brain 4sl3Dr"
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

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // by srtuss , 2013 

// rotate position around axis 
float2 rotate(float2 p , float a)
 {
     return float2 (p.x * cos(a) - p.y * sin(a) , p.x * sin(a) + p.y * cos(a));
 }

// 1D random numbers 
float rand(float n)
 {
    return frac(sin(n) * 43758.5453123);
 }

// 2D random numbers 
float2 rand2(in float2 p)
 {
     return frac(float2 (sin(p.x * 591.32 + p.y * 154.077) , cos(p.x * 391.32 + p.y * 49.077)));
 }

// 1D noise 
float noise1(float p)
 {
     float fl = floor(p);
     float fc = frac(p);
     return lerp(rand(fl) , rand(fl + 1.0) , fc);
 }

// voronoi distance noise , based on iq's articles 
float voronoi(in float2 x)
 {
     float2 p = floor(x);
     float2 f = frac(x);

     float2 res = float2 (8.0, 8.0);
     for (int j = -1; j <= 1; j++)
      {
          for (int i = -1; i <= 1; i++)
           {
               float2 b = float2 (i , j);
               float2 r = float2 (b)-f + rand2(p + b);

               // chebyshev distance , one of many ways to do this 
              float d = max(abs(r.x) , abs(r.y));

              if (d < res.x)
               {
                   res.y = res.x;
                   res.x = d;
               }
              else if (d < res.y)
               {
                   res.y = d;
               }
          }
     }
    return res.y - res.x;
}



half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float flicker = noise1(_Time.y * 2.0) * 0.8 + 0.4;

     float2 uv = fragCoord.xy / _ScreenParams.xy;
      uv = (uv - 0.5) * 2.0;
      float2 suv = uv;
      uv.x *= _ScreenParams.x / _ScreenParams.y;


      float v = 0.0;

      // that looks highly interesting: 
      // v = 1.0 - length ( uv ) * 1.3 ; 


      // a bit of camera movement 
     uv *= 0.6 + sin(_Time.y * 0.1) * 0.4;
     uv = rotate(uv , sin(_Time.y * 0.3) * 1.0);
     uv += _Time.y * 0.4;


     // add some noise octaves 
    float a = 0.6 , f = 1.0;

    for (int i = 0; i < 3; i++) // 4 octaves also look nice , its getting a bit slow though 
     {
         float v1 = voronoi(uv * f + 5.0);
         float v2 = 0.0;

         // make the moving electrons - effect for higher octaves 
        if (i > 0)
         {
            // of course everything based on voronoi 
           v2 = voronoi(uv * f * 0.5 + 50.0 + _Time.y);

           float va = 0.0 , vb = 0.0;
           va = 1.0 - smoothstep(0.0 , 0.1 , v1);
           vb = 1.0 - smoothstep(0.0 , 0.08 , v2);
           v += a * pow(va * (0.5 + vb) , 2.0);
       }

        // make sharp edges 
       v1 = 1.0 - smoothstep(0.0 , 0.3 , v1);

       // noise is used as intensity map 
      v2 = a * (noise1(v1 * 5.5 + 0.1));

      // octave 0's intensity changes a bit 
     if (i == 0)
          v += v2 * flicker;
     else
          v += v2;

     f *= 3.0;
     a *= 0.7;
 }

    // slight vignetting 
   v *= exp(-0.6 * length(suv)) * 1.2;

   // use SAMPLE_TEXTURE2D channel0 for color? why not. 
  float3 cexp = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv * 0.001).xyz * 3.0 + SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv * 0.01).xyz; // float3 ( 1.0 , 2.0 , 4.0 ) ; 
  cexp *= 1.4;

  // old blueish color set 
  // float3 cexp = float3 ( 6.0 , 4.0 , 2.0 ) ; 

 float3 col = float3 (pow(v , cexp.x) , pow(v , cexp.y) , pow(v , cexp.z)) * 2.0;

 fragColor = float4 (col, 1.0);
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