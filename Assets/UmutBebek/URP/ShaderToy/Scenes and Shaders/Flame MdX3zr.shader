Shader "UmutBebek/URP/ShaderToy/Flame MdX3zr"
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

            float noise(float3 p) // Thx to Las^Mercury 
{
    float3 i = floor(p);
    float4 a = dot(i , float3 (1. , 57. , 21.)) + float4 (0. , 57. , 21. , 78.);
    float3 f = cos((p - i) * acos(-1.)) * (-.5) + .5;
    a = lerp(sin(cos(a) * a) , sin(cos(1. + a) * (1. + a)) , f.x);
    a.xy = lerp(a.xz , a.yw , f.y);
    return lerp(a.x , a.y , f.z);
}

float sphere(float3 p , float4 spr)
 {
     return length(spr.xyz - p) - spr.w;
 }

float flame(float3 p)
 {
     float d = sphere(p * float3 (1. , .5 , 1.) , float4 (.0 , -1. , .0 , 1.));
     return d + (noise(p + float3 (.0 , _Time.y * 2. , .0)) + noise(p * 3.) * .5) * .25 * (p.y);
 }

float scene(float3 p)
 {
     return min(100. - length(p) , abs(flame(p)));
 }

float4 raymarch(float3 org , float3 dir)
 {
     float d = 0.0 , glow = 0.0 , eps = 0.02;
     float3 p = org;
     bool glowed = false;

     for (int i = 0; i < 64; i++)
      {
          d = scene(p) + eps;
          p += d * dir;
          if (d > eps)
           {
               if (flame(p) < .0)
                    glowed = true;
               if (glowed)
                      glow = float(i) / 64.;
           }
      }
     return float4 (p , glow);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 v = -1.0 + 2.0 * fragCoord.xy / _ScreenParams.xy;
     v.x *= _ScreenParams.x / _ScreenParams.y;

     float3 org = float3 (0. , -2. , 4.);
     float3 dir = normalize(float3 (v.x * 1.6 , -v.y , -1.5));

     float4 p = raymarch(org , dir);
     float glow = p.w;

     float4 col = lerp(float4 (1. , .5 , .1 , 1.) , float4 (0.1 , .5 , 1. , 1.) , p.y * .02 + .4);

     fragColor = lerp(float4 (0., 0., 0., 0.) , col , pow(glow * 2. , 4.));
     // fragColor = lerp ( float4 ( 1. ) , lerp ( float4 ( 1. , .5 , .1 , 1. ) , float4 ( 0.1 , .5 , 1. , 1. ) , p.y * .02 + .4 ) , pow ( glow * 2. , 4. ) ) ; 

return fragColor-0.1;
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