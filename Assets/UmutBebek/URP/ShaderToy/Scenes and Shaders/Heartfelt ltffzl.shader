Shader "UmutBebek/URP/ShaderToy/Heartfelt ltffzl"
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

           // Heartfelt - by Martijn Steinrucken aka BigWings - 2017 
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// I revisited the rain effect I did for another shader. This one is better in multiple ways: 
// 1. The glass gets foggy. 
// 2. Drops cut trails in the fog on the glass. 
// 3. The amount of rain is adjustable ( with Mouse.y ) 

// To have full control over the rain , uncomment the HAS_HEART define 

// A video of the effect can be found here: 
// https: // www.youtube.com / watch?v = uiF5Tlw22PI&feature = youtu.be 

// Music - Alone In The Dark - Vadim Kiselev 
// https: // soundcloud.com / ahmed - gado - 1 / sad - piano - alone - in - the - dark 
// Rain sounds: 
// https: // soundcloud.com / elirtmusic / sleeping - sound - rain - and - thunder - 1 - hours 

#define S( a , b , t ) smoothstep ( a , b , t ) 
 // #define CHEAP_NORMALS 
#define HAS_HEART 
#define USE_POST_PROCESSING 

float3 N13(float p) {
    // from DAVE HOSKINS 
  float3 p3 = frac(float3 (p, p, p) * float3 (.1031 , .11369 , .13787));
  p3 += dot(p3 , p3.yzx + 19.19);
  return frac(float3 ((p3.x + p3.y) * p3.z , (p3.x + p3.z) * p3.y , (p3.y + p3.z) * p3.x));
}

float4 N14(float t) {
     return frac(sin(t * float4 (123. , 1024. , 1456. , 264.)) * float4 (6547. , 345. , 8799. , 1564.));
 }
float N(float t) {
    return frac(sin(t * 12345.564) * 7658.76);
 }

float Saw(float b , float t) {
     return S(0. , b , t) * S(1. , b , t);
 }


float2 DropLayer2(float2 uv , float t) {
    float2 UV = uv;

    uv.y += t * 0.75;
    float2 a = float2 (6. , 1.);
    float2 grid = a * 2.;
    float2 id = floor(uv * grid);

    float colShift = N(id.x);
    uv.y += colShift;

    id = floor(uv * grid);
    float3 n = N13(id.x * 35.2 + id.y * 2376.1);
    float2 st = frac(uv * grid) - float2 (.5 , 0);

    float x = n.x - .5;

    float y = UV.y * 20.;
    float wiggle = sin(y + sin(y));
    x += wiggle * (.5 - abs(x)) * (n.z - .5);
    x *= .7;
    float ti = frac(t + n.z);
    y = (Saw(.85 , ti) - .5) * .9 + .5;
    float2 p = float2 (x , y);

    float d = length((st - p) * a.yx);

    float mainDrop = S(.4 , .0 , d);

    float r = sqrt(S(1. , y , st.y));
    float cd = abs(st.x - x);
    float trail = S(.23 * r , .15 * r * r , cd);
    float trailFront = S(-.02 , .02 , st.y - y);
    trail *= trailFront * r * r;

    y = UV.y;
    float trail2 = S(.2 * r , .0 , cd);
    float droplets = max(0. , (sin(y * (1. - y) * 120.) - st.y)) * trail2 * trailFront * n.z;
    y = frac(y * 10.) + (st.y - .5);
    float dd = length(st - float2 (x , y));
    droplets = S(.3 , 0. , dd);
    float m = mainDrop + droplets * r * trailFront;

    // m += st.x > a.y * .45 || st.y > a.x * .165 ? 1.2 : 0. ; 
   return float2 (m , trail);
}

float StaticDrops(float2 uv , float t) {
     uv *= 40.;

    float2 id = floor(uv);
    uv = frac(uv) - .5;
    float3 n = N13(id.x * 107.45 + id.y * 3543.654);
    float2 p = (n.xy - .5) * .7;
    float d = length(uv - p);

    float fade = Saw(.025 , frac(t + n.z));
    float c = S(.3 , 0. , d) * frac(n.z * 10.) * fade;
    return c;
 }

