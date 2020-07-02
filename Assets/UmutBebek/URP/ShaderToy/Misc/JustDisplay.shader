Shader "UmutBebek/URP/ShaderToy/Just Diplay"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
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

        half4 LitPassFragment(Varyings input) : SV_Target  
        {
            half4 fragColor = half4 (1 , 1 , 1 , 1);
            float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)); // *_ScreenParams.xy; no multply because it is already on 0,1 space
            fragColor = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord);
            return fragColor;
        }
        ENDHLSL
        }
    }
}