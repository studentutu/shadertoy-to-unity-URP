Shader "UmutBebek/URP/ShaderToy/VolumetricIntegration XlBSRz"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)
            /*_Iteration("Iteration", float) = 1
            _NeighbourPixels("Neighbour Pixels", float) = 1
            _Lod("Lod",float) = 0
            _AR("AR Mode",float) = 0*/
            D_FOG_NOISE("D_FOG_NOISE", float) = 1.0
D_STRONG_FOG("D_STRONG_FOG", float) = 0.0
D_VOLUME_SHADOW_ENABLE("D_VOLUME_SHADOW_ENABLE", float) = 1
D_USE_IMPROVE_INTEGRATION("D_USE_IMPROVE_INTEGRATION", float) = 1
D_UPDATE_TRANS_FIRST("D_UPDATE_TRANS_FIRST", float) = 0
D_DETAILED_WALLS("D_DETAILED_WALLS", float) = 0
D_MAX_STEP_LENGTH_ENABLE("D_MAX_STEP_LENGTH_ENABLE", float) = 1

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
            float D_FOG_NOISE;
float D_STRONG_FOG;
float D_VOLUME_SHADOW_ENABLE;
float D_USE_IMPROVE_INTEGRATION;
float D_UPDATE_TRANS_FIRST;
float D_DETAILED_WALLS;
float D_MAX_STEP_LENGTH_ENABLE;

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

float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
{
    //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
    float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
    return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
}

/* Hi there!
* Here is a demo presenting volumetric rendering single with shadowing.
* Did it quickly so I hope I have not made any big mistakes : )
*
* I also added the improved scattering integration I propose in my SIGGRAPH'15 presentation
* about Frostbite new volumetric system I have developed. See slide 28 at http: // www.frostbite.com / 2015 / 08 / physically - based - unified - volumetric - rendering - in - frostbite /
* Basically it improves the scattering integration for each step with respect to extinction
* The difference is mainly visible for some participating media having a very strong scattering value.
* I have setup some pre - defined settings for you to checkout below ( to present the case it improves ) :
* - D_DEMO_SHOW_IMPROVEMENT_xxx: shows improvement ( on the right side of the screen ) . You can still see aliasing due to volumetric shadow and the low amount of sample we take for it.
* - D_DEMO_SHOW_IMPROVEMENT_xxx_NOVOLUMETRICSHADOW: same as above but without volumetric shadow
*
* To increase the volumetric rendering accuracy , I constrain the ray marching steps to a maximum distance.
*
* Volumetric shadows are evaluated by raymarching toward the light to evaluate transmittance for each view ray steps ( ouch! )
*
* Do not hesitate to contact me to discuss about all that : )
* SebH
*/



/*
 * This are predefined settings you can quickly use
 * - D_DEMO_FREE play with parameters as you would like
 * - D_DEMO_SHOW_IMPROVEMENT_FLAT show improved integration on flat surface
 * - D_DEMO_SHOW_IMPROVEMENT_NOISE show improved integration on noisy surface
 * - the two previous without volumetric shadows
 */
#define D_DEMO_FREE 
 // #define D_DEMO_SHOW_IMPROVEMENT_FLAT 
 // #define D_DEMO_SHOW_IMPROVEMENT_NOISE 
 // #define D_DEMO_SHOW_IMPROVEMENT_FLAT_NOVOLUMETRICSHADOW 
 // #define D_DEMO_SHOW_IMPROVEMENT_NOISE_NOVOLUMETRICSHADOW 





