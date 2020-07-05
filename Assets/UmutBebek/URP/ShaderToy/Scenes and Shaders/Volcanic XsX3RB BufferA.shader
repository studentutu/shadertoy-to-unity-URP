Shader "UmutBebek/URP/ShaderToy/Volcanic XsX3RB BufferA"
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
            lig("lig", vector) = (-0.3 , 0.4 , 0.7)

    }

        SubShader
        {
            // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
            // "UniversalRenderPipeline"
            Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent"}
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

            //Blend One One
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


// #define HIGH_QUALITY_NOISE 

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
#ifndef HIGH_QUALITY_NOISE 
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.).yx;
#else 
     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z);
     float2 rg1 = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (0.5 , 0.5)) / 256.0 , 0.).yx;
     float2 rg2 = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (1.5 , 0.5)) / 256.0 , 0.).yx;
     float2 rg3 = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (0.5 , 1.5)) / 256.0 , 0.).yx;
     float2 rg4 = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (1.5 , 1.5)) / 256.0 , 0.).yx;
     float2 rg = lerp(lerp(rg1 , rg2 , f.x) , lerp(rg3 , rg4 , f.x) , f.y);
#endif 
     return lerp(rg.x , rg.y , f.z);
 }



float noise(in float2 x)
 {
    float2 p = floor(x);
    float2 f = frac(x);
     float2 uv = p.xy + f.xy * f.xy * (3.0 - 2.0 * f.xy);
     return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 118.4) / 256.0 , 0.).x;
 }

float4 texcube(Texture2D sam, SamplerState samp, in float3 p , in float3 n)
 {
     float4 x = SAMPLE_TEXTURE2D(sam, samp, p.yz);
     float4 y = SAMPLE_TEXTURE2D(sam , samp,p.zx);
     float4 z = SAMPLE_TEXTURE2D(sam , samp,p.xy);
     return x * abs(n.x) + y * abs(n.y) + z * abs(n.z);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float lava(float2 p)
 {
     p += float2 (2.0 , 4.0);
    float f;
    f = 0.5000 * noise(p); p = p * 2.02;
    f += 0.2500 * noise(p); p = p * 2.03;
    f += 0.1250 * noise(p); p = p * 2.01;
    f += 0.0625 * noise(p);
    return f;
 }



float displacement(float3 p)
 {
     p += float3 (1.0 , 0.0 , 0.8);

    float f;
    f = 0.5000 * noise(p); 
    p = mul(float3x3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64) , p) * 2.02;
    f += 0.2500 * noise(p); 
    p = mul(float3x3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64) , p) * 2.03;
    f += 0.1250 * noise(p); 
    p = mul(float3x3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64) , p) * 2.01;
    f += 0.0625 * noise(p);

     float n = noise(p * 3.5);
    f += 0.03 * n * n;

    return f;
 }

float mapTerrain(in float3 pos)
 {
     return pos.y * 0.1 + (displacement(pos * float3 (0.8 , 1.0 , 0.8)) - 0.4) * (1.0 - smoothstep(1.0 , 3.0 , pos.y));
 }

float raymarchTerrain(in float3 ro , in float3 rd)
 {
     float maxd = 30.0;
    float t = 0.1;
    for (int i = 0; i < 256; i++)
     {
         float h = mapTerrain(ro + rd * t);
        if (h < (0.001 * t) || t > maxd) break;
        t += h * 0.8;
     }

    if (t > maxd) t = -1.0;
    return t;
 }

float3 calcNormal(in float3 pos , in float t)
 {
    float3 eps = float3 (max(0.02 , 0.001 * t) , 0.0 , 0.0);
     return normalize(float3 (
           mapTerrain(pos + eps.xyy) - mapTerrain(pos - eps.xyy) ,
           mapTerrain(pos + eps.yxy) - mapTerrain(pos - eps.yxy) ,
           mapTerrain(pos + eps.yyx) - mapTerrain(pos - eps.yyx)));

 }



