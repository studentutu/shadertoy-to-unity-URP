Shader "UmutBebek/URP/ShaderToy/Simplex Trabeculae 3tXcRs"
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

             #define STEPS 256 
#define TMAX 100. 
#define PRECIS .0001 

#define r(a) float2x2( cos ( a ) , - sin ( a ) , sin ( a ) , cos ( a ) ) 

#define shaded 1

float3 hash33(float3 c , float r) {
     float3 h = .5 * normalize(frac(float3 (8. , 1. , 64.) * sin(dot(float3 (17. , 59.4 , 15.) , c)) * 32768.) - .5);
    return lerp(float3 (.4 , .4 , .4) , h , r); // attenuate randomness ( make sure everything on the path of the camera is not random ) 
 }

/* 3d simplex noise from candycat's "Noise Lab ( 3D ) " https: // www.shadertoy.com / view / 4sc3z2
based on the one by nikat: https: // www.shadertoy.com / view / XsX3zB */
float4 simplex_noise(float3 p , float r) {

    const float K1 = .333333333;
    const float K2 = .166666667;

    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);

    float3 e = step(float3 (0. , 0. , 0.) , d0 - d0.yzx);
     float3 i1 = e * (1. - e.zxy);
     float3 i2 = 1. - e.zxy * (1. - e);

    float3 d1 = d0 - (i1 - 1. * K2);
    float3 d2 = d0 - (i2 - 2. * K2);
    float3 d3 = d0 - (1. - 3. * K2);

    float4 h = max(.6 - float4 (dot(d0 , d0) , dot(d1 , d1) , dot(d2 , d2) , dot(d3 , d3)) , 0.);
    float4 n = h * h * h * h * float4 (dot(d0 , hash33(i , r)) , dot(d1 , hash33(i + i1 , r)) , dot(d2 , hash33(i + i2 , r)) , dot(d3 , hash33(i + 1. , r)));

    return 70. * n;
 }

// see https: // www.shadertoy.com / view / ttsyRB 
float4 variations(float4 n) {
    float4 an = abs(n);
    float4 s = float4 (
        dot(n , float4 (1. , 1. , 1. , 1.)) ,
        dot(an , float4 (1. , 1. , 1. , 1.)) ,
        length(n) ,
        max(max(max(an.x , an.y) , an.z) , an.w));

    float t = .27;

    return float4 (
        // worms 
       max(0. , 1.25 * (s.y * t - abs(s.x)) / t) ,
        // cells ( trabeculae ) 
      pow((1. + t) * ((1. - t) + (s.y - s.w / t) * t) , 2.) , // step ( .7 , ( 1. + t ) * ( ( 1. - t ) + ( s.y - s.w / t ) * t ) ) , 
       .75 * s.y ,
      .5 + .5 * s.x);
}

float map(float3 p) {
    float c = smoothstep(0. , 1. , length(p.xy) - .1); // controls the randomness 
    p += float3 (-.65 , .35 , 44.85);
    float s = 1.;
    float n = variations(simplex_noise(p * s * .5 , c)).y;
    n = .78 - n;
    n /= s * 4.;

    return n;
 }

float march(float3 ro , float3 rd) {
     float t = .01;
    for (int i; i < STEPS; i++) {
        float h = map(ro + rd * t);
        t += h;
        if (t > TMAX || abs(h) < PRECIS) break;
     }
    return t;
 }

float3 normal(float3 p) {
    float2 e = float2 (.4 , 0);
    return normalize(
        map(p) - float3 (
        map(p - e.xyy) ,
        map(p - e.yxy) ,
        map(p - e.yyx)
         ));
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = (fragCoord - .5 * _ScreenParams.xy) / _ScreenParams.y;

    float3 ro; ro.z = _Time.y * .67;
    float3 rd = float3 ((uv).x , (uv).y , .5);

    float3 l = normalize(float3 (-3 , 2 , 1));

    float fc = exp2(.5 * dot(rd , l)) * .5;

     float t = march(ro , rd);
    float3 p = ro + rd * t;

    float dif;
#if shaded 
    float3 n = normal(p);
    dif = dot(n , l) * .5 + .5;
    dif *= .125;
#endif 

    float fog = pow(1. - .05 / (t * .75 + .5) , 25.);
    float v = lerp(dif , fc , fog);
    v *= v;

    float3 col = 1. - float3 (.67 , .45 , .05);
    col = pow(float3 (v , v , v) , col * 1.5);

    // subtle SAMPLE_TEXTURE2D 
  col += .004 * (SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord * .001 * r(.2) + .1).x - .5)
         + .008 * (SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord * .002 * r(.3) + .1).x - .5)
         + .015 * (SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord * .004 * r(.5) + .1).x - .5)
         + .03 * (SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord * .008 * r(.7) + .1).x - .5);

  col = smoothstep(0. , 1. , 2.3 * col);

  fragColor = float4 ((col).x , (col).y , (col).z , 1);
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