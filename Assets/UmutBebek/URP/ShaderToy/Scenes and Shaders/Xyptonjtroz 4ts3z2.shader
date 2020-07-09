Shader "UmutBebek/URP/ShaderToy/Xyptonjtroz 4ts3z2"
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
            ITR("ITR", float) = 100
FAR("FAR", float) = 30.

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
            float ITR;
float FAR;

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

float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
{
    //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
    float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
    return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
}

// Xyptonjtroz by nimitz ( twitter: @stormoid ) 
// https: // www.shadertoy.com / view / 4ts3z2 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

// Audio by Dave_Hoskins 



#define time _Time.y 

 /*
     Believable animated volumetric dust storm in 7 samples ,
     blending each layer in based on geometry distance allows to
     render it without visible seams. 3d Triangle noise is
     used for the dust volume.

     Also included is procedural bump mapping and glow based on
     curvature * fresnel. ( see: https: // www.shadertoy.com / view / Xts3WM )


     Further explanation of the dust generation ( per Dave's request ) :

     The basic idea is to have layers of gradient shaded volumetric
     animated noise. The problem is when geometry is intersected
     before the ray reaches the far plane. A way to smoothly blend
     the low sampled noise is needed. So I am blending ( smoothstep )
     each dust layer based on current ray distance and the solid
     interesction distance. I am also scaling the noise taps as a
     function of the current distance so that the distant dust doesn't
     appear too noisy and as a function of current height to get some
     "ground hugging" effect.

 */

float2x2 mm2(in float a) { float c = cos(a) , s = sin(a); return float2x2 (c , s , -s , c); }

float height(in float2 p)
 {
    p *= 0.2;
    return sin(p.y) * 0.4 + sin(p.x) * 0.4;
 }

// smooth min ( http: // iquilezles.org / www / articles / smin / smin.htm ) 
float smin(float a , float b)
 {
     float h = clamp(0.5 + 0.5 * (b - a) / 0.7 , 0.0 , 1.0);
     return lerp(b , a , h) - 0.7 * h * (1.0 - h);
 }


float2 nmzHash22(float2 q)
 {
    int2 p = int2(int2 (q));
    p = p * int2(3266489917U , 668265263U) + p.yx;
    p = p * (p.yx ^ (p >> 15U));
    return float2 (p ^ (p >> 16U)) * (1.0 / float2 (0xffffffffU, 0xffffffffU));
 }

float vine(float3 p , in float c , in float h)
 {
    p.y += sin(p.z * 0.2625) * 2.5;
    p.x += cos(p.z * 0.1575) * 3.;
    float2 q = float2 (mod(p.x , c) - c / 2. , p.y);
    return length(q) - h - sin(p.z * 2. + sin(p.x * 7.) * 0.5 + time * 0.5) * 0.13;
 }

float map(float3 p)
 {
    p.y += height(p.zx);

    float3 bp = p;
    float2 hs = nmzHash22(floor(p.zx / 4.));
    p.zx = mod(p.zx , 4.) - 2.;

    float d = p.y + 0.5;
    p.y -= hs.x * 0.4 - 0.15;
    p.zx += hs * 1.3;
    d = smin(d , length(p) - hs.x * 0.4);

    d = smin(d , vine(bp + float3 (1.8 , 0. , 0) , 15. , .8));
    d = smin(d , vine(bp.zyx + float3 (0. , 0 , 17.) , 20. , 0.75));

    return d * 1.1;
 }

float march(in float3 ro , in float3 rd)
 {
     float precis = 0.002;
    float h = precis * 2.0;
    float d = 0.;
    for (int i = 0; i < ITR; i++)
     {
        if (abs(h) < precis || d > FAR) break;
        d += h;
         float res = map(ro + rd * d);
        h = res;
     }
     return d;
 }

float tri(in float x) { return abs(frac(x) - .5); }
float3 tri3(in float3 p) { return float3 (tri(p.z + tri(p.y * 1.)) , tri(p.z + tri(p.x * 1.)) , tri(p.y + tri(p.x * 1.))); }



