Shader "UmutBebek/URP/ShaderToy/attic Mdl3Rr"
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

           // Robert Cupisz 2013 
// Creative Commons Attribution - ShareAlike 3.0 Unported 
// 
// Bits of code taken from Inigo Quilez , including fbm ( ) , impulse ( ) 
// and friends , sdCone ( ) and friends ; also box ( ) by Simon Green. 

#define BRUTE_FORCE_AA 1 

#if BRUTE_FORCE_AA 
#define AA_SAMPLES 4 
#define INSCATTER_STEPS 30 
#define NOISE_AMPLITUDE 0.1 
#else 
#define INSCATTER_STEPS 50 
#define NOISE_AMPLITUDE 0.05 
#endif 

#define INF 1.0e38 
#define HIT(x) hit = min ( hit , x ) 

 // Shadow rays can make things faster if there are big occluders 
 // but kinda ugly with no #include statement 
 // #define HIT ( x ) if ( x < INF ) return 0.0 

static float3x3 m = float3x3 (0.00 , 0.80 , 0.60 ,
                  -0.80 , 0.36 , -0.48 ,
                  -0.60 , -0.48 , 0.64);

float hash(float n)
 {
     return frac(sin(n) * 43758.5453);
 }

float noise(in float3 x)
 {
     float3 p = floor(x);
     float3 f = frac(x);

     f = f * f * (3.0 - 2.0 * f);

     float n = p.x + p.y * 57.0 + 113.0 * p.z;

     float res = lerp(lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                              lerp(hash(n + 57.0) , hash(n + 58.0) , f.x) , f.y) ,
                         lerp(lerp(hash(n + 113.0) , hash(n + 114.0) , f.x) ,
                              lerp(hash(n + 170.0) , hash(n + 171.0) , f.x) , f.y) , f.z);
     return res;
 }

float fbm(float3 p)
 {
     float f;
     f = 0.5000 * noise(p); p = mul(m , p) * 2.02;
     f += 0.2500 * noise(p); p = mul(m , p) * 2.03;
     f += 0.1250 * noise(p); // p = m * p * 2.01 ; 
      // f += 0.0625 * noise ( p ) ; 
     return f;
 }

float box(float3 org , float3 dir , float3 size , out float far)
 {
    // compute intersection of ray with all six bbox planes 
   float3 invR = 1.0 / dir;
   float3 tbot = invR * (-0.5 * size - org);
   float3 ttop = invR * (0.5 * size - org);

   // re - order intersections to find smallest and largest on each axis 
  float3 tmin = min(ttop , tbot);
  float3 tmax = max(ttop , tbot);

  // find the largest tmin and the smallest tmax 
 float2 t0 = max(tmin.xx , tmin.yz);
 float near;
 near = max(t0.x , t0.y);
 t0 = min(tmax.xx , tmax.yz);
 far = min(t0.x , t0.y);

 // check for hit 
return near < far&& far > 0.0 ? near : INF;
}

float box(float3 org , float3 dir , float3 size)
 {
     float far;
     return box(org , dir , size , far);
 }

float impulse(float k , float x)
 {
     float h = k * x;
     return h * exp(1.0 - h);
 }

float impulse2(float k0 , float k1 , float x)
 {
     float k = k0;
     if (x > 1.0 / k0)
      {
          x += 1.0 / k1 - 1.0 / k0;
          k = k1;
      }
     float h = k * x;
     return h * exp(1.0 - h);
 }

float cubicPulse(float w , float x)
 {
     x = abs(x);
     if (x > w)
          return 0.0;
     x /= w;
     return 1.0 - x * x * (3.0 - 2.0 * x);
 }

float2x2 rot(float angle)
 {
     float c = cos(angle);
     float s = sin(angle);
     return float2x2 (c , -s , s , c);
 }

// rd doesn't have to be normalized 
float sphere(float3 ro , float3 rd , float r)
 {
     float b = dot(ro , rd);
     float c = dot(ro , ro) - r * r;
     float a = dot(rd , rd);
     // Exit if râ€™s origin outside s ( c > 0 ) and r pointing away from s ( b > 0 ) 
    if (c > 0.0 && b > 0.0)
         return INF;
    float discr = b * b - a * c;
    // A negative discriminant corresponds to ray missing sphere 
   if (discr < 0.0)
        return INF;
   // Ray now found to intersect sphere , compute smallest t value of intersection 
  float t = -b - sqrt(discr);
  t /= a;
  // If t is negative , ray started inside sphere so clamp t to zeroExtended 
 t = max(0.0 , t);
 return t;
}

