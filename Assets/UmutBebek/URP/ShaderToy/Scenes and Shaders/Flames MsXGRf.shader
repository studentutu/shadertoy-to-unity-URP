Shader "UmutBebek/URP/ShaderToy/Flames MsXGRf"
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

// You can buy a metal print of this shader here: 
// https: // www.redbubble.com / i / metal - print / Flames - by - InigoQuilez / 39844894.0JXQP 


float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
    float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
    return lerp(rg.x , rg.y , f.z);
 }

float4 map(in float3 p)
 {
    float3 r = p; p.y += 0.6;
    // invert space 
   p = -4.0 * p / dot(p , p);
   // twist space 
  float an = -1.0 * sin(0.1 * _Time.y + length(p.xz) + p.y);
  float co = cos(an);
  float si = sin(an);
  p.xz = mul(float2x2 (co , -si , si , co) , p.xz);

  // distort 
 p.xz += -1.0 + 2.0 * noise(p * 1.1);
 // pattern 
float f;
float3 q = p * 0.85 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
f = 0.50000 * noise(q); q = q * 2.02 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
f += 0.25000 * noise(q); q = q * 2.03 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
f += 0.12500 * noise(q); q = q * 2.01 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
f += 0.06250 * noise(q); q = q * 2.02 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
f += 0.04000 * noise(q); q = q * 2.00 - float3 (0.0 , 1.0 , 0.0) * _Time.y * 0.12;
float den = clamp((-r.y - 0.6 + 4.0 * f) * 1.2 , 0.0 , 1.0);
float3 col = 1.2 * lerp(float3 (1.0 , 0.8 , 0.6) , 0.9 * float3 (0.3 , 0.2 , 0.35) , den);
col += 0.05 * sin(0.05 * q);
col *= 1.0 - 0.8 * smoothstep(0.6 , 1.0 , sin(0.7 * q.x) * sin(0.7 * q.y) * sin(0.7 * q.z)) * float3 (0.6 , 1.0 , 0.8);
col *= 1.0 + 1.0 * smoothstep(0.5 , 1.0 , 1.0 - length((frac(q.xz * 0.12) - 0.5) / 0.5)) * float3 (1.0 , 0.9 , 0.8);
col = lerp(float3 (0.8 , 0.32 , 0.2) , col , clamp((r.y + 0.1) / 1.5 , 0.0 , 1.0));
return float4 (col , den);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // inputs 
float2 q = fragCoord.xy / _ScreenParams.xy;
float2 p = (-1.0 + 2.0 * q) * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
float2 mo = iMouse.xy / _ScreenParams.xy;
if (iMouse.w <= 0.00001) mo = float2 (0.0 , 0.0);

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// cameran 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float an = -0.07 * _Time.y + 3.0 * mo.x;
float3 ro = 4.5 * normalize(float3 (cos(an) , 0.5 , sin(an)));
ro.y += 1.0;
float3 ta = float3 (0.0 , 0.5 , 0.0);
float cr = -0.4 * cos(0.02 * _Time.y);

// build rayn 
float3 ww = normalize(ta - ro);
float3 uu = normalize(cross(float3 (sin(cr) , cos(cr) , 0.0) , ww));
float3 vv = normalize(cross(ww , uu));
float3 rd = normalize(p.x * uu + p.y * vv + 2.5 * ww);

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// raymarch 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);
float3 bg = float3 (0.4 , 0.5 , 0.5) * 1.3;
// dithering 
float t = 0.05 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord.xy / _ScreenParams.x).x;
for (int i = 0; i < 128; i++)
 {
    if (sum.a > 0.99) break;
    float3 pos = ro + t * rd;
    float4 col = map(pos);
    col.a *= 0.5;
    col.rgb = lerp(bg , col.rgb , exp(-0.002 * t * t * t)) * col.a;
    sum = sum + col * (1.0 - sum.a);
    t += 0.05;
 }

float3 col = clamp(lerp(bg , sum.xyz / (0.001 + sum.w) , sum.w) , 0.0 , 1.0);

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// contrast + vignetting 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
col = col * col * (3.0 - 2.0 * col) * 1.4 - 0.4;
col *= 0.25 + 0.75 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);
fragColor = float4 (col , 1.0);
return fragColor*0.85;
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