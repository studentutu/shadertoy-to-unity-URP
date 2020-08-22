Shader "UmutBebek/URP/ShaderToy/Menger Journey Mdf3z7"
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

            #define MaxSteps 30 
#define MinimumDistance 0.0009 
#define normalDistance 0.0002 

#define Iterations 7 
#define PI 3.141592 
#define Scale 3.0 
#define FieldOfView 1.0 
#define Jitter 0.05 
#define FudgeFactor 0.7 
#define NonLinearPerspective 2.0 
#define DebugNonlinearPerspective false 

#define Ambient 0.32184 
#define Diffuse 0.5 
#define LightDir float3 ( 1.0 , 1.0 , 1.0 ) 
#define LightColor float3 ( 1.0 , 1.0 , 0.858824 ) 
#define LightDir2 float3 ( 1.0 , - 1.0 , 1.0 ) 
#define LightColor2 float3 ( 0.0 , 0.333333 , 1.0 ) 
#define Offset float3 ( 0.92858 , 0.92858 , 0.32858 ) 

float2 rotate(float2 v , float a) {
     return float2 (cos(a) * v.x + sin(a) * v.y , -sin(a) * v.x + cos(a) * v.y);
 }

// Two light sources. No specular 
float3 getLight(in float3 color , in float3 normal , in float3 dir) {
     float3 lightDir = normalize(LightDir);
     float diffuse = max(0.0 , dot(-normal , lightDir)); // Lambertian 

     float3 lightDir2 = normalize(LightDir2);
     float diffuse2 = max(0.0 , dot(-normal , lightDir2)); // Lambertian 

     return
      (diffuse * Diffuse) * (LightColor * color) +
      (diffuse2 * Diffuse) * (LightColor2 * color);
 }


// DE: Infinitely tiled Menger IFS. 
// 
// For more info on KIFS , see: 
// http: // www.fractalforums.com / 3d - fractal - generation / kaleidoscopic - %28escape - time - ifs%29 / 
float DE(in float3 z)
 {
    // enable this to debug the non - linear perspective 
   if (DebugNonlinearPerspective) {
        z = frac(z);
        float d = length(z.xy - float2 (0.5 , 0.5));
        d = min(d , length(z.xz - float2 (0.5 , 0.5)));
        d = min(d , length(z.yz - float2 (0.5 , 0.5)));
        return d - 0.01;
    }
   // Folding 'tiling' of 3D space ; 
  z = abs(1.0 - mod(z , 2.0));

  float d = 1000.0;
  for (int n = 0; n < Iterations; n++) {
       z.xy = rotate(z.xy , 4.0 + 2.0 * cos(_Time.y / 8.0));
       z = abs(z);
       if (z.x < z.y) { z.xy = z.yx; }
       if (z.x < z.z) { z.xz = z.zx; }
       if (z.y < z.z) { z.yz = z.zy; }
       z = Scale * z - Offset * (Scale - 1.0);
       if (z.z < -0.5 * Offset.z * (Scale - 1.0)) z.z += Offset.z * (Scale - 1.0);
       d = min(d , length(z) * pow(Scale , float(-n) - 1.0));
   }

  return d - 0.001;
}

// Finite difference normal 
float3 getNormal(in float3 pos) {
     float3 e = float3 (0.0 , normalDistance , 0.0);

     return normalize(float3 (
               DE(pos + e.yxx) - DE(pos - e.yxx) ,
               DE(pos + e.xyx) - DE(pos - e.xyx) ,
               DE(pos + e.xxy) - DE(pos - e.xxy)
                )
           );
 }

// Solid color 
float3 getColor(float3 normal , float3 pos) {
     return float3 (1.0 , 1.0 , 1.0);
 }


// Pseudo - random number 
// From: lumina.sourceforge.net / Tutorials / Noise.html 
float rand(float2 co) {
     return frac(cos(dot(co , float2 (4.898 , 7.23))) * 23421.631);
 }

float4 rayMarch(in float3 from , in float3 dir , in float2 fragCoord) {
    // Add some noise to prevent banding 
   float totalDistance = Jitter * rand(fragCoord.xy + float2 (_Time.y, _Time.y));
   float3 dir2 = dir;
   float distance;
   int steps = 0;
   float3 pos;
   for (int i = 0; i < MaxSteps; i++) {
       // Non - linear perspective applied here. 
      dir.zy = rotate(dir2.zy , totalDistance * cos(_Time.y / 4.0) * NonLinearPerspective);

      pos = from + totalDistance * dir;
      distance = DE(pos) * FudgeFactor;
      totalDistance += distance;
      if (distance < MinimumDistance) break;
      steps = i;
  }

   // 'AO' is based on number of steps. 
   // Try to smooth the count , to combat banding. 
  float smoothStep = float(steps) + distance / MinimumDistance;
  float ao = 1.1 - smoothStep / float(MaxSteps);

  // Since our distance field is not signed , 
  // backstep when calc'ing normal 
 float3 normal = getNormal(pos - dir * normalDistance * 3.0);

 float3 color = getColor(normal , pos);
 float3 light = getLight(color , normal , dir);
 color = (color * Ambient + light) * ao;
 return float4 (color , 1.0);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // Camera position ( eye ) , and camera target 
float3 camPos = 0.5 * _Time.y * float3 (1.0 , 0.0 , 0.0);
float3 target = camPos + float3 (1.0 , 0.0 * cos(_Time.y) , 0.0 * sin(0.4 * _Time.y));
float3 camUp = float3 (0.0 , 1.0 , 0.0);

// Calculate orthonormal camera reference system 
float3 camDir = normalize(target - camPos); // direction for center ray 
camUp = normalize(camUp - dot(camDir , camUp) * camDir); // orthogonalize 
float3 camRight = normalize(cross(camDir , camUp));

float2 coord = -1.0 + 2.0 * fragCoord.xy / _ScreenParams.xy;
coord.x *= _ScreenParams.x / _ScreenParams.y;

// Get direction for this pixel 
float3 rayDir = normalize(camDir + (coord.x * camRight + coord.y * camUp) * FieldOfView);

fragColor = rayMarch(camPos , rayDir , fragCoord);
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