float sdCone(float3 p , float2 c)
 {
    // c must be normalized 
   float q = length(p.xy);
   return dot(c , float2 (q , p.z));
}

float sdPlane(float3 p , float4 n)
 {
    // n must be normalized 
   return dot(p , n.xyz) + n.w;
}

float sdSphere(float3 p , float s)
 {
     return length(p) - s;
 }

float3 animateTentacle(float3 p)
 {
     float t = 0.8 * _Time.y + 2.6;
     float pi = 3.1415;
     float pi4 = pi * 4.0;

     // major up and down 
    float offset = 1.05;
    p.z += offset;
    float a = 0.6;
    a += 0.1 * sin(1.33 * t - 0.7);
    a += 0.15 * sin(2.0 * t);
    a -= 1.2 * impulse2(3.0 , 1.1 , mod(pi4 - t , pi4));
    a *= 0.8 * max(-0.1 , p.z) + 0.1;
    float2x2 m = rot(a);
    p = float3 (mul(m , p.yz) , p.x).zxy;
    p.z -= offset;

    // ripples 
   float ripplesPos = p.z + 0.5 * mod(t , pi4) - 0.3;
   float ripples = 0.003 * sin(80.0 * ripplesPos) * cubicPulse(0.15 , ripplesPos + 0.7);
   p.y += ripples;
   p.x += ripples;

   // whiplash 
  p.y += 0.06 * smoothstep(-0.6 , -0.3 , p.z) * impulse(25.0 , mod(t - 0.01 , pi4));

  return p;
}

float sdTentacle(float3 p)
 {
     p += float3 (-0.6 , 0.52 , -0.06);

     // bend 
    p.y -= smoothstep(0.95 , 1.1 , -p.z) * (p.z + 0.9) * 0.5;

    // animate 
   p = animateTentacle(p);

   // wavy 
  p.y += 0.02 * sin(13.0 * p.z + _Time.y + 3.0);
  p.x += 0.01 * cos(17.0 * p.z);

  // primitives 
 float d = sdCone(p , float2 (0.99 , 0.12));
 d = max(d , -sdPlane(p , float4 (0 , 0 , 1 , 1.135)));
 d = max(d , -sdPlane(p , float4 (0 , 0 , -1 , -0.4)));
 d = min(d , sdSphere(p + float3 (0.0 , 0.0 , 0.41) , 0.05));

 return d;
}

float tentacle(float3 ro , float3 rd)
 {
     float far;
     float3 bboxpos = float3 (-0.6 , 0.51 , 0.69);
     float3 bboxsize = float3 (0.25 , 0.66 , 0.79);
     float near = box(ro + bboxpos , rd , bboxsize);
     if (near == INF)
          return INF;
     // return near ; 

    near = max(0.0 , near);

    ro += near * rd;
    float t = 0.0;
    float hit = -1.0;
    for (int i = 0; i < 24; i++)
     {
         float h = sdTentacle(ro + rd * t);
         // We will be overwriting the hit multiple times once 
         // we're close to the surface , but it actually gives 
         // a better result than the first below threshold 
         // and we can't break anyway. 
        if (h < 1e-5)
             hit = t;
        t += h;
    }

   return hit > -1.0 ? hit + near : INF;
}

float roof(float3 ro , float3 rd)
 {
     float hit = -ro.y / rd.y;
     // An offset , so that shadow rays starting from the roof don't 
     // think they're unoccluded 
    if (hit < -0.1)
         return INF;

    // We've hit the plane. If we've hit the window , but 
    // not the beams , return no hit. 
   float2 pos = ro.xz + hit * rd.xz;
   float2 window = abs(pos) - 0.81;
   // single beams 
   // float2 beams = 0.02 - abs ( pos ) ; 
   // double beams 
  float2 beams = 0.015 - abs(mod(pos , 0.54) - 0.27);
  if (max(max(window.x , window.y) , max(beams.x , beams.y)) < 0.0)
       return INF;

  return hit;
}

