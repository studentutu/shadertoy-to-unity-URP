Shader "UmutBebek/URP/ShaderToy/Physically Based Shading 4sSfzK BufferA"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        MENU_SURFACE("MENU_SURFACE", float) = 0.
MENU_METAL("MENU_METAL", float) = 1.
MENU_DIELECTRIC("MENU_DIELECTRIC", float) = 2.
MENU_ROUGHNESS("MENU_ROUGHNESS", float) = 3.
MENU_BASE_COLOR("MENU_BASE_COLOR", float) = 4.
MENU_LIGHTING("MENU_LIGHTING", float) = 5.
MENU_DIFFUSE("MENU_DIFFUSE", float) = 6.
MENU_SPECULAR("MENU_SPECULAR", float) = 7.
MENU_DISTR("MENU_DISTR", float) = 8.
MENU_FRESNEL("MENU_FRESNEL", float) = 9.
MENU_GEOMETRY("MENU_GEOMETRY", float) = 10.
FOCUS_SLIDER("FOCUS_SLIDER", float) = 1.
FOCUS_OBJ("FOCUS_OBJ", float) = 2.
FOCUS_COLOR("FOCUS_COLOR", float) = 3.

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
            float MENU_SURFACE;
float MENU_METAL;
float MENU_DIELECTRIC;
float MENU_ROUGHNESS;
float MENU_BASE_COLOR;
float MENU_LIGHTING;
float MENU_DIFFUSE;
float MENU_SPECULAR;
float MENU_DISTR;
float MENU_FRESNEL;
float MENU_GEOMETRY;
float FOCUS_SLIDER;
float FOCUS_OBJ;
float FOCUS_COLOR;


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

                   // control loop 

















struct AppState
 {
    float menuId;
    float metal;
    float roughness;
    float baseColor;
    float focus;
    float focusObjRot;
    float objRot;
 };

float4 LoadValue(int x , int y)
 {
    return pointSampleTex2D(_Channel0 , sampler_Channel0 , int2 (x , y));
 }

void LoadState(out AppState s)
 {
    float4 data;

    data = LoadValue(0 , 0);
    s.menuId = data.x;
    s.metal = data.y;
    s.roughness = data.z;
    s.baseColor = data.w;

    data = LoadValue(1 , 0);
    s.focus = data.x;
    s.focusObjRot = data.y;
    s.objRot = data.z;
 }

void StoreValue(float2 re , float4 va , inout float4 fragColor , float2 fragCoord)
 {
    fragCoord = floor(fragCoord);
    fragColor = (fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor;
 }

float4 SaveState(in AppState s , in float2 fragCoord)
 {
    float4 ret = float4 (0. , 0. , 0. , 0.);
    StoreValue(float2 (0. , 0.) , float4 (s.menuId , s.metal , s.roughness , s.baseColor) , ret , fragCoord);
    StoreValue(float2 (1. , 0.) , float4 (s.focus , s.focusObjRot , s.objRot , 0.) , ret , fragCoord);
    ret = iFrame >= 1 ? ret : float4 (0. , 0. , 0. , 0.);
    return ret;
 }

float saturate(float x)
 {
    return clamp(x , 0. , 1.);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     if (fragCoord.x >= 8. || fragCoord.y >= 8.)
      {
         discard;
      }

     AppState s;
     LoadState(s);

     float4 q = iMouse / _ScreenParams.xyxy;
     float4 m = -1. + 2. * q;
     m.xz *= _ScreenParams.x / _ScreenParams.y;
     m *= 100.;

     float4 sliderM = m - float2 (-110 , 74).xyxy;
     if (sliderM.z >= -4. && sliderM.z < 44. && sliderM.w >= -20. && sliderM.w < -10.)
      {
         s.focus = FOCUS_SLIDER;
      }
     else if (sliderM.z >= -4. && sliderM.z < 44. && sliderM.w >= -30. && sliderM.w < -20.)
      {
         s.focus = FOCUS_COLOR;
      }
     else if (sliderM.z >= -4. && sliderM.z < 6. && sliderM.w >= -10. && sliderM.w < -4.)
      {
         s.metal = 0.;
         s.menuId = s.menuId == MENU_METAL ? MENU_DIELECTRIC : s.menuId;
      }
     else if (sliderM.z >= -4. && sliderM.z < 6. && sliderM.w >= -4. && sliderM.w < 6.)
      {
         s.metal = 1.;
         s.menuId = s.menuId == MENU_DIELECTRIC ? MENU_METAL : s.menuId;
      }
     else if (m.w > -100. && m.w < 40. && abs(m.z + 20.) < 70.)
      {
         if (s.focus != FOCUS_OBJ)
          {
             s.focusObjRot = s.objRot;
          }
         s.focus = FOCUS_OBJ;
      }
     else
      {
         s.focus = 0.;
         float2 mp = (m.xy - float2 (-160 , -1));
         float menuId = mp.x < 40. || (mp.x < 60. && (mp.y > 18. && mp.y < 24.)) ? 10. - floor(mp.y / 8.) : -1.;
         if (menuId >= 0. && menuId <= 10.)
          {
             s.menuId = menuId;
          }
         s.metal = menuId == MENU_METAL ? 1. : s.metal;
         s.metal = menuId == MENU_DIELECTRIC ? 0. : s.metal;
      }

     if (s.focus == FOCUS_SLIDER)
      {
         s.roughness = saturate(sliderM.x / 40.);
      }
     if (s.focus == FOCUS_COLOR)
      {
         s.baseColor = floor(clamp((sliderM.x * 5.) / 32. , 0. , 5.));
      }
     if (s.focus == FOCUS_OBJ)
      {
         s.objRot = s.focusObjRot + .04 * (m.x - m.z);
      }

     fragColor = SaveState(s , fragCoord);
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