float4 mapClouds(in float3 pos)
 {
     float3 q = pos * 0.5 + float3 (0.0 , -_Time.y , 0.0);

     float d;
    d = 0.5000 * noise(q); q = q * 2.02;
    d += 0.2500 * noise(q); q = q * 2.03;
    d += 0.1250 * noise(q); q = q * 2.01;
    d += 0.0625 * noise(q);

     d = d - 0.55;
     d *= smoothstep(0.5 , 0.55 , lava(0.1 * pos.xz) + 0.01);

     d = clamp(d , 0.0 , 1.0);

     float4 res = float4 (d, d, d, d);

     res.xyz = lerp(float3 (1.0 , 0.8 , 0.7) , 0.2 * float3 (0.4 , 0.4 , 0.4) , res.x);
     res.xyz *= 0.25;
     res.xyz *= 0.5 + 0.5 * smoothstep(-2.0 , 1.0 , pos.y);

     return res;
 }

float4 raymarchClouds(in float3 ro , in float3 rd , in float3 bcol , float tmax)
 {
     float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);

     float sun = pow(clamp(dot(rd , lig) , 0.0 , 1.0) , 6.0);
     float t = 0.0;
     for (int i = 0; i < 60; i++)
      {
          if (t > tmax || sum.w > 0.95) break; // continue ; 
          float3 pos = ro + t * rd;
          float4 col = mapClouds(pos);

        col.xyz += float3 (1.0 , 0.7 , 0.4) * 0.4 * sun * (1.0 - col.w);
          col.xyz = lerp(col.xyz , bcol , 1.0 - exp(-0.00006 * t * t * t));

          col.rgb *= col.a;

          sum = sum + col * (1.0 - sum.a);

          t += max(0.1 , 0.05 * t);
      }

     sum.xyz /= (0.001 + sum.w);

     return clamp(sum , 0.0 , 1.0);
 }

float softshadow(in float3 ro , in float3 rd , float mint , float k)
 {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 64; i++)
     {
        float h = mapTerrain(ro + rd * t);
          h = max(h , 0.0);
        res = min(res , k * h / t);
        t += clamp(h , 0.02 , 0.5);
          if (res < 0.001) break;
     }
    return clamp(res , 0.0 , 1.0);
 }

float3 path(float time)
 {
     return float3 (16.0 * cos(0.2 + 0.5 * .1 * time * 1.5) , 1.5 , 16.0 * sin(0.1 + 0.5 * 0.11 * time * 1.5));

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
     float3 ro = path(time + 0.0);
     float3 ta = path(time + 1.6);
     ta.y *= 0.35 + 0.25 * sin(0.09 * time);
     float cr = 0.3 * sin(1.0 + 0.07 * time);
    oRo = ro;
    oTa = ta;
    oCr = cr;
    oFl = 2.1;
 }


