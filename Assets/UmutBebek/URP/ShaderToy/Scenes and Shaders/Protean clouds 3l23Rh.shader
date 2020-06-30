Shader "UmutBebek/URP/ShaderToy/Protean clouds 3l23Rh"
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

           // Protean clouds by nimitz ( twitter: @stormoid ) 
// https: // www.shadertoy.com / view / 3l23Rh 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

/*
    Technical details:

    The main volume noise is generated from a deformed periodic grid , which can produce
    a large range of noise - like patterns at very cheap evalutation cost. Allowing for multiple
    fetches of volume gradient computation for improved lighting.

    To further accelerate marching , since the volume is smooth , more than half the the density
    information isn't used to rendering or shading but only as an underlying volume distance to
    determine dynamic step size , by carefully selecting an equation ( polynomial for speed ) to
    step as a function of overall density ( not necessarialy rendered ) the visual results can be
    the same as a naive implementation with ~40% increase in rendering performance.

    Since the dynamic marching step size is even less uniform due to steps not being rendered at all
    the fog is evaluated as the difference of the fog integral at each rendered step.

*/

float2x2 rot(in float a) { float c = cos(a) , s = sin(a); return float2x2 (c , s , -s , c); }
//const float3x3 m3 = float3x3 (0.33338 , 0.56034 , -0.71817 , -0.87887 , 0.32651 , -0.15323 , 0.15162 , 0.69596 , 0.61339) * 1.93;
float mag2(float2 p) { return dot(p , p); }
float linstep(in float mn , in float mx , in float x) { return clamp((x - mn) / (mx - mn) , 0. , 1.); }
float prm1 = 0.;
float2 bsMo = float2 (0, 0);

float2 disp(float t) { return float2 (sin(t * 0.22) * 1. , cos(t * 0.175) * 1.) * 2.; }

float2 map(float3 p)
 {
    float3 p2 = p;
    p2.xy -= disp(p.z).xy;
    p.xy = mul(p.xy, rot(sin(p.z + _Time.y) * (0.1 + prm1 * 0.05) + _Time.y * 0.09));
    float cl = mag2(p2.xy);
    float d = 0.;
    p *= .61;
    float z = 1.;
    float trk = 1.;
    float dspAmp = 0.1 + prm1 * 0.2;
    for (int i = 0; i < 5; i++)
     {
          p += sin(p.zxy * 0.75 * trk + _Time.y * trk * .8) * dspAmp;
        d -= abs(dot(cos(p) , sin(p.yzx)) * z);
        z *= 0.57;
        trk *= 1.4;
        p = mul(p , float3x3 (0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339) * 1.93);
     }
    d = abs(d + prm1 * 3.) + prm1 * .3 - 2.5 + bsMo.y;
    return float2 (d + cl * .2 + 0.25 , cl);
 }

float4 render(in float3 ro , in float3 rd , float time)
 {
     float4 rez = float4 (0, 0, 0, 0);
    const float ldst = 8.;
     float3 lpos = float3 (disp(time + ldst) * 0.5 , time + ldst);
     float t = 1.5;
     float fogT = 0.;
     for (int i = 0; i < 130; i++)
      {
          if (rez.a > 0.99) break;

          float3 pos = ro + t * rd;
        float2 mpv = map(pos);
          float den = clamp(mpv.x - 0.3 , 0. , 1.) * 1.12;
          float dn = clamp((mpv.x + 2.) , 0. , 3.);

          float4 col = float4 (0, 0, 0, 0);
        if (mpv.x > 0.6)
         {

            col = float4 (sin(float3 (5. , 0.4 , 0.2) + mpv.y * 0.1 + sin(pos.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5 , 0.08);
            col *= den * den * den;
               col.rgb *= linstep(4. , -2.5 , mpv.x) * 2.3;
            float dif = clamp((den - map(pos + .8).x) / 9. , 0.001 , 1.);
            dif += clamp((den - map(pos + .35).x) / 2.5 , 0.001 , 1.);
            col.xyz *= den * (float3 (0.005 , .045 , .075) + 1.5 * float3 (0.033 , 0.07 , 0.03) * dif);
         }

          float fogC = exp(t * 0.2 - 2.2);
          col.rgba += float4 (0.06 , 0.11 , 0.11 , 0.1) * clamp(fogC - fogT , 0. , 1.);
          fogT = fogC;
          rez = rez + col * (1. - rez.a);
          t += clamp(0.5 - dn * dn * .05 , 0.09 , 0.3);
      }
     return clamp(rez , 0.0 , 1.0);
 }

float getsat(float3 c)
 {
    float mi = min(min(c.x , c.y) , c.z);
    float ma = max(max(c.x , c.y) , c.z);
    return (ma - mi) / (ma + 1e-7);
 }

// from my "Will it blend" shader ( https: // www.shadertoy.com / view / lsdGzN ) 
float3 iLerp(in float3 a , in float3 b , in float x)
 {
    float3 ic = lerp(a , b , x) + float3 (1e-6 , 0. , 0.);
    float sd = abs(getsat(ic) - lerp(getsat(a) , getsat(b) , x));
    float3 dir = normalize(float3 (2. * ic.x - ic.y - ic.z , 2. * ic.y - ic.x - ic.z , 2. * ic.z - ic.y - ic.x));
    float lgt = dot(float3 (1.0, 1.0, 1.0) , ic);
    float ff = dot(dir , normalize(ic));
    ic += 1.5 * dir * sd * ff * lgt;
    return clamp(ic , 0. , 1.);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
//float2 gl_fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN));
     float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = (fragCoord.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y;
    bsMo = (iMouse.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y;

    float time = _Time.y * 3.;
    float3 ro = float3 (0 , 0 , time);

    ro += float3 (sin(_Time.y) * 0.5 , sin(_Time.y * 1.) * 0. , 0);

    float dspAmp = .85;
    ro.xy += disp(ro.z) * dspAmp;
    float tgtDst = 3.5;

    float3 target = normalize(ro - float3 (disp(time + tgtDst) * dspAmp , time + tgtDst));
    ro.x -= bsMo.x * 2.;
    float3 rightdir = normalize(cross(target , float3 (0 , 1 , 0)));
    float3 updir = normalize(cross(rightdir , target));
    rightdir = normalize(cross(updir , target));
     float3 rd = normalize((p.x * rightdir + p.y * updir) * 1. - target);
    rd.xy = mul(rd.xy, rot(-disp(time + 3.5).x * 0.2 + bsMo.x));
    prm1 = smoothstep(-0.4 , 0.4 , sin(_Time.y * 0.3));
     float4 scn = render(ro , rd , time);

    float3 col = scn.rgb;
    col = iLerp(col.bgr , col.rgb , clamp(1. - prm1 , 0.05 , 1.));

    col = pow(col , float3 (.55 , 0.65 , 0.6)) * float3 (1. , .97 , .9);

    col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.12) * 0.7 + 0.3; // Vign 

     fragColor = float4 (col , 1.0);
 return fragColor-0.1;
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