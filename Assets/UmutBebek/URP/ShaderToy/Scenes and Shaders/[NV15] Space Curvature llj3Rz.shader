Shader "UmutBebek/URP/ShaderToy/[NV15] Space Curvature llj3Rz"
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
            sph1("sph1", vector) = (0.0 , 0.0 , 0.0 , 1.0)

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
            float4 sph1;

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

           // Created by inigo quilez - iq / 2015 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 


float3 fancyCube(Texture2D sam, SamplerState samp, in float3 d , in float s , in float b)
 {
    float3 colx = SAMPLE_TEXTURE2D_LOD(sam , samp, 0.5 + s * d.yz / d.x , b).xyz;
    float3 coly = SAMPLE_TEXTURE2D_LOD(sam, samp, 0.5 + s * d.zx / d.y , b).xyz;
    float3 colz = SAMPLE_TEXTURE2D_LOD(sam, samp, 0.5 + s * d.xy / d.z , b).xyz;

    float3 n = d * d;

    return (colx * n.x + coly * n.y + colz * n.z) / (n.x + n.y + n.z);
 }


float2 hash(float2 p) { p = float2 (dot(p , float2 (127.1 , 311.7)) , dot(p , float2 (269.5 , 183.3))); return frac(sin(p) * 43758.5453); }

float2 voronoi(in float2 x)
 {
    float2 n = floor(x);
    float2 f = frac(x);

     float3 m = float3 (8.0, 8.0, 8.0);
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++)
     {
        float2 g = float2 (float(i) , float(j));
        float2 o = hash(n + g);
        float2 r = g - f + o;
          float d = dot(r , r);
        if (d < m.x)
            m = float3 (d , o);
     }

    return float2 (sqrt(m.x) , m.y + m.z);
 }

float shpIntersect(in float3 ro , in float3 rd , in float4 sph)
 {
    float3 oc = ro - sph.xyz;
    float b = dot(rd , oc);
    float c = dot(oc , oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h > 0.0) h = -b - sqrt(h);
    return h;
 }

float sphDistance(in float3 ro , in float3 rd , in float4 sph)
 {
     float3 oc = ro - sph.xyz;
    float b = dot(oc , rd);
    float h = dot(oc , oc) - b * b;
    return sqrt(max(0.0 , h)) - sph.w;
 }

float sphSoftShadow(in float3 ro , in float3 rd , in float4 sph , in float k)
 {
    float3 oc = sph.xyz - ro;
    float b = dot(oc , rd);
    float c = dot(oc , oc) - sph.w * sph.w;
    float h = b * b - c;
    return (b < 0.0) ? 1.0 : 1.0 - smoothstep(0.0 , 1.0 , k * h / b);
 }


