Shader "UmutBebek/URP/ShaderToy/Goo lllBDM MainImage"
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
            W("W", float) = 1.2
T2("T2", float) = 7.5
N("N", int) = 8

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
            float W;
float T2;
int N;

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

float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
{
    //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
    float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
    return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
}

// Tone mapping and post processing 
float hash(float c) { return frac(sin(dot(c , 12.9898)) * 43758.5453); }

// linear white pointExtended 



float filmic_reinhard_curve(float x) {
    float q = (T2 * T2 + 1.0) * x * x;
     return q / (q + x + T2 * T2);
 }

float3 filmic_reinhard(float3 x) {
    float w = filmic_reinhard_curve(W);
    return float3 (
        filmic_reinhard_curve(x.r) ,
        filmic_reinhard_curve(x.g) ,
        filmic_reinhard_curve(x.b)) / w;
 }


float3 ca(Texture2D t, SamplerState samp, float2 UV , float4 sampl) {
     float2 uv = 1.0 - 2.0 * UV;
     float3 c = float3 (0 , 0 , 0);
     float rf = 1.0;
     float gf = 1.0;
    float bf = 1.0;
     float f = 1.0 / float(N);
     for (int i = 0; i < N; ++i) {
          c.r += f * SAMPLE_TEXTURE2D(t , samp, 0.5 - 0.5 * (uv * rf)).r;
          c.g += f * SAMPLE_TEXTURE2D(t , samp, 0.5 - 0.5 * (uv * gf)).g;
          c.b += f * SAMPLE_TEXTURE2D(t , samp, 0.5 - 0.5 * (uv * bf)).b;
          rf *= 0.9972;
          gf *= 0.998;
        bf /= 0.9988;
          c = clamp(c , 0.0 , 1.0);
      }
     return c;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 0);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    const float brightness = 1.0;
    float2 pp = fragCoord.xy / _ScreenParams.xy;
    float2 r = _ScreenParams.xy;
    float2 p = 1. - 2. * fragCoord.xy / r.xy;
    p.y *= r.y / r.x;

    // a little chromatic aberration 
   float4 sampl = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , pp);
   float3 color = ca(_Channel0 , sampler_Channel0 , pp , sampl).rgb;

   // final output 
  float vignette = 1.25 / (1.1 + 1.1 * dot(p , p));
  vignette *= vignette;
  vignette = lerp(1.0 , smoothstep(0.1 , 1.1 , vignette) , 0.25);
  float hasehs = hash(length(p) * _Time.y);
  float noise = .012 * float3 (hasehs, hasehs, hasehs).x;
  color = color * vignette + noise;
  color = filmic_reinhard(brightness * color);

  color = smoothstep(-0.025 , 1.0 , color);

  color = pow(color , float3 (1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));
  fragColor = float4 (color , 1.0);
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