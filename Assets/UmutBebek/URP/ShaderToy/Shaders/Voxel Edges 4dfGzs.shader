Shader "UmutBebek/URP/ShaderToy/Voxel Edges 4dfGzs"
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
            gro("gro", vector) = (0,0,0)
lig("lig", vector) = (-0.4,0.3,0.7)

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
            float4 gro;
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

// Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// 
// Shading technique explained here: 
// 
// http: // www.iquilezles.org / www / articles / voxellines / voxellines.htm 
// 

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }

float4 texcube(Texture2D sam, SamplerState samp, in float3 p , in float3 n)
 {
    float3 m = abs(n);
     float4 x = SAMPLE_TEXTURE2D(sam ,samp, p.yz);
     float4 y = SAMPLE_TEXTURE2D(sam, samp, p.zx);
     float4 z = SAMPLE_TEXTURE2D(sam, samp, p.xy);
     return x * m.x + y * m.y + z * m.z;
 }

float mapTerrain(float3 p)
 {
     p *= 0.1;
     p.xz *= 0.6;

     float time = 0.5 + 0.15 * _Time.y;
     float ft = frac(time);
     float it = floor(time);
     ft = smoothstep(0.7 , 1.0 , ft);
     time = it + ft;
     float spe = 1.4;

     float f;
    f = 0.5000 * noise(p * 1.00 + float3 (0.0 , 1.0 , 0.0) * spe * time);
    f += 0.2500 * noise(p * 2.02 + float3 (0.0 , 2.0 , 0.0) * spe * time);
    f += 0.1250 * noise(p * 4.01);
     return 25.0 * f - 10.0;
 }



float map(in float3 c)
 {
     float3 p = c + 0.5;

     float f = mapTerrain(p) + 0.25 * p.y;

    f = lerp(f , 1.0 , step(length(gro - p) , 5.0));

     return step(f , 0.5);
 }



float castRay(in float3 ro , in float3 rd , out float3 oVos , out float3 oDir)
 {
     float3 pos = floor(ro);
     float3 ri = 1.0 / rd;
     float3 rs = sign(rd);
     float3 dis = (pos - ro + 0.5 + rs * 0.5) * ri;

     float res = -1.0;
     float3 mm = float3 (0.0 , 0.0 , 0.0);
     for (int i = 0; i < 128; i++)
      {
          if (map(pos) > 0.5) { res = 1.0; break; }
          mm = step(dis.xyz , dis.yzx) * step(dis.xyz , dis.zxy);
          dis += mm * rs * ri;
        pos += mm * rs;
      }

     float3 nor = -mm * rs;
     float3 vos = pos;

     // intersect the cube 
     float3 mini = (pos - ro + 0.5 - 0.5 * float3 (rs)) * ri;
     float t = max(mini.x , max(mini.y , mini.z));

     oDir = mm;
     oVos = vos;

     return t * res;
 }

float3 path(float t , float ya)
 {
    float2 p = 100.0 * sin(0.02 * t * float2 (1.0 , 1.2) + float2 (0.1 , 0.9));
          p += 50.0 * sin(0.04 * t * float2 (1.3 , 1.0) + float2 (1.0 , 4.5));

     return float3 (p.x , 18.0 + ya * 4.0 * sin(0.05 * t) , p.y);
 }

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , -cw);
 }

float maxcomp(in float4 v)
 {
    return max(max(v.x , v.y) , max(v.z , v.w));
 }

float isEdge(in float2 uv , float4 va , float4 vb , float4 vc , float4 vd)
 {
    float2 st = 1.0 - uv;

    // edges 
   float4 wb = smoothstep(0.85 , 0.99 , float4 (uv.x ,
                                          st.x ,
                                          uv.y ,
                                          st.y)) * (1.0 - va + va * vc);
   // corners 
  float4 wc = smoothstep(0.85 , 0.99 , float4 (uv.x * uv.y ,
                                         st.x * uv.y ,
                                         st.x * st.y ,
                                         uv.x * st.y)) * (1.0 - vb + vd * vb);
  return maxcomp(max(wb , wc));
}