float3 sphNormal(in float3 pos , in float4 sph)
 {
    return (pos - sph.xyz) / sph.w;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float3 background(in float3 d , in float3 l)
 {
    float3 col = float3 (0.0 , 0.0 , 0.0);
         col += 0.5 * pow(fancyCube(_Channel1 , sampler_Channel1 , d , 0.05 , 5.0).zyx , float3 (2.0, 2.0, 2.0));
         col += 0.2 * pow(fancyCube(_Channel1 , sampler_Channel1 , d , 0.10 , 3.0).zyx , float3 (1.5, 1.5, 1.5));
         col += 0.8 * float3 (0.80 , 0.5 , 0.6) * pow(fancyCube(_Channel1 , sampler_Channel1 , d , 0.1 , 0.0).xxx , 
             float3 (6.0, 6.0, 6.0));
    float stars = smoothstep(0.3 , 0.7 , fancyCube(_Channel1 , sampler_Channel1 , d , 0.91 , 0.0).x);


    float3 n = abs(d);
    n = n * n * n;

    float2 vxy = voronoi(50.0 * d.xy);
    float2 vyz = voronoi(50.0 * d.yz);
    float2 vzx = voronoi(50.0 * d.zx);
    float2 r = (vyz * n.x + vzx * n.y + vxy * n.z) / (n.x + n.y + n.z);
    col += 0.9 * stars * clamp(1.0 - (3.0 + r.y * 5.0) * r.x , 0.0 , 1.0);

    col = 1.5 * col - 0.2;
    col += float3 (-0.05 , 0.1 , 0.0);

    float s = clamp(dot(d , l) , 0.0 , 1.0);
    col += 0.4 * pow(s , 5.0) * float3 (1.0 , 0.7 , 0.6) * 2.0;
    col += 0.4 * pow(s , 64.0) * float3 (1.0 , 0.9 , 0.8) * 2.0;

    return col;

 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



float rayTrace(in float3 ro , in float3 rd)
 {
    return shpIntersect(ro , rd , sph1);
 }

float map(in float3 pos)
 {
    float2 r = pos.xz - sph1.xz;
    float h = 1.0 - 2.0 / (1.0 + 0.3 * dot(r , r));
    return pos.y - h;
 }

float rayMarch(in float3 ro , in float3 rd , float tmax)
 {
    float t = 0.0;

    // bounding plane 
   float h = (1.0 - ro.y) / rd.y;
   if (h > 0.0) t = h;

   // raymarch 
  for (int i = 0; i < 20; i++)
   {
      float3 pos = ro + t * rd;
      float h = map(pos);
      if (h < 0.001 || t > tmax) break;
      t += h;
   }
  return t;
}

float3 render(in float3 ro , in float3 rd)
 {
    float3 lig = normalize(float3 (1.0 , 0.2 , 1.0));
    float3 col = background(rd , lig);

    // raytrace stuff 
   float t = rayTrace(ro , rd);

   if (t > 0.0)
    {
       float3 mat = float3 (0.18 , 0.18 , 0.18);
       float3 pos = ro + t * rd;
       float3 nor = sphNormal(pos , sph1);

       float am = 0.1 * _Time.y;
       float2 pr = float2 (cos(am) , sin(am));
       float3 tnor = nor;
       tnor.xz = mul(float2x2 (pr.x , -pr.y , pr.y , pr.x) , tnor.xz);

       float am2 = 0.08 * _Time.y - 1.0 * (1.0 - nor.y * nor.y);
       pr = float2 (cos(am2) , sin(am2));
       float3 tnor2 = nor;
       tnor2.xz = mul(float2x2 (pr.x , -pr.y , pr.y , pr.x) , tnor2.xz);

       float3 ref = reflect(rd , nor);
       float fre = clamp(1.0 + dot(nor , rd) , 0.0 , 1.0);

       float l = fancyCube(_Channel0 , sampler_Channel0 , tnor , 0.03 , 0.0).x;
       l += -0.1 + 0.3 * fancyCube(_Channel0 , sampler_Channel0 , tnor , 8.0 , 0.0).x;

       float3 sea = lerp(float3 (0.0 , 0.07 , 0.2) , float3 (0.0 , 0.01 , 0.3) , fre);
       sea *= 0.15;

       float3 land = float3 (0.02 , 0.04 , 0.0);
       land = lerp(land , float3 (0.05 , 0.1 , 0.0) , smoothstep(0.4 , 1.0 , fancyCube(_Channel0 , sampler_Channel0 , tnor , 0.1 , 0.0).x));
       land *= fancyCube(_Channel0 , sampler_Channel0 , tnor , 0.3 , 0.0).xyz;
       land *= 0.5;

       float los = smoothstep(0.45 , 0.46 , l);
       mat = lerp(sea , land , los);

       float3 wrap = -1.0 + 2.0 * fancyCube(_Channel1 , sampler_Channel1 , tnor2.xzy , 0.025 , 0.0).xyz;
       float cc1 = fancyCube(_Channel1 , sampler_Channel1 , tnor2 + 0.2 * wrap , 0.05 , 0.0).y;
       float clouds = smoothstep(0.3 , 0.6 , cc1);

       mat = lerp(mat , float3 (0.93 * 0.15, 0.93 * 0.15, 0.93 * 0.15) , clouds);

       float dif = clamp(dot(nor , lig) , 0.0 , 1.0);
       mat *= 0.8;
       float3 lin = float3 (3.0 , 2.5 , 2.0) * dif;
       lin += 0.01;
       col = mat * lin;
       col = pow(col , float3 (0.4545, 0.4545, 0.4545));
       col += 0.6 * fre * fre * float3 (0.9 , 0.9 , 1.0) * (0.3 + 0.7 * dif);

       float spe = clamp(dot(ref , lig) , 0.0 , 1.0);
       float tspe = pow(spe , 3.0) + 0.5 * pow(spe , 16.0);
       col += (1.0 - 0.5 * los) * clamp(1.0 - 2.0 * clouds , 0.0 , 1.0) * 0.3 * float3 (0.5 , 0.4 , 0.3) * tspe * dif; ;
    }

   // raymarch stuff 
  float tmax = 20.0;
  if (t > 0.0) tmax = t;
  t = rayMarch(ro , rd , tmax);
  if (t < tmax)
   {
          float3 pos = ro + t * rd;

          float2 scp = sin(2.0 * 6.2831 * pos.xz);

          float3 wir = float3 (0.0 , 0.0 , 0.0);
          wir += 1.0 * exp(-12.0 * abs(scp.x));
          wir += 1.0 * exp(-12.0 * abs(scp.y));
          wir += 0.5 * exp(-4.0 * abs(scp.x));
          wir += 0.5 * exp(-4.0 * abs(scp.y));
          wir *= 0.2 + 1.0 * sphSoftShadow(pos , lig , sph1 , 4.0);

          col += wir * 0.5 * exp(-0.05 * t * t); ;
   }

  if (dot(rd , sph1.xyz - ro) > 0.0)
   {
  float d = sphDistance(ro , rd , sph1);
  float3 glo = float3 (0.0 , 0.0 , 0.0);
  glo += float3 (0.6 , 0.7 , 1.0) * 0.3 * exp(-2.0 * abs(d)) * step(0.0 , d);
  glo += 0.6 * float3 (0.6 , 0.7 , 1.0) * 0.3 * exp(-8.0 * abs(d));
  glo += 0.6 * float3 (0.8 , 0.9 , 1.0) * 0.4 * exp(-100.0 * abs(d));
  col += glo * 2.0;
   }

  col *= smoothstep(0.0 , 6.0 , _Time.y);

  return col;
}


float3x3 setCamera(in float3 ro , in float3 rt , in float cr)
 {
     float3 cw = normalize(rt - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , -cw);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 p = (-_ScreenParams.xy + 2.0 * fragCoord.xy) / _ScreenParams.y;

    float zo = 1.0 + smoothstep(5.0 , 15.0 , abs(_Time.y - 48.0));
    float an = 3.0 + 0.05 * _Time.y + 6.0 * iMouse.x / _ScreenParams.x;
    float3 ro = zo * float3 (2.0 * cos(an) , 1.0 , 2.0 * sin(an));
    float3 rt = float3 (1.0 , 0.0 , 0.0);
    float3x3 cam = setCamera(ro , rt , 0.35);
    float3 rd = normalize(mul(cam , float3 (p.x,p.y, -2.0)));

    float3 col = render(ro , rd);

    float2 q = fragCoord.xy / _ScreenParams.xy;
    col *= 0.2 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

     fragColor = float4 (col , 1.0);
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