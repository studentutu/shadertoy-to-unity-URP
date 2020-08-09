Shader "UmutBebek/URP/ShaderToy/Magnetismic XlB3zV"
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

           float3 makeDarker(float3 item) {
               return item *= 0.90;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Magnetismic by nimitz ( twitter: @stormoid ) 
// https: // www.shadertoy.com / view / XlB3zV 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

// Getting 60fps here at high quality 
#define HIGH_QUALITY 

#ifdef HIGH_QUALITY 
#define STEPS 130 
#define ALPHA_WEIGHT 0.015 
#define BASE_STEP 0.025 
#else 
#define STEPS 50 
#define ALPHA_WEIGHT 0.05 
#define BASE_STEP 0.1 
#endif 

#define time _Time.y 
float2 mo;
float2 rot(in float2 p , in float a) { float c = cos(a) , s = sin(a); return mul(p , float2x2 (c , s , -s , c)); }
float hash21(in float2 n) { return frac(sin(dot(n , float2 (12.9898 , 4.1414))) * 43758.5453); }
float noise(in float3 p)
 {
     float3 ip = floor(p) , fp = frac(p);
    fp = fp * fp * (3.0 - 2.0 * fp);
     float2 tap = (ip.xy + float2 (37.0 , 17.0) * ip.z) + fp.xy;
     float2 cl = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (tap + 0.5) / 256.0 , 0.0).yx;
     return lerp(cl.x , cl.y , fp.z);
 }

float fbm(in float3 p , in float sr)
 {
    p *= 3.5;
    float rz = 0. , z = 1.;
    for (int i = 0; i < 4; i++)
     {
        float n = noise(p - time * .6);
        rz += (sin(n * 4.4) - .45) * z;
        z *= .47;
        p *= 3.5;
     }
    return rz;
 }

float4 map(in float3 p)
 {
    float dtp = dot(p , p);
     p = .5 * p / (dtp + .2);
    p.xz = rot(p.xz , p.y * 2.5);
    p.xy = rot(p.xz , p.y * 2.);

    float dtp2 = dot(p , p);
    p = (mo.y + .6) * 3. * p / (dtp2 - 5.);
    float r = clamp(fbm(p , dtp * 0.1) * 1.5 - dtp * (.35 - sin(time * 0.3) * 0.15) , 0. , 1.);
    float4 col = float4 (.5 , 1.7 , .5 , .96) * r;

    float grd = clamp((dtp + .7) * 0.4 , 0. , 1.);
    col.b += grd * .6;
    col.r -= grd * .5;
    float3 lv = lerp(p , float3 (0.3 , 0.3 , 0.3) , 2.);
    grd = clamp((col.w - fbm(p + lv * .05 , 1.)) * 2. , 0.01 , 1.5);
    col.rgb *= float3 (.5 , 0.4 , .6) * grd + float3 (4. , 0. , .4);
    col.a *= clamp(dtp * 2. - 1. , 0. , 1.) * 0.07 + 0.87;

    return col;
 }

float4 vmarch(in float3 ro , in float3 rd, float4 positionCS)
 {
     float4 rz = float4 (0 , 0 , 0 , 0);
     float t = 2.5;
    t += 0.03 * hash21(positionCS.xy);
     for (int i = 0; i < STEPS; i++)
      {
          if (rz.a > 0.99 || t > 6.) break;
          float3 pos = ro + t * rd;
        float4 col = map(pos);
        float den = col.a;
        col.a *= ALPHA_WEIGHT;
          col.rgb *= col.a * 1.7;
          rz += col * (1. - rz.a);
        t += BASE_STEP - den * (BASE_STEP - BASE_STEP * 0.015);
      }
    return rz;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 p = fragCoord.xy / _ScreenParams.xy * 2. - 1.;
      p.x *= _ScreenParams.x / _ScreenParams.y * .85;
     p *= 1.1;
      mo = 2.0 * iMouse.xy / _ScreenParams.xy;
     mo = (mo == float2 (.0 , .0)) ? mo = float2 (0.5 , 1.) : mo;

      float3 ro = 4. * normalize(float3 (cos(2.75 - 2.0 * (mo.x + time * 0.05)) , sin(time * 0.22) * 0.2 , sin(2.75 - 2.0 * (mo.x + time * 0.05))));
      float3 eye = normalize(float3 (0 , 0 , 0) - ro);
      float3 rgt = normalize(cross(float3 (0 , 1 , 0) , eye));
      float3 up = cross(eye , rgt);
      float3 rd = normalize(p.x * rgt + p.y * up + (3.3 - sin(time * 0.3) * .7) * eye);

      float4 col = clamp(vmarch(ro , rd, input.positionCS) , 0. , 1.);
     col.rgb = pow(col.rgb , float3 (.9 , .9 , .9));
     /* col.rb = rot ( col.rg , 0.35 ) ;
    col.gb = rot ( col.gb , - 0.1 ) ; */

    fragColor = float4 (col.rgb , 1.0);
    fragColor *= 0.85;
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