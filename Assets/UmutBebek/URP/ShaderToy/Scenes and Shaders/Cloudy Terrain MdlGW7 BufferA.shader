Shader "UmutBebek/URP/ShaderToy/Cloudy Terrain MdlGW7 BufferA"
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
lig("lig", vector) = (0.7 , 0.4 , 0.2)

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
float4 lig;

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

// Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);

    float a = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , x.xy / 256.0 + (p.z + 0.0) * 120.7123 , 0.0).x;
    float b = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , x.xy / 256.0 + (p.z + 1.0) * 120.7123 , 0.0).x;
     return lerp(a , b , f.z);
 }


float fbm(float3 p)
 {
    float3x3 m = float3x3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64);
    float f;
    f = 0.5000 * noise(p); 
    p = mul(m , p) * 2.02;
    f += 0.2500 * noise(p); 
    p = mul(m, p) * 2.03;
    f += 0.1250 * noise(p); 
    p = mul(m, p) * 2.01;
    f += 0.0625 * noise(p);
    return f;
 }

float envelope(float3 p)
 {
     float isLake = 1.0 - smoothstep(0.62 , 0.72 , SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.001 * p.zx , 0.0).x);
     return 0.1 + isLake * 0.9 * SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , 0.01 * p.xz , 0.0).x;
 }

float mapTerrain(in float3 pos)
 {
     return pos.y - envelope(pos);
 }

float raymarchTerrain(in float3 ro , in float3 rd)
 {
     float maxd = 50.0;
     float precis = 0.001;
    float h = 1.0;
    float t = 0.0;
    for (int i = 0; i < 80; i++)
     {
        if (abs(h) < precis || t > maxd) break;
        t += h;
         h = mapTerrain(ro + rd * t);
     }

    if (t > maxd) t = -1.0;
    return t;
 }



float3 calcNormal(in float3 pos)
 {
    float3 eps = float3 (0.02 , 0.0 , 0.0);
     return normalize(float3 (
           mapTerrain(pos + eps.xyy) - mapTerrain(pos - eps.xyy) ,
           0.5 * 2.0 * eps.x ,
           mapTerrain(pos + eps.yyx) - mapTerrain(pos - eps.yyx)));

 }

float4 mapTrees(in float3 pos , in float3 rd)
 {
    float3 col = float3 (0.0 , 0.0 , 0.0);
     float den = 1.0;

     float kklake = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , 0.001 * pos.zx , 0.0).x;
     float isLake = smoothstep(0.7 , 0.71 , kklake);

     if (pos.y > 1.0 || pos.y < 0.0)
      {
          den = 0.0;
      }
     else
      {

          float h = pos.y;
          float e = envelope(pos);
          float r = clamp(h / e , 0.0 , 1.0);

        den = smoothstep(r , 1.0 , SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , pos.xz * 0.15 , 0.0).x);

          den *= 1.0 - 0.95 * clamp((r - 0.75) / (1.0 - 0.75) , 0.0 , 1.0);

        float id = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , pos.xz , 0.0).x;
        float oc = pow(r , 2.0);

          float3 nor = calcNormal(pos);
          float3 dif = float3 (1.0 , 1.0 , 1.0) * clamp(dot(nor , lig) , 0.0 , 1.0);
          float amb = 0.5 + 0.5 * nor.y;

          float w = (2.8 - pos.y) / lig.y;
          float c = fbm((pos + w * lig) * 0.35);
          c = smoothstep(0.38 , 0.6 , c);
          dif *= pow(float3 (c, c, c) , float3 (0.8 , 1.0 , 1.5));

          float3 brdf = 1.7 * float3 (1.5 , 1.0 , 0.8) * dif * (0.1 + 0.9 * oc) + 1.3 * amb * float3 (0.1 , 0.15 , 0.2) * oc;

          float3 mate = 0.6 * float3 (0.5 , 0.5 , 0.1);
          mate += 0.3 * SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , 0.1 * pos.xz , 0.0).zyx;

          col = brdf * mate;

          den *= 1.0 - isLake;
      }

     return float4 (col , den);
 }


