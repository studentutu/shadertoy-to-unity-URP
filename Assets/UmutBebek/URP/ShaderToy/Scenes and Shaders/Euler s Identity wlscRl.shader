Shader "UmutBebek/URP/ShaderToy/Euler s Identity wlscRl"
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

           // Great lecture on the subject! https: // youtu.be / ZxYOEwM6Wbk?t = 2177 


#define rot ( j ) float2x2 ( cos ( j ) , sin ( j ) , sin ( j ) , cos ( j ) ) 

#define pi acos ( - 1. ) 

float2 cmul(float2 a , float2 b) { return float2 (a.x * b.x - a.y * b.y , a.x * b.y + b.y * b.x); }
// cpolar ( ) and cpow ( ) I borrowed from some shader on shadertoy! not sure which 
float2 cpolar(float k , float t) { return k * float2 (cos(t) , sin(t)); }
float2 cpow(float2 z , float k) { return cpolar(pow(length(z) , k) , k * atan2(z.y , z.x)); }


float factoriel(float a) {
     float f = 1.;
    for (float i = 1.; i <= a; i++) {
         f *= i;
     }
    return f;
 }

// from iq 
float sdSegment(in float2 p , in float2 a , in float2 b)
 {
    float2 pa = p - a , ba = b - a;
    float h = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.0);
    return length(pa - ba * h);
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = (fragCoord - 0.5 * _ScreenParams.xy) / _ScreenParams.y;

    float3 col = float3 (0 , 0 , 0);


    float2 z = float2 (1 , 0.);



    col = lerp(col , float3 (1. , 1. , 1.) , smoothstep(1. * ddx(uv.x) , 0. , abs(length(uv.x)) - 0.002));

    col = lerp(col , float3 (1. , 1. , 1.) , smoothstep(1. * ddx(uv.x) , 0. , abs(length(uv.y)) - 0.002));

    float modD = 0.125;
    col = lerp(col , float3 (1. , 1. , 1.) , smoothstep(1. * ddx(uv.x) , 0. , max(
        abs(length(mod(uv.x - modD / 2. , modD) - modD / 2.)) - 0.002 ,
        abs(uv.y) - 0.01)));

    col = lerp(col , float3 (1. , 1. , 1.) , smoothstep(1. * ddx(uv.x) , 0. , max(
        abs(length(mod(uv.y - modD / 2. , modD) - modD / 2.)) - 0.002 ,
        abs(uv.x) - 0.01)));


    col = lerp(col , float3 (0.2 , 0.4 , 0.9) , smoothstep(1. * ddx(uv.x) , 0. , abs(length(uv) - 0.25) - 0.002));


    // lines 

   float dotSz = 0.01;

   float dDots = length(uv - z / 4.) - dotSz;
   float dLines = 10e5;
   float theta = pi * 1. - sin(_Time.y / 2.) * pi * 0.75;
   float2 numerator = float2 (0 , theta);
   for (float i = 1.; i < 20.; i++) {
       float2 denominator = float2 (factoriel(i) , 0.);
       float2 oldz = z;
       z += cpow(numerator , i) / denominator.x;

       dLines = min(dLines , sdSegment(uv , oldz / 4. , z / 4.) - 0.002);
       dDots = min(dDots , length(uv - z / 4.) - dotSz);

    }

   col = lerp(col , float3 (1. , 0.4 , 0.2) , smoothstep(1. * ddx(uv.x) , 0. , dLines));
   col = lerp(col , float3 (1. , 0.2 , 0.4) , smoothstep(1. * ddx(uv.x) , 0. , dDots));

   col = pow(col , float3 (0.454545, 0.454545, 0.454545));

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