Shader "UmutBebek/URP/ShaderToy/Volumetric explosion lsySzd"
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

            // "Volumetric explosion" by Duke 
// https: // www.shadertoy.com / view / lsySzd 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// Based on "Supernova remnant" ( https: // www.shadertoy.com / view / MdKXzc ) 
// and other previous shaders 
// otaviogood's "Alien Beacon" ( https: // www.shadertoy.com / view / ld2SzK ) 
// and Shane's "Cheap Cloud Flythrough" ( https: // www.shadertoy.com / view / Xsc3R4 ) shaders 
// Some ideas came from other shaders from this wonderful site 
// Press 1 - 2 - 3 to zoom in and zoom out. 
// License: Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

// comment this string to see each part in full screen 
#define BOTH 
 // uncomment this string to see left part 
 // #define LEFT 

 // #define LOW_QUALITY 

#define DITHERING 

 // #define TONEMAPPING 

 // -- -- -- -- -- -- -- -- -- - 
#define pi 3.14159265 
#define R(p,a) p=cos(a)*p+sin(a)*float2(p.y,-p.x)

 // iq's noise 
float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return 1. - 0.82 * lerp(rg.x , rg.y , f.z);
 }

float fbm(float3 p)
 {
   return noise(p * .06125) * .5 + noise(p * .125) * .25 + noise(p * .25) * .125 + noise(p * .4) * .2;
 }

