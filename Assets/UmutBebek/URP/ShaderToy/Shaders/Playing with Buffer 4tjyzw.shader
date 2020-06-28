Shader "UmutBebek/URP/ShaderToy/Playing with Buffer 4tjyzw"
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

             float circle(in float2 _st , in float _radius) {
float2 dist = _st;
 return 1. - smoothstep(_radius - (_radius * 0.01) ,
                     _radius + (_radius * 0.01) ,
                     dot(dist , dist) * 4.0);
}

float noise3D(float3 p)
 {
     return frac(sin(dot(p , float3 (12.9898 , 78.233 , 128.852))) * 43758.5453) * 2.0 - 1.0;
 }

float simplex3D(float3 p)
 {

     float f3 = 1.0 / 3.0;
     float s = (p.x + p.y + p.z) * f3;
     int i = int(floor(p.x + s));
     int j = int(floor(p.y + s));
     int k = int(floor(p.z + s));

     float g3 = 1.0 / 6.0;
     float t = float((i + j + k)) * g3;
     float x0 = float(i) - t;
     float y0 = float(j) - t;
     float z0 = float(k) - t;
     x0 = p.x - x0;
     y0 = p.y - y0;
     z0 = p.z - z0;

     int i1 , j1 , k1;
     int i2 , j2 , k2;

     if (x0 >= y0)
      {
          if (y0 >= z0) { i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0; } // X Y Z order 
          else if (x0 >= z0) { i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1; } // X Z Y order 
          else { i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1; } // Z X Z order 
      }
     else
      {
          if (y0 < z0) { i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1; } // Z Y X order 
          else if (x0 < z0) { i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1; } // Y Z X order 
          else { i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0; } // Y X Z order 
      }

     float x1 = x0 - float(i1) + g3;
     float y1 = y0 - float(j1) + g3;
     float z1 = z0 - float(k1) + g3;
     float x2 = x0 - float(i2) + 2.0 * g3;
     float y2 = y0 - float(j2) + 2.0 * g3;
     float z2 = z0 - float(k2) + 2.0 * g3;
     float x3 = x0 - 1.0 + 3.0 * g3;
     float y3 = y0 - 1.0 + 3.0 * g3;
     float z3 = z0 - 1.0 + 3.0 * g3;

     float3 ijk0 = float3 (i , j , k);
     float3 ijk1 = float3 (i + i1 , j + j1 , k + k1);
     float3 ijk2 = float3 (i + i2 , j + j2 , k + k2);
     float3 ijk3 = float3 (i + 1 , j + 1 , k + 1);

     float3 gr0 = normalize(float3 (noise3D(ijk0) , noise3D(ijk0 * 2.01) , noise3D(ijk0 * 2.02)));
     float3 gr1 = normalize(float3 (noise3D(ijk1) , noise3D(ijk1 * 2.01) , noise3D(ijk1 * 2.02)));
     float3 gr2 = normalize(float3 (noise3D(ijk2) , noise3D(ijk2 * 2.01) , noise3D(ijk2 * 2.02)));
     float3 gr3 = normalize(float3 (noise3D(ijk3) , noise3D(ijk3 * 2.01) , noise3D(ijk3 * 2.02)));

     float n0 = 0.0;
     float n1 = 0.0;
     float n2 = 0.0;
     float n3 = 0.0;

     float t0 = 0.5 - x0 * x0 - y0 * y0 - z0 * z0;
     if (t0 >= 0.0)
      {
          t0 *= t0;
          n0 = t0 * t0 * dot(gr0 , float3 (x0 , y0 , z0));
      }
     float t1 = 0.5 - x1 * x1 - y1 * y1 - z1 * z1;
     if (t1 >= 0.0)
      {
          t1 *= t1;
          n1 = t1 * t1 * dot(gr1 , float3 (x1 , y1 , z1));
      }
     float t2 = 0.5 - x2 * x2 - y2 * y2 - z2 * z2;
     if (t2 >= 0.0)
      {
          t2 *= t2;
          n2 = t2 * t2 * dot(gr2 , float3 (x2 , y2 , z2));
      }
     float t3 = 0.5 - x3 * x3 - y3 * y3 - z3 * z3;
     if (t3 >= 0.0)
      {
          t3 *= t3;
          n3 = t3 * t3 * dot(gr3 , float3 (x3 , y3 , z3));
      }
     return 96.0 * (n0 + n1 + n2 + n3);

 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 uv = fragCoord.xy / _ScreenParams.xy;

     float pX = simplex3D(float3(_Time.y / 10., float2(uv / 10.))) * 0.6;
     float pY = simplex3D(float3(1. + _Time.y / 10., float2(uv / 10.))) * 0.6;

    // buffer 
   float3 col = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv).rgb;

   // random read the neighbor 
   float d = (simplex3D(float3(1.5 + _Time.y, float2(uv * 20.))) * 0.5) / 20.;
  float3 colT = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv + float2 (0. , -d)).rgb;
  float3 colB = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv + float2 (0. , +d)).rgb;
  float3 colL = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv + float2 (-d , 0.)).rgb;
  float3 colR = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv + float2 (+d , 0.)).rgb;

  // automata? 
 if (all(colT == colB)) col = float3 (0. , 0. , 0.);
 else if (all(colL == colR)) col = float3 (0. , 0. , 0.);
 else if (!all(colT == colL)) col = float3 (1. , 1. , 1.);
 else if (!all(colB == colR)) col = float3 (1. , 1. , 1.);

 float2 m = float2 (pX , pY) - uv + 0.5;
 if (iMouse.z > 0.) m = iMouse.xy / _ScreenParams.xy - uv;
 col += float3 ((circle(m , 0.001)) , (circle(m , 0.001)) , (circle(m , 0.001)));

  fragColor = float4 ((col).x , (col).y , (col).z , 1.0);
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