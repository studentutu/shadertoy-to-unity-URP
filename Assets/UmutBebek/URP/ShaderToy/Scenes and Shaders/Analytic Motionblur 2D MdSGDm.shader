Shader "UmutBebek/URP/ShaderToy/Analytic Motionblur 2D MdSGDm"
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

           // The MIT License 
// Copyright © 2014 Inigo Quilez 
// Permission is hereby granted , free of charge , to any person obtaining a copy of this software and associated documentation files ( the "Software" ) , to deal in the Software without restriction , including without limitation the rights to use , copy , modify , merge , publish , distribute , sublicense , and / or sell copies of the Software , and to permit persons to whom the Software is furnished to do so , subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS" , WITHOUT WARRANTY OF ANY KIND , EXPRESS OR IMPLIED , INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY , FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM , DAMAGES OR OTHER LIABILITY , WHETHER IN AN ACTION OF CONTRACT , TORT OR OTHERWISE , ARISING FROM , OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 


// Analytic motion blur , for 2D spheres ( disks ) . 
// 
// ( Linearly ) Moving Disk - pixel / ray overlap test. The resulting 
// equation is a quadratic that can be solved to compute time coverage 
// of the swept disk behind the pixel over the aperture of the camera 
// ( a full frame at 24 hz in this test ) . 



// draw a disk with motion blur 
float3 diskWithMotionBlur(in float3 pcol , // pixel color ( background ) 
                         in float2 puv , // pixel coordinates 
                         in float3 dpr , // disk ( pos , rad ) 
                         in float2 dv , // disk velocity 
                         in float3 dcol) // disk color 
 {
     float2 xc = puv - dpr.xy;
     float a = dot(dv , dv);
     float b = dot(dv , xc);
     float c = dot(xc , xc) - dpr.z * dpr.z;
     float h = b * b - a * c;
     if (h > 0.0)
      {
          h = sqrt(h);

          float ta = max(0.0 , (-b - h) / a);
          float tb = min(1.0 , (-b + h) / a);

          if (ta < tb) // we can comment this conditional , in fact 
              pcol = lerp(pcol , dcol , clamp(2.0 * (tb - ta) , 0.0 , 1.0));
      }

     return pcol;
 }


float3 hash3(float n) { return frac(sin(float3 (n , n + 1.0 , n + 2.0)) * 43758.5453123); }
float4 hash4(float n) { return frac(sin(float4 (n , n + 1.0 , n + 2.0 , n + 3.0)) * 43758.5453123); }

static const float speed = 8.0;
float2 getPosition(float time , float4 id) { return float2 (0.9 * sin((speed * (0.75 + 0.5 * id.z)) * time + 20.0 * id.x) , 0.75 * cos(speed * (0.75 + 0.5 * id.w) * time + 20.0 * id.y)); }
float2 getVelocity(float time , float4 id) { return float2 (speed * 0.9 * cos((speed * (0.75 + 0.5 * id.z)) * time + 20.0 * id.x) , -speed * 0.75 * sin(speed * (0.75 + 0.5 * id.w) * time + 20.0 * id.y)); }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 p = (2.0 * fragCoord - _ScreenParams.xy) / _ScreenParams.y;

      float3 col = float3 (0.03 , 0.03 , 0.03) + 0.015 * p.y;

      for (int i = 0; i < 16; i++)
       {
           float4 off = hash4(float(i) * 13.13);
         float3 sph = float3 (getPosition(_Time.y , off) , 0.02 + 0.1 * off.x);
         float2 dv = getVelocity(_Time.y , off) / 24.0;
           float3 sphcol = 0.55 + 0.45 * sin(3.0 * off.z + float3 (4.0 , 0.0 , 2.0));

         col = diskWithMotionBlur(col , p , sph , dv , sphcol);
       }

     //col = pow(col , float3 (0.4545, 0.4545, 0.4545));

     col += (1.0 / 255.0) * hash3(p.x + 13.0 * p.y);

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