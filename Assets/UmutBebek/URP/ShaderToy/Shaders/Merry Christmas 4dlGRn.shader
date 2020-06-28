Shader "UmutBebek/URP/ShaderToy/Merry Christmas 4dlGRn"
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

           // Merry Christmas! by @paulofalcao 

// Util Start 

//float PI = 3.14159265;

float2 ObjUnion(float2 obj0 , float2 obj1) {
  if (obj0.x < obj1.x)
    return obj0;
  else
    return obj1;
 }

float3 sim(float3 p , float s) {
   float3 ret = p;
   ret = p + s / 2.0;
   ret = frac(ret / s) * s - s / 2.0;
   return ret;
 }

float2 rot(float2 p , float r) {
   float2 ret;
   ret.x = p.x * cos(r) - p.y * sin(r);
   ret.y = p.x * sin(r) + p.y * cos(r);
   return ret;
 }

float2 rotsim(float2 p , float s) {
   float2 ret = p;
   ret = rot(p , -PI / (s * 2.0));
   ret = rot(p , floor(atan2(ret.x , ret.y) / PI * s) * (PI / s));
   return ret;
 }

float rnd(float2 v) {
  return sin((sin(((v.y - 1453.0) / (v.x + 1229.0)) * 23232.124)) * 16283.223) * 0.5 + 0.5;
 }

float noise(float2 v) {
  float2 v1 = floor(v);
  float2 v2 = smoothstep(0.0 , 1.0 , frac(v));
  float n00 = rnd(v1);
  float n01 = rnd(v1 + float2 (0 , 1));
  float n10 = rnd(v1 + float2 (1 , 0));
  float n11 = rnd(v1 + float2 (1 , 1));
  return lerp(lerp(n00 , n01 , v2.y) , lerp(n10 , n11 , v2.y) , v2.x);
 }

// Util End 


// Scene Start 

// Floor 
float2 obj0(in float3 p) {
  if (p.y < 0.4)
  p.y += sin(p.x) * 0.4 * cos(p.z) * 0.4;
  return float2 (p.y , 0);
 }

float3 obj0_c(float3 p) {
  float f =
    noise(p.xz) * 0.5 +
    noise(p.xz * 2.0 + 13.45) * 0.25 +
    noise(p.xz * 4.0 + 23.45) * 0.15;
  float pc = min(max(1.0 / length(p.xz) , 0.0) , 1.0) * 0.5;
  return float3 (f,f,f) * 0.3 + pc + 0.5;
 }

// Snow 
float makeshowflake(float3 p) {
  return length(p) - 0.03;
 }

float makeShow(float3 p , float tx , float ty , float tz) {
  p.y = p.y + _Time.y * tx;
  p.x = p.x + _Time.y * ty;
  p.z = p.z + _Time.y * tz;
  p = sim(p , 4.0);
  return makeshowflake(p);
 }

float2 obj1(float3 p) {
  float f = makeShow(p , 1.11 , 1.03 , 1.38);
  f = min(f , makeShow(p , 1.72 , 0.74 , 1.06));
  f = min(f , makeShow(p , 1.93 , 0.75 , 1.35));
  f = min(f , makeShow(p , 1.54 , 0.94 , 1.72));
  f = min(f , makeShow(p , 1.35 , 1.33 , 1.13));
  f = min(f , makeShow(p , 1.55 , 0.23 , 1.16));
  f = min(f , makeShow(p , 1.25 , 0.41 , 1.04));
  f = min(f , makeShow(p , 1.49 , 0.29 , 1.31));
  f = min(f , makeShow(p , 1.31 , 1.31 , 1.13));
  return float2 (f , 1.0);
 }

float3 obj1_c(float3 p) {
    return float3 (1 , 1 , 1);
 }


// Star 
float2 obj2(float3 p) {
  p.y = p.y - 4.3;
  p = p * 4.0;
  float l = length(p);
  if (l < 2.0) {
  p.xy = rotsim(p.xy , 2.5);
  p.y = p.y - 2.0;
  p.z = abs(p.z);
  p.x = abs(p.x);
  return float2 (dot(p , normalize(float3 (2.0 , 1 , 3.0))) / 4.0 , 2);
   }
else return float2 ((l - 1.9) / 4.0 , 2.0);
}

float3 obj2_c(float3 p) {
  return float3 (1.0 , 0.5 , 0.2);
 }