float2 Drops(float2 uv , float t , float l0 , float l1 , float l2) {
    float s = StaticDrops(uv , t) * l0;
    float2 m1 = DropLayer2(uv , t) * l1;
    float2 m2 = DropLayer2(uv * 1.85 , t) * l2;

    float c = s + m1.x + m2.x;
    c = S(.3 , 1. , c);

    return float2 (c , max(m1.y * l0 , m2.y * l1));
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 uv = (fragCoord.xy - .5 * _ScreenParams.xy) / _ScreenParams.y;
    float2 UV = fragCoord.xy / _ScreenParams.xy;
    float3 M = iMouse.xyz / _ScreenParams.xyz;
    float T = _Time.y + M.x * 2.;

    #ifdef HAS_HEART 
    T = mod(_Time.y , 102.);
    T = lerp(T , M.x * 102. , M.z > 0. ? 1. : 0.);
    #endif 


    float t = T * .2;

    float rainAmount = iMouse.z > 0. ? M.y : sin(T * .05) * .3 + .7;

    float maxBlur = lerp(3. , 6. , rainAmount);
    float minBlur = 2.;

    float story = 0.;
    float heart = 0.;

    #ifdef HAS_HEART 
    story = S(0. , 70. , T);

    t = min(1. , T / 70.); // remap drop time so it goes slower when it freezes 
    t = 1. - t;
    t = (1. - t * t) * 70.;

    float zoom = lerp(.3 , 1.2 , story); // slowly zoom out 
    uv *= zoom;
    minBlur = 4. + S(.5 , 1. , story) * 3.; // more opaque glass towards the end 
    maxBlur = 6. + S(.5 , 1. , story) * 1.5;

    float2 hv = uv - float2 (.0 , -.1); // build heart 
    hv.x *= .5;
    float s = S(110. , 70. , T); // heart gets smaller and fades towards the end 
    hv.y -= sqrt(abs(hv.x)) * .5 * s;
    heart = length(hv);
    heart = S(.4 * s , .2 * s , heart) * s;
    rainAmount = heart; // the rain is where the heart is 

    maxBlur -= heart; // inside the heart slighly less foggy 
    uv *= 1.5; // zoom out a bit more 
    t *= .25;
    #else 
    float zoom = -cos(T * .2);
    uv *= .7 + zoom * .3;
    #endif 
    UV = (UV - .5) * (.9 + zoom * .1) + .5;

    float staticDrops = S(-.5 , 1. , rainAmount) * 2.;
    float layer1 = S(.25 , .75 , rainAmount);
    float layer2 = S(.0 , .5 , rainAmount);


    float2 c = Drops(uv , t , staticDrops , layer1 , layer2);
   #ifdef CHEAP_NORMALS 
         float2 n = float2 (ddx(c.x) , ddy(c.x)); // cheap normals ( 3x cheaper , but 2 times shittier ; ) ) 
    #else 
         float2 e = float2 (.001 , 0.);
         float cx = Drops(uv + e , t , staticDrops , layer1 , layer2).x;
         float cy = Drops(uv + e.yx , t , staticDrops , layer1 , layer2).x;
         float2 n = float2 (cx - c.x , cy - c.x); // expensive normals 
    #endif 


    #ifdef HAS_HEART 
    n *= 1. - S(60. , 85. , T);
    c.y *= 1. - S(80. , 100. , T) * .8;
    #endif 

    float focus = lerp(maxBlur - c.y , minBlur , S(.1 , .2 , c.x));
    float3 col = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , UV + n , focus).rgb;


    #ifdef USE_POST_PROCESSING 
    t = (T + 3.) * .5; // make time sync with first lightnoing 
    float colFade = sin(t * .2) * .5 + .5 + story;
    col *= lerp(float3 (1. , 1. , 1.) , float3 (.8 , .9 , 1.3) , colFade); // subtle color shift 
    float fade = S(0. , 10. , T); // fade in at the start 
    float lightning = sin(t * sin(t * 10.)); // lighting flicker 
    lightning *= pow(max(0. , sin(t + sin(t))) , 10.); // lightning flash 
    col *= 1. + lightning * fade * lerp(1. , .1 , story * story); // composite lightning 
    col *= 1. - dot(UV -= .5 , UV); // vignette 

    #ifdef HAS_HEART 
         col = lerp(pow(col , float3 (1.2, 1.2, 1.2)) , col , heart);
         fade *= S(102. , 97. , T);
    #endif 

    col *= fade; // composite start and end fade 
    #endif 

     // col = float3 ( heart ) ; 
    fragColor = float4 (col , 1.);
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