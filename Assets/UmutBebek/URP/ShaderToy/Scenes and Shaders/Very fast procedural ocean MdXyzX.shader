Shader "UmutBebek/URP/ShaderToy/Very fast procedural ocean MdXyzX"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        DRAG_MULT("DRAG_MULT", float) = 0.048
ITERATIONS_RAYMARCH("ITERATIONS_RAYMARCH", float) = 13
ITERATIONS_NORMAL("ITERATIONS_NORMAL", float) = 48
H("H", float) = 0.0

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
            float DRAG_MULT;
float ITERATIONS_RAYMARCH;
float ITERATIONS_NORMAL;
float H;


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

                   // afl_ext 2017 - 2019 





#define Mouse ( iMouse.xy / _ScreenParams.xy ) 
#define Resolution ( _ScreenParams.xy ) 
#define Time ( _Time.y ) 

float2 wavedx(float2 position , float2 direction , float speed , float frequency , float timeshift) {
    float x = dot(direction , position) * frequency + timeshift * speed;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return float2 (wave , -dx);
 }

float getwaves(float2 position , int iterations) {
     float iter = 0.0;
    float phase = 6.0;
    float speed = 2.0;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for (int i = 0; i < iterations; i++) {
        float2 p = float2 (sin(iter) , cos(iter));
        float2 res = wavedx(position , p , speed , phase , Time);
        position += normalize(p) * res.y * weight * DRAG_MULT;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = lerp(weight , 0.0 , 0.2);
        phase *= 1.18;
        speed *= 1.07;
     }
    return w / ws;
 }

float raymarchwater(float3 camera , float3 start , float3 end , float depth) {
    float3 pos = start;
    float h = 0.0;
    float hupper = depth;
    float hlower = 0.0;
    float2 zer = float2 (0.0 , 0.0);
    float3 dir = normalize(end - start);
    for (int i = 0; i < 318; i++) {
        h = getwaves(pos.xz * 0.1 , ITERATIONS_RAYMARCH) * depth - depth;
        if (h + 0.01 > pos.y) {
            return distance(pos , camera);
         }
        pos += dir * (pos.y - h);
     }
    return -1.0;
 }


float3 normal(float2 pos , float e , float depth) {
    float2 ex = float2 (e , 0);
    H = getwaves(pos.xy * 0.1 , ITERATIONS_NORMAL) * depth;
    float3 a = float3 (pos.x , H , pos.y);
    return normalize(cross(normalize(a - float3 (pos.x - e , getwaves(pos.xy * 0.1 - ex.xy * 0.1 , ITERATIONS_NORMAL) * depth , pos.y)) ,
                           normalize(a - float3 (pos.x , getwaves(pos.xy * 0.1 + ex.yx * 0.1 , ITERATIONS_NORMAL) * depth , pos.y + e))));
 }
float3x3 rotmat(float3 axis , float angle)
 {
     axis = normalize(axis);
     float s = sin(angle);
     float c = cos(angle);
     float oc = 1.0 - c;
     return float3x3 (oc * axis.x * axis.x + c , oc * axis.x * axis.y - axis.z * s , oc * axis.z * axis.x + axis.y * s ,
     oc * axis.x * axis.y + axis.z * s , oc * axis.y * axis.y + c , oc * axis.y * axis.z - axis.x * s ,
     oc * axis.z * axis.x - axis.y * s , oc * axis.y * axis.z + axis.x * s , oc * axis.z * axis.z + c);
 }

float3 getRay(float2 uv) {
    uv = (uv * 2.0 - 1.0) * float2 (Resolution.x / Resolution.y , 1.0);
     float3 proj = normalize(float3 (uv.x , uv.y , 1.0) + float3 (uv.x , uv.y , -1.0) * pow(length(uv) , 2.0) * 0.05);
    if (Resolution.x < 400.0) return proj;
     float3 ray = mul(rotmat( 
         float3 (0.0 , -1.0 , 0.0) , 
         3.0 * (Mouse.x * 2.0 - 1.0)) * rotmat(float3 (1.0 , 0.0 , 0.0) , 
             1.5 * (Mouse.y * 2.0 - 1.0)) 
         , proj);
    return ray;
 }

