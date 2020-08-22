Shader "UmutBebek/URP/ShaderToy/sound - acid jam ldfSW2"
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

           // srtuss , 2014 
// 
// I started making these visuals for Dave's "Tropical Beeper" track , but then the 
// soundshader - feature was added. :P 

float2 rotate(float2 p , float a)
 {
     return float2 (p.x * cos(a) - p.y * sin(a) , p.x * sin(a) + p.y * cos(a));
 }

float box(float2 p , float2 b)
 {
     float2 d = abs(p) - b;
     return min(max(d.x , d.y) , 0.0) + length(max(d , 0.0));
 }

#define aav ( 4.0 / _ScreenParams.y ) 

void button(out float4 bcol , inout float3 acol , float2 uv , float i1)
 {
     float v; float3 col;
     v = box(uv , float2 (0.1 , 0.1)) - 0.05;
     float l = length(uv);
     float shd = exp(-40.0 * max(v , 0.0));
     col = float3 (exp(l * -4.0) * 0.3 + 0.2, exp(l * -4.0) * 0.3 + 0.2, exp(l * -4.0) * 0.3 + 0.2);
     col *= 1.0 - float3 (exp(-100.0 * abs(v)), exp(-100.0 * abs(v)), exp(-100.0 * abs(v))) * 0.4;
     v = smoothstep(aav , 0.0 , v);
     bcol = lerp(float4 (0.0 , 0.0 , 0.0 , shd * 0.5) , float4 (col , 1.0) , v);
     col = float3 (0.3 , 1.0 , 0.2) * exp(-30.0 * l * l) * 0.8 * i1;
     acol += col;
 }

float f0(float2 uv)
 {
     float l = length(uv);
     return l - 0.2;
 }

float f1(float2 uv , float a)
 {
     float l = length(uv);
     return l - 0.14 + sin((a + atan2(uv.y , uv.x)) * 13.0) * 0.005;
 }

float f2(float2 uv , float a)
 {
     uv = rotate(uv , a);
     float l = length(uv);
     float w = max(abs(uv.x + 0.12) - 0.03 , abs(uv.y) - 0.01);
     return min(l - 0.1 , w);
 }

float3 n0(float2 p)
 {
     float2 h = float2 (0.01 , 0.0);
     float m = -0.01;
     return normalize(float3 (max(f0(p + h.xy) , m) - max(f0(p - h.xy) , m) , max(f0(p + h.yx) , m) - max(f0(p - h.yx) , m) , 2.0 * h.x));
 }

float3 n1(float2 p , float a)
 {
     float2 h = float2 (0.01 , 0.0);
     return normalize(float3 (f1(p + h.xy , a) - f1(p - h.xy , a) , f1(p + h.yx , a) - f1(p - h.yx , a) , 2.0 * h.x));
 }

float3 n2(float2 p , float a)
 {
     float2 h = float2 (0.005 , 0.0);
     float m = -0.005;
     return normalize(float3 (max(f2(p + h.xy , a) , m) - max(f2(p - h.xy , a) , m) , max(f2(p + h.yx , a) , m) - max(f2(p - h.yx , a) , m) , 2.0 * h.x));
 }

float3 sun = normalize(float3 (-0.2 , 0.5 , 0.5));

void knob(inout float3 bcol , inout float3 acol , float2 uv , float a)
 {
     float v; float3 col;
     float diff;
     float l = length(uv);
     bcol = lerp(bcol , float3 (0.0 , 0.0 , 0.0) , exp(max(l - 0.2 , 0.0) * -20.0) * 0.5);
     v = f0(uv);
     v = smoothstep(aav , 0.0 , v);
     diff = max(dot(lerp(n0(uv) , float3 (0.0 , 0.0 , 1.0) , smoothstep(0.02 , 0.0 , l - 0.115)) , sun) , 0.0);
     col = float3 (diff, diff, diff) * 0.2;
     bcol = lerp(bcol , col , v);
     bcol = lerp(bcol , float3 (0.0 , 0.0 , 0.0) , exp(max(l - 0.14 , 0.0) * -40.0) * 0.5);
     v = f1(uv , a); // l - 0.14 + sin ( atan2 ( uv.y , uv.x ) * 13.0 ) * 0.005 ; 
     v = smoothstep(aav , 0.0 , v);
     diff = max(dot(lerp(n1(uv , a) , float3 (0.0 , 0.0 , 1.0) , smoothstep(0.02 , 0.0 , l - 0.115)) , sun) , 0.0);
     col = float3 (diff, diff, diff) * 0.2; // float3 ( 0.05 , 0.05 , 0.05 ) ; 
     bcol = lerp(bcol , col , v);
     v = f2(uv , a);
     v = smoothstep(aav , 0.0 , v);
     diff = max(dot(lerp(n2(uv , a) , float3 (0.0 , 0.0 , 1.0) , 0.0) , sun) , 0.0);
     col = float3 (diff, diff, diff) * 0.1 + 0.2;
     bcol = lerp(bcol , col , v); // */ 
 }

float hash1(float x)
 {
     return frac(sin(x * 11.1753) * 192652.37862);
 }

float nse1(float x)
 {
     float fl = floor(x);
     return lerp(hash1(fl) , hash1(fl + 1.0) , smoothstep(0.0 , 1.0 , frac(x)));
 }

float bf(float t)
 {
     float v = 0.04;
     return exp(t * -30.0) + smoothstep(0.25 + v , 0.25 - v , abs(t * 2.0 - 1.0));
 }

