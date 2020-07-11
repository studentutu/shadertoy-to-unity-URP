Shader "UmutBebek/URP/ShaderToy/Auroras XtGGRt"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

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
            float4 m2;


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
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

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

           // Auroras by nimitz 2017 ( twitter: @stormoid ) 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

/*

    There are two main hurdles I encountered rendering this effect.
    First , the nature of the SAMPLE_TEXTURE2D that needs to be generated to get a believable effect
    needs to be very specific , with large scale band - like structures , small scale non - smooth variations
    to create the trail - like effect , a method for animating said SAMPLE_TEXTURE2D smoothly and finally doing all
    of this cheaply enough to be able to evaluate it several times per fragment / pixel.

    The second obstacle is the need to render a large volume while keeping the computational cost low.
    Since the effect requires the trails to extend way up in the atmosphere to look good , this means
    that the evaluated volume cannot be as constrained as with cloud effects. My solution was to make
    the sample stride increase polynomially , which works very well as long as the trails are lower opcaity than
    the rest of the effect. Which is always the case for auroras.

    After that , there were some issues with getting the correct emission curves and removing banding at lowered
    sample densities , this was fixed by a combination of sample number influenced dithering and slight sample blending.

    N.B. the base setup is from an old shader and ideally the effect would take an arbitrary ray origin and
    direction. But this was not required for this demo and would be trivial to fix.
*/

#define time _Time.y 

float2x2 mm2(in float a) { float c = cos(a) , s = sin(a); return float2x2 (c , s , -s , c); }

float tri(in float x) { return clamp(abs(frac(x) - .5) , 0.01 , 0.49); }
float2 tri2(in float2 p) { return float2 (tri(p.x) + tri(p.y) , tri(p.y + tri(p.x))); }

float triNoise2d(in float2 p , float spd)
 {
    float z = 1.8;
    float z2 = 2.5;
     float rz = 0.;
    p = mul (p , mm2(p.x * 0.06));
    float2 bp = p;
     for (float i = 0.; i < 5.; i++)
      {
        float2 dg = tri2(bp * 1.85) * .75;
        dg = mul(dg,  mm2(time * spd));
        p -= dg / z2;

        bp *= 1.3;
        z2 *= .45;
        z *= .42;
          p *= 1.21 + (rz - 1.0) * .02;

        rz += tri(p.x + tri(p.y)) * z;
        p = mul( p, -float2x2(0.95534, 0.29552, -0.29552, 0.95534));
      }
    return clamp(1. / pow(rz * 29. , 1.3) , 0. , .55);
 }

float hash21(in float2 n) { return frac(sin(dot(n , float2 (12.9898 , 4.1414))) * 43758.5453); }
float4 aurora(float3 ro , float3 rd, float4 positionCS)
 {
    float4 col = float4 (0 , 0 , 0 , 0);
    float4 avgCol = float4 (0 , 0 , 0 , 0);

    for (float i = 0.; i < 50.; i++)
     {
        float of = 0.006 * hash21(positionCS.xy) * smoothstep(0. , 15. , i);
        float pt = ((.8 + pow(i , 1.4) * .002) - ro.y) / (rd.y * 2. + 0.4);
        pt -= of;
         float3 bpos = ro + pt * rd;
        float2 p = bpos.zx;
        float rzt = triNoise2d(p , 0.06);
        float4 col2 = float4 (0 , 0 , 0 , rzt);
        col2.rgb = (sin(1. - float3 (2.15 , -.5 , 1.2) + i * 0.043) * 0.5 + 0.5) * rzt;
        avgCol = lerp(avgCol , col2 , .5);
        col += avgCol * exp2(-i * 0.065 - 2.5) * smoothstep(0. , 5. , i);

     }

    col *= (clamp(rd.y * 15. + .4 , 0. , 1.));


    // return clamp ( pow ( col , float4 ( 1.3 ) ) * 1.5 , 0. , 1. ) ; 
    // return clamp ( pow ( col , float4 ( 1.7 ) ) * 2. , 0. , 1. ) ; 
    // return clamp ( pow ( col , float4 ( 1.5 ) ) * 2.5 , 0. , 1. ) ; 
    // return clamp ( pow ( col , float4 ( 1.8 ) ) * 1.5 , 0. , 1. ) ; 

    // return smoothstep ( 0. , 1.1 , pow ( col , float4 ( 1. , 1. , 1. , 1. ) ) * 1.5 ) ; 
   return col * 1.8;
   // return pow ( col , float4 ( 1. , 1. , 1. , 1. ) ) * 2. 
}


