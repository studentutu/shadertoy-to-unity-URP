Shader "UmutBebek/URP/ShaderToy/furball XsfGWN"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        uvScale("uvScale", float) = 1.0
colorUvScale("colorUvScale", float) = 0.1
furDepth("furDepth", float) = 0.2
furLayers("furLayers", int) = 64
rayStep("rayStep", float) = 0.
furThreshold("furThreshold", float) = 0.4
shininess1("shininess1", float) = 50.0

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
            float uvScale;
float colorUvScale;
float furDepth;
int furLayers;
float rayStep;
float furThreshold;
float shininess1;


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

                   // fur ball 
// ( c ) simon greenExtended 2013 
// @simesgreen 
// v1.1 









bool intersectSphere(float3 ro , float3 rd , float r , out float t)
 {
     float b = dot(-ro , rd);
     float det = b * b - dot(ro , ro) + r * r;
     if (det < 0.0) return false;
     det = sqrt(det);
     t = b - det;
     return t > 0.0;
 }

float3 rotateX(float3 p , float a)
 {
    float sa = sin(a);
    float ca = cos(a);
    return float3 (p.x , ca * p.y - sa * p.z , sa * p.y + ca * p.z);
 }

float3 rotateY(float3 p , float a)
 {
    float sa = sin(a);
    float ca = cos(a);
    return float3 (ca * p.x + sa * p.z , p.y , -sa * p.x + ca * p.z);
 }

float2 cartesianToSpherical(float3 p)
 {
     float r = length(p);

     float t = (r - (1.0 - furDepth)) / furDepth;
     p = rotateX(p.zyx , -cos(_Time.y * 1.5) * t * t * 0.4).zyx; // curl 

     p /= r;
     float2 uv = float2 (atan2(p.y , p.x) , acos(p.z));

     // uv.x += cos ( _Time.y * 1.5 ) * t * t * 0.4 ; // curl 
     // uv.y += sin ( _Time.y * 1.7 ) * t * t * 0.2 ; 
    uv.y -= t * t * 0.1; // curl down 
    return uv;
}

// returns fur density at given position 
float furDensity(float3 pos , out float2 uv)
 {
     uv = cartesianToSpherical(pos.xzy);
     float4 tex = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , uv * uvScale , 0.0);

     // thin out hair 
    float density = smoothstep(furThreshold , 1.0 , tex.x);

    float r = length(pos);
    float t = (r - (1.0 - furDepth)) / furDepth;

    // fade out along length 
   float len = tex.y;
   density *= smoothstep(len , len - 0.2 , t);

   return density;
}

// calculate normal from density 
float3 furNormal(float3 pos , float density)
 {
    float eps = 0.01;
    float3 n;
     float2 uv;
    n.x = furDensity(float3 (pos.x + eps , pos.y , pos.z) , uv) - density;
    n.y = furDensity(float3 (pos.x , pos.y + eps , pos.z) , uv) - density;
    n.z = furDensity(float3 (pos.x , pos.y , pos.z + eps) , uv) - density;
    return normalize(n);
 }

float3 furShade(float3 pos , float2 uv , float3 ro , float density)
 {
    // lighting 
   const float3 L = float3 (0 , 1 , 0);
   float3 V = normalize(ro - pos);
   float3 H = normalize(V + L);

   float3 N = -furNormal(pos , density);
   // float diff = max ( 0.0 , dot ( N , L ) ) ; 
  float diff = max(0.0 , dot(N , L) * 0.5 + 0.5);
  float spec = pow(max(0.0 , dot(N , H)) , shininess1);

  // base color 
 float3 color = SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , uv * colorUvScale , 0.0).xyz;

 // darken with depth 
float r = length(pos);
float t = (r - (1.0 - furDepth)) / furDepth;
t = clamp(t , 0.0 , 1.0);
float i = t * 0.5 + 0.5;

return color * diff * i + float3 (spec * i, spec * i, spec * i);
}

float4 scene(float3 ro , float3 rd)
 {
     float3 p = float3 (0.0 , 0.0 , 0.0);
     const float r = 1.0;
     float t;
     bool hit = intersectSphere(ro - p , rd , r , t);

     float4 c = float4 (0.0 , 0.0 , 0.0 , 0.0);
     if (hit) {
          float3 pos = ro + rd * t;

          // ray - march into volume 
         for (int i = 0; i < furLayers; i++) {
              float4 sampleCol;
              float2 uv;
              sampleCol.a = furDensity(pos , uv);
              if (sampleCol.a > 0.0) {
                   sampleCol.rgb = furShade(pos , uv , ro , sampleCol.a);

                   // pre - multiply alpha 
                  sampleCol.rgb *= sampleCol.a;
                  c = c + sampleCol * (1.0 - c.a);
                  if (c.a > 0.95) break;
              }

             pos += rd * rayStep;
         }
    }

   return c;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
rayStep = furDepth * 2.0 / (furLayers);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.xy;
      uv = uv * 2.0 - 1.0;
      uv.x *= _ScreenParams.x / _ScreenParams.y;

      float3 ro = float3 (0.0 , 0.0 , 2.5);
      float3 rd = normalize(float3 (uv , -2.0));

      float2 mouse = iMouse.xy / _ScreenParams.xy;
      float roty = 0.0;
      float rotx = 0.0;
      if (iMouse.z > 0.0) {
           rotx = (mouse.y - 0.5) * 3.0;
           roty = -(mouse.x - 0.5) * 6.0;
       }
 else {
  roty = sin(_Time.y * 1.5);
}

ro = rotateX(ro , rotx);
ro = rotateY(ro , roty);
rd = rotateX(rd , rotx);
rd = rotateY(rd , roty);

 fragColor = scene(ro , rd);
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