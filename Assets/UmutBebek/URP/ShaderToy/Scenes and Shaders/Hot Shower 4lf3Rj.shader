Shader "UmutBebek/URP/ShaderToy/Hot Shower 4lf3Rj"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        sphsize("sphsize", float) = .7 // planet size 
dist("dist", float) = .27 // distance for glow and distortion 
perturb("perturb", float) = .3 // distortion amount of the flow around the planet 
displacement("displacement", float) = .015 // hot air effect 
windspeed("windspeed", float) = .4 // speed of wind flow 
steps("steps", float) = 110. // number of steps for the volumetric rendering 
stepsize("stepsize", float) = .025
brightness("brightness", float) = .43
planetcolor("planetcolor", vector) = (0.55 , 0.4 , 0.3)
fade("fade", float) = .005 // fade by distance 
glow("glow", float) = 3.5 // glow amount , mainly on hit side 
iterations("iterations", int) = 13
fractparam("fractparam", float) = .7
offset1("offset1", vector) = (1.5 , 2. , -1.5, 1.)

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
    float sphsize;
float dist;
float perturb;
float displacement;
float windspeed;
float steps;
float stepsize;
float brightness;
float4 planetcolor;
float fade;
float glow;
int iterations;
float fractparam;
float4 offset1;


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

                   float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
                   {
                       //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
                       float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
                       return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
                   }

                   // rendering params 













// fractal params 





float wind(float3 p) {
     float d = max(0. , dist - max(0. , length(p) - sphsize) / sphsize) / dist; // for distortion and glow area 
     float x = max(0.2 , p.x * 2.); // to increase glow on left side 
     p.y *= 1. + max(0. , -p.x - sphsize * .25) * 1.5; // left side distortion ( cheesy ) 
     p -= d * normalize(p) * perturb; // spheric distortion of flow 
     p += float3 (_Time.y * windspeed , 0. , 0.); // flow movement 
     p = abs(frac((p + offset1) * .1) - .5); // tile folding 
     for (int i = 0; i < iterations; i++) {
          p = abs(p) / dot(p , p) - fractparam; // the magic formula for the hot flow 
      }
     return length(p) * (1. + d * glow * x) + d * glow * x; // return the result with glow applied 
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // get ray dir 
float2 uv = fragCoord.xy / _ScreenParams.xy - .5;
float3 dir = float3 (uv , 1.);
dir.x *= _ScreenParams.x / _ScreenParams.y;
float3 from = float3 (0. , 0. , -2. + SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv * .5 + _Time.y).x * stepsize); // from + dither 

 // volumetric rendering 
float v = 0. , l = -0.0001 , t = _Time.y * windspeed * .2;
for (float r = 10.; r < steps; r++) {
     float3 p = from + r * dir * stepsize;
     float tx = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv * .2 + float2 (t , 0.)).x * displacement; // hot air effect 
     if (length(p) - sphsize - tx > 0.)
         // outside planet , accumulate values as ray goes , applying distance fading 
             v += min(50. , wind(p)) * max(0. , 1. - r * fade);
        else if (l < 0.)
         // inside planet , get planet shading if not already 
         // loop continues because of previous problems with breaks and not always optimizes much 
             l = pow(max(.53 , dot(normalize(p) , normalize(float3 (-1. , .5 , -0.3)))) , 4.)
              * (.5 + SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , uv * float2 (2. , 1.) * (1. + p.z * .5) + float2 (tx + t * .5 , 0.)).x * 2.);
         }
   v /= steps; v *= brightness; // average values and apply bright factor 
   float3 col = float3 (v * 1.25 , v * v , v * v * v) + l * planetcolor; // set color 
   col *= 1. - length(pow(abs(uv) , float2 (5., 5.))) * 14.; // vignette ( kind of ) 
   fragColor = float4 (col, 1.0);
   fragColor.xyz -= 0.15;
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