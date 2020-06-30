Shader "UmutBebek/URP/ShaderToy/Apple XdfGRn"
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

               // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float hash(float n)
 {
    return frac(sin(n) * 4121.15393);
 }

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);

    f = f * f * (3.0 - 2.0 * f);

    float n = p.x + p.y * 157.0 + 113.0 * p.z;

    return lerp(lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                   lerp(hash(n + 157.0) , hash(n + 158.0) , f.x) , f.y) ,
               lerp(lerp(hash(n + 113.0) , hash(n + 114.0) , f.x) ,
                   lerp(hash(n + 270.0) , hash(n + 271.0) , f.x) , f.y) , f.z);
 }

float3x3 m = float3x3(0.00, 0.80, 0.60,
    -0.80, 0.36, -0.48,
    -0.60, -0.48, 0.64);

float fbm(float3 p)
 {
    float f = 0.0;

    f += 0.5000 * noise(p); 
    p = mul(m , p) * 2.02;
    f += 0.2500 * noise(p); 
    p = mul(m, p) * 2.03;
    f += 0.1250 * noise(p); 
    p = mul(m, p) * 2.01;
    f += 0.0625 * noise(p);

    return f / 0.9375;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float2 map(float3 p)
 {
    // table 
   float2 d2 = float2 (p.y + 0.55 , 2.0);

   // apple 
  p.y -= 0.75 * pow(dot(p.xz , p.xz) , 0.2);
  float2 d1 = float2 (length(p) - 1.0 , 1.0);

  // union 
 return (d2.x < d1.x) ? d2 : d1;
}

float3 appleColor(in float3 pos , in float3 nor , out float2 spe)
 {
    spe.x = 1.0;
    spe.y = 1.0;

    float a = atan2(pos.x , pos.z);
    float r = length(pos.xz);

    // redExtended 
   float3 col = float3 (1.0 , 0.0 , 0.0);

   // greenExtended 
  float f = smoothstep(0.4 , 1.0 , fbm(pos * 1.0));
  col = lerp(col , float3 (0.9 , 0.9 , 0.2) , f);

  // dirty 
 f = smoothstep(0.0 , 1.0 , fbm(pos * 4.0));
 col *= 0.8 + 0.2 * f;

 // frekles 
f = smoothstep(0.0 , 1.0 , fbm(pos * 48.0));
f = smoothstep(0.6 , 1.0 , f);
col = lerp(col , float3 (0.9 , 0.9 , 0.6) , f * 0.4);

// stripes 
f = fbm(float3 (a * 7.0 + pos.z , 3.0 * pos.y , pos.x) * 2.0);
f = smoothstep(0.2 , 1.0 , f);
f *= smoothstep(0.4 , 1.2 , pos.y + 0.75 * (noise(4.0 * pos.zyx) - 0.5));
col = lerp(col , float3 (0.4 , 0.2 , 0.0) , 0.5 * f);
spe.x *= 1.0 - 0.35 * f;
spe.y = 1.0 - 0.5 * f;

// top 
f = 1.0 - smoothstep(0.14 , 0.2 , r);
col = lerp(col , float3 (0.6 , 0.6 , 0.5) , f);
spe.x *= 1.0 - f;


float ao = 0.5 + 0.5 * nor.y;
col *= ao * 1.2;

return col;
}

float3 floorColor(in float3 pos , in float3 nor , out float2 spe)
 {
    spe.x = 1.0;
    spe.y = 1.0;
    float3 col = float3 (0.5 , 0.4 , 0.3) * 1.7;

    float f = fbm(4.0 * pos * float3 (6.0 , 0.0 , 0.5));
    col = lerp(col , float3 (0.3 , 0.2 , 0.1) * 1.7 , f);
    spe.y = 1.0 + 4.0 * f;

    f = fbm(2.0 * pos);
    col *= 0.7 + 0.3 * f;

    // frekles 
   f = smoothstep(0.0 , 1.0 , fbm(pos * 48.0));
   f = smoothstep(0.7 , 0.9 , f);
   col = lerp(col , float3 (0.2 , 0.2 , 0.2) , f * 0.75);

   // fake ao 
  f = smoothstep(0.1 , 1.55 , length(pos.xz));
  col *= f * f * 1.4;
  col.x += 0.1 * (1.0 - f);
  return col;
}

float2 intersect(in float3 ro , in float3 rd)
 {
    float t = 0.0;
    float dt = 0.06;
    float nh = 0.0;
    float lh = 0.0;
    float lm = -1.0;
    for (int i = 0; i < 128; i++)
     {
        float2 ma = map(ro + rd * t);
        nh = ma.x;
        if (nh > 0.0) { lh = nh; t += dt; } lm = ma.y;
     }

    if (nh > 0.0) return float2 (-1.0, -1.0);
    t = t - dt * nh / (nh - lh);

    return float2 (t , lm);
 }

float softshadow(in float3 ro , in float3 rd , float mint , float maxt , float k)
 {
    float res = 1.0;
    float dt = 0.1;
    float t = mint;
    for (int i = 0; i < 30; i++)
     {
        float h = map(ro + rd * t).x;
        h = max(h , 0.0);
        res = min(res , smoothstep(0.0 , 1.0 , k * h / t));
        t += dt;
          if (h < 0.001) break;
     }
    return res;
 }

float3 calcNormal(in float3 pos)
 {
    float2 eps = float2 (.001 , 0.0);
    return normalize(float3 (map(pos + eps.xyy).x - map(pos - eps.xyy).x ,
                           map(pos + eps.yxy).x - map(pos - eps.yxy).x ,
                           map(pos + eps.yyx).x - map(pos - eps.yyx).x));
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = -1.0 + 2.0 * q;
    p.x *= _ScreenParams.x / _ScreenParams.y;

    // camera 
   float3 ro = 2.5 * normalize(float3 (cos(0.2 * _Time.y) , 0.9 + 0.3 * cos(_Time.y * .11) ,
                                         sin(0.2 * _Time.y)));
   float3 ww = normalize(float3 (0.0 , 0.5 , 0.0) - ro);
   float3 uu = normalize(cross(float3 (0.0 , 1.0 , 0.0) , ww));
   float3 vv = normalize(cross(ww , uu));
   float3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww);

   // raymarch 
  float3 col = float3 (0.96 , 0.98 , 1.0);
  float2 tmat = intersect(ro , rd);
  if (tmat.y > 0.5)
   {
      // geometry 
     float3 pos = ro + tmat.x * rd;
     float3 nor = calcNormal(pos);
     float3 ref = reflect(rd , nor);
     float3 lig = normalize(float3 (1.0 , 0.8 , -0.6));

     float con = 1.0;
     float amb = 0.5 + 0.5 * nor.y;
     float dif = max(dot(nor , lig) , 0.0);
     float bac = max(0.2 + 0.8 * dot(nor , float3 (-lig.x , lig.y , -lig.z)) , 0.0);
     float rim = pow(1.0 + dot(nor , rd) , 3.0);
     float spe = pow(clamp(dot(lig , ref) , 0.0 , 1.0) , 16.0);

     // shadow 
    float sh = softshadow(pos , lig , 0.06 , 4.0 , 6.0);

    // lights 
   col = 0.10 * con * float3 (0.80 , 0.90 , 1.00);
   col += 0.70 * dif * float3 (1.00 , 0.97 , 0.85) * float3 (sh , (sh + sh * sh) * 0.5 , sh * sh);
   col += 0.15 * bac * float3 (1.00 , 0.97 , 0.85);
   col += 0.50 * amb * float3 (0.10 , 0.15 , 0.20);

   // color 
  float2 pro;
  if (tmat.y < 1.5)
  col *= appleColor(pos , nor , pro);
  else
  col *= floorColor(pos , nor , pro);

  // rim and spec 
 col += 0.70 * rim * float3 (1.0 , 0.9 , 0.8) * amb * amb * amb;
 col += 0.60 * pow(spe , pro.y) * float3 (1.0 , 1.0 , 1.0) * pro.x * sh;

 // gamma 
col = sqrt(col);
}

  // vignetting 
 col *= 0.25 + 0.75 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.15);

 fragColor = float4 (col , 1.0);
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