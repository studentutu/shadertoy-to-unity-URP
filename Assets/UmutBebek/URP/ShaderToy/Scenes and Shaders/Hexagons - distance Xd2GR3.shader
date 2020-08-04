Shader "UmutBebek/URP/ShaderToy/Hexagons - distance Xd2GR3"
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

           // Created by inigo quilez - iq / 2014 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

#define AA 2 

 // { 2d cell id , distance to border , distnace to center ) 
float4 hexagon(float2 p)
 {
     float2 q = float2 (p.x * 2.0 * 0.5773503 , p.y + p.x * 0.5773503);

     float2 pi = floor(q);
     float2 pf = frac(q);

     float v = mod(pi.x + pi.y , 3.0);

     float ca = step(1.0 , v);
     float cb = step(2.0 , v);
     float2 ma = step(pf.xy , pf.yx);

     // distance to borders 
     float e = dot(ma , 1.0 - pf.yx + ca * (pf.x + pf.y - 1.0) + cb * (pf.yx - 2.0 * pf.xy));

     // distance to center 
    p = float2 (q.x + floor(0.5 + p.y / 1.5) , 4.0 * p.y / 3.0) * 0.5 + 0.5;
    float f = length((frac(p) - 0.5) * float2 (1.0 , 0.85));

    return float4 (pi + ca - cb * ma , e , f);
}

float hash1(float2 p) { float n = dot(p , float2 (127.1 , 311.7)); return frac(sin(n) * 43758.5453); }

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float3 tot = float3 (0.0 , 0.0 , 0.0);

     #if AA > 1 
     for (int mm = 0; mm < AA; mm++)
     for (int nn = 0; nn < AA; nn++)
      {
         float2 off = float2 (mm , nn) / float(AA);
         float2 uv = (fragCoord + off) / _ScreenParams.xy;
         float2 pos = (-_ScreenParams.xy + 2.0 * (fragCoord + off)) / _ScreenParams.y;
     #else 
      {
         float2 uv = fragCoord / _ScreenParams.xy;
         float2 pos = (-_ScreenParams.xy + 2.0 * fragCoord) / _ScreenParams.y;
     #endif 

         // distort 
        pos *= 1.0 + 0.1 * length(pos);

        // gray 
       float4 h = hexagon(8.0 * pos + 0.5 * _Time.y);
       float n = noise(float3 (0.3 * h.xy + _Time.y * 0.1 , _Time.y));
       float3 col = 0.15 + 0.15 * hash1(h.xy + 1.2) * float3 (1.0 , 1.0 , 1.0);
       col *= smoothstep(0.10 , 0.11 , h.z);
       col *= smoothstep(0.10 , 0.11 , h.w);
       col *= 1.0 + 0.15 * sin(40.0 * h.z);
       col *= 0.75 + 0.5 * h.z * n;


       // redExtended 
      h = hexagon(6.0 * pos + 0.6 * _Time.y);
      n = noise(float3 (0.3 * h.xy + _Time.y * 0.1 , _Time.y));
      float3 colb = 0.9 + 0.8 * sin(hash1(h.xy) * 1.5 + 2.0 + float3 (0.0 , 1.0 , 1.0));
      colb *= smoothstep(0.10 , 0.11 , h.z);
      colb *= 1.0 + 0.15 * sin(40.0 * h.z);
      colb *= 0.75 + 0.5 * h.z * n;

      h = hexagon(6.0 * (pos + 0.1 * float2 (-1.3 , 1.0)) + 0.6 * _Time.y);
      col *= 1.0 - 0.8 * smoothstep(0.45 , 0.451 , noise(float3 (0.3 * h.xy + _Time.y * 0.1 , _Time.y)));

      col = lerp(col , colb , smoothstep(0.45 , 0.451 , n));

      col *= pow(16.0 * uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) , 0.1);

      tot += col;
    }
    #if AA > 1 
  tot /= float(AA * AA);
  #endif 

  fragColor = float4 (tot, 1.0);
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