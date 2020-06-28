Shader "UmutBebek/URP/ShaderToy/Sunset on the sea 4dl3zr"
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
            [MaterialToggle]USE_MOUSE("USE_MOUSE", float) = 1
MAX_RAYMARCH_DIST("MAX_RAYMARCH_DIST", float) = 150.0
MIN_RAYMARCH_DELTA("MIN_RAYMARCH_DELTA", float) = 0.00015
GRADIENT_DELTA("GRADIENT_DELTA", float) = 0.015
waveHeight1("waveHeight1", float) = 0.005
waveHeight2("waveHeight2", float) = 0.004
waveHeight3("waveHeight3", float) = 0.001

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
            float USE_MOUSE;
float MAX_RAYMARCH_DIST;
float MIN_RAYMARCH_DELTA;
float GRADIENT_DELTA;
float waveHeight1;
float waveHeight2;
float waveHeight3;

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

// Sunset on the sea v.1.0.1 - Ray Marching & Ray Tracing experiment by Riccardo Gerosa aka h3r3 
// Blog: http: // www.postronic.org / h3 / G + : https: // plus.google.com / u / 0 / 117369239966730363327 Twitter: @h3r3 http: // twitter.com / h3r3 
// More information about this shader can be found here: http: // www.postronic.org / h3 / pid65.html 
// This GLSL shader is based on the work of T Whitted , JC Hart , K Perlin , I Quilez and many others 
// This shader uses a Simplex Noise implementation by and I McEwan , A Arts ( more info below ) 
// If you modify this code please update this header 










float2 mouse;

// -- -- -- -- -- -- -- -- -- -- - START of SIMPLEX NOISE 
// 
// Description : Array and textureless GLSL 2D simplex noise function. 
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

float2 mod289(float2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
 }

float3 permute(float3 x) {
  return mod289(((x * 34.0) + 1.0) * x);
 }

