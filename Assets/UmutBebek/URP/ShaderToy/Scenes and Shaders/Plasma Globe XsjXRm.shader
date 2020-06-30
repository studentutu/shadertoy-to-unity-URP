Shader "UmutBebek/URP/ShaderToy/Plasma Globe XsjXRm"
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
            NUM_RAYS("NUM_RAYS", float) = 13.
VOLUMETRIC_STEPS("VOLUMETRIC_STEPS", float) = 19
MAX_ITER("MAX_ITER", float) = 35
FAR("FAR", float) = 6.

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
    float NUM_RAYS;
float VOLUMETRIC_STEPS;
float MAX_ITER;
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

// Plasma Globe by nimitz ( twitter: @stormoid ) 
// https: // www.shadertoy.com / view / XsjXRm 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

// looks best with around 25 rays 







#define time _Time.y * 1.1 


float2x2 mm2(in float a) { float c = cos(a) , s = sin(a); return float2x2 (c , -s , s , c); }
float noise(in float x) { return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , float2 (x * .01 , 1.) , 0.0).x; }

float hash(float n) { return frac(sin(n) * 43758.5453); }

float noise(in float3 p)
 {
     float3 ip = floor(p);
    float3 fp = frac(p);
     fp = fp * fp * (3.0 - 2.0 * fp);

     float2 tap = (ip.xy + float2 (37.0 , 17.0) * ip.z) + fp.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (tap + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , fp.z);
 }



        // See: https: // www.shadertoy.com / view / XdfXRj 
       float flow(in float3 p , in float t)
        {
            float z = 2.;
            float rz = 0.;
            float3 bp = p;
            for (float i = 1.; i < 5.; i++)
             {
                 p += time * .1;
                 rz += (sin(noise(p + t * 0.8) * 6.) * 0.5 + 0.5) / z;
                 p = lerp(bp , p , 0.6);
                 z *= 2.;
                 p *= 2.01;
               p = mul(p, float3x3(0.00, 0.80, 0.60,
                   -0.80, 0.36, -0.48,
                   -0.60, -0.48, 0.64));
             }
            return rz;
        }

       // could be improved 
      float sins(in float x)
       {
            float rz = 0.;
          float z = 2.;
          for (float i = 0.; i < 3.; i++)
            {
              rz += abs(frac(x * 1.4) - 0.5) / z;
              x *= 1.3;
              z *= 1.15;
              x -= time * .65 * z;
           }
          return rz;
       }

      float segm(float3 p , float3 a , float3 b)
       {
          float3 pa = p - a;
           float3 ba = b - a;
           float h = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.);
           return length(pa - ba * h) * .5;
       }

      float3 path(in float i , in float d)
       {
          float3 en = float3 (0. , 0. , 1.);
          float sns2 = sins(d + i * 0.5) * 0.22;
          float sns = sins(d + i * .6) * 0.21;
          en.xz = mul(en.xz, mm2((hash(i * 10.569) - .5) * 6.2 + sns2));
          en.xy = mul(en.xy, mm2((hash(i * 4.732) - .5) * 6.2 + sns));
          return en;
       }

      float2 map(float3 p , float i)
       {
           float lp = length(p);
          float3 bg = float3 (0. , 0. , 0.);
          float3 en = path(i , lp);

          float ins = smoothstep(0.11 , .46 , lp);
          float outs = .15 + smoothstep(.0 , .15 , abs(lp - 1.));
          p *= ins * outs;
          float id = ins * outs;

          float rz = segm(p , bg , en) - 0.011;
          return float2 (rz , id);
       }

      float march(in float3 ro , in float3 rd , in float startf , in float maxd , in float j)
       {
           float precis = 0.001;
          float h = 0.5;
          float d = startf;
          for (int i = 0; i < MAX_ITER; i++)
           {
              if (abs(h) < precis || d > maxd) break;
              d += h * 1.2;
               float res = map(ro + rd * d , j).x;
              h = res;
           }
           return d;
       }

      // volumetric marching 
     float3 vmarch(in float3 ro , in float3 rd , in float j , in float3 orig)
      {
         float3 p = ro;
         float2 r = float2 (0. , 0.);
         float3 sum = float3 (0 , 0 , 0);
         float w = 0.;
         for (int i = 0; i < VOLUMETRIC_STEPS; i++)
          {
             r = map(p , j);
             p += rd * .03;
             float lp = length(p);

             float3 col = sin(float3 (1.05 , 2.5 , 1.52) * 3.94 + r.y) * .85 + 0.4;
             col.rgb *= smoothstep(.0 , .015 , -r.x);
             col *= smoothstep(0.04 , .2 , abs(lp - 1.1));
             col *= smoothstep(0.1 , .34 , lp);
             sum += abs(col) * 5. * (1.2 - noise(lp * 2. + j * 13. + time * 5.) * 1.1) / (log(distance(p , orig) - 2.) + .75);
          }
         return sum;
      }

     // returns both collision dists of unit sphere 
    float2 iSphere2(in float3 ro , in float3 rd)
     {
        float3 oc = ro;
        float b = dot(oc , rd);
        float c = dot(oc , oc) - 1.;
        float h = b * b - c;
        if (h < 0.0) return float2 (-1., -1.);
        else return float2 ((-b - sqrt(h)) , (-b + sqrt(h)));
     }

    half4 LitPassFragment(Varyings input) : SV_Target  {
    half4 fragColor = half4 (1 , 1 , 1 , 1);
    float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
         float2 p = fragCoord.xy / _ScreenParams.xy - 0.5;
         p.x *= _ScreenParams.x / _ScreenParams.y;
         float2 um = iMouse.xy / _ScreenParams.xy - .5;

         // camera 
        float3 ro = float3 (0. , 0. , 5.);
       float3 rd = normalize(float3 (p * .7 , -1.5));
       float2x2 mx = mm2(time * .4 + um.x * 6.);
       float2x2 my = mm2(time * 0.3 + um.y * 6.);
       ro.xz = mul(ro.xz, mx);
       rd.xz = mul(rd.xz , mx);
       ro.xy =mul(ro.xy, my);
       rd.xy =mul(rd.xy, my);

       float3 bro = ro;
       float3 brd = rd;

       float3 col = float3 (0.0125 , 0. , 0.025);
       #if 1 
       for (float j = 1.; j < NUM_RAYS + 1.; j++)
        {
           ro = bro;
           rd = brd;
           float2x2 mm = mm2((time * 0.1 + ((j + 1.) * 5.1)) * j * 0.25);
           ro.xy = mul(ro.xy, mm);
           rd.xy = mul(rd.xy, mm);
           ro.xz = mul(ro.xz, mm);
           rd.xz = mul(rd.xz, mm);
           float rz = march(ro , rd , 2.5 , FAR , j);
             if (rz >= FAR) continue;
            float3 pos = ro + rz * rd;
            col = max(col , vmarch(pos , rd , j , bro));
        }
       #endif 

       ro = bro;
       rd = brd;
       float2 sph = iSphere2(ro , rd);

       if (sph.x > 0.)
        {
           float3 pos = ro + rd * sph.x;
           float3 pos2 = ro + rd * sph.y;
           float3 rf = reflect(rd , pos);
           float3 rf2 = reflect(rd , pos2);
           float nz = (-log(abs(flow(rf * 1.2 , time) - .01)));
           float nz2 = (-log(abs(flow(rf2 * 1.2 , -time) - .01)));
           col += (0.1 * nz * nz * float3 (0.12 , 0.12 , .5) + 0.05 * nz2 * nz2 * float3 (0.55 , 0.2 , .55)) * 0.8;
        }

        fragColor = float4 (col * 1.3 , 1.0);
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