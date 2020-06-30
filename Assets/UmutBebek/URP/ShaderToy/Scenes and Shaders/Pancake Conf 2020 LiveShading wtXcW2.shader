Shader "UmutBebek/URP/ShaderToy/Pancake Conf 2020 LiveShading wtXcW2"
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


float t , st , m;
#define sat(a) clamp ( a , 0. , 1. ) 
float2 amod(float2 p , float m) { float a = mod(atan2(p.x , p.y) , m) - m * .5; return float2 (cos(a) , sin(a)) * length(p); }
float2x2 rot(float a) { float c = cos(a) , s = sin(a); return float2x2 (c , s , -s , c); }
float sphere(float3 p , float r) { return length(p) - r; }
float caps(float3 p , float h , float r) { p.y -= clamp(p.y , 0. , h); return length(p) - r; }
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // / 
// Simplex Noise 2D ( by IQ ) : https: // www.shadertoy.com / view / Msf3WH 
float2 hash(float2 p) {
     p = float2 (dot(p , float2 (127.1 , 311.7)) , dot(p , float2 (269.5 , 183.3)));
     return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
 }
float noise(in float2 p) {
    const float K1 = 0.366025404; // ( sqrt ( 3 ) - 1 ) / 2 ; 
    const float K2 = 0.211324865; // ( 3 - sqrt ( 3 ) ) / 6 ; 
     float2 i = floor(p + (p.x + p.y) * K1);
    float2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y , a.x);
    float2 o = float2 (m , 1.0 - m);
    float2 b = a - o + K2;
     float2 c = a - 1.0 + 2.0 * K2;
    float3 h = max(0.5 - float3 (dot(a , a) , dot(b , b) , dot(c , c)) , 0.0);
     float3 n = h * h * h * h * float3 (dot(a , hash(i + 0.0)) , dot(b , hash(i + o)) , dot(c , hash(i + 1.0)));
    return dot(n , float3 (70.0, 70.0, 70.0));
 }
float fnoise(float2 uv) {
    float2x2 m = float2x2 (1.6 , 1.2 , -1.2 , 1.6);
    float f = 0.5000 * noise(uv); uv = mul(m , uv);
    f += 0.2500 * noise(uv); uv = mul(m, uv);
    f += 0.1250 * noise(uv); uv = mul(m, uv);
    f += 0.0625 * noise(uv); uv = mul(m, uv);
    return f;
 }
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // / 
float scene(float3 p) {
  if (length(p) - 1.5 > .1) return .1;
  float nz = fnoise(p.xz * 8.) * .0001;

  float o = 100.;
  float3 pp = p;
  pp *= float3 (1 , 10. , 1);
  o = min(o , sphere(1.02 * pp , 1.) * .1 + nz * 2.);
  pp -= float3 (0 , 1.1 + .4 * sin(t * 6.) , 0); o = min(o , sphere(1.12 * pp , 1.) * .1 + nz * 6.);
  pp -= float3 (0 , 1.1 + .4 * sin(t * 4.) , 0); o = min(o , sphere(1.1 * pp , 1.) * .1 + nz * 6.);
  pp -= float3 (0 , 1.1 + .4 * sin(t * 10.) , 0); o = min(o , sphere(1.2 * pp , 1.) * .1 + nz * 4.);
  pp -= float3 (0 , 1.1 + .0 * sin(t * 4.) , 0); o = min(o , sphere(1.2 * pp , 1.) * .1 + nz * 4.);
  float3 p2 = p;
  p2.xz = amod(p2.xz , PI * .01);
  p2.xy = mul(p2.xy, rot(-PI * .34));
  p2 -= float3 (.55 , 0 , 0);
  float plate = caps(p2 , 1.2 - .05 * sin(p.x * p.y * p.z * 10.) , .05 - .01 * sin(p.x * p.z * 20.));
  if (plate < o) m = 5.;
  return min(o , plate);
 }
