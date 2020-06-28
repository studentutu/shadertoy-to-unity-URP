Shader "UmutBebek/URP/ShaderToy/2D Clouds 4tdSWr"
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
            cloudscale("cloudscale", float) = 1.1
speed("speed", float) = 0.03
clouddark("clouddark", float) = 0.5
cloudlight("cloudlight", float) = 0.3
cloudcover("cloudcover", float) = 0.2
cloudalpha("cloudalpha", float) = 8.0
skytint("skytint", float) = 0.5
skycolour1("skycolour1", vector) = (0.2, 0.4, 0.6)
skycolour2("skycolour2", vector) = (0.4, 0.7, 1.0)


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
            float cloudscale;
float speed;
float clouddark;
float cloudlight;
float cloudcover;
float cloudalpha;
float skytint;
float4 skycolour1;
float4 skycolour2;


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













float2 hash(float2 p) {
     p = float2 (dot(p , float2 (127.1 , 311.7)) , dot(p , float2 (269.5 , 183.3)));
     return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
 }

float noise(in float2 p) {
    const float K1 = 0.366025404; // ( sqrt ( 3 ) - 1 ) / 2 ; 
    const float K2 = 0.211324865; // ( 3 - sqrt ( 3 ) ) / 6 ; 
     float2 i = floor(p + (p.x + p.y) * K1);
    float2 a = p - i + (i.x + i.y) * K2;
    float2 o = (a.x > a.y) ? float2 (1.0 , 0.0) : float2 (0.0 , 1.0); // float2 of = 0.5 + 0.5 * float2 ( sign ( a.x - a.y ) , sign ( a.y - a.x ) ) ; 
    float2 b = a - o + K2;
     float2 c = a - 1.0 + 2.0 * K2;
    float3 h = max(0.5 - float3 (dot(a , a) , dot(b , b) , dot(c , c)) , 0.0);
     float3 n = h * h * h * h * float3 (dot(a , hash(i + 0.0)) , dot(b , hash(i + o)) , dot(c , hash(i + 1.0)));
    return dot(n , float3 (70.0, 70.0, 70.0));
 }

float fbm(float2 n) {
     float total = 0.0 , amplitude = 0.1;
     for (int i = 0; i < 7; i++) {
          total += noise(n) * amplitude;
          n = mul(float2x2(1.6, 1.2, -1.2, 1.6) ,  n);
          amplitude *= 0.4;
      }
     return total;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 p = fragCoord.xy / _ScreenParams.xy;
     float2 uv = p * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
    float time = _Time.y * speed;
    float q = fbm(uv * cloudscale * 0.5);

    // ridged noise shape 
    float r = 0.0;
    uv *= cloudscale;
   uv -= q - time;
   float weight = 0.8;
   for (int i = 0; i < 8; i++) {
         r += abs(weight * noise(uv));
       uv = mul(float2x2(1.6, 1.2, -1.2, 1.6) , uv) + time;
         weight *= 0.7;
    }

   // noise shape 
   float f = 0.0;
  uv = p * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
   uv *= cloudscale;
  uv -= q - time;
  weight = 0.7;
  for (int i = 0; i < 8; i++) {
        f += weight * noise(uv);
      uv = mul(float2x2(1.6, 1.2, -1.2, 1.6) , uv) + time;
        weight *= 0.6;
   }

  f *= r + f;

  // noise colour 
 float c = 0.0;
 time = _Time.y * speed * 2.0;
 uv = p * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
  uv *= cloudscale * 2.0;
 uv -= q - time;
 weight = 0.4;
 for (int i = 0; i < 7; i++) {
       c += weight * noise(uv);
     uv = mul(float2x2(1.6, 1.2, -1.2, 1.6) , uv) + time;
       weight *= 0.6;
  }

 // noise ridge colour 
float c1 = 0.0;
time = _Time.y * speed * 3.0;
uv = p * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
 uv *= cloudscale * 3.0;
uv -= q - time;
weight = 0.4;
for (int i = 0; i < 7; i++) {
      c1 += abs(weight * noise(uv));
    uv = mul(float2x2(1.6, 1.2, -1.2, 1.6) , uv) + time;
      weight *= 0.6;
 }

c += c1;

float3 skycolour = lerp(skycolour2 , skycolour1 , p.y);
float3 cloudcolour = float3 (1.1 , 1.1 , 0.9) * clamp((clouddark + cloudlight * c) , 0.0 , 1.0);

f = cloudcover + cloudalpha * f * r;

float3 result = lerp(skycolour , clamp(skytint * skycolour + cloudcolour , 0.0 , 1.0) , clamp(f + c , 0.0 , 1.0));

 fragColor = float4 (result , 1.0);
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