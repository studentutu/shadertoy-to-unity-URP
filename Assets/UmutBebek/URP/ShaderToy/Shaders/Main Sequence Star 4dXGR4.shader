Shader "UmutBebek/URP/ShaderToy/Main Sequence Star 4dXGR4"
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

           // based on https: // www.shadertoy.com / view / lsf3RH by 
// trisomie21 ( THANKS! ) 
// My apologies for the ugly code. 

float snoise(float3 uv , float res) // by trisomie21 
 {
     const float3 s = float3 (1e0 , 1e2 , 1e4);

     uv *= res;

     float3 uv0 = floor(mod(uv , res)) * s;
     float3 uv1 = floor(mod(uv + float3 (1. , 1. , 1.) , res)) * s;

     float3 f = frac(uv); f = f * f * (3.0 - 2.0 * f);

     float4 v = float4 (uv0.x + uv0.y + uv0.z , uv1.x + uv0.y + uv0.z ,
                       uv0.x + uv1.y + uv0.z , uv1.x + uv1.y + uv0.z);

     float4 r = frac(sin(v * 1e-3) * 1e5);
     float r0 = lerp(lerp(r.x , r.y , f.x) , lerp(r.z , r.w , f.x) , f.y);

     r = frac(sin((v + uv1.z - uv0.z) * 1e-3) * 1e5);
     float r1 = lerp(lerp(r.x , r.y , f.x) , lerp(r.z , r.w , f.x) , f.y);

     return lerp(r0 , r1 , f.z) * 2. - 1.;
 }

float freqs[4];

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     freqs[0] = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (0.01 , 0.25)).x;
     freqs[1] = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (0.07 , 0.25)).x;
     freqs[2] = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (0.15 , 0.25)).x;
     freqs[3] = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (0.30 , 0.25)).x;

     float brightness = freqs[1] * 0.25 + freqs[2] * 0.25;
     float radius = 0.24 + brightness * 0.2;
     float invRadius = 1.0 / radius;

     float3 orange = float3 (0.8 , 0.65 , 0.3);
     float3 orangeRed = float3 (0.8 , 0.35 , 0.1);
     float time = _Time.y * 0.1;
     float aspect = _ScreenParams.x / _ScreenParams.y;
     float2 uv = fragCoord.xy / _ScreenParams.xy;
     float2 p = -0.5 + uv;
     p.x *= aspect;

     float fade = pow(length(2.0 * p) , 0.5);
     float fVal1 = 1.0 - fade;
     float fVal2 = 1.0 - fade;

     float angle = atan2(p.x , p.y) / 6.2832;
     float dist = length(p);
     float3 coord = float3 (angle , dist , time * 0.1);

     float newTime1 = abs(snoise(coord + float3 (0.0 , -time * (0.35 + brightness * 0.001) , time * 0.015) , 15.0));
     float newTime2 = abs(snoise(coord + float3 (0.0 , -time * (0.15 + brightness * 0.001) , time * 0.015) , 45.0));
     for (int i = 1; i <= 7; i++) {
          float power = pow(2.0 , float(i + 1));
          fVal1 += (0.5 / power) * snoise(coord + float3 (0.0 , -time , time * 0.2) , (power * (10.0) * (newTime1 + 1.0)));
          fVal2 += (0.5 / power) * snoise(coord + float3 (0.0 , -time , time * 0.2) , (power * (25.0) * (newTime2 + 1.0)));
      }

     float corona = pow(fVal1 * max(1.1 - fade , 0.0) , 2.0) * 50.0;
     corona += pow(fVal2 * max(1.1 - fade , 0.0) , 2.0) * 50.0;
     corona *= 1.2 - newTime1;
     float3 sphereNormal = float3 (0.0 , 0.0 , 1.0);
     float3 dir = float3 (0.0 , 0.0 , 0.0);
     float3 center = float3 (0.5 , 0.5 , 1.0);
     float3 starSphere = float3 (0.0 , 0.0 , 0.0);

     float2 sp = -1.0 + 2.0 * uv;
     sp.x *= aspect;
     sp *= (2.0 - brightness);
       float r = dot(sp , sp);
     float f = (1.0 - sqrt(abs(1.0 - r))) / (r)+brightness * 0.5;
     if (dist < radius) {
          corona *= pow(dist * invRadius , 24.0);
            float2 newUv;
           newUv.x = sp.x * f;
            newUv.y = sp.y * f;
          newUv += float2 (time , 0.0);

          float3 texSample = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , newUv).rgb;
          float uOff = (texSample.g * brightness * 4.5 + time);
          float2 starUV = newUv + float2 (uOff , 0.0);
          starSphere = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , starUV).rgb;
      }

     float starGlow = min(max(1.0 - dist * (1.0 - brightness) , 0.0) , 1.0);
     // fragColor.rgb = float3 ( r ) ; 
    fragColor.rgb = float3 (f * (0.75 + brightness * 0.3) * orange) + starSphere + corona * orange + starGlow * orangeRed;
    fragColor.a = 1.0;
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