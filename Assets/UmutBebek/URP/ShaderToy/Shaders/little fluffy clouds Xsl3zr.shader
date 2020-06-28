Shader "UmutBebek/URP/ShaderToy/little fluffy clouds Xsl3zr"
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
            _VolumeSteps("_VolumeSteps", int) = 64
_StepSize("_StepSize", float) = 0.05
_Density("_Density", float) = 0.1
_OpacityThreshold("_OpacityThreshold", float) = 0.95
_SphereRadius("_SphereRadius", float) = 1.2
_NoiseFreq("_NoiseFreq", float) = 0.5
_NoiseAmp("_NoiseAmp", float) = 2.0
innerColor("innerColor", vector) = (0.7, 0.7, 0.7, 0.1)
outerColor("outerColor", vector) = (1.0, 1.0, 1.0, 0.0)
sunDir("sunDir", vector) = (-0.666, 0.333, 0.666)

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
            int _VolumeSteps;
float _StepSize;
float _Density;
float _OpacityThreshold;
float _SphereRadius;
float _NoiseFreq;
float _NoiseAmp;
float4 innerColor;
float4 outerColor;
float4 sunDir;

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

// little fluffy clouds 
// @simesgreen 













// const float3 sunDir = float3 ( - 0.577 , 0.577 , 0.577 ) ; 


// Description : Array and textureless GLSL 2D / 3D / 4D simplex 
// noise functions. 
// Author : Ian McEwan , Ashima Arts. 
// Maintainer : ijm 
// Lastmod : 20110822 ( ijm ) 
// License : Copyright ( C ) 2011 Ashima Arts. All rights reserved. 
// Distributed under the MIT License. See LICENSE file. 
// https: // github.com / ashima / webgl - noise 
// 

float3 mod289(float3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
 }

float4 mod289(float4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
 }

float4 permute(float4 x) {
     return mod289(((x * 34.0) + 1.0) * x);
 }

float4 taylorInvSqrt(float4 r)
 {
  return 1.79284291400159 - 0.85373472095314 * r;
 }

float snoise(float3 v)
   {
  const float2 C = float2 (1.0 / 6.0 , 1.0 / 3.0);
  const float4 D = float4 (0.0 , 0.5 , 1.0 , 2.0);

  // First corner 
 float3 i = floor(v + dot(v , C.yyy));
 float3 x0 = v - i + dot(i , C.xxx);

 // Other corners 
float3 g = step(x0.yzx , x0.xyz);
float3 l = 1.0 - g;
float3 i1 = min(g.xyz , l.zxy);
float3 i2 = max(g.xyz , l.zxy);

// x0 = x0 - 0.0 + 0.0 * C.xxx ; 
// x1 = x0 - i1 + 1.0 * C.xxx ; 
// x2 = x0 - i2 + 2.0 * C.xxx ; 
// x3 = x0 - 1.0 + 3.0 * C.xxx ; 
float3 x1 = x0 - i1 + C.xxx;
float3 x2 = x0 - i2 + C.yyy; // 2.0 * C.x = 1 / 3 = C.y 
float3 x3 = x0 - D.yyy; // - 1.0 + 3.0 * C.x = - 0.5 = - D.y 

 // Permutations 
i = mod289(i);
float4 p = permute(permute(permute(
           i.z + float4 (0.0 , i1.z , i2.z , 1.0))
          + i.y + float4 (0.0 , i1.y , i2.y , 1.0))
          + i.x + float4 (0.0 , i1.x , i2.x , 1.0));

// Gradients: 7x7 points over a square , mapped onto an octahedron. 
// The ring size 17 * 17 = 289 is close to a multiple of 49 ( 49 * 6 = 294 ) 
float n_ = 0.142857142857; // 1.0 / 7.0 
float3 ns = n_ * D.wyz - D.xzx;

float4 j = p - 49.0 * floor(p * ns.z * ns.z); // mod ( p , 7 * 7 ) 

float4 x_ = floor(j * ns.z);
float4 y_ = floor(j - 7.0 * x_); // mod ( j , N ) 

float4 x = x_ * ns.x + ns.yyyy;
float4 y = y_ * ns.x + ns.yyyy;
float4 h = 1.0 - abs(x) - abs(y);

float4 b0 = float4 (x.xy , y.xy);
float4 b1 = float4 (x.zw , y.zw);

// float4 s0 = float4 ( lessThan ( b0 , 0.0 ) ) * 2.0 - 1.0 ; 
// float4 s1 = float4 ( lessThan ( b1 , 0.0 ) ) * 2.0 - 1.0 ; 
float4 s0 = floor(b0) * 2.0 + 1.0;
float4 s1 = floor(b1) * 2.0 + 1.0;
float4 sh = -step(h , float4 (0.0, 0.0, 0.0, 0.0));

float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

float3 p0 = float3 (a0.xy , h.x);
float3 p1 = float3 (a0.zw , h.y);
float3 p2 = float3 (a1.xy , h.z);
float3 p3 = float3 (a1.zw , h.w);

// Normalise gradients 
float4 norm = taylorInvSqrt(float4 (dot(p0 , p0) , dot(p1 , p1) , dot(p2 , p2) , dot(p3 , p3)));
p0 *= norm.x;
p1 *= norm.y;
p2 *= norm.z;
p3 *= norm.w;

// Mix final noise value 
float4 m = max(0.6 - float4 (dot(x0 , x0) , dot(x1 , x1) , dot(x2 , x2) , dot(x3 , x3)) , 0.0);
m = m * m;
return 42.0 * dot(m * m , float4 (dot(p0 , x0) , dot(p1 , x1) ,
                              dot(p2 , x2) , dot(p3 , x3)));
}


