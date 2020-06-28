Shader "UmutBebek/URP/ShaderToy/Clouds XslGRr"
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

// Volumetric clouds. It performs level of detail ( LOD ) for faster rendering 

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

#if 1 
     float2 uv = (p.xy + float2 (37.0 , 239.0) * p.z) + f.xy;
    float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
#else 
    int3 q = int3 (p);
     int2 uv = q.xy + int2 (37 , 239) * q.z;

     float2 rg = lerp(lerp(texelFetch(_Channel0 , sampler_Channel0 , (uv) & 255 , 0) ,
                          texelFetch(_Channel0 , sampler_Channel0 , (uv + int2 (1 , 0)) & 255 , 0) , f.x) ,
                      lerp(texelFetch(_Channel0 , sampler_Channel0 , (uv + int2 (0 , 1)) & 255 , 0) ,
                          texelFetch(_Channel0 , sampler_Channel0 , (uv + int2 (1 , 1)) & 255 , 0) , f.x) , f.y).yx;
#endif 
     return -1.0 + 2.0 * lerp(rg.x , rg.y , f.z);
 }

float map5(in float3 p)
 {
     float3 q = p - float3 (0.0 , 0.1 , 1.0) * _Time.y;
     float f;
    f = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q); q = q * 2.01;
    f += 0.06250 * noise(q); q = q * 2.02;
    f += 0.03125 * noise(q);
     return clamp(1.5 - p.y - 2.0 + 1.75 * f , 0.0 , 1.0);
 }
float map4(in float3 p)
 {
     float3 q = p - float3 (0.0 , 0.1 , 1.0) * _Time.y;
     float f;
    f = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q); q = q * 2.01;
    f += 0.06250 * noise(q);
     return clamp(1.5 - p.y - 2.0 + 1.75 * f , 0.0 , 1.0);
 }
float map3(in float3 p)
 {
     float3 q = p - float3 (0.0 , 0.1 , 1.0) * _Time.y;
     float f;
    f = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q);
     return clamp(1.5 - p.y - 2.0 + 1.75 * f , 0.0 , 1.0);
 }
float map2(in float3 p)
 {
     float3 q = p - float3 (0.0 , 0.1 , 1.0) * _Time.y;
     float f;
    f = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); ;
     return clamp(1.5 - p.y - 2.0 + 1.75 * f , 0.0 , 1.0);
 }

float3 sundir = normalize(float3 (-1.0 , 0.0 , -1.0));

float4 integrate(in float4 sum , in float dif , in float den , in float3 bgcol , in float t)
 {
    // lighting 
   float3 lin = float3 (0.65 , 0.7 , 0.75) * 1.4 + float3 (1.0 , 0.6 , 0.3) * dif;
   float4 col = float4 (lerp(float3 (1.0 , 0.95 , 0.8) , float3 (0.25 , 0.3 , 0.35) , den) , den);
   col.xyz *= lin;
   col.xyz = lerp(col.xyz , bgcol , 1.0 - exp(-0.003 * t * t));
   col.w *= 0.4;
   // front to back blending 
  col.rgb *= col.a;
  return sum + col * (1.0 - sum.a);
}

void MARCH(int STEPS, float MAPLOD, inout float t, inout float4 sum, inout float3 ro, inout float3 rd, inout float3 bgcol) {
    for (int i = 0; i < STEPS; i++)
    {
        float3 pos = ro + t * rd;
        if (pos.y < -3.0 || pos.y > 2.0 || sum.a > 0.99) break;
        float den;
        if (MAPLOD == 5)
            den = map5(pos);
        else if (MAPLOD == 4)
            den = map4(pos);
        else if (MAPLOD == 3)
            den = map3(pos);
        else if (MAPLOD == 2)
            den = map2(pos);

        if (den > 0.01)
        {
            float dif = 0;
            if (MAPLOD == 5)
                dif = clamp((den - map5(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
            else if (MAPLOD == 4)
                dif = clamp((den - map4(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
            else if (MAPLOD == 3)
                dif = clamp((den - map3(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
            else if (MAPLOD == 2)
                dif = clamp((den - map2(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
                
            float3 lin = float3 (0.65, 0.7, 0.75) * 1.4 + float3 (1.0, 0.6, 0.3) * dif;
            float4 col = float4 (lerp(float3 (1.0, 0.95, 0.8), float3 (0.25, 0.3, 0.35), den), den);
            col.xyz *= lin;
            col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-0.003 * t * t));
            col.w *= 0.4;

            col.rgb *= col.a;
            sum += col * (1.0 - sum.a);
        }
        t += max(0.05, 0.02 * t);
    }
}

float4 raymarch(in float3 ro , in float3 rd , in float3 bgcol , in int2 px)
 { 
     float4 sum = float4 (0.0, 0.0, 0.0, 0.0);

     float t = 0.0; // 0.05 * texelFetch ( _Channel0 , sampler_Channel0 , px&255 , 0 ) .x ; 

    MARCH(30 , 5, t, sum, ro, rd, bgcol);
    MARCH(30 , 4, t, sum, ro, rd, bgcol);
    MARCH(30 , 3, t, sum, ro, rd, bgcol);
    MARCH(30 , 2, t, sum, ro, rd, bgcol);

    return clamp(sum , 0.0 , 1.0);
 }

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

float4 render(in float3 ro , in float3 rd , in int2 px)
 {
    // background sky 
    float sun = clamp(dot(sundir , rd) , 0.0 , 1.0);
    float3 col = float3 (0.6 , 0.71 , 0.75) - rd.y * 0.2 * float3 (1.0 , 0.5 , 1.0) + 0.15 * 0.5;
    col += 0.2 * float3 (1.0 , .6 , 0.1) * pow(sun , 8.0);

    // clouds 
   float4 res = raymarch(ro , rd , col , px);
   col = col * (1.0 - res.w) + res.xyz;

   // sun glare 
   col += 0.2 * float3 (1.0 , 0.4 , 0.2) * pow(sun , 3.0);

  return float4 (col , 1.0);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 p = (2.0 * fragCoord - _ScreenParams.xy) / _ScreenParams.y;

    float2 m = iMouse.xy / _ScreenParams.xy;

    // camera 
   float3 ro = 4.0 * normalize(float3 (sin(3.0 * m.x) , 0.4 * m.y , cos(3.0 * m.x)));
    float3 ta = float3 (0.0 , -1.0 , 0.0);
   float3x3 ca = setCamera(ro , ta , 0.0);
   // ray 
  float3 rd = mul(ca , normalize(float3 (p.xy , 1.5)));

  fragColor = render(ro , rd , int2 (fragCoord - 0.5));
  return fragColor;
}

//void mainVR(out float4 fragColor , in float2 fragCoord , in float3 fragRayOri , in float3 fragRayDir)
// {
//    fragColor = render(fragRayOri , fragRayDir , int2 (fragCoord - 0.5));
// return fragColor;
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