#ifdef D_DEMO_FREE 
#endif
      // Apply noise on top of the height fog? 


      // Height fog multiplier to show off improvement with new integration formula 


     // Enable / disable volumetric shadow ( single scattering shadow ) 


      // Use imporved scattering? 
      // In this mode it is full screen and can be toggle on / off. 



 /*
  * Other options you can tweak
  */

  // Used to control wether transmittance is updated before or after scattering ( when not using improved integration ) 
  // If 0 strongly scattering participating media will not be energy conservative 
  // If 1 participating media will look too dark especially for strong extinction ( as compared to what it should be ) 
  // Toggle only visible zhen not using the improved scattering integration. 


  // Apply bump mapping on walls 


  // Use to restrict ray marching length. Needed for volumetric evaluation. 


  // Light position and color 
 #define LPOS float3 ( 20.0 + 15.0 * sin ( _Time.y ) , 15.0 + 12.0 * cos ( _Time.y ) , - 20.0 ) 
 #define LCOL ( 600.0 * float3 ( 1.0 , 0.9 , 0.5 ) ) 


 float displacementSimple(float2 p)
  {
     float f;
     f = 0.5000 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p , 0.0).x; p = p * 2.0;
     f += 0.2500 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p , 0.0).x; p = p * 2.0;
     f += 0.1250 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p , 0.0).x; p = p * 2.0;
     f += 0.0625 * SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , p , 0.0).x; p = p * 2.0;

     return f;
  }


 float3 getSceneColor(float3 p , float material)
  {
      if (material == 1.0)
       {
           return float3 (1.0 , 0.5 , 0.5);
       }
      else if (material == 2.0)
       {
           return float3 (0.5 , 1.0 , 0.5);
       }
      else if (material == 3.0)
       {
           return float3 (0.5 , 0.5 , 1.0);
       }

      return float3 (0.0 , 0.0 , 0.0);
  }


 float getClosestDistance(float3 p , out float material)
  {
      float d = 0.0;
 #if D_MAX_STEP_LENGTH_ENABLE 
     float minD = 1.0; // restrict max step for better scattering evaluation 
 #else 
      float minD = 10000000.0;
 #endif 
      material = 0.0;

     float yNoise = 0.0;
     float xNoise = 0.0;
     float zNoise = 0.0;
 #if D_DETAILED_WALLS 
     yNoise = 1.0 * clamp(displacementSimple(p.xz * 0.005) , 0.0 , 1.0);
     xNoise = 2.0 * clamp(displacementSimple(p.zy * 0.005) , 0.0 , 1.0);
     zNoise = 0.5 * clamp(displacementSimple(p.xy * 0.01) , 0.0 , 1.0);
 #endif 

      d = max(0.0 , p.y - yNoise);
      if (d < minD)
       {
           minD = d;
           material = 2.0;
       }

      d = max(0.0 , p.x - xNoise);
      if (d < minD)
       {
           minD = d;
           material = 1.0;
       }

      d = max(0.0 , 40.0 - p.x - xNoise);
      if (d < minD)
       {
           minD = d;
           material = 1.0;
       }

      d = max(0.0 , -p.z - zNoise);
      if (d < minD)
       {
           minD = d;
           material = 3.0;
      }

      return minD;
  }


 float3 calcNormal(in float3 pos)
  {
     float material = 0.0;
     float3 eps = float3 (0.3 , 0.0 , 0.0);
      return normalize(float3 (
            getClosestDistance(pos + eps.xyy , material) - getClosestDistance(pos - eps.xyy , material) ,
            getClosestDistance(pos + eps.yxy , material) - getClosestDistance(pos - eps.yxy , material) ,
            getClosestDistance(pos + eps.yyx , material) - getClosestDistance(pos - eps.yyx , material)));

  }

 float3 evaluateLight(in float3 pos)
  {
     float3 lightPos = LPOS;
     float3 lightCol = LCOL;
     float3 L = lightPos - pos;
     return lightCol * 1.0 / dot(L , L);
  }

 float3 evaluateLight(in float3 pos , in float3 normal)
  {
     float3 lightPos = LPOS;
     float3 L = lightPos - pos;
     float distanceToL = length(L);
     float3 Lnorm = L / distanceToL;
     return max(0.0 , dot(normal , Lnorm)) * evaluateLight(pos);
  }

 // To simplify: wavelength independent scattering and extinction 
void getParticipatingMedia(out float sigmaS , out float sigmaE , in float3 pos)
 {
    float heightFog = 7.0 + D_FOG_NOISE * 3.0 * clamp(displacementSimple(pos.xz * 0.005 + _Time.y * 0.01) , 0.0 , 1.0);
    heightFog = 0.3 * clamp((heightFog - pos.y) * 1.0 , 0.0 , 1.0);

    const float fogFactor = 1.0 + D_STRONG_FOG * 5.0;

    const float sphereRadius = 5.0;
    float sphereFog = clamp((sphereRadius - length(pos - float3 (20.0 , 19.0 , -17.0))) / sphereRadius , 0.0 , 1.0);

    const float constantFog = 0.02;

    sigmaS = constantFog + heightFog * fogFactor + sphereFog;

    const float sigmaA = 0.0;
    sigmaE = max(0.000000001 , sigmaA + sigmaS); // to avoid division by zeroExtended extinction 
 }

float phaseFunction()
 {
    return 1.0 / (4.0 * 3.14);
 }

float volumetricShadow(in float3 from , in float3 to)
 {
#if D_VOLUME_SHADOW_ENABLE 
    const float numStep = 16.0; // quality control. Bump to avoid shadow alisaing 
    float shadow = 1.0;
    float sigmaS = 0.0;
    float sigmaE = 0.0;
    float dd = length(to - from) / numStep;
    for (float s = 0.5; s < (numStep - 0.1); s += 1.0) // start at 0.5 to sample at center of integral part 
     {
        float3 pos = from + (to - from) * (s / (numStep));
        getParticipatingMedia(sigmaS , sigmaE , pos);
        shadow *= exp(-sigmaE * dd);
     }
    return shadow;
#else 
    return 1.0;
#endif 
 }