float fbm(float3 p)
 {
    float f;
    f = 0.5000 * snoise(p); p = p * 2.02;
    f += 0.2500 * snoise(p); p = p * 2.03;
    f += 0.1250 * snoise(p); p = p * 2.01;
    f += 0.0625 * snoise(p);
    return f;
 }

float fbm2(float3 p)
 {
    const int octaves = 4;
    float amp = 0.5;
    float freq = 1.0;
    float n = 0.0;
    for (int i = 0; i < octaves; i++) {
        n += snoise(p * freq) * amp;
     freq *= 2.1;
     amp *= 0.5;
     }
    return n;
 }

// returns signed distance to surface 
float distanceFunc(float3 p)
 {
     p.x -= _Time.y; // translate with time 
      // p += snoise ( p * 0.5 ) * 1.0 ; // domain warp! 

     float3 q = p;
     // repeat on grid 
    q.xz = mod(q.xz - float2 (2.5, 2.5) , 5.0) - float2 (2.5, 2.5);
   q.y *= 2.0; // squash in y 
    float d = length(q) - _SphereRadius; // distance to sphere 

     // offset distance with noise 
     // p = normalize ( p ) * _SphereRadius ; // project noise pointExtended to sphere surface 
    p.y -= _Time.y * 0.3; // animate noise with time 
    d += fbm(p * _NoiseFreq) * _NoiseAmp;
    return d;
}

// map distance to color 
float4 shade(float d)
 {
     return lerp(innerColor , outerColor , smoothstep(0.5 , 1.0 , d));
 }

// maps position to color 
float4 volumeFunc(float3 p)
 {
     float d = distanceFunc(p);
     float4 c = shade(d);
     c.rgb *= smoothstep(-1.0 , 0.0 , p.y) * 0.5 + 0.5; // fake shadows 
     float r = length(p) * 0.04;
     c.a *= exp(-r * r); // fog 
     return c;
 }

float3 sky(float3 v)
 {
    // gradient 
   float3 c = lerp(float3 (0.0 , 0.5 , 1.0) , float3 (0 , 0.25 , 0.5) , abs(v.y));
   // float3 c = lerp ( float3 ( 1.0 , 0.5 , 0.0 ) , float3 ( 0 , 0.5 , 1.0 ) , abs ( sqrt ( v.y ) ) ) ; 
  float sun = pow(dot(v , sunDir) , 200.0);
  c += sun * float3 (3.0 , 2.0 , 1.0);
  return c;
}

float sampleLight(float3 pos)
 {
     const int _LightSteps = 8;
     const float _ShadowDensity = 1.0;
     float3 lightStep = (sunDir * 2.0) / float(_LightSteps);
     float t = 1.0; // transmittance 
     for (int i = 0; i < _LightSteps; i++) {
          float4 col = volumeFunc(pos);
          t *= max(0.0 , 1.0 - col.a * _ShadowDensity);
          // if ( t < 0.01 ) 
               // break ; 
         pos += lightStep;
     }
    return t;
}

