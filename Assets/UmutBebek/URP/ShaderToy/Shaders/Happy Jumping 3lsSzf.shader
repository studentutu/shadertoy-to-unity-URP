Shader "UmutBebek/URP/ShaderToy/Happy Jumping 3lsSzf"
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
            AA("AA", float) = 1

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
            float AA;

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

           // Created by inigo quilez - iq / 2019 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 
// 
// 
// An animation test - a happy and blobby creature jumping and 
// looking around. It gets off - model very often , but it looks 
// good enough I think. 
// 
// Making - of and related math / shader / art explanations ( 6 hours 
// long ) : https: // www.youtube.com / watch?v = Cfe5UQ - 1L9Q 
// 
// Video capture: https: // www.youtube.com / watch?v = s_UOFo2IULQ 


#if HW_PERFORMANCE == 0 

#else 
#define AA 2 // Set AA to 1 if your machine is too slow 
#endif 


 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


 // http: // iquilezles.org / www / articles / smin / smin.htm 
float smin(float a , float b , float k)
 {
    float h = max(k - abs(a - b) , 0.0);
    return min(a , b) - h * h * 0.25 / k;
 }

// http: // iquilezles.org / www / articles / smin / smin.htm 
float2 smin(float2 a , float2 b , float k)
 {
    float h = clamp(0.5 + 0.5 * (b.x - a.x) / k , 0.0 , 1.0);
    return lerp(b , a , h) - k * h * (1.0 - h);
 }

// http: // iquilezles.org / www / articles / smin / smin.htm 
float smax(float a , float b , float k)
 {
    float h = max(k - abs(a - b) , 0.0);
    return max(a , b) + h * h * 0.25 / k;
 }

// http: // www.iquilezles.org / www / articles / distfunctions / distfunctions.htm 
float sdSphere(float3 p , float s)
 {
    return length(p) - s;
 }

// http: // www.iquilezles.org / www / articles / distfunctions / distfunctions.htm 
float sdEllipsoid(in float3 p , in float3 r) // approximated 
 {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
 }

float2 sdStick(float3 p , float3 a , float3 b , float r1 , float r2) // approximated 
 {
    float3 pa = p - a , ba = b - a;
     float h = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.0);
     return float2 (length(pa - ba * h) - lerp(r1 , r2 , h * h * (3.0 - 2.0 * h)) , h);
 }

