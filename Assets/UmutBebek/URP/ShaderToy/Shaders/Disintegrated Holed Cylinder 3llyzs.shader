Shader "UmutBebek/URP/ShaderToy/Disintegrated Holed Cylinder 3llyzs"
{
    Properties
    {
        _BaseMap("Base (RGB)", 2D) = "" {}
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

            float4 _BaseMap_ST;
            TEXTURE2D(_BaseMap);       SAMPLER(sampler_BaseMap);

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
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
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

            // from https: // www.shadertoy.com / view / lssSRn by FabriceNeyret2 

#define GAIN 1.6 // > 1 is unsafe , but up to 2 still looks ok ( noise don t sature dynamics ) 
#define NOISE 1 // 1: linear 2: blobby ( abs ) 3: hairy ( 1 - abs ) 

 // -- - scene ( screen = [ - 1.8 , 1.8] x [ - 1 , 1] ) 

float2 sphere1Pos = float2 (0. , 0.);
float sphere1Rad = .7; // sphere radius 

float planePos = .1;

float2 sphere2Pos = float2 (1. , 0.);
float sphere2Rad = .2;

// cloud appearance ( superseeded by mouse tuning ) 

float H = .2; // skin layer thickness ( % of normalized sphere ) 
float sharp = 0.9; // cloud sharpness ( 0 = ultra sharp ) . 



#define ANIM 1 // 1 / 0 


 // -- - noise functions from https: // www.shadertoy.com / view / XslGRr 
 // Created by inigo quilez - iq / 2013 
 // License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

float3x3 m = float3x3 (0.00 , 0.80 , 0.60 ,
               -0.80 , 0.36 , -0.48 ,
               -0.60 , -0.48 , 0.64);

float hash(float n) // base rand in [0 , 1] ; 
 {
    return frac(sin(n - 765.36334) * 43758.5453);
    // return - 1. + 2. * frac ( sin ( n - 765.36334 ) * 43758.5453 ) ; 
}

float noise(in float3 x) // base noise in [0 , 1] ; 
 {
    float3 p = floor(x);
    float3 f = frac(x);

    f = f * f * (3.0 - 2.0 * f);

    float n = p.x + p.y * 57.0 + 113.0 * p.z;

    float res = lerp(lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                        lerp(hash(n + 57.0) , hash(n + 58.0) , f.x) , f.y) ,
                    lerp(lerp(hash(n + 113.0) , hash(n + 114.0) , f.x) ,
                        lerp(hash(n + 170.0) , hash(n + 171.0) , f.x) , f.y) , f.z);
#if NOISE == 1 
     return res;
#elif NOISE == 2 
     return abs(2. * res - 1.);
#elif NOISE == 3 
     return 1. - abs(2. * res - 1.);
#endif 
 }

float fbm(float3 p) // turbulent ( = fractal ) noise in [0 , 1] ; 
 {
    float f;
    f = 0.5000 * noise(p); p = mul(m,p) * 2.02;
    f += 0.2500 * noise(p); p = mul(m, p) * 2.03;
    f += 0.1250 * noise(p); p = mul(m, p) * 2.01;
    f += 0.0625 * noise(p);
    return f;
 }
// -- - End of: Created by inigo quilez -- -- -- -- -- -- -- -- -- -- 



// smooth distance to sphere = [ - 1 , 1] around radius + - thickness H 

float sphere(float2 uv , float2 spherePos , float sphereRad)
 {
     float2 p = (uv - spherePos) / sphereRad; // pos in sphere normalized coordinates 
     float d = (1. - length(p)) / H;
     return clamp(d , -1. , 1.);
 }

// smooth distance to plane = [ - 1 , 1] around plane + - thickness H 

float plane(float2 uv , float planePos , float planeRad) // planeRad to share normalization with spheres 
 {
     float2 p = uv - float2 (planePos , 0.); // pos in sphere normalized coordinates 
     float d = -p.x / (H * planeRad);
     return clamp(d , -1. , 1.);
 }

// smooth intersect operator 

float inter(float d0 , float d1) {
     d0 = (1. + d0) / 2.; // [ - 1 , 1] - > [0 , 1] , mul , [0 , 1] - > [ - 1 , 1] 
     d1 = (1. + d1) / 2.;
     return 2. * d0 * d1 - 1.;
 }

// smooth union operator 

float add(float d0 , float d1) {
     d0 = (1. + d0) / 2.; // [ - 1 , 1] - > [0 , 1] , add , [0 , 1] - > [ - 1 , 1] 
     d1 = (1. + d1) / 2.;
     return 2. * (d0 + d1 - d0 * d1) - 1.;
 }

// jitter the distance around 0 and smoothclamp 

float perturb(float2 p , float d , float H) {
#if ANIM 
   float t = _Time.y;
#else 
  float t = 0.;
#endif 
  // float fillfactor = 0. ; d = ( d + 1. ) * fillfactor - 1. ; 
  if (d <= -1.) return -1.; // exterior 
  if (d >= 1.) return 1.; // interior ( 1 when H% inside radius ) 

  float n = 2. * fbm(float3 ((p / H).x , (p / H).y , t)) - 1.; // perturbation in [ - 1 , 1] 
  return 2. * (d + GAIN * n); // still in [ - 1 , 1] : - ) 
}

// convert [ - 1 , 1] distances into densities 

float dist2dens(float d) { // transition around zero. Tunable sharpness 
     return smoothstep(-sharp , sharp , d);
 }


// user - define shape 

float shape(float2 uv , float n) {

     float v1 = sphere(uv , sphere1Pos , sphere1Rad) ,
            v2 = plane(uv , planePos , sphere1Rad) , // share normalization radius 
            v3 = sphere(uv , sphere2Pos , sphere2Rad);
     float v;

#define globalNoise false 

     if (globalNoise || (n == 0.)) {
          v = add(inter(v1 , v2) , v3); // we combine smooth distances * then * perturbate 
          if (n > 0.) v = perturb(uv , v , H * sphere1Rad);
      }
     else {
          v = perturb(uv , inter(v1 , v2) , H * sphere1Rad); // we perturbate ( with different coefs ) * then * combine 
          v = add(v , perturb(uv , v3 , H * sphere2Rad));
      }

     return v;
 }

// main loop 

float2 polar_coord(float3 p)
 {
    float phi = atan2(p.z , p.x); // angle 
    float d_rad = length(float2 (p.x , p.z)); // delta radius 
    return float2 (d_rad * cos(phi) , d_rad * sin(phi));
 }

const float3 cam = float3 (0. , 0. , 10.);
float uniform_step = .5;
void draw_disk(float3 dir , float3 center , float3 normal , float radius , inout float3 c)
 {
    float antialiasing = 1.;
    antialiasing = frac(0.0001 * sin(0.0001 * dot(dir , float3 (1. , 7.1 , 13.3)))); // Comment to see it without antialiasing 
    float3 p = cam + dir * antialiasing;
    float s = 0.;


    for (s; s < 150.; s++)
     {
        float k_step = uniform_step;

        float dist_dist = dot(p , p);
        float dist_center = length(center - cam);

        float2 nu = polar_coord(p - (center));

        // if too far , then big step 

       if (sqrt(dist_dist) < (dist_center - radius))
        {
            k_step = dist_center - radius;
        }

       // if in the shape , draw 
      else if ((length(nu) - 5. <= 0.) && (length(nu) - 2.5 >= 0.) && (distance(p.y , center.y) < 2.))
       {
           c += 0.2 * float3 (0.4 , 0.4 , 0.6);
       }

       // if it will never be in the shape anymore , return ; 
      if (length(p) > (dist_center + radius))
       {
            break;
       }

      p += dir * k_step;
   }
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = (2.0 * (fragCoord)-_ScreenParams.xy) / _ScreenParams.y;
    float3 color = float3 (1., 0., 0.);

        if (iMouse.z > 0.)
     { // mouse tuning 
          float2 m = iMouse.xy / _ScreenParams.xy;
          H = m.x + 0.00001; sharp = m.y + 0.00001;
      }

     float v = dist2dens(shape(uv , 1.));
     float3 col = float3 (v,v,v);

    draw_disk(normalize(float3 ((uv).x , (uv).y , -1.)) , float3 (0. , 0. , 0.) , float3 (0. , 1. , 0.) , 30. , color);

    fragColor = float4 (min(color , max(float3 (0. , 0. , 0.) , col)).x , min(color , max(float3 (0. , 0. , 0.) , col)).y , min(color , max(float3 (0. , 0. , 0.) , col)).z , 1.);

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