void traceScene(bool improvedScattering , float3 rO , float3 rD , inout float3 finalPos , inout float3 normal , inout float3 albedo , inout float4 scatTrans)
 {
     const int numIter = 100;

    float sigmaS = 0.0;
    float sigmaE = 0.0;

    float3 lightPos = LPOS;

    // Initialise volumetric scattering integration ( to view ) 
   float transmittance = 1.0;
   float3 scatteredLight = float3 (0.0 , 0.0 , 0.0);

    float d = 1.0; // hack: always have a first step of 1 unit to go further 
    float material = 0.0;
    float3 p = float3 (0.0 , 0.0 , 0.0);
   float dd = 0.0;
    for (int i = 0; i < numIter; ++i)
     {
         float3 p = rO + d * rD;


        getParticipatingMedia(sigmaS , sigmaE , p);

#ifdef D_DEMO_FREE 
        if (D_USE_IMPROVE_INTEGRATION > 0) // freedom / tweakable version 
#else 
        if (improvedScattering)
#endif 
         {
            // See slide 28 at http: // www.frostbite.com / 2015 / 08 / physically - based - unified - volumetric - rendering - in - frostbite / 
           float3 S = evaluateLight(p) * sigmaS * phaseFunction() * volumetricShadow(p , lightPos); // incoming light 
           float3 Sint = (S - S * exp(-sigmaE * dd)) / sigmaE; // integrate along the current step segment 
           scatteredLight += transmittance * Sint; // accumulate and also take into account the transmittance from previous steps 

            // Evaluate transmittance to view independentely 
           transmittance *= exp(-sigmaE * dd);
        }
         else
        {
            // Basic scatering / transmittance integration 
       #if D_UPDATE_TRANS_FIRST 
           transmittance *= exp(-sigmaE * dd);
       #endif 
           scatteredLight += sigmaS * evaluateLight(p) * phaseFunction() * volumetricShadow(p , lightPos) * transmittance * dd;
       #if !D_UPDATE_TRANS_FIRST 
           transmittance *= exp(-sigmaE * dd);
       #endif 
        }


       dd = getClosestDistance(p , material);
       if (dd < 0.2)
           break; // give back a lot of performance without too much visual loss 
         d += dd;
     }

    albedo = getSceneColor(p , material);

   finalPos = rO + d * rD;

   normal = calcNormal(finalPos);

   scatTrans = float4 (scatteredLight , transmittance);
}


half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// _Time.y 
// iMouse 
// _ScreenParams 

float2 uv = fragCoord.xy / _ScreenParams.xy;

float hfactor = float(_ScreenParams.y) / float(_ScreenParams.x); // make it screen ratio independent 
 float2 uv2 = float2 (2.0 , 2.0 * hfactor) * fragCoord.xy / _ScreenParams.xy - float2 (1.0 , hfactor);

 float3 camPos = float3 (20.0 , 18.0 , -50.0);
 if (iMouse.x + iMouse.y > 0.0) // to handle first loading and see somthing on screen 
    camPos += float3 (0.05 , 0.12 , 0.0) * (float3 (iMouse.x , iMouse.y , 0.0) - float3 (_ScreenParams.xy * 0.5 , 0.0));
 float3 camX = float3 (1.0 , 0.0 , 0.0);
 float3 camY = float3 (0.0 , 1.0 , 0.0);
 float3 camZ = float3 (0.0 , 0.0 , 1.0);

 float3 rO = camPos;
 float3 rD = normalize(uv2.x * camX + uv2.y * camY + camZ);
 float3 finalPos = rO;
 float3 albedo = float3 (0.0 , 0.0 , 0.0);
 float3 normal = float3 (0.0 , 0.0 , 0.0);
float4 scatTrans = float4 (0.0 , 0.0 , 0.0 , 0.0);
traceScene(fragCoord.x > (_ScreenParams.x / 2.0) ,
    rO , rD , finalPos , normal , albedo , scatTrans);


// lighting 
float3 color = (albedo / 3.14) * evaluateLight(finalPos , normal) * volumetricShadow(finalPos , LPOS);
// Apply scattering / transmittance 
color = color * scatTrans.w + scatTrans.xyz;

// Gamma correction 
color = pow(color , float3 (1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2)); // simple linear to gamma , exposure of 1.0 

#ifndef D_DEMO_FREE 
     // Separation line 
    if (abs(fragCoord.x - (_ScreenParams.x * 0.5)) < 0.6)
        color.r = 0.5;
#endif 

     fragColor = float4 (color , 1.0);
     fragColor.xyz -= 0.2;
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