half4 LitPassFragment(Varyings input) : SV_Target{
    lig = normalize(lig);
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;

     // camera 
     float off = step(0.001 , iMouse.z) * 6.0 * iMouse.x / _ScreenParams.x;
    float time = 3.4 + _Time.y + off;

    float3 ro , ta; float cr , fl;
    moveCamera(time , ro , ta , cr , fl);
    // camera2world transform 
  float3x3 cam = setCamera(ro , ta , cr);

  // ray 
 float3 rd = mul(cam , normalize(float3 (p.xy , fl)));

 // sky 
 float3 col = float3 (0.32 , 0.36 , 0.4) - rd.y * 0.4;
float sun = clamp(dot(rd , lig) , 0.0 , 1.0);
 col += float3 (1.0 , 0.8 , 0.4) * 0.2 * pow(sun , 6.0);
col *= 0.9;

 float3 bcol = col;

 // terrain 
 float t = raymarchTerrain(ro , rd);
float st = t;
if (t > 0.0)
  {
      float3 pos = ro + t * rd;
      float3 nor = calcNormal(pos , t);
      float3 ref = reflect(rd , nor);

      float3 bn = -1.0 + 2.0 * texcube(_Channel0 , sampler_Channel0 , 3.0 * pos / 4.0 , nor).xyz;
      nor = normalize(nor + 0.6 * bn);

      float hh = 1.0 - smoothstep(-2.0 , 1.0 , pos.y);

      // lighting 
       float sun = clamp(dot(nor , lig) , 0.0 , 1.0);
       float sha = 0.0; if (sun > 0.01) sha = softshadow(pos , lig , 0.01 , 32.0);
       float bac = clamp(dot(nor , normalize(lig * float3 (-1.0 , 0.0 , -1.0))) , 0.0 , 1.0);
       float sky = 0.5 + 0.5 * nor.y;
     float lav = smoothstep(0.5 , 0.55 , lava(0.1 * pos.xz)) * hh * clamp(0.5 - 0.5 * nor.y , 0.0 , 1.0);
       float occ = pow((1.0 - displacement(pos * float3 (0.8 , 1.0 , 0.8))) * 1.6 - 0.5 , 2.0);

       float amb = 1.0;

       col = float3 (0.8 , 0.8 , 0.8);

       float3 lin = float3 (0.0 , 0.0 , 0.0);
       lin += 1.4 * sun * float3 (1.80 , 1.27 , 0.99) * pow(float3 (sha, sha, sha) , float3 (1.0 , 1.2 , 1.5));
       lin += 0.9 * sky * float3 (0.16 , 0.20 , 0.40) * occ;
       lin += 0.9 * bac * float3 (0.40 , 0.28 , 0.20) * occ;
       lin += 0.9 * amb * float3 (0.15 , 0.17 , 0.20) * occ;
       lin += lav * float3 (3.00 , 0.61 , 0.00);

       // surface shading / material 
        col = texcube(_Channel1 , sampler_Channel1 , 0.5 * pos , nor).xyz;
        col = col * (0.2 + 0.8 * texcube(_Channel2 , sampler_Channel2 , 4.0 * float3 (2.0 , 8.0 , 2.0) * pos , nor).x);
        float3 verde = float3 (1.0 , 0.9 , 0.2);
        verde *= SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , pos.xz).xyz;
        col = lerp(col , 0.8 * verde , hh);

        float vv = smoothstep(0.0 , 0.8 , nor.y) * smoothstep(0.0 , 0.1 , pos.y - 0.8);
        verde = float3 (0.2 , 0.45 , 0.1);
        verde *= SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 30.0 * pos.xz).xyz;
        verde += 0.2 * SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 1.0 * pos.xz).xyz;
        vv *= smoothstep(0.0 , 0.5 , SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , 0.1 * pos.xz + 0.01 * nor.x).x);
        col = lerp(col , verde * 1.1 , vv);

        col = lin * col;

        // sun spec 
       float3 hal = normalize(lig - rd);
       col += 1.0 *
              float3 (1.80 , 1.27 , 0.99) *
              pow(clamp(dot(nor , hal) , 0.0 , 1.0) , 16.0) *
              sun * sha *
               (0.04 + 0.96 * pow(clamp(1.0 + dot(hal , rd) , 0.0 , 1.0) , 5.0));

       // atmospheric 
      col = lerp(col , (1.0 - 0.7 * hh) * bcol , 1.0 - exp(-0.00006 * t * t * t));
 }

// sun glow 
col += float3 (1.0 , 0.6 , 0.2) * 0.2 * pow(sun , 2.0) * clamp((rd.y + 0.4) / (0.0 + 0.4) , 0.0 , 1.0);

// smoke 

if (t < 0.0) t = 600.0;
float4 res = raymarchClouds(ro , rd , bcol , t);
 col = lerp(col , res.xyz , res.w);
 

 // gamma 
 col = pow(clamp(col , 0.0 , 1.0) , float3 (0.45 , 0.45 , 0.45));

 // contrast , desat , tint and vignetting 
 col = col * 0.3 + 0.7 * col * col * (3.0 - 2.0 * col);
 col = lerp(col , float3 (col.x + col.y + col.z, col.x + col.y + col.z, col.x + col.y + col.z) * 0.33 , 0.2);
col *= 1.25 * float3 (1.02 , 1.05 , 1.0);

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
 // velocity vectors ( through depth reprojection ) 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
float vel = -1.0;
if (st > 0.0)
 {
    // old camera position 
   float oldTime = time - 1.0 / 30.0; // 1 / 30 of a second blur 
   float3 oldRo , oldTa; float oldCr , oldFl;
   moveCamera(oldTime , oldRo , oldTa , oldCr , oldFl);
   float3x3 oldCam = setCamera(oldRo , oldTa , oldCr);

   // world spcae 
  float3 wpos = ro + rd * st;
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