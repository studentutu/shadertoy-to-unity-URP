Shader "UmutBebek/URP/ShaderToy/Mandelbulb - derivative ltfSWn"
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
            //LOD 300

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
            //Blend One One
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

           // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// The source code for these videos from 2009: 
// https: // www.youtube.com / watch?v = eKUh4nkmQbc 
// https: // www.youtube.com / watch?v = erS6SKqtXLY 

// More info here: http: // iquilezles.org / www / articles / mandelbulb / mandelbulb.htm 

// See https: // www.shadertoy.com / view / MdfGRr to see the Julia counterpart 


//#if HW_PERFORMANCE == 0 
//#define AA 1 
//#else 
#define AA 1 // make AA 1 for slow machines or 3 for fast machines 
//#endif 

float2 isphere(in float4 sph , in float3 ro , in float3 rd)
 {
    float3 oc = ro - sph.xyz;

     float b = dot(oc , rd);
     float c = dot(oc , oc) - sph.w * sph.w;
    float h = b * b - c;

    if (h < 0.0) return float2 (-1.0, -1.0);

    h = sqrt(h);

    return -b + float2 (-h , h);
 }

#define ZERO ( min ( iFrame , 0 ) ) 


float map(in float3 p , out float4 resColor)
 {
    float3 w = p;
    float m = dot(w , w);

    float4 trap = float4 (abs(w) , m);
     float dz = 1.0;


     for (int i = 0; i < 4; i++)
     {
#if 0 
        float m2 = m * m;
        float m4 = m2 * m2;
          dz = 8.0 * sqrt(m4 * m2 * m) * dz + 1.0;

        float x = w.x; float x2 = x * x; float x4 = x2 * x2;
        float y = w.y; float y2 = y * y; float y4 = y2 * y2;
        float z = w.z; float z2 = z * z; float z4 = z2 * z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt(k3 * k3 * k3 * k3 * k3 * k3 * k3);
        float k1 = x4 + y4 + z4 - 6.0 * y2 * z2 - 6.0 * x2 * y2 + 2.0 * z2 * x2;
        float k4 = x2 - y2 + z2;

        w.x = p.x + 64.0 * x * y * z * (x2 - z2) * k4 * (x4 - 6.0 * x2 * z2 + z4) * k1 * k2;
        w.y = p.y + -16.0 * y2 * k3 * k4 * k4 + k1 * k1;
        w.z = p.z + -8.0 * y * k4 * (x4 * x4 - 28.0 * x4 * x2 * z2 + 70.0 * x4 * z4 - 28.0 * x2 * z2 * z4 + z4 * z4) * k1 * k2;
#else 
        dz = 8.0 * pow(sqrt(m) , 7.0) * dz + 1.0;
        // dz = 8.0 * pow ( m , 3.5 ) * dz + 1.0 ; 

     float r = length(w);
     float b = 8.0 * acos(w.y / r);
     float a = 8.0 * atan2(w.x , w.z);
     w = p + pow(r , 8.0) * float3 (sin(b) * sin(a) , cos(b) , sin(b) * cos(a));
#endif 

        trap = min(trap , float4 (abs(w) , m));

        m = dot(w , w);
          if (m > 256.0)
            break;
     }

    resColor = float4 (m , trap.yzw);

    return 0.25 * log(m) * sqrt(m) / dz;
 }

float intersect(in float3 ro , in float3 rd , out float4 rescol , in float px)
 {
    float res = -1.0;

    // bounding sphere 
   float2 dis = isphere(float4 (0.0 , 0.0 , 0.0 , 1.25) , ro , rd);
   if (dis.y < 0.0)
       return -1.0;
   dis.x = max(dis.x , 0.0);
   dis.y = min(dis.y , 10.0);

   // raymarch fractal distance field 
   float4 trap;

   float t = dis.x;
   for (int i = 0; i < 128; i++)
   {
      float3 pos = ro + rd * t;
      float th = 0.25 * px * t;
        float h = map(pos , trap);
        if (t > dis.y || h < th) break;
      t += h;
   }


  if (t < dis.y)
   {
      rescol = trap;
      res = t;
   }

  return res;
}

float softshadow(in float3 ro , in float3 rd , in float k)
 {
    float res = 1.0;
    float t = 0.0;
    for (int i = 0; i < 64; i++)
     {
        float4 kk;
        float h = map(ro + rd * t , kk);
        res = min(res , k * h / t);
        if (res < 0.001) break;
        t += clamp(h , 0.01 , 0.2);
     }
    return clamp(res , 0.0 , 1.0);
 }

float3 calcNormal(in float3 pos , in float t , in float px)
 {
    float4 tmp;
    float2 e = float2 (1.0 , -1.0) * 0.5773 * 0.25 * px;
    return normalize(e.xyy * map(pos + e.xyy , tmp) +
                           e.yyx * map(pos + e.yyx , tmp) +
                           e.yxy * map(pos + e.yxy , tmp) +
                           e.xxx * map(pos + e.xxx , tmp));
 }