// ray march volume 
float4 rayMarch(float3 rayOrigin , float3 rayStep , float4 sum , out float3 pos)
 {
     pos = rayOrigin;
     for (int i = 0; i < _VolumeSteps; i++) {
          float4 col = volumeFunc(pos);
#if 0 
          // volume shadows 
         if (col.a > 0.0) {
              col.rgb *= sampleLight(pos);
          }
#endif 

#if 0 
          sum = lerp(sum , col , col.a); // under operator for back - to - front 
#else 
          col.rgb *= col.a; // pre - multiply alpha 
          sum = sum + col * (1.0 - sum.a); // over operator for front - to - back 
#endif 

#if 0 
           // exit early if opaque 
             if (sum.a > _OpacityThreshold)
                      break;
#endif 
          pos += rayStep;
          // rayStep *= 1.01 ; 
     }
    return sum;
}

bool
intersectBox(float3 ro , float3 rd , float3 boxmin , float3 boxmax , out float tnear , out float tfar)
 {
    // compute intersection of ray with all six bbox planes 
   float3 invR = 1.0 / rd;
   float3 tbot = invR * (boxmin - ro);
   float3 ttop = invR * (boxmax - ro);
   // re - order intersections to find smallest and largest on each axis 
  float3 tmin = min(ttop , tbot);
  float3 tmax = max(ttop , tbot);
  // find the largest tmin and the smallest tmax 
 float2 t0 = max(tmin.xx , tmin.yz);
 tnear = max(t0.x , t0.y);
 t0 = min(tmax.xx , tmax.yz);
 tfar = min(t0.x , t0.y);
 // check for hit 
bool hit;
if ((tnear > tfar))
     hit = false;
else
     hit = true;
return hit;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 p = (fragCoord.xy / _ScreenParams.xy) * 2.0 - 1.0;
    p.x *= _ScreenParams.x / _ScreenParams.y;

    float rotx = 2.5 + (iMouse.y / _ScreenParams.y) * 4.0;
    float roty = -0.2 - (iMouse.x / _ScreenParams.x) * 4.0;

    float zoom = 4.0;

    // camera 
   float3 ro = zoom * normalize(float3 (cos(roty) , cos(rotx) , sin(roty)));

   float3 ww = normalize(float3 (0.0 , 0.0 , 0.0) - ro);
   float3 uu = normalize(cross(float3 (0.0 , 1.0 , 0.0) , ww));
   float3 vv = normalize(cross(ww , uu));
   float3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww);

   // box 
  float3 boxMin = float3 (-50.0 , 2.0 , -50);
  float3 boxMax = float3 (50.0 , -2.0 , 50);
  // float3 boxMin = float3 ( - 3.0 , - 2.0 , - 3.0 ) ; 
  // float3 boxMax = float3 ( 3.0 , 2.0 , 3.0 ) ; 

 float tnear , tfar;
 bool hit = intersectBox(ro , rd , boxMin , boxMax , tnear , tfar);
 tnear = max(tnear , 0.0);
 tfar = max(tfar , 0.0);

  float3 pnear = ro + rd * tnear;
 float3 pfar = ro + rd * tfar;

 // ro = pfar ; rd = - rd ; // back to front 
ro = pnear; // front to back 
float stepSize = length(pfar - pnear) / float(_VolumeSteps);

float3 hitPos;
// float4 col = float4 ( 0 , 0.25 , 0.5 , 0 ) ; 
// float4 col = float4 ( sky ( rd ) , 0 ) ; 
float4 col = float4 (0, 0, 0, 0);
if (hit) {
    // col = rayMarch ( ro , rd * _StepSize , col , hitPos ) ; 
   col = rayMarch(ro , rd * stepSize , col , hitPos);
}

// blend sun under clouds 
col += float4 (sky(rd) , 0) * (1.0 - col.w);

// col *= smoothstep ( 4.0 , 0.7 , dot ( p , p ) ) ; 

fragColor = float4 (col.rgb , 1.0);
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