float intersectPlane(float3 origin , float3 direction , float3 pointExtended , float3 normal)
 {
    return clamp(dot(pointExtended - origin , normal) / dot(direction , normal) , -1.0 , 9991999.0);
 }

float3 extra_cheap_atmosphere(float3 raydir , float3 sundir) {
     sundir.y = max(sundir.y , -0.07);
     float special_trick = 1.0 / (raydir.y * 1.0 + 0.1);
     float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
     float raysundt = pow(abs(dot(sundir , raydir)) , 2.0);
     float sundt = pow(max(0.0 , dot(sundir , raydir)) , 8.0);
     float mymie = sundt * special_trick * 0.2;
     float3 suncolor = lerp(float3 (1.0 , 1.0 , 1.0) , max(float3 (0.0 , 0.0 , 0.0) , float3 (1.0 , 1.0 , 1.0) - float3 (5.5 , 13.0 , 22.4) / 22.4) , special_trick2);
     float3 bluesky = float3 (5.5 , 13.0 , 22.4) / 22.4 * suncolor;
     float3 bluesky2 = max(float3 (0.0 , 0.0 , 0.0) , bluesky - float3 (5.5 , 13.0 , 22.4) * 0.002 * (special_trick + -6.0 * sundir.y * sundir.y));
     bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
     return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y , 3.0)) + mymie * suncolor;
 }
float3 getatm(float3 ray) {
      return extra_cheap_atmosphere(ray , normalize(float3 (1.0 , 1.0 , 1.0))) * 0.5;

 }

float sun(float3 ray) {
      float3 sd = normalize(float3 (1.0 , 1.0 , 1.0));
    return pow(max(0.0 , dot(ray , sd)) , 528.0) * 110.0;
 }
float3 aces_tonemap(float3 color) {
     float3x3 m1 = float3x3 (
        0.59719 , 0.07600 , 0.02840 ,
        0.35458 , 0.90834 , 0.13383 ,
        0.04823 , 0.01566 , 0.83777
      );
     float3x3 m2 = float3x3 (
        1.60475 , -0.10208 , -0.00327 ,
         -0.53108 , 1.10813 , -0.07276 ,
         -0.07367 , -0.00605 , 1.07602
      );
     float3 v = mul(m1 , color);
     float3 a = v * (v + 0.0245786) - 0.000090537;
     float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
     return pow(clamp( mul(m2 , (a / b)) , 0.0 , 1.0) , float3 (1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));
 }
half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.xy;

      float waterdepth = 2.1;
      float3 wfloor = float3 (0.0 , -waterdepth , 0.0);
      float3 wceil = float3 (0.0 , 0.0 , 0.0);
      float3 orig = float3 (0.0 , 2.0 , 0.0);
      float3 ray = getRay(uv);
      float hihit = intersectPlane(orig , ray , wceil , float3 (0.0 , 1.0 , 0.0));
     if (ray.y >= -0.01) {
         float3 C = getatm(ray) * 2.0 + sun(ray);
         // tonemapping 
         C = aces_tonemap(C);
          fragColor = float4 (C , 1.0);
          return fragColor;
     }
     float lohit = intersectPlane(orig , ray , wfloor , float3 (0.0 , 1.0 , 0.0));
    float3 hipos = orig + ray * hihit;
    float3 lopos = orig + ray * lohit;
     float dist = raymarchwater(orig , hipos , lopos , waterdepth);
    float3 pos = orig + ray * dist;

     float3 N = normal(pos.xz , 0.001 , waterdepth);
    float2 velocity = N.xz * (1.0 - N.y);
    N = lerp(float3 (0.0 , 1.0 , 0.0) , N , 1.0 / (dist * dist * 0.01 + 1.0));
    float3 R = reflect(ray , N);
    float fresnel = (0.04 + (1.0 - 0.04) * (pow(1.0 - max(0.0 , dot(-N , ray)) , 5.0)));

    float3 C = fresnel * getatm(R) * 2.0 + fresnel * sun(R);
    // tonemapping 
   C = aces_tonemap(C);

    fragColor = float4 (C , 1.0);
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