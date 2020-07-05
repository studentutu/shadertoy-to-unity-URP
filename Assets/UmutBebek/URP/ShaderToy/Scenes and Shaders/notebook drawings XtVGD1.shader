Shader "UmutBebek/URP/ShaderToy/notebook drawings XtVGD1"
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

AngleNum("AngleNum", float) = 3
SampNum("SampNum", float) = 8
PI2("PI2", float) = 6.28318530717959

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

            //Blend Zero One
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
float AngleNum;
float SampNum;
float PI2;

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

// created by florian berger ( flockaroo ) - 2016 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// trying to resemle some hand drawing style 








#define Res _ScreenParams.xy 
#define Res0 _ScreenParams.xy
#define Res1 _ScreenParams.xy


float4 getRand(float2 pos)
 {
    return SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , pos / Res1 / _ScreenParams.y * 1080. , 0.0);
 }

float4 getCol(float2 pos)
 {
    // take aspect ratio into account 
   float2 uv = ((pos - Res.xy * .5) / Res.y * Res0.y) / Res0.xy + .5;
   float4 c1 = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv);
   float4 e = smoothstep(float4 (-0.05, -0.05, -0.05, -0.05) , float4 (-0.0, -0.0, -0.0, -0.0) , float4 (uv , float2 (1 , 1) - uv));
   c1 = lerp(float4 (1 , 1 , 1 , 0) , c1 , e.x * e.y * e.z * e.w);
   float d = clamp(dot(c1.xyz , float3 (-.5 , 1. , -.5)) , 0.0 , 1.0);
   float4 c2 = float4 (.7 , .7 , .7 , .7);
   return min(lerp(c1 , c2 , 1.8 * d) , .7);
}

float4 getColHT(float2 pos)
 {
      return smoothstep(.95 , 1.05 , getCol(pos) * .8 + .2 + getRand(pos * .7));
 }

float getVal(float2 pos)
 {
    float4 c = getCol(pos);
      return pow(dot(c.xyz , float3 (.333 , .333 , .333)) , 1.) * 1.;
 }

float2 getGrad(float2 pos , float eps)
 {
        float2 d = float2 (eps , 0);
    return float2 (
        getVal(pos + d.xy) - getVal(pos - d.xy) ,
        getVal(pos + d.yx) - getVal(pos - d.yx)
     ) / eps / 2.;
 }






half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 pos = fragCoord + 4.0 * sin(_Time.y * 1. * float2 (1 , 1.7)) * _ScreenParams.y / 400.;
    float3 col = float3 (0 , 0 , 0);
    float3 col2 = float3 (0 , 0 , 0);
    float sum = 0.;
    for (int i = 0; i < AngleNum; i++)
     {
        float ang = PI2 / float(AngleNum) * (float(i) + .8);
        float2 v = float2 (cos(ang) , sin(ang));
        for (int j = 0; j < SampNum; j++)
         {
            float2 dpos = v.yx * float2 (1 , -1) * float(j) * _ScreenParams.y / 400.;
            float2 dpos2 = v.xy * float(j * j) / float(SampNum) * .5 * _ScreenParams.y / 400.;
             float2 g;
            float fact;
            float fact2;

            for (float s = -1.; s <= 1.; s += 2.)
             {
                float2 pos2 = pos + s * dpos + dpos2;
                float2 pos3 = pos + (s * dpos + dpos2).yx * float2 (1 , -1) * 2.;
                 g = getGrad(pos2 , .4);
                 fact = dot(g , v) - .5 * abs(dot(g , v.yx * float2 (1 , -1))) /* * ( 1. - getVal ( pos2 ) ) */;
                 fact2 = dot(normalize(g + float2 (.0001, .0001)) , v.yx * float2 (1 , -1));

                fact = clamp(fact , 0. , .05);
                fact2 = abs(fact2);

                fact *= 1. - float(j) / float(SampNum);
                 col += fact;
                 col2 += fact2 * getColHT(pos3).xyz;
                 sum += fact2;
             }
         }
     }
    col /= float(SampNum * AngleNum) * .75 / sqrt(_ScreenParams.y);
    col2 /= sum;
    col.x *= (.6 + .8 * getRand(pos * .7).x);
    col.x = 1. - col.x;
    col.x *= col.x * col.x;

    float2 s = sin(pos.xy * .1 / sqrt(_ScreenParams.y / 400.));
    float3 karo = float3 (1 , 1 , 1);
    karo -= .5 * float3 (.25 , .1 , .1) * dot(exp(-s * s * 80.) , float2 (1 , 1));
    float r = length(pos - _ScreenParams.xy * .5) / _ScreenParams.x;
    float vign = 1. - r * r * r;
     fragColor = float4 (float3 (col.x * col2 * 1. * vign) , 1);
     // fragColor = getCol ( fragCoord ) ; 
     //fragColor.xyz -= 0.1;
 return fragColor*5;
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