float monsterBox(float3 ro , float3 rd)
 {
     float hit = INF;
     float size = 0.33;
     float halfSize = 0.5 * size;
     HIT(box(ro , rd , float3 (size, size, size)));

     ro.y -= halfSize;
     ro.z += halfSize;
     float2x2 m = rot(0.017 * (sin(_Time.y) - 48.0));
     ro.yz = mul(m , ro.yz);
     rd.yz = mul(m , rd.yz);
     ro.z -= halfSize;

     HIT(box(ro , rd , float3 (size , 0.04 , size)));
     return hit;
 }

float ship(float3 ro , float3 rd)
 {
     float pi = 3.1415;
     float pihalf = 0.5 * pi;
     float t = 0.8 * _Time.y + 3.0;
     float angle = 0.0;

     // tilting back and forth 
    float tiltt = t + 0.3;
    float tiltAmp = -0.14 * sign(frac((tiltt + pihalf) / (2.0 * pi)) - 0.5);
    angle += tiltAmp * cubicPulse(1.2 , mod(tiltt + pihalf , pi) - pihalf);

    // running away 
   angle += 0.7 * impulse(3.0 , mod(t + 0.08 , 4.0 * pi));
   float post = mod(t , 2.0 * pi);
   post += impulse(1.0 , mod(t , 4.0 * pi));
   ro += float3 (-0.6 , 0.5 , 0.3 * cos(post) - 0.08);

   // rotate 
  float2x2 m = rot(angle);
  ro.yz = mul(m , ro.yz);
  rd.yz = mul(m , rd.yz);

  // intersect 
 float hit = INF;
 HIT(sphere(ro + float3 (0.0 , -0.025 , 0.0) , rd , 0.05));
 float flatten = 4.0;
 ro.y *= flatten;
 rd.y *= flatten;
 HIT(sphere(ro , rd , 0.17));
 return hit;
}

#define ROOFPOS float3 ( 0 , - 1 , 0.01 ) 

float intersect(float3 ro , float3 rd)
 {
     float hit = INF;

     // tentacle 
    HIT(tentacle(ro , rd));

    // ship 
   HIT(ship(ro , rd));

   // stuff 
  HIT(box(ro + float3 (0.5 , 0.5 , 0) , rd , float3 (0.4 , 2 , 1)));
  HIT(sphere(ro + float3 (0.3 , 0.8 , 0.65) , rd , 0.25));
  float2x2 m = rot(3.5);
  float3 rorot = ro + float3 (0.4 , -0.6 , 0.3);
  float3 rdrot = rd;
  rorot.xz = mul(m , rorot.xz);
  rdrot.xz = mul(m , rdrot.xz);
  HIT(box(rorot , rdrot , float3 (0.35 , 0.2 , 0.35)));

  // roof 
 rorot = ro + ROOFPOS;
 rdrot = rd;
 // reuse the previous rotation matrix 
rorot.xy = mul(m , rorot.xy);
rdrot.xy = mul(m , rdrot.xy);
HIT(roof(rorot , rdrot));

// monster box 
m = rot(-0.175);
rorot = ro + float3 (-0.6 , 0.78 , 1.0);
rdrot = rd;
rorot.xz = mul(m , rorot.xz);
rdrot.xz = mul(m , rdrot.xz);
HIT(monsterBox(rorot , rdrot));

// floor 
float floorHit = -(ro.y + 0.95) / rd.y;
if (floorHit < 0.0)
     floorHit = INF;
HIT(floorHit);

return hit;
}

float particles(float3 p)
 {
     float3 pos = p;
     pos.y -= _Time.y * 0.02;
     float n = fbm(20.0 * pos);
     n = pow(n , 5.0);
     float brightness = noise(10.3 * p);
     float threshold = 0.26;
     return smoothstep(threshold , threshold + 0.15 , n) * brightness * 90.0;
 }

float transmittance(float3 p)
 {
     return exp(0.4 * p.y);
 }