float calcOcc(in float2 uv , float4 va , float4 vb , float4 vc , float4 vd)
 {
    float2 st = 1.0 - uv;

    // edges 
   float4 wa = float4 (uv.x , st.x , uv.y , st.y) * vc;

   // corners 
  float4 wb = float4 (uv.x * uv.y ,
                 st.x * uv.y ,
                 st.x * st.y ,
                 uv.x * st.y) * vd * (1.0 - vc.xzyw) * (1.0 - vc.zywx);

  return wa.x + wa.y + wa.z + wa.w +
         wb.x + wb.y + wb.z + wb.w;
}

float3 render(in float3 ro , in float3 rd)
 {
    float3 col = float3 (0.0 , 0.0 , 0.0);

    // raymarch 
    float3 vos , dir;
    float t = castRay(ro , rd , vos , dir);
    if (t > 0.0)
     {
       float3 nor = -dir * sign(rd);
       float3 pos = ro + rd * t;
       float3 uvw = pos - vos;

         float3 v1 = vos + nor + dir.yzx;
        float3 v2 = vos + nor - dir.yzx;
        float3 v3 = vos + nor + dir.zxy;
        float3 v4 = vos + nor - dir.zxy;
         float3 v5 = vos + nor + dir.yzx + dir.zxy;
       float3 v6 = vos + nor - dir.yzx + dir.zxy;
        float3 v7 = vos + nor - dir.yzx - dir.zxy;
        float3 v8 = vos + nor + dir.yzx - dir.zxy;
        float3 v9 = vos + dir.yzx;
        float3 v10 = vos - dir.yzx;
        float3 v11 = vos + dir.zxy;
        float3 v12 = vos - dir.zxy;
         float3 v13 = vos + dir.yzx + dir.zxy;
        float3 v14 = vos - dir.yzx + dir.zxy;
        float3 v15 = vos - dir.yzx - dir.zxy;
        float3 v16 = vos + dir.yzx - dir.zxy;

         float4 vc = float4 (map(v1) , map(v2) , map(v3) , map(v4));
        float4 vd = float4 (map(v5) , map(v6) , map(v7) , map(v8));
        float4 va = float4 (map(v9) , map(v10) , map(v11) , map(v12));
        float4 vb = float4 (map(v13) , map(v14) , map(v15) , map(v16));

         float2 uv = float2 (dot(dir.yzx , uvw) , dot(dir.zxy , uvw));

         // wireframe 
        float www = 1.0 - isEdge(uv , va , vb , vc , vd);

        float3 wir = smoothstep(0.4 , 0.5 , abs(uvw - 0.5));
        float vvv = (1.0 - wir.x * wir.y) * (1.0 - wir.x * wir.z) * (1.0 - wir.y * wir.z);

        col = 2.0 * SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , 0.01 * pos.xz).zyx;
        col += 0.8 * float3 (0.1 , 0.3 , 0.4);
        col *= 0.5 + 0.5 * texcube(_Channel2 , sampler_Channel2 , 0.5 * pos , nor).x;
        col *= 1.0 - 0.75 * (1.0 - vvv) * www;

        // lighting 
       float dif = clamp(dot(nor , lig) , 0.0 , 1.0);
       float bac = clamp(dot(nor , normalize(lig * float3 (-1.0 , 0.0 , -1.0))) , 0.0 , 1.0);
       float sky = 0.5 + 0.5 * nor.y;
       float amb = clamp(0.75 + pos.y / 25.0 , 0.0 , 1.0);
       float occ = 1.0;

       // ambient occlusion 
      occ = calcOcc(uv , va , vb , vc , vd);
      occ = 1.0 - occ / 8.0;
      occ = occ * occ;
      occ = occ * occ;
      occ *= amb;

      // lighting 
     float3 lin = float3 (0.0 , 0.0 , 0.0);
     lin += 2.5 * dif * float3 (1.00 , 0.90 , 0.70) * (0.5 + 0.5 * occ);
     lin += 0.5 * bac * float3 (0.15 , 0.10 , 0.10) * occ;
     lin += 2.0 * sky * float3 (0.40 , 0.30 , 0.15) * occ;

     // line glow 
    float lineglow = 0.0;
    lineglow += smoothstep(0.4 , 1.0 , uv.x) * (1.0 - va.x * (1.0 - vc.x));
    lineglow += smoothstep(0.4 , 1.0 , 1.0 - uv.x) * (1.0 - va.y * (1.0 - vc.y));
    lineglow += smoothstep(0.4 , 1.0 , uv.y) * (1.0 - va.z * (1.0 - vc.z));
    lineglow += smoothstep(0.4 , 1.0 , 1.0 - uv.y) * (1.0 - va.w * (1.0 - vc.w));
    lineglow += smoothstep(0.4 , 1.0 , uv.y * uv.x) * (1.0 - vb.x * (1.0 - vd.x));
    lineglow += smoothstep(0.4 , 1.0 , uv.y * (1.0 - uv.x)) * (1.0 - vb.y * (1.0 - vd.y));
    lineglow += smoothstep(0.4 , 1.0 , (1.0 - uv.y) * (1.0 - uv.x)) * (1.0 - vb.z * (1.0 - vd.z));
    lineglow += smoothstep(0.4 , 1.0 , (1.0 - uv.y) * uv.x) * (1.0 - vb.w * (1.0 - vd.w));

    float3 linCol = 2.0 * float3 (5.0 , 0.6 , 0.0);
    linCol *= (0.5 + 0.5 * occ) * 0.5;
    lin += 3.0 * lineglow * linCol;

    col = col * lin;
    col += 8.0 * linCol * float3 (1.0 , 2.0 , 3.0) * (1.0 - www); // * ( 0.5 + 1.0 * sha ) ; 
    col += 0.1 * lineglow * linCol;
    col *= min(0.1 , exp(-0.07 * t));

    // blend to black & white 
   float3 col2 = float3 (1.3, 1.3, 1.3) * (0.5 + 0.5 * nor.y) * occ * www * (0.9 + 0.1 * vvv) * exp(-0.04 * t); ;
   float mi = sin(-1.57 + 0.5 * _Time.y);
   mi = smoothstep(0.70 , 0.75 , mi);
   col = lerp(col , col2 , mi);
 }

    // gamma 
   col = pow(col , float3 (0.45 , 0.45 , 0.45));

  return col;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
    lig = normalize(lig);
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// inputs 
float2 q = fragCoord.xy / _ScreenParams.xy;
float2 p = -1.0 + 2.0 * q;
p.x *= _ScreenParams.x / _ScreenParams.y;