float snoise(float2 v)
   {
  const float4 C = float4 (0.211324865405187 , // ( 3.0 - sqrt ( 3.0 ) ) / 6.0 
                      0.366025403784439 , // 0.5 * ( sqrt ( 3.0 ) - 1.0 ) 
                      -0.577350269189626 , // - 1.0 + 2.0 * C.x 
                      0.024390243902439); // 1.0 / 41.0 
 // First corner 
  float2 i = floor(v + dot(v , C.yy));
  float2 x0 = v - i + dot(i , C.xx);

  // Other corners 
   float2 i1;
   // i1.x = step ( x0.y , x0.x ) ; // x0.x > x0.y ? 1.0 : 0.0 
   // i1.y = 1.0 - i1.x ; 
  i1 = (x0.x > x0.y) ? float2 (1.0 , 0.0) : float2 (0.0 , 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ; 
  // x1 = x0 - i1 + 1.0 * C.xx ; 
  // x2 = x0 - 1.0 + 2.0 * C.xx ; 
 float4 x12 = x0.xyxy + C.xxzz;
 x12.xy -= i1;

 // Permutations 
  i = mod289(i); // Avoid truncation effects in permutation 
  float3 p = permute(permute(i.y + float3 (0.0 , i1.y , 1.0))
           + i.x + float3 (0.0 , i1.x , 1.0));

  float3 m = max(0.5 - float3 (dot(x0 , x0) , dot(x12.xy , x12.xy) , dot(x12.zw , x12.zw)) , 0.0);
  m = m * m;
  m = m * m;

  // Gradients: 41 points uniformly over a line , mapped onto a diamond. 
  // The ring size 17 * 17 = 289 is close to a multiple of 41 ( 41 * 7 = 287 ) 

   float3 x = 2.0 * frac(p * C.www) - 1.0;
   float3 h = abs(x) - 0.5;
   float3 ox = floor(x + 0.5);
   float3 a0 = x - ox;

   // Normalise gradients implicitly by scaling m 
   // Approximation of: m *= inversesqrt ( a0 * a0 + h * h ) ; 
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    // Compute final noise value at P 
     float3 g;
     g.x = a0.x * x0.x + h.x * x0.y;
     g.yz = a0.yz * x12.xz + h.yz * x12.yw;
     return 130.0 * dot(m , g);
    }

// -- -- -- -- -- -- -- -- -- -- - END of SIMPLEX NOISE 


float map(float3 p) {
     return p.y + (0.5 + waveHeight1 + waveHeight2 + waveHeight3)
           + snoise(float2 (p.x + _Time.y * 0.4 , p.z + _Time.y * 0.6)) * waveHeight1
           + snoise(float2 (p.x * 1.6 - _Time.y * 0.4 , p.z * 1.7 - _Time.y * 0.6)) * waveHeight2
             + snoise(float2 (p.x * 6.6 - _Time.y * 1.0 , p.z * 2.7 + _Time.y * 1.176)) * waveHeight3;
 }

float3 gradientNormalFast(float3 p , float map_p) {
    return normalize(float3 (
        map_p - map(p - float3 (GRADIENT_DELTA , 0 , 0)) ,
        map_p - map(p - float3 (0 , GRADIENT_DELTA , 0)) ,
        map_p - map(p - float3 (0 , 0 , GRADIENT_DELTA))));
 }

float intersect(float3 p , float3 ray_dir , out float map_p , out int iterations) {
     iterations = 0;
     if (ray_dir.y >= 0.0) { return -1.0; } // to see the sea you have to look down 

     float distMin = (-0.5 - p.y) / ray_dir.y;
     float distMid = distMin;
     for (int i = 0; i < 50; i++) {
         // iterations ++ ; 
        distMid += max(0.05 + float(i) * 0.002 , map_p);
        map_p = map(p + ray_dir * distMid);
        if (map_p > 0.0) {
             distMin = distMid + map_p;
         }
else {
 float distMax = distMid + map_p;
 // interval found , now bisect inside it 
for (int i = 0; i < 10; i++) {
    // iterations ++ ; 
   distMid = distMin + (distMax - distMin) / 2.0;
   map_p = map(p + ray_dir * distMid);
   if (abs(map_p) < MIN_RAYMARCH_DELTA) return distMid;
   if (map_p > 0.0) {
        distMin = distMid + map_p;
    }
else {
 distMax = distMid + map_p;
}
}
return distMid;
}
}
return distMin;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    mouse = float2 (iMouse.x / _ScreenParams.x , iMouse.y / _ScreenParams.y);
     float waveHeight = USE_MOUSE ? mouse.x * 5.0 : cos(_Time.y * 0.03) * 1.2 + 1.6;
     waveHeight1 *= waveHeight;
     waveHeight2 *= waveHeight;
     waveHeight3 *= waveHeight;

     float2 position = float2 ((fragCoord.x - _ScreenParams.x / 2.0) / _ScreenParams.y , (fragCoord.y - _ScreenParams.y / 2.0) / _ScreenParams.y);
     float3 ray_start = float3 (0 , 0.2 , -2);
     float3 ray_dir = normalize(float3 (position , 0) - ray_start);
     ray_start.y = cos(_Time.y * 0.5) * 0.2 - 0.25 + sin(_Time.y * 2.0) * 0.05;

     const float dayspeed = 0.04;
     float subtime = max(-0.16 , sin(_Time.y * dayspeed) * 0.2);
     float middayperc = USE_MOUSE ? mouse.y * 0.3 - 0.15 : max(0.0 , sin(subtime));
     float3 light1_pos = float3 (0.0 , middayperc * 200.0 , USE_MOUSE ? 200.0 : cos(subtime * dayspeed) * 200.0);
     float sunperc = pow(max(0.0 , min(dot(ray_dir , normalize(light1_pos)) , 1.0)) , 190.0 + max(0.0 , light1_pos.y * 4.3));
     float3 suncolor = (1.0 - max(0.0 , middayperc)) * float3 (1.5 , 1.2 , middayperc + 0.5) + max(0.0 , middayperc) * float3 (1.0 , 1.0 , 1.0) * 4.0;
     float3 skycolor = float3 (middayperc + 0.8 , middayperc + 0.7 , middayperc + 0.5);
     float3 skycolor_now = suncolor * sunperc + (skycolor * (middayperc * 1.6 + 0.5)) * (1.0 - sunperc);
     float4 color = float4 (0.0 , 0.0 , 0.0 , 1.0);
     float map_p;
     int iterations;
     float dist = intersect(ray_start , ray_dir , map_p , iterations);
     if (dist > 0.0) {
          float3 p = ray_start + ray_dir * dist;
          float3 light1_dir = normalize(light1_pos - p);
             float3 n = gradientNormalFast(p , map_p);
          float3 ambient = skycolor_now * 0.1;
             float3 diffuse1 = float3 (1.1 , 1.1 , 0.6) * max(0.0 , dot(light1_dir , n) * 2.8);
          float3 r = reflect(light1_dir , n);
          float3 specular1 = float3 (1.5 , 1.2 , 0.6) * (0.8 * pow(max(0.0 , dot(r , ray_dir)) , 200.0));
          float fog = min(max(p.z * 0.07 , 0.0) , 1.0);
             color.rgb = (float3 (0.6 , 0.6 , 1.0) * diffuse1 + specular1 + ambient) * (1.0 - fog) + skycolor_now * fog;
          }
else {
color.rgb = skycolor_now.rgb;
}
fragColor = color;
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