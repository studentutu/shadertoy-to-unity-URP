Shader "UmutBebek/URP/ShaderToy/Hell MdfGRX"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
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
            float4 _Channel3_ST;
            TEXTURE2D(_Channel3);       SAMPLER(sampler_Channel3);

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

           // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }

float4 map(float3 p)
 {
     float den = 0.2 - p.y;

     // invert space 
     p = -7.0 * p / dot(p , p);

     // twist space 
     float co = cos(den - 0.25 * _Time.y);
     float si = sin(den - 0.25 * _Time.y);
     p.xz = mul(float2x2 (co , -si , si , co) , p.xz);

     // smoke 
     float f;
     float3 q = p - float3 (0.0 , 1.0 , 0.0) * _Time.y; ;
    f = 0.50000 * noise(q); q = q * 2.02 - float3 (0.0 , 1.0 , 0.0) * _Time.y;
    f += 0.25000 * noise(q); q = q * 2.03 - float3 (0.0 , 1.0 , 0.0) * _Time.y;
    f += 0.12500 * noise(q); q = q * 2.01 - float3 (0.0 , 1.0 , 0.0) * _Time.y;
    f += 0.06250 * noise(q); q = q * 2.02 - float3 (0.0 , 1.0 , 0.0) * _Time.y;
    f += 0.03125 * noise(q);

     den = clamp(den + 4.0 * f , 0.0 , 1.0);

     float3 col = lerp(float3 (1.0 , 0.9 , 0.8) , float3 (0.4 , 0.15 , 0.1) , den) + 0.05 * sin(p);

     return float4 (col , den);
 }

float3 raymarch(in float3 ro , in float3 rd , in float2 pixel)
 {
     float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);

     float t = 0.0;

     // dithering 
     t += 0.05 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , pixel.xy / _Channel0_ST.x , 0.0).x;

     for (int i = 0; i < 100; i++)
      {
          if (sum.a > 0.99) break;

          float3 pos = ro + t * rd;
          float4 col = map(pos);

          col.xyz *= lerp(3.1 * float3 (1.0 , 0.5 , 0.05) , float3 (0.48 , 0.53 , 0.5) , clamp((pos.y - 0.2) / 2.0 , 0.0 , 1.0));

          col.a *= 0.6;
          col.rgb *= col.a;

          sum = sum + col * (1.0 - sum.a);

          t += 0.05;
      }

     return clamp(sum.xyz , 0.0 , 1.0);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = -1.0 + 2.0 * q;
    p.x *= (_ScreenParams.x / _ScreenParams.y);

    float2 mo = iMouse.xy / _ScreenParams.xy;
    if (iMouse.w <= 0.00001) mo = float2 (0.0 , 0.0);

    // camera 
    float3 ro = 4.0 * normalize(float3 (cos(3.0 * mo.x), 1.4 - 1.0 * (mo.y - .1), sin(3.0 * mo.x)));
    float3 ta = float3 (0.0 , 1.0 , 0.0);
    float cr = 0.5 * cos(0.7 * _Time.y);

    // shake 
    ro += 0.1 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , _Time.y * float2 (0.010 , 0.014) , 0.0).xyz);
    ta += 0.1 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , _Time.y * float2 (0.013 , 0.008) , 0.0).xyz);

    // build ray 
  float3 ww = normalize(ta - ro);
  float3 uu = normalize(cross(float3 (sin(cr) , cos(cr) , 0.0) , ww));
  float3 vv = normalize(cross(ww , uu));
  float3 rd = normalize(p.x * uu + p.y * vv + 2.0 * ww);

  // raymarch 
  float3 col = raymarch(ro , rd , fragCoord);

  // contrast and vignetting 
 col = col * 0.5 + 0.5 * col * col * (3.0 - 2.0 * col);
 col *= 0.25 + 0.75 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

fragColor = float4 (col , 1.0);
return fragColor - 0.1;
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