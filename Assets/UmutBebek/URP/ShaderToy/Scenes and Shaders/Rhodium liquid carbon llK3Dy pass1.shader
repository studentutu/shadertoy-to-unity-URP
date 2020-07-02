Shader "UmutBebek/URP/ShaderToy/Rhodium liquid carbon llK3Dy pass1"
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
            Tags{"RenderType" = "Transparent" 
            "RenderPipeline" = "UniversalRenderPipeline" 
            "IgnoreProjector" = "True"
        "Queue" = "Transparent"}
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
            Blend One Zero
            ZWrite Off ZTest Always
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

           // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
// Alcatraz / Rhodium 4k Intro liquid carbon 
// by Jochen "Virgill" Feldkötter 
// 
// 4kb executable: http: // www.pouet.net / prod.php?which = 68239 
// Youtube: https: // www.youtube.com / watch?v = YK7fbtQw3ZU 
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

#define time _Time.y 
#define res _ScreenParams 

float bounce;

// signed box 
float sdBox(float3 p , float3 b)
 {
  float3 d = abs(p) - b;
  return min(max(d.x , max(d.y , d.z)) , 0.) + length(max(d , 0.));
 }

// rotation 
void pR(inout float2 p , float a)
 {
     p = cos(a) * p + sin(a) * float2 (p.y , -p.x);
 }

// 3D noise function ( IQ ) 
float noise(float3 p)
 {
     float3 ip = floor(p);
    p -= ip;
    float3 s = float3 (7 , 157 , 113);
    float4 h = float4 (0. , s.yz , s.y + s.z) + dot(ip , s);
    p = p * p * (3. - 2. * p);
    h = lerp(frac(sin(h) * 43758.5) , frac(sin(h + s.x) * 43758.5) , p.x);
    h.xy = lerp(h.xz , h.yw , p.y);
    return lerp(h.x , h.y , p.z);
 }

float map(float3 p)
 {
     p.z -= 1.0;
    p *= 0.9;
    pR(p.yz , bounce * 1. + 0.4 * p.x);
    return sdBox(p + float3 (0 , sin(1.6 * time) , 0) , float3 (20.0 , 0.05 , 1.2)) - .4 * noise(8. * p + 3. * bounce);
 }

// normal calculation 
float3 calcNormal(float3 pos)
 {
    float eps = 0.0001;
     float d = map(pos);
     return normalize(float3 (map(pos + float3 (eps , 0 , 0)) - d , map(pos + float3 (0 , eps , 0)) - d , map(pos + float3 (0 , 0 , eps)) - d));
 }


// standard sphere tracing inside and outside 
float castRayx(float3 ro , float3 rd)
 {
    float function_sign = (map(ro) < 0.) ? -1. : 1.;
    float precis = .0001;
    float h = precis * 2.;
    float t = 0.;
     for (int i = 0; i < 120; i++)
      {
        if (abs(h) < precis || t > 12.) break;
          h = function_sign * map(ro + rd * t);
        t += h;
      }
    return t;
 }

// refraction 
float refr(float3 pos , float3 lig , float3 dir , float3 nor , float angle , out float t2 , out float3 nor2)
 {
    float h = 0.;
    t2 = 2.;
     float3 dir2 = refract(dir , nor , angle);
      for (int i = 0; i < 50; i++)
      {
          if (abs(h) > 3.) break;
          h = map(pos + dir2 * t2);
          t2 -= h;
      }
    nor2 = calcNormal(pos + dir2 * t2);
    return (.5 * clamp(dot(-lig , nor2) , 0. , 1.) + pow(max(dot(reflect(dir2 , nor2) , lig) , 0.) , 8.));
 }

// softshadow 
float softshadow(float3 ro , float3 rd)
 {
    float sh = 1.;
    float t = .02;
    float h = .0;
    for (int i = 0; i < 22; i++)
      {
        if (t > 20.) continue;
        h = map(ro + rd * t);
        sh = min(sh , 4. * h / t);
        t += h;
     }
    return sh;
 }

// main function 
half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    bounce = abs(frac(0.05 * time) - .5) * 20.; // triangle function 

     float2 uv = fragCoord.xy / res.xy;
    float2 p = uv * 2. - 1.;

    // bouncy cam every 10 seconds 
       float wobble = (frac(.1 * (time - 1.)) >= 0.9) ? frac(-time) * 0.1 * sin(30. * time) : 0.;

       // camera 
          float3 dir = normalize(float3 (2. * fragCoord.xy - res.xy , res.y));
          float3 org = float3 (0 , 2. * wobble , -3.);


          // standard sphere tracing: 
             float3 color = float3 (0. , 0. , 0.);
             float3 color2 = float3 (0. , 0. , 0.);
             float t = castRayx(org , dir);
              float3 pos = org + dir * t;
              float3 nor = calcNormal(pos);

              // lighting: 
                 float3 lig = normalize(float3 (.2 , 6. , .5));
                 // scene depth 
                    float depth = clamp((1. - 0.09 * t) , 0. , 1.);

                    float3 pos2 = float3 (0. , 0. , 0.);
                    float3 nor2 = float3 (0. , 0. , 0.);
                    if (t < 12.0)
                     {
                        float aaa = max(dot(lig, nor), 0.) + pow(max(dot(reflect(dir, nor), lig), 0.), 16.);
                         color2 = float3 (aaa,aaa,aaa);
                         color2 *= clamp(softshadow(pos , lig) , 0. , 1.); // shadow 
                            float t2;
                          color2.rgb += refr(pos , lig , dir , nor , 0.9 , t2 , nor2) * depth;
                        color2 -= clamp(.1 * t2 , 0. , 1.); // inner intensity loss 

                      }


                    float tmp = 0.;
                    float T = 1.;

                    // animation of glow intensity 
                       float intensity = 0.1 * -sin(.209 * time + 1.) + 0.05;
                        for (int i = 0; i < 128; i++)
                         {
                           float density = 0.; float nebula = noise(org + bounce);
                           density = intensity - map(org + .5 * nor2) * nebula;
                             if (density > 0.)
                              {
                                  tmp = density / 128.;
                               T *= 1. - tmp * 100.;
                                  if (T <= 0.) break;
                              }
                             org += dir * 0.078;
                        }
                        float3 basecol = float3 (1. / 1. , 1. / 4. , 1. / 16.);
                       T = clamp(T , 0. , 1.5);
                       color += basecol * exp(4. * (0.5 - T) - 0.8);
                       color2 *= depth;
                       color2 += (1. - depth) * noise(6. * dir + 0.3 * time) * .1; // subtle mist 


                    // scene depth included in alpha channel 
                       fragColor = float4 (float3 (1. * color + 0.8 * color2) * 1.3,
                           abs(0.67 - depth) * 2. + 4. * wobble);
                       fragColor.xyz -= 0.1;
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