const float3 light1 = float3 (0.577 , 0.577 , -0.577);
const float3 light2 = float3 (-0.707 , 0.000 , 0.707);


float3 render(in float2 p , in float4x4 cam)
 {
    // ray setup 
  const float fle = 1.5;

  float2 sp = (2.0 * p - _ScreenParams.xy) / _ScreenParams.y;
  float px = 2.0 / (_ScreenParams.y * fle);

  float3 ro = float3 (cam[0].w , cam[1].w , cam[2].w);
   float3 rd = normalize((mul(cam , float4 (sp , fle , 0.0))).xyz);

   // intersect fractal 
   float4 tra;
  float t = intersect(ro , rd , tra , px);

   float3 col;

   // color sky 
  if (t < 0.0)
   {
        col = float3 (0.8 , .9 , 1.1) * (0.6 + 0.4 * rd.y);
        col += 5.0 * float3 (0.8 , 0.7 , 0.5) * pow(clamp(dot(rd , light1) , 0.0 , 1.0) , 32.0);
    }
  // color fractal 
  else
   {
      // color 
     col = float3 (0.01, 0.01, 0.01);
       col = lerp(col , float3 (0.10 , 0.20 , 0.30) , clamp(tra.y , 0.0 , 1.0));
        col = lerp(col , float3 (0.02 , 0.10 , 0.30) , clamp(tra.z * tra.z , 0.0 , 1.0));
     col = lerp(col , float3 (0.30 , 0.10 , 0.02) , clamp(pow(tra.w , 6.0) , 0.0 , 1.0));
     col *= 0.5;
     // col = float3 ( 0.1 ) ; 

   // lighting terms 
  float3 pos = ro + t * rd;
  float3 nor = calcNormal(pos , t , px);
  float3 hal = normalize(light1 - rd);
  float3 ref = reflect(rd , nor);
  float occ = clamp(0.05 * log(tra.x) , 0.0 , 1.0);
  float fac = clamp(1.0 + dot(rd , nor) , 0.0 , 1.0);

  // sun 
 float sha1 = softshadow(pos + 0.001 * nor , light1 , 32.0);
 float dif1 = clamp(dot(light1 , nor) , 0.0 , 1.0) * sha1;
 float spe1 = pow(clamp(dot(nor , hal) , 0.0 , 1.0) , 32.0) * dif1 * (0.04 + 0.96 * pow(clamp(1.0 - dot(hal , light1) , 0.0 , 1.0) , 5.0));
 // bounce 
float dif2 = clamp(0.5 + 0.5 * dot(light2 , nor) , 0.0 , 1.0) * occ;
// sky 
float dif3 = (0.7 + 0.3 * nor.y) * (0.2 + 0.8 * occ);

  float3 lin = float3 (0.0, 0.0, 0.0);
       lin += 7.0 * float3 (1.50 , 1.10 , 0.70) * dif1;
       lin += 4.0 * float3 (0.25 , 0.20 , 0.15) * dif2;
      lin += 1.5 * float3 (0.10 , 0.20 , 0.30) * dif3;
     lin += 2.5 * float3 (0.35 , 0.30 , 0.25) * (0.05 + 0.95 * occ); // ambient 
      lin += 4.0 * fac * occ; // fake SSS 
  col *= lin;
  col = pow(col , float3 (0.7 , 0.9 , 1.0)); // fake SSS 
col += spe1 * 15.0;
// col += 8.0 * float3 ( 0.8 , 0.9 , 1.0 ) * ( 0.2 + 0.8 * occ ) * ( 0.03 + 0.97 * pow ( fac , 5.0 ) ) * smoothstep ( 0.0 , 0.1 , ref.y ) * softshadow ( pos + 0.01 * nor , ref , 2.0 ) ; 
// col = float3 ( occ * occ ) ; 
}

  // gamma 
  col = sqrt(col);

  // vignette 
 col *= 1.0 - 0.05 * length(sp);

 return col;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float time = _Time.y * .1;

    // camera 
    float di = 1.4 + 0.1 * cos(.29 * time);
    float3 ro = di * float3 (cos(.33 * time) , 0.8 * sin(.37 * time) , sin(.31 * time));
    float3 ta = float3 (0.0 , 0.1 , 0.0);
    float cr = 0.5 * cos(0.1 * time);

    // camera matrix 
    float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
   float3 cw = normalize(ta - ro);
    float3 cu = normalize(cross(cw , cp));
    float3 cv = (cross(cu , cw));
   float4x4 cam = float4x4 (cu , ro.x , cv , ro.y , cw , ro.z , 0.0 , 0.0 , 0.0 , 1.0);

   // render 
  #if AA < 2 
   float3 col = render(fragCoord , cam);
  #else 
  float3 col = float3 (0.0, 0.0, 0.0);
  for (int j = ZERO; j < AA; j++)
  for (int i = ZERO; i < AA; i++)
   {
       col += render(fragCoord + (float2 (i , j) / float(AA)) , cam);
   }
   col /= float(AA * AA);
  #endif 

   fragColor = float4 (col , 1.0);
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