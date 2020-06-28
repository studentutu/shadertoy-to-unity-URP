Shader "UmutBebek/URP/ShaderToy/Planet 4sf3Rn"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)
            /*_Iteration("Iteration", float) = 1
            _NeighbourPixels("Neighbour Pixels", float) = 1
            _Lod("Lod",float) = 0
            _AR("AR Mode",float) = 0*/

    }

        SubShader
        {
            // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
            // "UniversalRenderPipeline"
            Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
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

            float4 iMouse;

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

            // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

float3 doit(in float2 pix)
 {
    float2 p = -1.0 + 2.0 * pix;
    p.x *= _ScreenParams.x / _ScreenParams.y;

    float3 ro = float3 (0.0 , 0.0 , 2.5);
    float3 rd = normalize(float3 ((p).x , (p).y , -2.0));

    float3 col = float3 (0.1 , 0.1 , 0.1);

    // intersect sphere 
   float b = dot(ro , rd);
   float c = dot(ro , ro) - 1.0;
   float h = b * b - c;
   if (h > 0.0)
    {
       float t = -b - sqrt(h);
       float3 pos = ro + t * rd;
       float3 nor = pos;

       // SAMPLE_TEXTURE2D mapping 
      float2 uv;
      uv.x = atan2(nor.x , nor.z) / 6.2831 - 0.03 * _Time.y - iMouse.x / _ScreenParams.x;
      uv.y = acos(nor.y) / 3.1416;
        uv.y *= 0.5;

      col = float3 (0.2 , 0.3 , 0.4);
      float3 te = 1.0 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , 0.5 * uv.yx).xyz;
           te += 0.3 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , 2.5 * uv.yx).xyz;
        col = lerp(col , (float3 (0.2 , 0.5 , 0.1) * 0.55 + 0.45 * te + 0.5 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 15.5 * uv.yx).xyz) * 0.4 , smoothstep(0.45 , 0.5 , te.x));

      float3 cl = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 2.0 * uv).xxx;
        col = lerp(col , float3 (0.9 , 0.9 , 0.9) , 0.75 * smoothstep(0.55 , 0.8 , cl.x));

        // lighting 
       float dif = max(nor.x * 2.0 + nor.z , 0.0);
       float fre = 1.0 - clamp(nor.z , 0.0 , 1.0);
       float spe = clamp(dot(nor , normalize(float3 (0.4 , 0.3 , 1.0))) , 0.0 , 1.0);
       col *= 0.03 + 0.75 * dif;
       col += pow(spe , 64.0) * (1.0 - te.x);
       col += lerp(float3 (0.20 , 0.10 , 0.05) , float3 (0.4 , 0.7 , 1.0) , dif) * 0.3 * fre;
       col += lerp(float3 (0.02 , 0.10 , 0.20) , float3 (0.7 , 0.9 , 1.0) , dif) * 2.5 * fre * fre * fre;
    }
    else
     {
         c = dot(ro , ro) - 10.0;
         h = b * b - c;
       float t = -b - sqrt(h);
       float3 pos = ro + t * rd;
       float3 nor = pos;

       float2 uv;
       uv.x = 16.0 * atan2(nor.x , nor.z) / 6.2831 - 0.05 * _Time.y - iMouse.x / _ScreenParams.x;
       uv.y = 2.0 * acos(nor.y) / 3.1416;
       col = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , uv , 1.0).zyx;
         col = col * col * col;
       col *= 0.15;
       float3 sta = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.5 * uv , 4.0).yzx;
         col += pow(sta , float3 (8.0 , 8.0 , 8.0)) * 1.3;

     }

   col = 0.5 * (col + sqrt(col));
   return col;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// render this with four sampels per pixel 
float3 col0 = doit((fragCoord.xy + float2 (0.0 , 0.0)) / _ScreenParams.xy);
float3 col1 = doit((fragCoord.xy + float2 (0.5 , 0.0)) / _ScreenParams.xy);
float3 col2 = doit((fragCoord.xy + float2 (0.0 , 0.5)) / _ScreenParams.xy);
float3 col3 = doit((fragCoord.xy + float2 (0.5 , 0.5)) / _ScreenParams.xy);
float3 col = 0.25 * (col0 + col1 + col2 + col3);

fragColor = float4 ((col).x , (col).y , (col).z , 1.0);
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