float Sphere(float3 p , float r)
 {
    return length(p) - r;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// otaviogood's noise from https: // www.shadertoy.com / view / ld2SzK 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// This spiral noise works by successively adding and rotating sin waves while increasing frequency. 
// It should work the same on all computers since it's not based on a hash function like some other noises. 
// It can be much faster than other noise functions if you're ok with some repetition. 
const float nudge = 4.; // size of perpendicular vector 
float normalizer = 1.0 / sqrt(1.0 + 4 * 4); // pythagorean theorem on that perpendicular to maintain scale 
float SpiralNoiseC(float3 p)
 {
    float n = -mod(_Time.y * 0.2 , -2.); // noise amount 
    float iter = 2.0;
    for (int i = 0; i < 8; i++)
     {
        // add sin and cos scaled inverse with the frequency 
       n += -abs(sin(p.y * iter) + cos(p.x * iter)) / iter; // abs for a ridged look 
        // rotate by adding perpendicular and scaling down 
       p.xy += float2 (p.y , -p.x) * nudge;
       p.xy *= normalizer;
       // rotate on other axis 
      p.xz += float2 (p.z , -p.x) * nudge;
      p.xz *= normalizer;
      // increase the frequency 
     iter *= 1.733733;
  }
 return n;
}

float VolumetricExplosion(float3 p)
 {
    float final = Sphere(p , 4.);
    #ifdef LOW_QUALITY 
    final += noise(p * 12.5) * .2;
    #else 
    final += fbm(p * 50.);
    #endif 
    final += SpiralNoiseC(p.zxy * 0.4132 + 333.) * 3.0; // 1.25 ; 

    return final;
 }

float map(float3 p)
 {
     R(p.xz , iMouse.x * 0.008 * pi + _Time.y * 0.1);

     float VolExplosion = VolumetricExplosion(p / 0.5) * 0.5; // scale 

     return VolExplosion;
 }
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

// assign color to the media 
float3 computeColor(float density , float radius)
 {
    // color based on density alone , gives impression of occlusion within 
    // the media 
   float3 result = lerp(float3 (1.0 , 0.9 , 0.8) , float3 (0.4 , 0.15 , 0.1) , density);

   // color added to the media 
  float3 colCenter = 7. * float3 (0.8 , 1.0 , 1.0);
  float3 colEdge = 1.5 * float3 (0.48 , 0.53 , 0.5);
  result *= lerp(colCenter , colEdge , min((radius + .05) / .9 , 1.15));

  return result;
}

bool RaySphereIntersect(float3 org , float3 dir , out float near , out float far)
 {
     float b = dot(dir , org);
     float c = dot(org , org) - 8.;
     float delta = b * b - c;
     if (delta < 0.0)
          return false;
     float deltasqrt = sqrt(delta);
     near = -b - deltasqrt;
     far = -b + deltasqrt;
     return far > 0.0;
 }

// Applies the filmic curve from John Hable's presentation 
// More details at : http: // filmicgames.com / archives / 75 
float3 ToneMapFilmicALU(float3 _color)
 {
     _color = max(float3 (0 , 0 , 0) , _color - float3 (0.004 , 0.004 , 0.004));
     _color = (_color * (6.2 * _color + float3 (0.5 , 0.5 , 0.5))) / (_color * (6.2 * _color + float3 (1.7 , 1.7 , 1.7)) + float3 (0.06 , 0.06 , 0.06));
     return _color;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    const float KEY_1 = 49.5 / 256.0;
     const float KEY_2 = 50.5 / 256.0;
     const float KEY_3 = 51.5 / 256.0;
    float key = 0.0;
    key += 0.7 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (KEY_1 , 0.25)).x;
    key += 0.7 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (KEY_2 , 0.25)).x;
    key += 0.7 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (KEY_3 , 0.25)).x;

    float2 uv = fragCoord / _ScreenParams.xy;

    // ro: ray origin 
    // rd: direction of the ray 
   float3 rd = normalize(float3 (((fragCoord.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y).x , ((fragCoord.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y).y , 1.));
   float3 ro = float3 (0. , 0. , -6. + key * 1.6);

   // ld , td: local , total density 
   // w: weighting factor 
  float ld = 0. , td = 0. , w = 0.;

  // t: length of the ray 
  // d: distance function 
 float d = 1. , t = 0.;

const float h = 0.1;

 float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);

float min_dist = 0.0 , max_dist = 0.0;

if (RaySphereIntersect(ro , rd , min_dist , max_dist))
 {

 t = min_dist * step(t , min_dist);

 // raymarch loop 
#ifdef LOW_QUALITY 
 for (int i = 0; i < 56; i++)
#else 
for (int i = 0; i < 86; i++)
#endif 
  {

      float3 pos = ro + t * rd;

      // Loop break conditions. 
    if (td > 0.9 || d < 0.12 * t || t > 10. || sum.a > 0.99 || t > max_dist) break;

    // evaluate distance function 
   float d = map(pos);

   #ifdef BOTH 
   /*
  if ( uv.x < 0.5 )
   {
      d = abs ( d ) + 0.07 ;
   }
   */
  d = uv.x < 0.5 ? abs(d) + 0.07 : d;
  #else 
  #ifdef LEFT 
  d = abs(d) + 0.07;
  #endif 
    #endif 

  // change this string to control density 
 d = max(d , 0.03);

 // pointExtended light calculations 
float3 ldst = float3 (0.0 , 0.0 , 0.0) - pos;
float lDist = max(length(ldst) , 0.001);

// the color of light 
float3 lightColor = float3 (1.0 , 0.5 , 0.25);

sum.rgb += (lightColor / exp(lDist * lDist * lDist * .08) / 30.); // bloom 

  if (d < h)
   {
      // compute local density 
     ld = h - d;

     // compute weighting factor 
       w = (1. - td) * ld;

       // accumulate density 
      td += w + 1. / 200.;

      float4 col = float4 ((computeColor(td , lDist)).x , (computeColor(td , lDist)).y , (computeColor(td , lDist)).z , td);

      // emission 
     sum += sum.a * float4 ((sum.rgb).x , (sum.rgb).y , (sum.rgb).z , 0.0) * 0.2 / lDist;

     // uniform scale density 
    col.a *= 0.2;
    // colour by alpha 
   col.rgb *= col.a;
   // alpha blend in contribution 
  sum = sum + col * (1.0 - sum.a);

}

td += 1. / 70.;

#ifdef DITHERING 
// idea from https: // www.shadertoy.com / view / lsj3Dw 
float2 uvd = uv;
uvd.y *= 120.;
uvd.x *= 280.;
d = abs(d) * (.8 + 0.08 * SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , float2 (uvd.y , -uvd.x + 0.5 * sin(4. * _Time.y + uvd.y * 4.0))).r);
#endif 

// trying to optimize step size 
#ifdef LOW_QUALITY 
t += max(d * 0.25 , 0.01);
#else 
t += max(d * 0.08 * max(min(length(ldst) , d) , 2.0) , 0.01);
#endif 


}

// simple scattering 
#ifdef LOW_QUALITY 
sum *= 1. / exp(ld * 0.2) * 0.9;
#else 
sum *= 1. / exp(ld * 0.2) * 0.8;
#endif 

    sum = clamp(sum , 0.0 , 1.0);

sum.xyz = sum.xyz * sum.xyz * (3.0 - 2.0 * sum.xyz);

  }

#ifdef TONEMAPPING 
fragColor = float4 ((ToneMapFilmicALU(sum.xyz * 2.2)).x , (ToneMapFilmicALU(sum.xyz * 2.2)).y , (ToneMapFilmicALU(sum.xyz * 2.2)).z , 1.0);
 #else 
fragColor = float4 ((sum.xyz).x , (sum.xyz).y , (sum.xyz).z , 1.0);
 #endif 
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