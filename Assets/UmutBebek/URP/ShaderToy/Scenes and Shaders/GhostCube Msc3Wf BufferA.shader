Shader "UmutBebek/URP/ShaderToy/GhostCube Msc3Wf BufferA"
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
            Tags{"RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            "IgnoreProjector" = "True"}
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

            //Blend SrcAlpha OneMinusSrcAlpha // Traditional transparency
//Blend One OneMinusSrcAlpha // Premultiplied transparency
//Blend One One // Additive
//Blend OneMinusDstColor One // Soft Additive
//Blend DstColor Zero // Multiplicative
//Blend DstColor SrcColor // 2x Multiplicative
            //Blend zero one
            //Blend One one
            //Blend[_SrcBlend][_DstBlend]
            //ZWrite Off ZTest Always
            /*ZWrite Off ZTest Always
            Blend[_SrcBlend][_DstBlend]*/
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

float sdBox(float3 p , float3 b)
{
 float3 d = abs(p) - b;
 return min(max(d.x , max(d.y , d.z)) , 0.0) +
        length(max(d , 0.0));
}

float map(float3 p)
 {
    float t = _Time.y;
    p.xz = mul(p.xz , float2x2 (cos(t) , sin(t) , -sin(t) , cos(t)));
    p.xy = mul(p.xy, float2x2 (cos(t) , sin(t) , -sin(t) , cos(t)));
    p.yz = mul(p.yz , float2x2 (cos(t) , sin(t) , -sin(t) , cos(t)));

    float k = sdBox(p , float3 (1.0 , 1.0 , 1.0));
    float o = 0.85;
     k = max(k , -sdBox(p , float3 (2.0 , o , o)));
    k = max(k , -sdBox(p , float3 (o , 2.0 , o)));
    k = max(k , -sdBox(p , float3 (o , o , 2.0)));
    return k;
 }

float trace(float3 o , float3 r)
 {
      float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        float3 p = o + r * t;
        float d = map(p) * 0.9;
        t += d;
     }
    return t;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 uv = fragCoord.xy / _ScreenParams.xy;

    float4 old = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv - float2 (0.0 , 1.0 / _ScreenParams.y));
    float4 old2 = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv - float2 (0.0 , 2.0 * 1.0 / _ScreenParams.y));

    uv = uv * 2.0 - 1.0;
    uv.x *= _ScreenParams.x / _ScreenParams.y;

    float3 o = float3 (0.0 , 0.0 , -2.5);
    float3 r = float3 (uv , 0.8);

    float t = trace(o , r);

    float3 fog = float3 (1.0 , 1.0 , 1.0) / (1.0 + t * t * 0.1) * 0.1;

    float c = _Time.y * 5.0 + uv.x;
    fog *= float3 (sin(c) * cos(c * 2.0) , cos(c) * cos(c * 2.0) , sin(c)) * 0.5 + 0.5;

    fog += old.xyz * 0.6 + old2.xyz * 0.37;

     fragColor = float4 (fog , 1.0);
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