float4 raymarchTrees(in float3 ro , in float3 rd , float tmax , float3 bgcol , out float resT)
 {
     float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);
    float t = tmax;
     for (int i = 0; i < 512; i++)
      {
          float3 pos = ro + t * rd;
          if (sum.a > 0.99 || pos.y < 0.0 || t > 20.0) break;

          float4 col = mapTrees(pos , rd);

          col.xyz = lerp(col.xyz , bgcol , 1.0 - exp(-0.0018 * t * t));

          col.rgb *= col.a;

          sum = sum + col * (1.0 - sum.a);

          t += 0.0035 * t;
      }

    resT = t;

     return clamp(sum , 0.0 , 1.0);
 }

float4 mapClouds(in float3 p)
 {
     float d = 1.0 - 0.3 * abs(2.8 - p.y);
     d -= 1.6 * fbm(p * 0.35);

     d = clamp(d , 0.0 , 1.0);

     float4 res = float4 (d, d, d, d);

     res.xyz = lerp(0.8 * float3 (1.0 , 0.95 , 0.8) , 0.2 * float3 (0.6 , 0.6 , 0.6) , res.x);
     res.xyz *= 0.65;

     return res;
 }


float4 raymarchClouds(in float3 ro , in float3 rd , in float3 bcol , float tmax , out float rays , int2 px)
 {
     float4 sum = float4 (0 , 0 , 0 , 0);
     rays = 0.0;

     float sun = clamp(dot(rd , lig) , 0.0 , 1.0);
     float t = 0.1 * pointSampleTex2D(_Channel0 , sampler_Channel0 , px & int2(255, 255) ).x;
     for (int i = 0; i < 64; i++)
      {
          if (sum.w > 0.99 || t > tmax) break;
          float3 pos = ro + t * rd;
          float4 col = mapClouds(pos);

          float dt = max(0.1 , 0.05 * t);
          float h = (2.8 - pos.y) / lig.y;
          float c = fbm((pos + lig * h) * 0.35);
          // kk += 0.05 * dt * ( smoothstep ( 0.38 , 0.6 , c ) ) * ( 1.0 - col.a ) ; 
         rays += 0.02 * (smoothstep(0.38 , 0.6 , c)) * (1.0 - col.a) * (1.0 - smoothstep(2.75 , 2.8 , pos.y));


         col.xyz *= float3 (0.4 , 0.52 , 0.6);

       col.xyz += float3 (1.0 , 0.7 , 0.4) * 0.4 * pow(sun , 6.0) * (1.0 - col.w);

         col.xyz = lerp(col.xyz , bcol , 1.0 - exp(-0.0018 * t * t));

         col.a *= 0.5;
         col.rgb *= col.a;

         sum = sum + col * (1.0 - sum.a);

         t += dt; // max ( 0.1 , 0.05 * t ) ; 
     }
   rays = clamp(rays , 0.0 , 1.0);

    return clamp(sum , 0.0 , 1.0);
}

float3 path(float time)
 {
     return float3 (32.0 * cos(0.2 + 0.75 * .1 * time * 1.5) , 1.2 , 32.0 * sin(0.1 + 0.75 * 0.11 * time * 1.5));
 }

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

void moveCamera(float time , out float3 oRo , out float3 oTa , out float oCr , out float oFl)
 {
    // camera 
    oRo = path(time);
    oTa = path(time + 1.0);
    oTa.y *= 0.2;
    oCr = 0.3 * cos(0.07 * time);
   oFl = 1.75;
}