float3 camdir(float2 uv , float3 og , float3 tg , float z) {
  float3 f = normalize(tg - og);
  float3 s = normalize(cross(float3 (.3 * sin(t + sin(st)) , 1 , 0) , f));
  float3 u = normalize(cross(f , s));
  return normalize(f * z + uv.x * s + uv.y * u);
 }
float3 normal(float3 p) {
  float2 e = float2 (.001 , 0);
  return normalize(scene(p) - float3 (scene(p - e.xyy) , scene(p - e.yxy) , scene(p - e.yyx)));
 }
float pales(float2 uv , float screen , float number) {
  uv = mul(uv, rot(-t * screen));
  return floor(smoothstep(.1 , .2 , cos(atan2(uv.y , uv.x) * number)));
 }
float4 march(float3 og , float3 dir , int it , float tr , float mx) {
  float d = 0.;
  float3 p = og;
  for (int i = 0; i < it; i++) {
    float h = scene(p) * .8;
    if (abs(h) < tr || d > mx) break;
    d += h;
    p += dir * h;
   }
  return float4 (p , d);
 }
float shadow(float3 p , float3 lp) {
  float3 ldir = normalize(lp - p);
  float ldist = length(lp - p);
  float d = march(p , ldir , 100 , .0001 , 5.).w;
  if (d < ldist) {
    return .5;
   }
else {
return 1.;
}
}
half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
  float2 uv = (fragCoord.xy / _ScreenParams.xy - .5) * float2 (_ScreenParams.x / _ScreenParams.y , 1.);

  t = mod(.4 * _Time.y , 10. * PI);
  float ft = floor(t);
  float dt = frac(t);
  st = ft + dt * dt;
  m = 0.;

  float2 uv2 = uv;
  uv2.xy += .4 * float2 ((sin(st) + .2 * sin(t * 2.)) , sin(st * .5));
  float3 bg = float3 (0 , 0 , 0);
  bg += pales(uv2 , .4 , 30.);
  bg -= pales(uv2 , .2 , 28.);
  bg += pales(uv2 , -.6 , 20.);
  bg -= pales(uv2 , -.3 , 18.);
  bg = lerp(float3 (1. , .9 , .5) , float3 (1. , .4 , .1) , sat(bg));
  float ccc = 1. - length(uv2 * (1. + .2 * sin(t * 8.)));
  bg += ccc;
  bg += .05 * step(.9 , bg.ggg);
  float3 col = bg;

  float3 eye = 3. * float3 (.1 , .35 , .1);
  eye += 2. * float3 (sin(st) + .2 * sin(t * 2.) , .2 * sin(st * .5) , cos(st - sin(t)));
  float3 target = float3 (.2 * sin(st * 4.) , .1 * sin(st * 2.) , .2 * cos(st));
  float3 dir = camdir(uv , eye , target , .75);

  float3 lp = float3 (1 , 3 , -2);
  lp.xz += 1.5 * float2 (sin(t * 8.) , cos(t * 6.));

  float4 hit = march(eye , dir , 400 , .001 , 5.);
  float d = hit.w;
  if (d < 5.) {
    float3 p = hit.xyz;
    float3 n = normal(p);
    float3 ld = normalize(lp - p);
    float diff = abs(dot(n , ld));
    if (m == 0.) {
      float miaou = smoothstep(.96 , 1. , abs(n.y));
      col = diff * lerp(float3 (1. , .9 , .5) , float3 (1. , .4 , .1) , miaou);
      col -= .5 * pow(.5 + .5 * fnoise(p.xz * (5. - p.y)) , 4.);
     }
else {
float spec = sat(pow(abs(dot(dir , reflect(ld , n))) , 50.));
float fres = 1. - sat(pow(abs(1. - dot(n , -dir)) , 5.));
col = sat(float3 (.8 + spec, .8 + spec, .8 + spec) * fres) * cos(dir);
}
col *= shadow(p , lp);
}

fragColor = float4 (pow(col , float3 (1. / 2.2, 1. / 2.2, 1. / 2.2)) , 1.0);
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