float2 mo = iMouse.xy / _ScreenParams.xy;
if (iMouse.w <= 0.00001) mo = float2 (0.0 , 0.0);

 float time = 2.0 * _Time.y + 50.0 * mo.x;
 // camera 
 float cr = 0.2 * cos(0.1 * _Time.y);
 float3 ro = path(time + 0.0 , 1.0);
 float3 ta = path(time + 5.0 , 1.0) - float3 (0.0 , 6.0 , 0.0);
 gro.xyz = ro;

float3x3 cam = setCamera(ro , ta , cr);

// build ray 
float r2 = p.x * p.x * 0.32 + p.y * p.y;
p *= (7.0 - sqrt(37.5 - 11.5 * r2)) / (r2 + 1.0);
float3 rd = normalize(mul(cam , float3 (p.xy , -2.5)));

float3 col = render(ro , rd);

// vignetting 
col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

fragColor = float4 (col , 1.0);
return fragColor - 0.1;
}

//void mainVR(out float4 fragColor , in float2 fragCoord , in float3 fragRayOri , in float3 fragRayDir)
// {
//     float time = 1.0 * _Time.y;
//
//    float cr = 0.0;
//     float3 ro = path(time + 0.0 , 0.0) + float3 (0.0 , 0.7 , 0.0);
//     float3 ta = path(time + 2.5 , 0.0) + float3 (0.0 , 0.7 , 0.0);
//
//    float3x3 cam = setCamera(ro , ta , cr);
//
//    float3 col = render(ro + cam * fragRayOri , cam * fragRayDir);
//
//    fragColor = float4 (col , 1.0);
// return fragColor - 0.1;
//}

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