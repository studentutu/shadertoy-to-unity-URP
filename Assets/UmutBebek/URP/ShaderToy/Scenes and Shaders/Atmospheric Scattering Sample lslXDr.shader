Shader "UmutBebek/URP/ShaderToy/Atmospheric Scattering Sample lslXDr"
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

           // Written by GLtracy 

// math static const 
static const float MAX = 10000.0;

// ray intersects sphere 
// e = - b + / - sqrt ( b^2 - c ) 
float2 ray_vs_sphere(float3 p , float3 dir , float r) {
     float b = dot(p , dir);
     float c = dot(p , p) - r * r;

     float d = b * b - c;
     if (d < 0.0) {
          return float2 (MAX , -MAX);
      }
     d = sqrt(d);

     return float2 (-b - d , -b + d);
 }

// Mie 
// g : ( - 0.75 , - 0.999 ) 
// 3 * ( 1 - g^2 ) 1 + c^2 
// F = -- -- -- -- -- -- -- -- - * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// 8pi * ( 2 + g^2 ) ( 1 + g^2 - 2 * g * c ) ^ ( 3 / 2 ) 
float phase_mie(float g , float c , float cc) {
     float gg = g * g;

     float a = (1.0 - gg) * (1.0 + cc);

     float b = 1.0 + gg - 2.0 * g * c;
     b *= sqrt(b);
     b *= 2.0 + gg;

     return (3.0 / 8.0 / PI) * a / b;
 }

// Rayleigh 
// g : 0 
// F = 3 / 16PI * ( 1 + c^2 ) 
float phase_ray(float cc) {
     return (3.0 / 16.0 / PI) * (1.0 + cc);
 }

// scatter static const 
static const float R_INNER = 1.0;
static const float R = R_INNER + 0.5;

static const int NUM_OUT_SCATTER = 8;
static const int NUM_IN_SCATTER = 80;

float density(float3 p , float ph) {
     return exp(-max(length(p) - R_INNER , 0.0) / ph);
 }

float optic(float3 p , float3 q , float ph) {
     float3 s = (q - p) / float(NUM_OUT_SCATTER);
     float3 v = p + s * 0.5;

     float sum = 0.0;
     for (int i = 0; i < NUM_OUT_SCATTER; i++) {
          sum += density(v , ph);
          v += s;
      }
     sum *= length(s);

     return sum;
 }

float3 in_scatter(float3 o , float3 dir , float2 e , float3 l) {
     static const float ph_ray = 0.05;
    static const float ph_mie = 0.02;

    static const float3 k_ray = float3 (3.8 , 13.5 , 33.1);
    static const float3 k_mie = float3 (21.0, 21.0, 21.0);
    static const float k_mie_ex = 1.1;

     float3 sum_ray = float3 (0.0 , 0.0 , 0.0);
    float3 sum_mie = float3 (0.0 , 0.0 , 0.0);

    float n_ray0 = 0.0;
    float n_mie0 = 0.0;

     float len = (e.y - e.x) / float(NUM_IN_SCATTER);
    float3 s = dir * len;
     float3 v = o + dir * (e.x + len * 0.5);

    for (int i = 0; i < NUM_IN_SCATTER; i++ , v += s) {
          float d_ray = density(v , ph_ray) * len;
        float d_mie = density(v , ph_mie) * len;

        n_ray0 += d_ray;
        n_mie0 += d_mie;

#if 0 
        float2 e = ray_vs_sphere(v , l , R_INNER);
        e.x = max(e.x , 0.0);
        if (e.x < e.y) {
           continue;
         }
#endif 

        float2 f = ray_vs_sphere(v , l , R);
          float3 u = v + l * f.y;

        float n_ray1 = optic(v , u , ph_ray);
        float n_mie1 = optic(v , u , ph_mie);

        float3 att = exp(-(n_ray0 + n_ray1) * k_ray - (n_mie0 + n_mie1) * k_mie * k_mie_ex);

          sum_ray += d_ray * att;
        sum_mie += d_mie * att;
      }

     float c = dot(dir , -l);
     float cc = c * c;
    float3 scatter =
        sum_ray * k_ray * phase_ray(cc) +
          sum_mie * k_mie * phase_mie(-0.78 , c , cc);


     return 10.0 * scatter;
 }

// angle : pitch , yaw 
float3x3 rot3xy(float2 angle) {
     float2 c = cos(angle);
     float2 s = sin(angle);

     return float3x3 (
          c.y , 0.0 , -s.y ,
          s.y * s.x , c.x , c.y * s.x ,
          s.y * c.x , -s.x , c.y * c.x
      );
 }

// ray direction 
float3 ray_dir(float fov , float2 size , float2 pos) {
     float2 xy = pos - size * 0.5;

     float cot_half_fov = tan(radians(90.0 - fov * 0.5));
     float z = size.y * 0.5 * cot_half_fov;

     return normalize(float3 (xy , -z));
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // default ray dir 
float3 dir = ray_dir(45.0 , _ScreenParams.xy , fragCoord.xy);

// default ray origin 
float3 eye = float3 (0.0 , 0.0 , 3.0);

// rotate camera 
float3x3 rot = rot3xy(float2 (0.0 , _Time.y * 0.5));
dir = mul(rot , dir);
eye = mul(rot , eye);

// sun light dir 
float3 l = float3 (0.0 , 0.0 , 1.0);

float2 e = ray_vs_sphere(eye , dir , R);
if (e.x > e.y) {
     fragColor = float4 (0.0 , 0.0 , 0.0 , 1.0);
   return fragColor*0.85;
 }

float2 f = ray_vs_sphere(eye , dir , R_INNER);
e.y = min(e.y , f.x);

float3 I = in_scatter(eye , dir , e , l);

fragColor = float4 (pow(I , float3 (1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2)) , 1.0);
return fragColor * 0.85;
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