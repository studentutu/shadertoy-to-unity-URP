Shader "UmutBebek/URP/ShaderToy/Simplicity Galaxy MslGWN"
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

           // CBS 
// Parallax scrolling fractal galaxy. 
// Inspired by JoshP's Simplicity shader: https: // www.shadertoy.com / view / lslGWr 

// http: // www.fractalforums.com / new - theories - and - research / very - simple - formula - for - fractal - patterns / 
float field(in float3 p , float s) {
     float strength = 7. + .03 * log(1.e-6 + frac(sin(_Time.y) * 4373.11));
     float accum = s / 4.;
     float prev = 0.;
     float tw = 0.;
     for (int i = 0; i < 26; ++i) {
          float mag = dot(p , p);
          p = abs(p) / mag + float3 (-.5 , -.4 , -1.5);
          float w = exp(-float(i) / 7.);
          accum += w * exp(-strength * pow(abs(mag - prev) , 2.2));
          tw += w;
          prev = mag;
      }
     return max(0. , 5. * accum / tw - .7);
 }

// Less iterations for second layer 
float field2(in float3 p , float s) {
     float strength = 7. + .03 * log(1.e-6 + frac(sin(_Time.y) * 4373.11));
     float accum = s / 4.;
     float prev = 0.;
     float tw = 0.;
     for (int i = 0; i < 18; ++i) {
          float mag = dot(p , p);
          p = abs(p) / mag + float3 (-.5 , -.4 , -1.5);
          float w = exp(-float(i) / 7.);
          accum += w * exp(-strength * pow(abs(mag - prev) , 2.2));
          tw += w;
          prev = mag;
      }
     return max(0. , 5. * accum / tw - .7);
 }

float3 nrand3(float2 co)
 {
     float3 a = frac(cos(co.x * 8.3e-3 + co.y) * float3 (1.3e5 , 4.7e5 , 2.9e5));
     float3 b = frac(sin(co.x * 0.3e-3 + co.y) * float3 (8.1e5 , 1.0e5 , 0.1e5));
     float3 c = lerp(a , b , 0.5);
     return c;
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = 2. * fragCoord.xy / _ScreenParams.xy - 1.;
     float2 uvs = uv * _ScreenParams.xy / max(_ScreenParams.x , _ScreenParams.y);
     float3 p = float3 (uvs / 4. , 0) + float3 (1. , -1.3 , 0.);
     p += .2 * float3 (sin(_Time.y / 16.) , sin(_Time.y / 12.) , sin(_Time.y / 128.));

     float freqs[4];
     // Sound 
    freqs[0] = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (0.01 , 0.25)).x;
    freqs[1] = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (0.07 , 0.25)).x;
    freqs[2] = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (0.15 , 0.25)).x;
    freqs[3] = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (0.30 , 0.25)).x;

    float t = field(p , freqs[2]);
    float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));

    // Second Layer 
    float3 p2 = float3 (uvs / (4. + sin(_Time.y * 0.11) * 0.2 + 0.2 + sin(_Time.y * 0.15) * 0.3 + 0.4) , 1.5) + float3 (2. , -1.3 , -1.);
    p2 += 0.25 * float3 (sin(_Time.y / 16.) , sin(_Time.y / 12.) , sin(_Time.y / 128.));
    float t2 = field2(p2 , freqs[3]);
    float4 c2 = lerp(.4 , 1. , v) * float4 (1.3 * t2 * t2 * t2 , 1.8 * t2 * t2 , t2 * freqs[0] , t2);


    // Let's add some stars 
    // Thanks to http: // glsl.heroku.com / e#6904.0 
   float2 seed = p.xy * 2.0;
   seed = floor(seed * _ScreenParams.x);
   float3 rnd = nrand3(seed);
   float powerr = pow(rnd.y, 40.0);
   float4 starcolor = float4 (powerr, powerr, powerr, powerr);

   // Second Layer 
  float2 seed2 = p2.xy * 2.0;
  seed2 = floor(seed2 * _ScreenParams.x);
  float3 rnd2 = nrand3(seed2);
  float aaaa = pow(rnd2.y, 40.0);
  starcolor += float4 (aaaa, aaaa, aaaa, aaaa);

  fragColor = lerp(freqs[3] - .3 , 1. , v) * float4 (1.5 * freqs[2] * t * t * t , 1.2 * freqs[1] * t * t , freqs[3] * t , 1.0) + c2 + starcolor;
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