half4 LitPassFragment(Varyings input) : SV_Target{
    lig = normalize(lig);
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;

     float time = 23.5 + _Time.y;

     // camera 
     float3 ro , ta;
    float roll , fl;
    moveCamera(time , ro , ta , roll , fl);

    // camera tx 
  float3x3 cam = setCamera(ro , ta , roll);

  // ray direction 
 float3 rd = normalize(mul(cam , float3 (p.xy , fl)));

 // sky 
 float3 col = float3 (0.84 , 0.95 , 1.0) * 0.77 - rd.y * 0.6;
 col *= 0.75;
 float sun = clamp(dot(rd , lig) , 0.0 , 1.0);
col += float3 (1.0 , 0.7 , 0.3) * 0.3 * pow(sun , 6.0);
 float3 bcol = col;

 // lakes 
float gt = (0.0 - ro.y) / rd.y;
if (gt > 0.0)
 {
    float3 pos = ro + rd * gt;

      float3 nor = float3 (0.0 , 1.0 , 0.0);
     nor.xz = 0.10 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , 1.5 * pos.xz).xz);
     nor.xz += 0.15 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , 3.2 * pos.xz).xz);
     nor.xz += 0.20 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , 6.0 * pos.xz).xz);
 nor = normalize(nor);

      float3 ref = reflect(rd , nor);
     float3 sref = reflect(rd , float3 (0.0 , 1.0 , 0.0));
      float sunr = clamp(dot(ref , lig) , 0.0 , 1.0);

     float kklake = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 0.001 * pos.zx).x;
      col = float3 (0.1 , 0.1 , 0.0);
    float3 lcol = float3 (0.2 , 0.5 , 0.7);
      col = lerp(lcol , 1.1 * float3 (0.2 , 0.6 , 0.7) , 1.0 - smoothstep(0.7 , 0.81 , kklake));

      col *= 0.12;

     float fre = 1.0 - max(sref.y , 0.0);
      col += 0.8 * float3 (1.0 , 0.9 , 0.8) * pow(sunr , 64.0) * pow(fre , 1.0);
      col += 0.5 * float3 (1.0 , 0.9 , 0.8) * pow(fre , 10.0);

      float h = (2.8 - pos.y) / lig.y;
    float c = fbm((pos + h * lig) * 0.35);
      col *= 0.4 + 0.6 * smoothstep(0.38 , 0.6 , c);

     col *= smoothstep(0.7 , 0.701 , kklake);

     col.xyz = lerp(col.xyz , bcol , 1.0 - exp(-0.0018 * gt * gt));
 }


// terrain 
float t = raymarchTerrain(ro , rd);
if (t > 0.0)
  {
    // trees 
   float ot;
   float4 res = raymarchTrees(ro , rd , t , bcol , ot);
   t = ot;
    col = col * (1.0 - res.w) + res.xyz;
 }

// sun glow 
col += float3 (1.0 , 0.5 , 0.2) * 0.35 * pow(sun , 3.0);

float rays = 0.0;
// clouds 
{
if (t < 0.0) t = 600.0;
float4 res = raymarchClouds(ro , rd , bcol , t , rays , int2 (fragCoord));
 col = col * (1.0 - res.w) + res.xyz;
  }

 col += (1.0 - 0.8 * col) * rays * rays * rays * 0.4 * float3 (1.0 , 0.8 , 0.7);
 col = clamp(col , 0.0 , 1.0);


 // gamma 
 col = pow(col , float3 (0.45 , 0.45 , 0.45));

 // contrast , desat , tint and vignetting 
 col = col * 0.1 + 0.9 * col * col * (3.0 - 2.0 * col);
 col = lerp(col , float3 (col.x + col.y + col.z, col.x + col.y + col.z, col.x + col.y + col.z) * 0.33 , 0.2);
 col *= float3 (1.06 , 1.05 , 1.0);

 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
  // velocity vectors ( through depth reprojection ) 
 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
float vel = 0.0;
if (t < 0.0)
 {
    vel = -1.0;
 }
else
 {

    // old camera position 
   float oldTime = time - 1.0 / 30.0; // 1 / 30 of a second blur 
   float3 oldRo , oldTa; float oldCr , oldFl;
   moveCamera(oldTime , oldRo , oldTa , oldCr , oldFl);
   float3x3 oldCam = setCamera(oldRo , oldTa , oldCr);

   // world space 
  float3 wpos = ro + rd * t;
  // camera space 
 float3 cpos = float3 (dot(wpos - oldRo , oldCam[0]) ,
                   dot(wpos - oldRo , oldCam[1]) ,
                   dot(wpos - oldRo , oldCam[2]));
 // ndc space 
float2 npos = oldFl * cpos.xy / cpos.z;
// screen space 
float2 spos = 0.5 + 0.5 * npos * float2 (_ScreenParams.y / _ScreenParams.x , 1.0);


// compress velocity vector in a single float 
float2 uv = fragCoord / _ScreenParams.xy;
spos = clamp(0.5 + 0.5 * (spos - uv) / 0.25 , 0.0 , 1.0);
vel = floor(spos.x * 255.0) + floor(spos.y * 255.0) * 256.0;
}

fragColor = float4 (col , vel);
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