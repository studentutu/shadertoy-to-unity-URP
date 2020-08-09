Shader "UmutBebek/URP/ShaderToy/Storm Xd23zh"
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

float noise(in float2 x)
 {
    float2 p = floor(x);
    float2 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy) + f.xy;
     return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).x;
 }

float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }

float hash(in float n)
 {
    return frac(sin(n) * 43758.5453);
 }

// coulds 
float4 map(float3 p , float2 ani)
 {
     float3 r = p;

     float h = (0.7 + 0.3 * ani.x) * noise(0.76 * r.xz);
     r.y -= h;

     float den = -(r.y + 2.5);
     r += 0.2 * float3 (0.0 , 0.0 , 1.0) * ani.y;

     float3 q = 2.5 * r * float3 (1.0 , 1.0 , 0.15) + float3 (1.0 , 1.0 , 1.0) * ani.y * 0.15;
     float f;
    f = 0.50000 * noise(q); q = q * 2.02 - float3 (-1.0 , 1.0 , -1.0) * ani.y * 0.15;
    f += 0.25000 * noise(q); q = q * 2.03 + float3 (1.0 , -1.0 , 1.0) * ani.y * 0.15;
    f += 0.12500 * noise(q); q = q * 2.01 - float3 (1.0 , 1.0 , -1.0) * ani.y * 0.15;
    q.z *= 4.0;
    f += 0.06250 * noise(q); q = q * 2.02 + float3 (1.0 , 1.0 , 1.0) * ani.y * 0.15;
    f += 0.03125 * noise(q);

    float es = 1.0 - clamp((r.y + 1.0) / 0.26 , 0.0 , 1.0);
    f += f * (1.0 - f) * 0.6 * sin(q.z) * es;
     den = clamp(den + 4.4 * f , 0.0 , 1.0);

     // color 
     float3 col = lerp(float3 (0.2 , 0.3 , 0.3) , float3 (1.0 , 1.0 , 1.0) , clamp((r.y + 2.5) / 3.0 , 0.0 , 1.0));
    col = lerp(col , 3.0 * float3 (1.0 , 1.1 , 1.20) * (0.2 + 0.8 * ani.x) , es);
     col *= lerp(float3 (0.1 , 0.32 , 0.38) , float3 (1.05 , 0.95 , 0.75) , f * 1.2);
    col = col * (0.8 - 0.5 * ani.x) + ani.x * 2.0 * smoothstep(0.75 , 0.86 , sin(10.0 * ani.y + 2.0 * r.z + r.x * 10.0)) * smoothstep(0.6 , 0.8 , f) * float3 (1.0 , 0.8 , 0.5) * smoothstep(0.7 , 0.9 , noise(q.yx));

     return float4 (col , den);
 }

// light direction 
float3 lig = normalize(float3 (-1.0 , 1.0 , -1.0));

float3 raymarch(in float3 ro , in float3 rd , in float2 ani , in float2 pixel)
 {
    // background color 
    float3 bgc = float3 (0.6 , 0.7 , 0.7) + 0.3 * rd.y;
   bgc *= 0.2;


   // dithering 
   float t = 0.03 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , pixel.xy / _ScreenParams.x).x;

   // raymarch 
   float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);
   for (int i = 0; i < 150; i++)
    {
        if (sum.a > 0.99) continue;

        float3 pos = ro + t * rd;
        float4 col = map(pos , ani);

        // lighting 
         float dif = 0.1 + 0.4 * (col.w - map(pos + lig * 0.15 , ani).w);
         col.xyz += dif;

         // fog 
          col.xyz = lerp(col.xyz , bgc , 1.0 - exp(-0.005 * t * t));

          col.rgb *= col.a;
          sum = sum + col * (1.0 - sum.a);

          // advance ray with LOD 
           t += 0.03 + t * 0.012;
       }

   // blend with background 
   sum.xyz = lerp(bgc , sum.xyz / (sum.w + 0.0001) , sum.w);

   return clamp(sum.xyz , 0.0 , 1.0);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

lig = normalize(float3 (-1.0, 1.0, -1.0));

 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 q = fragCoord.xy / _ScreenParams.xy;
     float2 p = -1.0 + 2.0 * q;
     p.x *= _ScreenParams.x / _ScreenParams.y;

     float2 mo = iMouse.xy / _ScreenParams.xy;
     if (iMouse.w <= 0.00001) mo = float2 (0.0 , 0.0);

      float time = _Time.y;

      float2 ani = float2 (1.0 , 1.0);
      float ati = time / 17.0;
      float pt = mod(ati , 2.0);
      ani.x = smoothstep(0.3 , 0.7 , pt) - smoothstep(1.3 , 1.7 , pt);
      float it = floor(0.75 + ati * 0.5 + 0.1);
      float ft = frac(0.75 + ati * 0.5 + 0.1);
      ft = smoothstep(0.0 , 0.6 , ft);
      ani.y = time * 0.15 + 30.0 * (it + ft);

      // camera parameters 
     float4 camPars = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , floor(1.0 + _Time.y / 5.5) * float2 (5.0 , 7.0) / _ScreenParams.xy);

     // camera position 
    float3 ro = 4.0 * normalize(float3 (cos(30.0 * camPars.x + 0.023 * time) , 0.3 + 0.2 * sin(30.0 * camPars.x + 0.08 * time) , sin(30.0 * camPars.x + 0.023 * _Time.y)));
     float3 ta = float3 (0.0 , 0.0 , 0.0);
     float cr = 0.25 * cos(30.0 * camPars.y + 0.1 * time);

     // shake 
     ro += ani.x * ani.x * 0.05 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 1.035 * time * float2 (0.010 , 0.014)).xyz);
     ta += ani.x * ani.x * 0.20 * (-1.0 + 2.0 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , 1.035 * time * float2 (0.013 , 0.008)).xyz);

     // build ray 
   float3 ww = normalize(ta - ro);
   float3 uu = normalize(cross(float3 (sin(cr) , cos(cr) , 0.0) , ww));
   float3 vv = normalize(cross(ww , uu));
   float3 rd = normalize(p.x * uu + p.y * vv + (2.5 + 3.5 * pow(camPars.z , 2.0)) * ww);

   // raymarch 
   float3 col = raymarch(ro , rd , ani , fragCoord);

   // contrast , saturation and vignetting 
  col = col * col * (3.0 - 2.0 * col);
 col = lerp(col , float3 (dot(col , float3 (0.33 , 0.33 , 0.33)), dot(col, float3 (0.33, 0.33, 0.33)), dot(col, float3 (0.33, 0.33, 0.33))) , -0.5);
  col *= 0.25 + 0.75 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1);

  col *= 1.0 - smoothstep(0.4 , 0.5 , abs(frac(_Time.y / 5.5) - 0.5)) * (1.0 - sqrt(ani.x));
 fragColor = float4 (col , 1.0);
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