float triNoise3d(in float3 p , in float spd)
 {
    float z = 1.4;
     float rz = 0.;
    float3 bp = p;
     for (float i = 0.; i <= 3.; i++)
      {
        float3 dg = tri3(bp * 2.);
        p += (dg + time * spd);

        bp *= 1.8;
          z *= 1.5;
          p *= 1.2;
          // p.xz *= m2 ; 

         rz += (tri(p.z + tri(p.x + tri(p.y)))) / z;
         bp += 0.14;
       }
      return rz;
  }

 float fogmap(in float3 p , in float d)
  {
     p.x += time * 1.5;
     p.z += sin(p.x * .5);
     return triNoise3d(p * 2.2 / (d + 20.) , 0.2) * (1. - smoothstep(0. , .7 , p.y));
  }

 float3 fog(in float3 col , in float3 ro , in float3 rd , in float mt)
  {
     float d = .5;
     for (int i = 0; i < 7; i++)
      {
         float3 pos = ro + rd * d;
         float rz = fogmap(pos , d);
           float grd = clamp((rz - fogmap(pos + .8 - float(i) * 0.1 , d)) * 3. , 0.1 , 1.);
         float3 col2 = (float3 (.1 , 0.8 , .5) * .5 + .5 * float3 (.5 , .8 , 1.) * (1.7 - grd)) * 0.55;
         col = lerp(col , col2 , clamp(rz * smoothstep(d - 0.4 , d + 2. + d * .75 , mt) , 0. , 1.));
         d *= 1.5 + 0.3;
         if (d > mt) break;
      }
     return col;
  }

 float3 normal(in float3 p)
  {
     float2 e = float2 (-1. , 1.) * 0.005;
      return normalize(e.yxx * map(p + e.yxx) + e.xxy * map(p + e.xxy) +
                           e.xyx * map(p + e.xyx) + e.yyy * map(p + e.yyy));
  }

 float bnoise(in float3 p)
  {
     float n = sin(triNoise3d(p * .3 , 0.0) * 11.) * 0.6 + 0.4;
     n += sin(triNoise3d(p * 1. , 0.05) * 40.) * 0.1 + 0.9;
     return (n * n) * 0.003;
  }

 float3 bump(in float3 p , in float3 n , in float ds)
  {
     float2 e = float2 (.005 , 0);
     float n0 = bnoise(p);
     float3 d = float3 (bnoise(p + e.xyy) - n0 , bnoise(p + e.yxy) - n0 , bnoise(p + e.yyx) - n0) / e.x;
     n = normalize(n - d * 2.5 / sqrt(ds));
     return n;
  }

 float shadow(in float3 ro , in float3 rd , in float mint , in float tmax)
  {
      float res = 1.0;
     float t = mint;
     for (int i = 0; i < 10; i++)
      {
           float h = map(ro + rd * t);
         res = min(res , 4. * h / t);
         t += clamp(h , 0.05 , .5);
         if (h < 0.001 || t > tmax) break;
      }
     return clamp(res , 0.0 , 1.0);

  }

 float curv(in float3 p , in float w)
  {
     float2 e = float2 (-1. , 1.) * w;

     float t1 = map(p + e.yxx) , t2 = map(p + e.xxy);
     float t3 = map(p + e.xyx) , t4 = map(p + e.yyy);

     return .125 / (e.x * e.x) * (t1 + t2 + t3 + t4 - 4. * map(p));
  }

 half4 LitPassFragment(Varyings input) : SV_Target  {
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 p = fragCoord.xy / _ScreenParams.xy - 0.5;
     float2 q = fragCoord.xy / _ScreenParams.xy;
      p.x *= _ScreenParams.x / _ScreenParams.y;
     float2 mo = iMouse.xy / _ScreenParams.xy - .5;
     mo = (mo == float2 (-.5, -.5)) ? mo = float2 (-0.1 , 0.07) : mo;
      mo.x *= _ScreenParams.x / _ScreenParams.y;

      float3 ro = float3 (smoothstep(0. , 1. , tri(time * .45) * 2.) * 0.1 , smoothstep(0. , 1. , tri(time * 0.9) * 2.) * 0.07 , -time * 0.6);
     ro.y -= height(ro.zx) + 0.05;
     mo.x += smoothstep(0.6 , 1. , sin(time * .6) * 0.5 + 0.5) - 1.5;
     float3 eyedir = normalize(float3 (cos(mo.x) , mo.y * 2. - 0.2 + sin(time * 0.45 * 1.57) * 0.1 , sin(mo.x)));
     float3 rightdir = normalize(float3 (cos(mo.x + 1.5708) , 0. , sin(mo.x + 1.5708)));
     float3 updir = normalize(cross(rightdir , eyedir));
      float3 rd = normalize((p.x * rightdir + p.y * updir) * 1. + eyedir);

     float3 ligt = normalize(float3 (.5 , .05 , -.2));
     float3 ligt2 = normalize(float3 (.5 , -.1 , -.2));

      float rz = march(ro , rd);

     float3 fogb = lerp(float3 (.7 , .8 , .8) * 0.3 , float3 (1. , 1. , .77) * .95 , pow(dot(rd , ligt2) + 1.2 , 2.5) * .25);
     fogb *= clamp(rd.y * .5 + .6 , 0. , 1.);
     float3 col = fogb;

     if (rz < FAR)
      {
         float3 pos = ro + rz * rd;
         float3 nor = normal(pos);
         float d = distance(pos , ro);
         nor = bump(pos , nor , d);
         float crv = clamp(curv(pos , .4) , .0 , 10.);
         float shd = shadow(pos , ligt , 0.1 , 3.);
         float dif = clamp(dot(nor , ligt) , 0.0 , 1.0) * shd;
         float spe = pow(clamp(dot(reflect(rd , nor) , ligt) , 0.0 , 1.0) , 50.) * shd;
         float fre = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 1.5);
         float3 brdf = float3 (0.10 , 0.11 , 0.13);
         brdf += 1.5 * dif * float3 (1.00 , 0.90 , 0.7);
         col = lerp(float3 (0.1 , 0.2 , 1) , float3 (.3 , .5 , 1) , pos.y * .5) * 0.2 + .1;
         col *= (sin(bnoise(pos) * 900.) * 0.2 + 0.8);
         col = col * brdf + col * spe * .5 + fre * float3 (.7 , 1. , 0.2) * .3 * crv;
      }

     // ordinary distance fog first 
    col = lerp(col , fogb , smoothstep(FAR - 7. , FAR , rz));

    // then volumetric fog 
   col = fog(col , ro , rd , rz);

   // post 
   col = pow(col, float3 (0.8, 0.8, 0.8));
   //col = pow(col , float3 (2.5 , 2.5 , 2.5));
  col *= 1. - smoothstep(0.1 , 2. , length(p));

   fragColor = float4 (col , 1.0);
   //fragColor.xyz = float3(max(0,fragColor.x-0.2), max(0, fragColor.y - 0.2), max(0, fragColor.z - 0.2));
   fragColor.xyz -= 0.1;
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