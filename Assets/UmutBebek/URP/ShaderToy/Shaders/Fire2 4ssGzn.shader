Shader "UmutBebek/URP/ShaderToy/Fire2 4ssGzn"
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
            _VolumeSteps("_VolumeSteps", int) = 128
_StepSize("_StepSize", float) = 0.02
_Density("_Density", float) = 0.2
_SphereRadius("_SphereRadius", float) = 1.0
_NoiseFreq("_NoiseFreq", float) = 2.0
_NoiseAmp("_NoiseAmp", float) = 1.0
_NoiseAnim("_NoiseAnim", vector) = (0, -1, 0)

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
            int _VolumeSteps;
float _StepSize;
float _Density;
float _SphereRadius;
float _NoiseFreq;
float _NoiseAmp;
float4 _NoiseAnim;

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

// ray marched fireball 
// sgreen 









// iq's nice integer - less noise function 
float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0).yx;
     return lerp(rg.x , rg.y , f.z) * 2.0 - 1.0;
 }

float fbm(float3 p)
 {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++)
     {
        // f += abs ( noise ( p ) ) * amp ; 
       f += noise(p) * amp;
       p *= 2.03;
       amp *= 0.5;
     }
   return f;
}

float2 rotate(float2 v , float angle)
 {
    return mul(v, float2x2 (cos(angle) , sin(angle) , -sin(angle) , cos(angle)));
 }

// returns signed distance to surface 
float distanceFunc(float3 p)
 {

    // distance to sphere 
  float d = length(p) - _SphereRadius;
  // offset distance with noise 
 d += fbm(p * _NoiseFreq + _NoiseAnim.xyz * _Time.y) * _NoiseAmp;
 return d;
}

// shade a pointExtended based on distance 
float4 shade(float d)
 {
    if (d >= 0.0 && d < 0.2) return (lerp(float4 (3 , 3 , 3 , 1) , float4 (1 , 1 , 0 , 1) , d / 0.2));
     if (d >= 0.2 && d < 0.4) return (lerp(float4 (1 , 1 , 0 , 1) , float4 (1 , 0 , 0 , 1) , (d - 0.2) / 0.2));
     if (d >= 0.4 && d < 0.6) return (lerp(float4 (1 , 0 , 0 , 1) , float4 (0 , 0 , 0 , 0) , (d - 0.4) / 0.2));
    if (d >= 0.6 && d < 0.8) return (lerp(float4 (0 , 0 , 0 , 0) , float4 (0 , .5 , 1 , 0.2) , (d - 0.6) / 0.2));
    if (d >= 0.8 && d < 1.0) return (lerp(float4 (0 , .5 , 1 , .2) , float4 (0 , 0 , 0 , 0) , (d - 0.8) / 0.2));
    return 0; // (lerp(float4 (0, .5, 1, .2), float4 (0, 0, 0, 0), (d - 0.8) / 0.2));
 }

// procedural volume 
// maps position to color 
float4 volumeFunc(float3 p)
 {
    // p.xz = rotate ( p.xz , p.y * 2.0 + _Time.y ) ; // firestorm 
    float d = distanceFunc(p);
    return shade(d);
}

// ray march volume from front to back 
// returns color 
float4 rayMarch(float3 rayOrigin , float3 rayStep , out float3 pos)
 {
     float4 sum = float4 (0 , 0 , 0 , 0);
     pos = rayOrigin;
     for (int i = 0; i < _VolumeSteps; i++) {
          float4 col = volumeFunc(pos);
          col.a *= _Density;
          // pre - multiply alpha 
         col.rgb *= col.a;
         sum = sum + col * (1.0 - sum.a);
         pos += rayStep;
     }
    return sum;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 p = (fragCoord.xy / _ScreenParams.xy) * 2.0 - 1.0;
    p.x *= _ScreenParams.x / _ScreenParams.y;

    float rotx = (iMouse.y / _ScreenParams.y) * 4.0;
    float roty = -(iMouse.x / _ScreenParams.x) * 4.0;

    float zoom = 4.0;

    // camera 
   float3 ro = zoom * normalize(float3 (cos(roty) , cos(rotx) , sin(roty)));
   float3 ww = normalize(float3 (0.0 , 0.0 , 0.0) - ro);
   float3 uu = normalize(cross(float3 (0.0 , 1.0 , 0.0) , ww));
   float3 vv = normalize(cross(ww , uu));
   float3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww);

   ro += rd * 2.0;

   // volume render 
  float3 hitPos;
  float4 col = rayMarch(ro , rd * _StepSize , hitPos);

  fragColor = col;
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