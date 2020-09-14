Shader "UmutBebek/URP/ShaderToy/Sun surface XlSSzK"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)


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
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

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

           float3 makeDarker(float3 item) {
               return item *= 0.90;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Based on Shanes' Fiery Spikeball https: // www.shadertoy.com / view / 4lBXzy ( I think that his implementation is more understandable than the original : ) ) 
// Relief come from Siggraph workshop by Beautypi / 2015 https: // www.shadertoy.com / view / MtsSRf 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 

// #define ULTRAVIOLET 
#define DITHERING 

#define pi 3.14159265 
#define R(p,a) p = cos ( a ) * p + sin ( a ) * float2 ( p.y , - p.x ) 

 // IQ's noise 
float pn(in float3 p)
 {
    float3 ip = floor(p);
    p = frac(p);
    p *= p * (3.0 - 2.0 * p);
    float2 uv = (ip.xy + float2 (37.0 , 17.0) * ip.z) + p.xy;
    uv = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
    return lerp(uv.x , uv.y , p.z);
 }

// FBM 
float fpn(float3 p) {
    return pn(p * .06125) * .57 + pn(p * .125) * .28 + pn(p * .25) * .15;
 }

float rand(float2 co) { // implementation found at: lumina.sourceforge.net / Tutorials / Noise.html 
     return frac(sin(dot(co * 0.123 , float2 (12.9898 , 78.233))) * 43758.5453);
 }

float cosNoise(in float2 p)
 {
    return 0.5 * (sin(p.x) + sin(p.y));
 }

static const float2x2 m2 = float2x2 (1.6 , -1.2 ,
                     1.2 , 1.6);

float sdTorus(float3 p , float2 t)
 {
  return length(float2 (length(p.xz) - t.x * 1.2 , p.y)) - t.y;
 }

float smin(float a , float b , float k)
 {
     float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
     return lerp(b , a , h) - k * h * (1.0 - h);
 }

float SunSurface(in float3 pos)
 {
    float h = 0.0;
    float2 q = pos.xz * 0.5;

    float s = 0.5;

    float d2 = 0.0;

    for (int i = 0; i < 6; i++)
     {
        h += s * cosNoise(q);
        q = mul(m2 , q) * 0.85;
        q += float2 (2.41 , 8.13);
        s *= 0.48 + 0.2 * h;
     }
    h *= 2.0;

    float d1 = pos.y - h;

    // rings 
   float3 r1 = mod(2.3 + pos + 1.0 , 10.0) - 5.0;
   r1.y = pos.y - 0.1 - 0.7 * h + 0.5 * sin(3.0 * _Time.y + pos.x + 3.0 * pos.z);
   float c = cos(pos.x); float s1 = 1.0; // sin ( pos.x ) ; 
   r1.xz = c * r1.xz + s1 * float2 (r1.z , -r1.x);
   d2 = sdTorus(r1.xzy , float2 (clamp(abs(pos.x / pos.z) , 0.7 , 2.5) , 0.20));


   return smin(d1 , d2 , 1.0);
}

float map(float3 p) {
   p.z += 1.;
   R(p.yz , -25.5); // - 1.0 + iMouse.y * 0.003 ) ; 
   R(p.xz , iMouse.x * 0.008 * pi + _Time.y * 0.1);
   return SunSurface(p) + fpn(p * 50. + _Time.y * 25.) * 0.45;
 }

// See "Combustible Voronoi" 
// https: // www.shadertoy.com / view / 4tlSzl 
float3 firePalette(float i) {

    float T = 1400. + 1300. * i; // Temperature range ( in Kelvin ) . 
    float3 L = float3 (7.4 , 5.6 , 4.4); // Red , greenExtended , blueExtended wavelengths ( in hundreds of nanometers ) . 
    L = pow(L , float3 (5.0, 5.0, 5.0)) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8 / L); // Exposure level. Set to "50." For "70 , " change the "5" to a "7 , " etc. 
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // p: position on the ray 
 // rd: direction of the ray 
float3 rd = normalize(float3 ((input.positionCS.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y , 1.));
float3 ro = float3 (0. , 0. , -22.);

// ld , td: local , total density 
// w: weighting factor 
float ld = 0. , td = 0. , w = 0.;

// t: length of the ray 
// d: distance function 
float d = 1. , t = 1.;

// Distance threshold. 
static const float h = .1;

// total color 
float3 tc = float3 (0. , 0. , 0.);

#ifdef DITHERING 
float2 pos = (fragCoord.xy / _ScreenParams.xy);
float2 seed = pos + frac(_Time.y);
// t = ( 1. + 0.2 * rand ( seed ) ) ; 
#endif 

 // rm loop 
for (int i = 0; i < 56; i++) {

    // Loop break conditions. Seems to work , but let me 
    // know if I've overlooked something. 
   if (td > (1. - 1. / 80.) || d < 0.001 * t || t > 40.) break;

   // evaluate distance function 
  d = map(ro + t * rd);

  // fix some holes deep inside 
  // d = max ( d , - .3 ) ; 

  // check whether we are close enough ( step ) 
  // compute local density and weighting factor 
  // static const float h = .1 ; 
 ld = (h - d) * step(d , h);
 w = (1. - td) * ld;

 // accumulate color and density 
tc += w * w + 1. / 50.; // Different weight distribution. 
td += w + 1. / 200.;

// dithering implementation come from Eiffies' https: // www.shadertoy.com / view / MsBGRh 
#ifdef DITHERING 
#ifdef ULTRAVIOLET 
 // enforce minimum stepsize 
d = max(d , 0.04);
// add in noise to reduce banding and create fuzz 
d = abs(d) * (1. + 0.28 * rand(seed * float2 (i)));
#else 
 // add in noise to reduce banding and create fuzz 
d = abs(d) * (.8 + 0.28 * rand(seed * float2 (i, i)));
// enforce minimum stepsize 
d = max(d , 0.04);
#endif 
#else 
 // enforce minimum stepsize 
d = max(d , 0.04);
#endif 

// step forward 
t += d * 0.5;

}

// Fire palette. 
tc = firePalette(tc.x);

#ifdef ULTRAVIOLET 
tc *= 1. / exp(ld * 2.82) * 1.05;
#endif 

fragColor = float4 (tc , 1.0);
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