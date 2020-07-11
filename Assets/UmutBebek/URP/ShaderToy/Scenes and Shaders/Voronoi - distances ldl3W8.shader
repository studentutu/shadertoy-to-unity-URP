Shader "UmutBebek/URP/ShaderToy/Voronoi - distances ldl3W8"
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

           // The MIT License 
// Copyright © 2013 Inigo Quilez 
// Permission is hereby granted , free of charge , to any person obtaining a copy of this software and associated documentation files ( the "Software" ) , to deal in the Software without restriction , including without limitation the rights to use , copy , modify , merge , publish , distribute , sublicense , and / or sell copies of the Software , and to permit persons to whom the Software is furnished to do so , subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS" , WITHOUT WARRANTY OF ANY KIND , EXPRESS OR IMPLIED , INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY , FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM , DAMAGES OR OTHER LIABILITY , WHETHER IN AN ACTION OF CONTRACT , TORT OR OTHERWISE , ARISING FROM , OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

// I've not seen anybody out there computing correct cell interior distances for Voronoi 
// patterns yet. That's why they cannot shade the cell interior correctly , and why you've 
// never seen cell boundaries rendered correctly. 
// 
// However , here's how you do mathematically correct distances ( note the equidistant and non 
// degenerated grey isolines inside the cells ) and hence edges ( in yellow ) : 
// 
// http: // www.iquilezles.org / www / articles / voronoilines / voronoilines.htm 
// 
// More Voronoi shaders: 
// 
// Exact edges: https: // www.shadertoy.com / view / ldl3W8 
// Hierarchical: https: // www.shadertoy.com / view / Xll3zX 
// Smooth: https: // www.shadertoy.com / view / ldB3zc 
// Voronoise: https: // www.shadertoy.com / view / Xd23Dh 

#define ANIMATE 

float2 hash2(float2 p)
 {
    // SAMPLE_TEXTURE2D based white noise 
   return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + 0.5) / 256.0 , 0.0).xy;

   // procedural white noise 
    // return frac ( sin ( float2 ( dot ( p , float2 ( 127.1 , 311.7 ) ) , dot ( p , float2 ( 269.5 , 183.3 ) ) ) ) * 43758.5453 ) ; 
}

float3 voronoi(in float2 x)
 {
    float2 n = floor(x);
    float2 f = frac(x);

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    // first pass: regular voronoi 
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
    float2 mg , mr;

   float md = 8.0;
   for (int j = -1; j <= 1; j++)
   for (int i = -1; i <= 1; i++)
    {
       float2 g = float2 (float(i) , float(j));
         float2 o = hash2(n + g);
         #ifdef ANIMATE 
       o = 0.5 + 0.5 * sin(_Time.y + 6.2831 * o);
       #endif 
       float2 r = g + o - f;
       float d = dot(r , r);

       if (d < md)
        {
           md = d;
           mr = r;
           mg = g;
        }
    }

   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
   // second pass: distance to borders 
   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
  md = 8.0;
  for (int j = -2; j <= 2; j++)
  for (int i = -2; i <= 2; i++)
   {
      float2 g = mg + float2 (float(i) , float(j));
        float2 o = hash2(n + g);
        #ifdef ANIMATE 
      o = 0.5 + 0.5 * sin(_Time.y + 6.2831 * o);
      #endif 
      float2 r = g + o - f;

      if (dot(mr - r , mr - r) > 0.00001)
      md = min(md , dot(0.5 * (mr + r) , normalize(r - mr)));
   }

  return float3 (md , mr);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 p = fragCoord / _ScreenParams.xx;

     float3 c = voronoi(8.0 * p);

     // isolines 
   float3 col = c.x * (0.5 + 0.5 * sin(64.0 * c.x)) * float3 (1.0 , 1.0 , 1.0);
   // borders 
  col = lerp(float3 (1.0 , 0.6 , 0.0) , col , smoothstep(0.04 , 0.07 , c.x));
  // feature points 
  float dd = length(c.yz);
  col = lerp(float3 (1.0 , 0.6 , 0.1) , col , smoothstep(0.0 , 0.12 , dd));
  col += float3 (1.0 , 0.6 , 0.1) * (1.0 - smoothstep(0.0 , 0.04 , dd));

  fragColor = float4 (col , 1.0);
  fragColor.xyz -= 0.1;
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