// -- -- -- -- -- -- -- -- -- - Background and Stars -- -- -- -- -- -- -- -- -- -- 

float3 nmzHash33(float3 q)
 {
    int3 p = int3(int3 (q));
    p = p * int3(374761393U , 1103515245U , 668265263U) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3U));
    return float3 (p ^ (p >> 16U)) * (1.0 / float3 (0xffffffffU, 0xffffffffU, 0xffffffffU));
 }

float3 stars(in float3 p)
 {
    float3 c = float3 (0. , 0. , 0.);
    float res = _ScreenParams.x * 1.;

     for (float i = 0.; i < 4.; i++)
     {
        float3 q = frac(p * (.15 * res)) - 0.5;
        float3 id = floor(p * (.15 * res));
        float2 rn = nmzHash33(id).xy;
        float c2 = 1. - smoothstep(0. , .6 , length(q));
        c2 *= step(rn.x , .0005 + i * i * 0.001);
        c += c2 * (lerp(float3 (1.0 , 0.49 , 0.1) , float3 (0.75 , 0.9 , 1.) , rn.y) * 0.1 + 0.9);
        p *= 1.3;
     }
    return c * c * .8;
 }

float3 bg(in float3 rd)
 {
    float sd = dot(normalize(float3 (-0.5 , -0.6 , 0.9)) , rd) * 0.5 + 0.5;
    sd = pow(sd , 5.);
    float3 col = lerp(float3 (0.05 , 0.1 , 0.2) , float3 (0.1 , 0.05 , 0.2) , sd);
    return col * .63;
 }
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = q - 0.5;
      p.x *= _ScreenParams.x / _ScreenParams.y;

     float3 ro = float3 (0 , 0 , -6.7);
     float3 rd = normalize(float3 (p , 1.3));
     float2 mo = iMouse.xy / _ScreenParams.xy - .5;
     mo = (mo == float2 (-.5, -.5)) ? mo = float2 (-0.1 , 0.1) : mo;
      mo.x *= _ScreenParams.x / _ScreenParams.y;
     rd.yz = mul(rd.yz,mm2(mo.y));
     rd.xz = mul(rd.xz, mm2(mo.x + sin(time * 0.05) * 0.2));

     float3 col = float3 (0. , 0. , 0.);
     float3 brd = rd;
     float fade = smoothstep(0. , 0.01 , abs(brd.y)) * 0.1 + 0.9;

     col = bg(rd) * fade;

     if (rd.y > 0.) {
         float4 aur = smoothstep(0. , 1.5 , aurora(ro , rd, input.positionCS)) * fade;
         col += stars(rd);
         col = col * (1. - aur.a) + aur.rgb;
      }
     else // Reflections 
      {
         rd.y = abs(rd.y);
         col = bg(rd) * fade * 0.6;
         float4 aur = smoothstep(0.0 , 2.5 , aurora(ro , rd, input.positionCS));
         col += stars(rd) * 0.1;
         col = col * (1. - aur.a) + aur.rgb;
         float3 pos = ro + ((0.5 - ro.y) / rd.y) * rd;
         float nz2 = triNoise2d(pos.xz * float2 (.5 , .7) , 0.);
         col += lerp(float3 (0.2 , 0.25 , 0.5) * 0.08 , float3 (0.3 , 0.3 , 0.5) * 0.7 , nz2 * 0.4);
      }

      fragColor = float4 (col , 1.);
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