#define ITS 7 

float2 circuit(float3 p)
 {
     p = mod(p , 2.0) - 1.0;
     float w = 1e38;
     float3 cut = float3 (1.0 , 0.0 , 0.0);
     float3 e1 = float3 (-1.0, -1.0, -1.0);
     float3 e2 = float3 (1.0 , 1.0 , 1.0);
     float rnd = 0.23;
     float pos , plane , cur;
     float fact = 0.9;
     float j = 0.0;
     for (int i = 0; i < ITS; i++)
      {
          pos = lerp(dot(e1 , cut) , dot(e2 , cut) , (rnd - 0.5) * fact + 0.5);
          plane = dot(p , cut) - pos;
          if (plane > 0.0)
           {
               e1 = lerp(e1 , float3 (pos, pos, pos) , cut);
               rnd = frac(rnd * 19827.5719);
               cut = cut.yzx;
           }
          else
           {
               e2 = lerp(e2 , float3 (pos, pos, pos) , cut);
               rnd = frac(rnd * 5827.5719);
               cut = cut.zxy;
           }
          j += step(rnd , 0.2);
          w = min(w , abs(plane));
      }
     return float2 (j / float(ITS - 1) , w);
 }

float3 pixel(float2 p , float time , float ct)
 {
     float te = ct * 9.0 / 16.0; // 0.25 + ( ct + 0.25 ) / 2.0 * 128.0 / 60.0 ; 
     float ll = dot(p , p);
     p *= 1.0 - cos((te + 0.75) * 6.283185307179586476925286766559) * 0.01;
     float2 pp = p;
     p = rotate(p , sin(time * 0.1) * 0.1 + nse1(time * 0.2) * 0.0);
     float r = 1.5;
     p = mod(p - r , r * 2.0) - r;
     p.x += 0.6;
     float i1 = bf(frac(0.75 + te));
     float i2 = bf(frac(0.5 + te));
     float i3 = bf(frac(0.25 + te));
     float i4 = bf(frac(0.0 + te));
     float s = time * 50.0;
     float2 shk = (float2 (nse1(s) , nse1(s + 11.0)) * 2.0 - 1.0) * exp(-5.0 * frac(te * 4.0)) * 0.1;
     pp += shk;
     p += shk;
     float3 col = float3 (0.1 , 0.1 , 0.1);
     s = 0.2;
     float c = smoothstep(aav , 0.0 , circuit(float3 (p , 0.1) * s).y / s - 0.001);
     col += float3 (c, c, c) * 0.05;
     float4 bcol; float3 acol = float3 (0.0 , 0.0 , 0.0);
     button(bcol , acol , p , i1);
     col = lerp(col , bcol.xyz , bcol.w);
     button(bcol , acol , p - float2 (0.4 , 0.0) , i2);
     col = lerp(col , bcol.xyz , bcol.w);
     button(bcol , acol , p - float2 (0.8 , 0.0) , i3);
     col = lerp(col , bcol.xyz , bcol.w);
     button(bcol , acol , p - float2 (1.2 , 0.0) , i4);
     col = lerp(col , bcol.xyz , bcol.w);
     knob(col , acol , p - float2 (1.2 , -0.6) , 1.9);
     knob(col , acol , p - float2 (0.4 , 0.6) , 0.2);
     knob(col , acol , p - float2 (0.7 , -0.6) , -0.5);
     float2 q = p - float2 (0.9 , 0.6);
     float2 qq = q - float2 (0.35 , 0.0);
     float v = box(qq , float2 (0.4 , 0.2)) - 0.01;
     col = lerp(col , float3 (0.2 , 0.2 , 0.2) * 0.8 , smoothstep(aav , 0.0 , v));
     col += float3 (1.0 , 1.0 , 1.0) * exp(max(v , 0.0) * -30.0) * 0.14;
     col -= float3 (1.0 , 1.0 , 1.0) * exp(dot(qq , qq) * -20.0) * 0.1;
     float2 fr = mod(q , 0.03) - 0.015;
     float2 id = floor(q / 0.03);
     v = box(fr , float2 (0.003 , 0.003)) - 0.003;
     float amp = 2.0;
     float inte = abs(id.y + sin(id.x * 0.6 + time * 4.0) * amp) - 0.8;
     acol += exp(max(v , 0.0) * -400.0) * smoothstep(0.5 , 0.0 , inte) * step(id.x , 21.0) * step(0.0 , id.x);
     // 0.018 
    col += acol;
    col *= exp((length(pp) - 0.5) * -1.0) * 0.5 + 0.5;
    col = pow(col , float3 (1.2 , 1.1 , 1.0) * 2.0) * 4.0;
    col = pow(col , float3 (1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));
    return col;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

sun = normalize(float3 (-0.2, 0.5, 0.5));

 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.xy;
      uv = 2.0 * uv - 1.0;
      uv.x *= _ScreenParams.x / _ScreenParams.y;
      float3 col = float3 (0.0 , 0.0 , 0.0);
      float j = 0.008;
      col = pixel(uv , _Time.y , _Time.y);
      /* col += pixel ( uv , _Time.y + j * 1.0 , _Time.y ) ;
     col += pixel ( uv , _Time.y - j * 1.0 , _Time.y ) ;
     col /= 3.0 ; // */
     fragColor = float4 (col , 1.0);
 return fragColor*0.5;
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