// Objects union 
float2 inObj(float3 p) {
  return ObjUnion(ObjUnion(obj0(p) , obj1(p)) , obj2(p));
 }

// Scene End 

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
  float2 vPos = -1.0 + 2.0 * fragCoord.xy / _ScreenParams.xy;

  // Camera animation 
 float3 vuv = normalize(float3 (sin(_Time.y) * 0.3 , 1 , 0));
 float3 vrp = float3 (0 , cos(_Time.y * 0.5) + 2.5 , 0);
 float3 prp = float3 (sin(_Time.y * 0.5) * (sin(_Time.y * 0.39) * 2.0 + 3.5) , sin(_Time.y * 0.5) + 3.5 , cos(_Time.y * 0.5) * (cos(_Time.y * 0.45) * 2.0 + 3.5));
 float vpd = 1.5;

 // Camera setup 
float3 vpn = normalize(vrp - prp);
float3 u = normalize(cross(vuv , vpn));
float3 v = cross(vpn , u);
float3 scrCoord = prp + vpn * vpd + vPos.x * u * _ScreenParams.x / _ScreenParams.y + vPos.y * v;
float3 scp = normalize(scrCoord - prp);

float maxl = 80.0;

// lights are 2d , no raymarching 
float4x4 cm = float4x4 (
  u.x , u.y , u.z , -dot(u , prp) ,
  v.x , v.y , v.z , -dot(v , prp) ,
  vpn.x , vpn.y , vpn.z , -dot(vpn , prp) ,
  0.0 , 0.0 , 0.0 , 1.0);

float4 pc = float4 (0 , 0 , 0 , 0);
 
for (float i = 0.0; i < maxl; i++) {
float4 pt = float4 (
  sin(i * PI * 2.0 * 7.0 / maxl) * 2.0 * (1.0 - i / maxl) ,
  i / maxl * 4.0 ,
  cos(i * PI * 2.0 * 7.0 / maxl) * 2.0 * (1.0 - i / maxl) ,
  1.0);
pt = mul(pt , cm);
float2 xy = (pt / (-pt.z / vpd)).xy + vPos * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);
float c;
c = 0.4 / length(xy);
pc += float4 (
         (sin(i * 5.0 + _Time.y * 10.0) * 0.5 + 0.5) * c ,
         (cos(i * 3.0 + _Time.y * 8.0) * 0.5 + 0.5) * c ,
         (sin(i * 6.0 + _Time.y * 9.0) * 0.5 + 0.5) * c , 0.0);
 }
pc = pc / maxl;

pc = smoothstep(0.0 , 1.0 , pc);

// Raymarching 
float3 e = float3 ( 0.1 , 0 , 0 ) ; 
float maxd = 15.0; // Max depth 

float2 s = float2 (0.1 , 0.0);
float3 c , p , n;

float f = 1.0;
for (int i = 0; i < 64; i++) {
  if (abs(s.x) < .001 || f > maxd) break;
  f += s.x;
  p = prp + scp * f;
  s = inObj(p);
 }

if (f < maxd) {
  if (s.y == 0.0)
    c = obj0_c(p);
  else if (s.y == 1.0)
    c = obj1_c(p);
  else
    c = obj2_c(p);
    if (s.y <= 1.0) {
      fragColor = float4 (c * max(1.0 - f * .08 , 0.0) , 1.0) + pc;
     }
else {
        // tetrahedron normal 
       const float n_er = 0.01 ; 
       float v1 = inObj(float3 (p.x + n_er , p.y - n_er , p.z - n_er)).x;
       float v2 = inObj(float3 (p.x - n_er , p.y - n_er , p.z + n_er)).x;
       float v3 = inObj(float3 (p.x - n_er , p.y + n_er , p.z - n_er)).x;
       float v4 = inObj(float3 (p.x + n_er , p.y + n_er , p.z + n_er)).x;
       n = normalize(float3 (v4 + v1 - v3 - v2 , v3 + v4 - v1 - v2 , v2 + v4 - v3 - v1));

      float b = max(dot(n , normalize(prp - p)) , 0.0);
      fragColor = float4 ((b * c + pow(b , 8.0)) * (1.0 - f * .01) , 1.0) + pc;
     }
 }
else fragColor = float4 (0 , 0 , 0 , 0) + pc; // background color 
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