// http: // iquilezles.org / www / articles / smin / smin.htm 
float4 opU(float4 d1 , float4 d2)
 {
     return (d1.x < d2.x) ? d1 : d2;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

#define ZEROExtended ( min ( iFrame , 0 ) ) 

 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float href;
float hsha;

float4 map(in float3 pos , float atime)
 {
    hsha = 1.0;

    float t1 = frac(atime);
    float t4 = abs(frac(atime * 0.5) - 0.5) / 0.5;

    float p = 4.0 * t1 * (1.0 - t1);
    float pp = 4.0 * (1.0 - 2.0 * t1); // derivative of p 

    float3 cen = float3 (0.5 * (-1.0 + 2.0 * t4) ,
                     pow(p , 2.0 - p) + 0.1 ,
                     floor(atime) + pow(t1 , 0.7) - 1.0);

    // body 
   float2 uu = normalize(float2 (1.0 , -pp));
   float2 vv = float2 (-uu.y , uu.x);

   float sy = 0.5 + 0.5 * p;
   float compress = 1.0 - smoothstep(0.0 , 0.4 , p);
   sy = sy * (1.0 - compress) + compress;
   float sz = 1.0 / sy;

   float3 q = pos - cen;
   float rot = -0.25 * (-1.0 + 2.0 * t4);
   float rc = cos(rot);
   float rs = sin(rot);
   q.xy = mul(float2x2(rc , rs , -rs , rc) , q.xy);
   float3 r = q;
    href = q.y;
   q.yz = float2 (dot(uu , q.yz) , dot(vv , q.yz));

   float4 res = float4 (sdEllipsoid(q , float3 (0.25 , 0.25 * sy , 0.25 * sz)) , 2.0 , 0.0 , 1.0);

   if (res.x - 1.0 < pos.y) // bounding volume 
     {
   float t2 = frac(atime + 0.8);
   float p2 = 0.5 - 0.5 * cos(6.2831 * t2);
   r.z += 0.05 - 0.2 * p2;
   r.y += 0.2 * sy - 0.2;
   float3 sq = float3 (abs(r.x) , r.yz);

   // head 
 float3 h = r;
 float hr = sin(0.791 * atime);
 hr = 0.7 * sign(hr) * smoothstep(0.5 , 0.7 , abs(hr));
 h.xz = mul(float2x2(cos(hr) , sin(hr) , -sin(hr) , cos(hr)) , h.xz);
 float3 hq = float3 (abs(h.x) , h.yz);
     float d = sdEllipsoid(h - float3 (0.0 , 0.20 , 0.02) , float3 (0.08 , 0.2 , 0.15));
  float d2 = sdEllipsoid(h - float3 (0.0 , 0.21 , -0.1) , float3 (0.20 , 0.2 , 0.20));
  d = smin(d , d2 , 0.1);
 res.x = smin(res.x , d , 0.1);

 // belly wrinkles 
 {
float yy = r.y - 0.02 - 2.5 * r.x * r.x;
res.x += 0.001 * sin(yy * 120.0) * (1.0 - smoothstep(0.0 , 0.1 , abs(yy)));
 }

 // arms 
 {
float2 arms = sdStick(sq , float3 (0.18 - 0.06 * hr * sign(r.x) , 0.2 , -0.05) , float3 (0.3 + 0.1 * p2 , -0.2 + 0.3 * p2 , -0.15) , 0.03 , 0.06);
res.xz = smin(res.xz , arms , 0.01 + 0.04 * (1.0 - arms.y) * (1.0 - arms.y) * (1.0 - arms.y));
 }

 // ears 
 {
float t3 = frac(atime + 0.9);
float p3 = 4.0 * t3 * (1.0 - t3);
float2 ear = sdStick(hq , float3 (0.15 , 0.32 , -0.05) , float3 (0.2 + 0.05 * p3 , 0.2 + 0.2 * p3 , -0.07) , 0.01 , 0.04);
res.xz = smin(res.xz , ear , 0.01);
 }

 // mouth 
 {
    d = sdEllipsoid(h - float3 (0.0 , 0.15 + 4.0 * hq.x * hq.x , 0.15) , float3 (0.1 , 0.04 , 0.2));
res.w = 0.3 + 0.7 * clamp(d * 150.0 , 0.0 , 1.0);
res.x = smax(res.x , -d , 0.03);
 }

 // legs 
{
float t6 = cos(6.2831 * (atime * 0.5 + 0.25));
float ccc = cos(1.57 * t6 * sign(r.x));
float sss = sin(1.57 * t6 * sign(r.x));
 float3 base = float3 (0.12 , -0.07 , -0.1); base.y -= 0.1 / sy;
float2 legs = sdStick(sq , base , base + float3 (0.2 , -ccc , sss) * 0.2 , 0.04 , 0.07);
res.xz = smin(res.xz , legs , 0.07);
 }

// eye 
{
float blink = pow(0.5 + 0.5 * sin(2.1 * _Time.y) , 20.0);
float eyeball = sdSphere(hq - float3 (0.08 , 0.27 , 0.06) , 0.065 + 0.02 * blink);
res.x = smin(res.x , eyeball , 0.03);

float3 cq = hq - float3 (0.1 , 0.34 , 0.08);
cq.xy = mul( float2x2(0.8 , 0.6 , -0.6 , 0.8) , cq.xy);
d = sdEllipsoid(cq , float3 (0.06 , 0.03 , 0.03));
res.x = smin(res.x , d , 0.03);

float eo = 1.0 - 0.5 * smoothstep(0.01 , 0.04 , length((hq.xy - float2 (0.095 , 0.285)) * float2 (1.0 , 1.1)));
res = opU(res , float4 (sdSphere(hq - float3 (0.08 , 0.28 , 0.08) , 0.060) , 3.0 , 0.0 , eo));
res = opU(res , float4 (sdSphere(hq - float3 (0.075 , 0.28 , 0.102) , 0.0395) , 4.0 , 0.0 , 1.0));
 }
  }

   // ground 
  float fh = -0.1 - 0.05 * (sin(pos.x * 2.0) + sin(pos.z * 2.0));
  float t5f = frac(atime + 0.05);
  float t5i = floor(atime + 0.05);
  float bt4 = abs(frac(t5i * 0.5) - 0.5) / 0.5;
  float2 bcen = float2 (0.5 * (-1.0 + 2.0 * bt4) , t5i + pow(t5f , 0.7) - 1.0);

  float k = length(pos.xz - bcen);
  float tt = t5f * 15.0 - 6.2831 - k * 3.0;
  fh -= 0.1 * exp(-k * k) * sin(tt) * exp(-max(tt , 0.0) / 2.0) * smoothstep(0.0 , 0.01 , t5f);
  float d = pos.y - fh;

  // bubbles 
  {
 float3 vp = float3 (mod(abs(pos.x) , 3.0) - 1.5 , pos.y , mod(pos.z + 1.5 , 3.0) - 1.5);
 float2 id = float2 (floor(pos.x / 3.0) , floor((pos.z + 1.5) / 3.0));
 float fid = id.x * 11.1 + id.y * 31.7;
 float fy = frac(fid * 1.312 + atime * 0.1);
 float y = -1.0 + 4.0 * fy;
 float3 rad = float3 (0.7 , 1.0 + 0.5 * sin(fid) , 0.7);
 rad -= 0.1 * (sin(pos.x * 3.0) + sin(pos.y * 4.0) + sin(pos.z * 5.0));
 float siz = 4.0 * fy * (1.0 - fy);
 float d2 = sdEllipsoid(vp - float3 (0.5 , y , 0.0) , siz * rad);

 d2 -= 0.03 * smoothstep(-1.0 , 1.0 , sin(18.0 * pos.x) + sin(18.0 * pos.y) + sin(18.0 * pos.z));
 d2 *= 0.6;
 d2 = min(d2 , 2.0);
 d = smin(d , d2 , 0.32);
 if (d < res.x) { res = float4 (d , 1.0 , 0.0 , 1.0); hsha = sqrt(siz); }
  }

  // candy 
  {
 float fs = 5.0;
 float3 qos = fs * float3 (pos.x , pos.y - fh , pos.z);
 float2 id = float2 (floor(qos.x + 0.5) , floor(qos.z + 0.5));
 float3 vp = float3 (frac(qos.x + 0.5) - 0.5 , qos.y , frac(qos.z + 0.5) - 0.5);
 vp.xz += 0.1 * cos(id.x * 130.143 + id.y * 120.372 + float2 (0.0 , 2.0));
 float den = sin(id.x * 0.1 + sin(id.y * 0.091)) + sin(id.y * 0.1);
 float fid = id.x * 0.143 + id.y * 0.372;
 float ra = smoothstep(0.0 , 0.1 , den * 0.1 + frac(fid) - 0.95);
 d = sdSphere(vp , 0.35 * ra) / fs;
 if (d < res.x) res = float4 (d , 5.0 , qos.y , 1.0);
  }

 return res;
}

float4 castRay(in float3 ro , in float3 rd , float time)
 {
    float4 res = float4 (-1.0 , -1.0 , 0.0 , 1.0);

    float tmin = 0.5;
    float tmax = 20.0;

     #if 1 
    // raytrace bounding plane 
   float tp = (3.5 - ro.y) / rd.y;
   if (tp > 0.0) tmax = min(tmax , tp);
    #endif 

   // raymarch scene 
  float t = tmin;
  for (int i = 0; i < 256 && t < tmax; i++)
   {
      float4 h = map(ro + rd * t , time);
      if (abs(h.x) < (0.0005 * t))
       {
          res = float4 (t , h.yzw);
          break;
       }
      t += h.x;
   }

  return res;
}

// http: // iquilezles.org / www / articles / rmshadows / rmshadows.htm 
float calcSoftshadow(in float3 ro , in float3 rd , float time)
 {
    float res = 1.0;

    float tmax = 12.0;
    #if 1 
    float tp = (3.5 - ro.y) / rd.y; // raytrace bounding plane 
    if (tp > 0.0) tmax = min(tmax , tp);
     #endif 

    float t = 0.02;
    for (int i = 0; i < 50; i++)
     {
          float h = map(ro + rd * t , time).x;
        res = min(res , lerp(1.0 , 16.0 * h / t , hsha));
        t += clamp(h , 0.05 , 0.40);
        if (res < 0.005 || t > tmax) break;
     }
    return clamp(res , 0.0 , 1.0);
 }

// http: // iquilezles.org / www / articles / normalsSDF / normalsSDF.htm 
float3 calcNormal(in float3 pos , float time)
 {

#if 0 
    float2 e = float2 (1.0 , -1.0) * 0.5773 * 0.001;
    return normalize(e.xyy * map(pos + e.xyy , time).x +
                           e.yyx * map(pos + e.yyx , time).x +
                           e.yxy * map(pos + e.yxy , time).x +
                           e.xxx * map(pos + e.xxx , time).x);
#else 
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map ( ) 4 times 
   float3 n = float3 (0.0 , 0.0 , 0.0);
   for (int i = ZEROExtended; i < 4; i++)
    {
       float3 e = 0.5773 * (2.0 * float3 ((((i + 3) >> 1) & 1) , ((i >> 1) & 1) , (i & 1)) - 1.0);
       n += e * map(pos + 0.001 * e , time).x;
    }
   return normalize(n);
#endif 
 }

float calcOcclusion(in float3 pos , in float3 nor , float time)
 {
     float occ = 0.0;
    float sca = 1.0;
    for (int i = ZEROExtended; i < 5; i++)
     {
        float h = 0.01 + 0.11 * float(i) / 4.0;
        float3 opos = pos + h * nor;
        float d = map(opos , time).x;
        occ += (h - d) * sca;
        sca *= 0.95;
     }
    return clamp(1.0 - 2.0 * occ , 0.0 , 1.0);
 }

float3 render(in float3 ro , in float3 rd , float time)
 {
    // sky dome 
   float3 col = float3 (0.5 , 0.8 , 0.9) - max(rd.y , 0.0) * 0.5;
   // sky clouds 
  float2 uv = 1.5 * rd.xz / rd.y;
  float cl = 1.0 * (sin(uv.x) + sin(uv.y)); 
  uv = mul(uv, mul(float2x2 (0.8 , 0.6 , -0.6 , 0.8) , 2.1));
        cl += 0.5 * (sin(uv.x) + sin(uv.y));
  col += 0.1 * (-1.0 + 2.0 * smoothstep(-0.1 , 0.1 , cl - 0.4));
  // sky horizon 
  col = lerp(col , float3 (0.5 , 0.7 , .9) , exp(-10.0 * max(rd.y , 0.0)));


  // scene geometry 
 float4 res = castRay(ro , rd , time);
 if (res.y > -0.5)
  {
     float t = res.x;
     float3 pos = ro + t * rd;
     float3 nor = calcNormal(pos , time);
     float3 ref = reflect(rd , nor);
     float focc = res.w;

     // material 
      col = float3 (0.2 , 0.2 , 0.2);
    float ks = 1.0;

    if (res.y > 4.5) // candy 
     {
         col = float3 (0.14 , 0.048 , 0.0);
         float2 id = floor(5.0 * pos.xz + 0.5);
           col += 0.036 * cos((id.x * 11.1 + id.y * 37.341) + float3 (0.0 , 1.0 , 2.0));
         col = max(col , 0.0);
         focc = clamp(4.0 * res.z , 0.0 , 1.0);
     }
    else if (res.y > 3.5) // eyeball 
     {
        col = float3 (0.0 , 0.0 , 0.0);
     }
    else if (res.y > 2.5) // iris 
     {
        col = float3 (0.4 , 0.4 , 0.4);
     }
    else if (res.y > 1.5) // body 
     {
        col = lerp(float3 (0.144 , 0.09 , 0.0036) , float3 (0.36 , 0.1 , 0.04) , res.z * res.z);
        col = lerp(col , float3 (0.14 , 0.09 , 0.06) * 2.0 , (1.0 - res.z) * smoothstep(-0.15 , 0.15 , -href));
     }
      else // terrain 
     {
        // base greenExtended 
       col = float3 (0.05 , 0.09 , 0.02);
       float f = 0.2 * (-1.0 + 2.0 * smoothstep(-0.2 , 0.2 , sin(18.0 * pos.x) + sin(18.0 * pos.y) + sin(18.0 * pos.z)));
       col += f * float3 (0.06 , 0.06 , 0.02);
       ks = 0.5 + pos.y * 0.15;

       // footprints 
   float2 mp = float2 (pos.x - 0.5 * (mod(floor(pos.z + 0.5) , 2.0) * 2.0 - 1.0) , frac(pos.z + 0.5) - 0.5);
   float mark = 1.0 - smoothstep(0.1 , 0.5 , length(mp));
   mark *= smoothstep(0.0 , 0.1 , floor(time) - floor(pos.z + 0.5));
   col *= lerp(float3 (1.0 , 1.0 , 1.0) , float3 (0.5 , 0.5 , 0.4) , mark);
   ks *= 1.0 - 0.5 * mark;
}

    // lighting ( sun , sky , bounce , back , sss ) 
   float occ = calcOcclusion(pos , nor , time) * focc;
   float fre = clamp(1.0 + dot(nor , rd) , 0.0 , 1.0);

   float3 sun_lig = normalize(float3 (0.6 , 0.35 , 0.5));
   float sun_dif = clamp(dot(nor , sun_lig) , 0.0 , 1.0);
   float3 sun_hal = normalize(sun_lig - rd);
   float sun_sha = calcSoftshadow(pos , sun_lig , time);
     float sun_spe = ks * pow(clamp(dot(nor , sun_hal) , 0.0 , 1.0) , 8.0) * sun_dif * (0.04 + 0.96 * pow(clamp(1.0 + dot(sun_hal , rd) , 0.0 , 1.0) , 5.0));
     float sky_dif = sqrt(clamp(0.5 + 0.5 * nor.y , 0.0 , 1.0));
   float sky_spe = ks * smoothstep(0.0 , 0.5 , ref.y) * (0.04 + 0.96 * pow(fre , 4.0));
   float bou_dif = sqrt(clamp(0.1 - 0.9 * nor.y , 0.0 , 1.0)) * clamp(1.0 - 0.1 * pos.y , 0.0 , 1.0);
   float bac_dif = clamp(0.1 + 0.9 * dot(nor , normalize(float3 (-sun_lig.x , 0.0 , -sun_lig.z))) , 0.0 , 1.0);
   float sss_dif = fre * sky_dif * (0.25 + 0.75 * sun_dif * sun_sha);

     float3 lin = float3 (0.0 , 0.0 , 0.0);
   lin += sun_dif * float3 (8.10 , 6.00 , 4.20) * float3 (sun_sha , sun_sha * sun_sha * 0.5 + 0.5 * sun_sha , sun_sha * sun_sha);
   lin += sky_dif * float3 (0.50 , 0.70 , 1.00) * occ;
   lin += bou_dif * float3 (0.20 , 0.70 , 0.10) * occ;
   lin += bac_dif * float3 (0.45 , 0.35 , 0.25) * occ;
   lin += sss_dif * float3 (3.25 , 2.75 , 2.50) * occ;
     col = col * lin;
     col += sun_spe * float3 (9.90 , 8.10 , 6.30) * sun_sha;
   col += sky_spe * float3 (0.20 , 0.30 , 0.65) * occ * occ;

   col = pow(col , float3 (0.8 , 0.9 , 1.0));

   // fog 
  col = lerp(col , float3 (0.5 , 0.7 , 0.9) , 1.0 - exp(-0.0001 * t * t * t));
}

return col;
}

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = (cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float3 tot = float3 (0.0 , 0.0 , 0.0);
#if AA > 1 
    for (int m = ZEROExtended; m < AA; m++)
    for (int n = ZEROExtended; n < AA; n++)
     {
        // pixel coordinates 
       float2 o = float2 (float(m) , float(n)) / float(AA) - 0.5;
       float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + o)) / _ScreenParams.y;
       // time coordinate ( motion blurred , shutter = 0.5 ) 
      float d = 0.5 * sin(fragCoord.x * 147.0) * sin(fragCoord.y * 131.0);
      float time = _Time.y - 0.5 * (1.0 / 24.0) * (float(m * AA + n) + d) / float(AA * AA - 1);
#else 
        float2 p = (-_ScreenParams.xy + 2.0 * fragCoord) / _ScreenParams.y;
        float time = _Time.y;
#endif 
        time += -2.6;
        time *= 0.9;

        // camera 
       float cl = sin(0.5 * time);
       float an = 1.57 + 0.7 * sin(0.15 * time);
       float3 ta = float3 (0.0 , 0.65 , -0.6 + time * 1.0 - 0.4 * cl);
       float3 ro = ta + float3 (1.3 * cos(an) , -0.250 , 1.3 * sin(an));
       float ti = frac(time - 0.15);
       ti = 4.0 * ti * (1.0 - ti);
       ta.y += 0.15 * ti * ti * (3.0 - 2.0 * ti) * smoothstep(0.4 , 0.9 , cl);

       // camera bounce 
      float t4 = abs(frac(time * 0.5) - 0.5) / 0.5;
      float bou = -1.0 + 2.0 * t4;
      ro += 0.06 * sin(time * 12.0 + float3 (0.0 , 2.0 , 4.0)) * smoothstep(0.85 , 1.0 , abs(bou));

      // camera - to - world rotation 
     float3x3 ca = setCamera(ro , ta , 0.0);

     // ray direction 
    float3 rd = mul(ca , normalize(float3 (p , 1.8)));

    // render 
   float3 col = render(ro , rd , time);

   // color grading 
  col = col * float3 (1.11 , 0.89 , 0.79);

  // compress 
 col = 1.35 * col / (1.0 + col);

 // gamma 
col = pow(col , float3 (0.4545, 0.4545, 0.4545));

tot += col;
#if AA > 1 
     }
    tot /= float(AA * AA);
#endif 

    // s - surve 
   tot = clamp(tot , 0.0 , 1.0);
   tot = tot * tot * (3.0 - 2.0 * tot);

   // vignetting 
  float2 q = fragCoord / _ScreenParams.xy;
  tot *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.25);

  // output 
 fragColor = float4 (tot , 1.0);
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