float3 inscatter(float3 ro , float3 rd , float3 roLight , float3 rdLight , float3 lightDir , float hit , float2 screenPos)
 {
     float far;
     float near = box(roLight + float3 (0.0 , 1.0 , 0.0) , rdLight , float3 (1.5 , 3.0 , 1.5) , far);
     if (near == INF || hit < near)
          return float3 (0 , 0 , 0);

     float distAlongView = min(hit , far) - near;
     float oneOverSteps = 1.0 / float(INSCATTER_STEPS);
     float3 step = rd * distAlongView * oneOverSteps;
    float3 pos = ro + rd * near;
     float light = 0.0;

     // add noise to the start position to hide banding 
     // TODO: blueExtended noise 
     pos += rd * noise(float3 (2.0 * screenPos , 0.0)) * NOISE_AMPLITUDE;

     for (int i = 0; i < INSCATTER_STEPS; i++)
      {
          float l = intersect(pos , lightDir) == INF ? 1.0 : 0.0;
          l *= transmittance(pos);
          light += l;
          light += particles(pos) * l;
          pos += step;
      }

     light *= oneOverSteps * distAlongView;
     return light * float3 (0.6 , 0.6 , 0.6);
 }

float3 rot(float3 v , float3 axis , float2 sincosangle)
 {
     return v * sincosangle.y + cross(axis , v) * sincosangle.x + axis * (dot(axis , v)) * (1.0 - sincosangle.y);
 }

float3 surface(float2 fragCoord , float3 ro , float3 u , float3 v , float3 w , float3 lightRotAxis , float2 lightAngleSinCos , float3 lightDir)
 {
    float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;

     float3 rd = normalize(p.x * u + p.y * v + 1.5 * w);

     // raycast the scene 
    float hit = intersect(ro , rd);
    float3 hitPos = ro + hit * rd;

    // white window 
   if (hit == INF)
        return float3 (1.0 , 1.0 , 1.0);

   // direct light ( screw shading! ) 
  float3 c = float3 (0.0 , 0.0 , 0.0);
 float shadowBias = 1.0e-4;
  if (intersect(hitPos + lightDir * shadowBias , lightDir) == INF)
       c = float3 (0.9 , 0.9 , 0.9);

 lightAngleSinCos.x *= -1.0; // rev angle 
  float3 roLight = rot(ro + ROOFPOS , lightRotAxis , lightAngleSinCos);
  float3 rdLight = rot(rd , lightRotAxis , lightAngleSinCos);
  c += inscatter(ro , rd , roLight , rdLight , lightDir , hit , fragCoord);

  // color correction - Sherlock color palette ; ) 
  c.r = smoothstep(0.0 , 1.0 , c.r);
  c.g = smoothstep(0.0 , 1.0 , c.g - 0.1);
  c.b = smoothstep(-0.3 , 1.3 , c.b);

 return c;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // camera 
 float3 ro = normalize(float3 (1.0 , -0.1 , 0.1));
 float cameraAngle = iMouse.x / _ScreenParams.x - 0.5;
 if (iMouse.z < 0.5)
      cameraAngle = 0.5 * sin(0.1 * _Time.y);
 float cca = cos(cameraAngle);
 float sca = sin(cameraAngle);
 float2x2 m = float2x2 (cca , -sca , sca , cca);
 ro = float3 (mul(m , ro.xz) , ro.y).xzy;
 float3 w = -ro;
 ro *= 2.5;
 float3 u = normalize(cross(float3 (0.0 , 1.0 , 0.0) , w));
 float3 v = normalize(cross(w , u));

 // light 
float3 lightRotAxis = float3 (0.707 , 0 , 0.707); // 1 , 0 , 1 normalized 
 float2 lightAngleSinCos = float2 (sin(0.28) , cos(0.28));
 float3 lightDir = rot(float3 (0 , 1 , 0) , lightRotAxis , lightAngleSinCos);

#if BRUTE_FORCE_AA 
    float invAA = 1.0 / float(AA_SAMPLES);
    float3 c = float3 (0 , 0 , 0);
    float2 offset = float2 (-0.5 , -0.5);
    for (int i = 0; i < AA_SAMPLES; i++)
     {
        for (int j = 0; j < AA_SAMPLES; j++)
         {
            c += surface(fragCoord + offset , ro , u , v , w , lightRotAxis , lightAngleSinCos , lightDir);
            offset.y += invAA;
         }
        offset.x += invAA;
        offset.y = -0.5;
     }
    c *= invAA * invAA;
#else 
    float3 c = surface(fragCoord , ro , u , v , w , lightRotAxis , lightAngleSinCos , lightDir);
#endif 

     fragColor = float4 (c , 0.0);
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