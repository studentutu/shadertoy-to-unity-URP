Shader "UmutBebek/URP/ShaderToy/Apollonian 4ds3zn"
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

           // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 
// 
// I can't recall where I learnt about this fractal. 
// 
// Coloring and fake occlusions are done by orbit trapping , as usual. 


// Antialiasing level 
#if HW_PERFORMANCE == 0 
#define AA 1 
#else 
#define AA 2 // Make it 3 if you have a fast machine 
#endif 

float4 orb;

float map(float3 p , float s)
 {
     float scale = 1.0;

     orb = float4 (1000.0, 1000.0, 1000.0, 1000.0);

     for (int i = 0; i < 8; i++)
      {
          p = -1.0 + 2.0 * frac(0.5 * p + 0.5);

          float r2 = dot(p , p);

        orb = min(orb , float4 (abs(p) , r2));

          float k = s / r2;
          p *= k;
          scale *= k;
      }

     return 0.25 * abs(p.y) / scale;
 }

float trace(in float3 ro , in float3 rd , float s)
 {
     float maxd = 30.0;
    float t = 0.01;
    for (int i = 0; i < 512; i++)
     {
         float precis = 0.001 * t;

         float h = map(ro + rd * t , s);
        if (h < precis || t > maxd) break;
        t += h;
     }

    if (t > maxd) t = -1.0;
    return t;
 }

float3 calcNormal(in float3 pos , in float t , in float s)
 {
    float precis = 0.001 * t;

    float2 e = float2 (1.0 , -1.0) * precis;
    return normalize(e.xyy * map(pos + e.xyy , s) +
                           e.yyx * map(pos + e.yyx , s) +
                           e.yxy * map(pos + e.yxy , s) +
                      e.xxx * map(pos + e.xxx , s));
 }

float3 render(in float3 ro , in float3 rd , in float anim)
 {
    // trace 
   float3 col = float3 (0.0 , 0.0 , 0.0);
   float t = trace(ro , rd , anim);
   if (t > 0.0)
    {
       float4 tra = orb;
       float3 pos = ro + t * rd;
       float3 nor = calcNormal(pos , t , anim);

       // lighting 
      float3 light1 = float3 (0.577 , 0.577 , -0.577);
      float3 light2 = float3 (-0.707 , 0.000 , 0.707);
      float key = clamp(dot(light1 , nor) , 0.0 , 1.0);
      float bac = clamp(0.2 + 0.8 * dot(light2 , nor) , 0.0 , 1.0);
      float amb = (0.7 + 0.3 * nor.y);
      float ao = pow(clamp(tra.w * 2.0 , 0.0 , 1.0) , 1.2);

      float3 brdf = 1.0 * float3 (0.40 , 0.40 , 0.40) * amb * ao;
      brdf += 1.0 * float3 (1.00 , 1.00 , 1.00) * key * ao;
      brdf += 1.0 * float3 (0.40 , 0.40 , 0.40) * bac * ao;

      // material 
     float3 rgb = float3 (1.0 , 1.0 , 1.0);
     rgb = lerp(rgb , float3 (1.0 , 0.80 , 0.2) , clamp(6.0 * tra.y , 0.0 , 1.0));
     rgb = lerp(rgb , float3 (1.0 , 0.55 , 0.0) , pow(clamp(1.0 - 2.0 * tra.z , 0.0 , 1.0) , 8.0));

     // color 
    col = rgb * brdf * exp(-0.2 * t);
 }

return sqrt(col);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float time = _Time.y * 0.25 + 0.01 * iMouse.x;
     float anim = 1.1 + 0.5 * smoothstep(-0.3 , 0.3 , cos(0.1 * _Time.y));

     float3 tot = float3 (0.0 , 0.0 , 0.0);
     #if AA > 1 
     for (int jj = 0; jj < AA; jj++)
     for (int ii = 0; ii < AA; ii++)
     #else 
     int ii = 1 , jj = 1;
     #endif 
      {
         float2 q = fragCoord.xy + float2 (float(ii) , float(jj)) / float(AA);
         float2 p = (2.0 * q - _ScreenParams.xy) / _ScreenParams.y;

         // camera 
        float3 ro = float3 (2.8 * cos(0.1 + .33 * time) , 0.4 + 0.30 * cos(0.37 * time) , 2.8 * cos(0.5 + 0.35 * time));
        float3 ta = float3 (1.9 * cos(1.2 + .41 * time) , 0.4 + 0.10 * cos(0.27 * time) , 1.9 * cos(2.0 + 0.38 * time));
        float roll = 0.2 * cos(0.1 * time);
        float3 cw = normalize(ta - ro);
        float3 cp = float3 (sin(roll) , cos(roll) , 0.0);
        float3 cu = normalize(cross(cw , cp));
        float3 cv = normalize(cross(cu , cw));
        float3 rd = normalize(p.x * cu + p.y * cv + 2.0 * cw);

        tot += render(ro , rd , anim);
     }

    tot = tot / float(AA * AA);

     fragColor = float4 (tot , 1.0);
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