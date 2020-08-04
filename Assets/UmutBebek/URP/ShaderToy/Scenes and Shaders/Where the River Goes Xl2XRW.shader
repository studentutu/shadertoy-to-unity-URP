Shader "UmutBebek/URP/ShaderToy/Where the River Goes Xl2XRW"
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

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Where the River Goes 
// @P_Malin 

// What started as a hacked flow and advection experiment turned into something nice. 

// Placeholder audio https: // www.youtube.com / watch?v = gmar4gh5nIw suggested by @qthund on twitter 

#define ENABLE_ULTRA_QUALITY 

#define ENABLE_WATER 
#define ENABLE_FOAM 
#define ENABLE_WATER_RECEIVE_SHADOW 
#define ENABLE_CONE_STEPPING 


 // Textureless version 
 // #define ENABLE_NIMITZ_TRIANGLE_NOISE 

 // #define ENABLE_LANDSCAPE_RECEIVE_SHADOW 

 // #define ENABLE_SCREENSHOT_MODE 
static const float k_screenshotTime = 13.0;

#if defined ( ENABLE_SCREENSHOT_MODE ) || defined ( ENABLE_ULTRA_QUALITY ) 
#define ENABLE_SUPERSAMPLE_MODE 
#endif 

#ifndef ENABLE_SCREENSHOT_MODE 
#ifdef ENABLE_ULTRA_QUALITY 
static const int k_raymarchSteps = 96;
static const int k_fmbSteps = 6;
static const int k_superSampleCount = 6;
#else 
static const int k_raymarchSteps = 64;
static const int k_fmbSteps = 3;
#endif 
#else 
static const int k_raymarchSteps = 96;
static const int k_fmbSteps = 5;
static const int k_superSampleCount = 10;
#endif 

static const int k_fmbWaterSteps = 4;

#define OBJ_ID_SKY 0.0 
#define OBJ_ID_GROUND 1.0 

float g_fTime;

static const float3 g_vSunDir = float3 (-1.0 , 0.7 , 0.25);
float3 GetSunDir() { return normalize(g_vSunDir); }

static const float3 g_sunColour = float3 (1.0 , 0.85 , 0.5) * 5.0;
static const float3 g_skyColour = float3 (0.1 , 0.5 , 1.0) * 1.0;

static const float3 k_bgSkyColourUp = g_skyColour * 4.0;
static const float3 k_bgSkyColourDown = g_skyColour * 6.0;

static const float3 k_envFloorColor = float3 (0.3 , 0.2 , 0.2);

static const float3 k_vFogExt = float3 (0.01 , 0.015 , 0.015) * 3.0;
static const float3 k_vFogIn = float3 (1.0 , 0.9 , 0.8) * 0.015;


static const float k_fFarClip = 20.0;

#define MOD2 float2 ( 4.438975 , 3.972973 ) 

float Hash(float p)
 {
    // https: // www.shadertoy.com / view / 4djSRW - Dave Hoskins 
    float2 p2 = frac(float2 (p, p)*MOD2);
   p2 += dot(p2.yx , p2.xy + 19.19);
    return frac(p2.x * p2.y);
    // return frac ( sin ( n ) * 43758.5453 ) ; 
}

float2 Hash2(float p)
 {
    // https: // www.shadertoy.com / view / 4djSRW - Dave Hoskins 
    float3 p3 = frac(float3 (p, p, p) * float3 (.1031 , .1030 , .0973));
    p3 += dot(p3 , p3.yzx + 19.19);
   return frac((p3.xx + p3.yz) * p3.zy);
}

float SmoothNoise(in float2 o)
 {
     float2 p = floor(o);
     float2 f = frac(o);

     float n = p.x + p.y * 57.0;

     float a = Hash(n + 0.0);
     float b = Hash(n + 1.0);
     float c = Hash(n + 57.0);
     float d = Hash(n + 58.0);

     float2 f2 = f * f;
     float2 f3 = f2 * f;

     float2 t = 3.0 * f2 - 2.0 * f3;

     float u = t.x;
     float v = t.y;

     float res = a + (b - a) * u + (c - a) * v + (a - b + d - c) * u * v;

    return res;
 }

float FBM(float2 p , float ps) {
     float f = 0.0;
    float tot = 0.0;
    float a = 1.0;
    for (int i = 0; i < k_fmbSteps; i++)
     {
        f += SmoothNoise(p) * a;
        p *= 2.0;
        tot += a;
        a *= ps;
     }
    return f / tot;
 }

float FBM_Simple(float2 p , float ps) {
     float f = 0.0;
    float tot = 0.0;
    float a = 1.0;
    for (int i = 0; i < 3; i++)
     {
        f += SmoothNoise(p) * a;
        p *= 2.0;
        tot += a;
        a *= ps;
     }
    return f / tot;
 }

float3 SmoothNoise_DXY(in float2 o)
 {
     float2 p = floor(o);
     float2 f = frac(o);

     float n = p.x + p.y * 57.0;

     float a = Hash(n + 0.0);
     float b = Hash(n + 1.0);
     float c = Hash(n + 57.0);
     float d = Hash(n + 58.0);

     float2 f2 = f * f;
     float2 f3 = f2 * f;

     float2 t = 3.0 * f2 - 2.0 * f3;
     float2 dt = 6.0 * f - 6.0 * f2;

     float u = t.x;
     float v = t.y;
     float du = dt.x;
     float dv = dt.y;

     float res = a + (b - a) * u + (c - a) * v + (a - b + d - c) * u * v;

     float dx = (b - a) * du + (a - b + d - c) * du * v;
     float dy = (c - a) * dv + (a - b + d - c) * u * dv;

    return float3 (dx , dy , res);
 }

float3 FBM_DXY(float2 p , float2 flow , float ps , float df) {
     float3 f = float3 (0.0 , 0.0 , 0.0);
    float tot = 0.0;
    float a = 1.0;
    // flow *= 0.6 ; 
   for (int i = 0; i < k_fmbWaterSteps; i++)
    {
       p += flow;
       flow *= -0.75; // modify flow for each octave - negating this is fun 
       float3 v = SmoothNoise_DXY(p);
       f += v * a;
       p += v.xy * df;
       p *= 2.0;
       tot += a;
       a *= ps;
    }
   return f / tot;
}

float GetRiverMeander(const float x)
 {
    return sin(x * 0.3) * 1.5;
 }

float GetRiverMeanderDx(const float x)
 {
    return cos(x * 0.3) * 1.5 * 0.3;
 }

float GetRiverBedOffset(const float3 vPos)
 {
    float fRiverBedDepth = 0.3 + (0.5 + 0.5 * sin(vPos.x * 0.001 + 3.0)) * 0.4;
    float fRiverBedWidth = 2.0 + cos(vPos.x * 0.1) * 1.0; ;

    float fRiverBedAmount = smoothstep(fRiverBedWidth , fRiverBedWidth * 0.5 , abs(vPos.z - GetRiverMeander(vPos.x)));

    return fRiverBedAmount * fRiverBedDepth;
 }

float GetTerrainHeight(const float3 vPos)
 {
    float fbm = FBM(vPos.xz * float2 (0.5 , 1.0) , 0.5);
    float fTerrainHeight = fbm * fbm;

    fTerrainHeight -= GetRiverBedOffset(vPos);

    return fTerrainHeight;
 }

float GetTerrainHeightSimple(const float3 vPos)
 {
    float fbm = FBM_Simple(vPos.xz * float2 (0.5 , 1.0) , 0.5);
    float fTerrainHeight = fbm * fbm;

    fTerrainHeight -= GetRiverBedOffset(vPos);

    return fTerrainHeight;
 }


float GetSceneDistance(const float3 vPos)
 {
    return vPos.y - GetTerrainHeight(vPos);
 }

float GetFlowDistance(const float2 vPos)
 {
    return -GetTerrainHeightSimple(float3 (vPos.x , 0.0 , vPos.y));
 }

float2 GetBaseFlow(const float2 vPos)
 {
    return float2 (1.0 , GetRiverMeanderDx(vPos.x));
 }

float2 GetGradient(const float2 vPos)
 {
    float2 vDelta = float2 (0.01 , 0.00);
    float dx = GetFlowDistance(vPos + vDelta.xy) - GetFlowDistance(vPos - vDelta.xy);
    float dy = GetFlowDistance(vPos + vDelta.yx) - GetFlowDistance(vPos - vDelta.yx);
    return float2 (dx , dy);
 }

float3 GetFlowRate(const float2 vPos)
 {
    float2 vBaseFlow = GetBaseFlow(vPos);

    float2 vFlow = vBaseFlow;

    float fFoam = 0.0;

     float fDepth = -GetTerrainHeightSimple(float3 (vPos.x , 0.0 , vPos.y));
    float fDist = GetFlowDistance(vPos);
    float2 vGradient = GetGradient(vPos);

    vFlow += -vGradient * 40.0 / (1.0 + fDist * 1.5);
    vFlow *= 1.0 / (1.0 + fDist * 0.5);

#if 1 
    float fBehindObstacle = 0.5 - dot(normalize(vGradient) , -normalize(vFlow)) * 0.5;
    float fSlowDist = clamp(fDepth * 5.0 , 0.0 , 1.0);
    fSlowDist = lerp(fSlowDist * 0.9 + 0.1 , 1.0 , fBehindObstacle * 0.9);
    // vFlow += vGradient * 10.0 * ( 1.0 - fSlowDist ) ; 
   fSlowDist = 0.5 + fSlowDist * 0.5;
   vFlow *= fSlowDist;
#endif 

    float fFoamScale1 = 0.5;
    float fFoamCutoff = 0.4;
    float fFoamScale2 = 0.35;

    fFoam = abs(length(vFlow)) * fFoamScale1; // - length ( vBaseFlow ) ) ; 
     fFoam += clamp(fFoam - fFoamCutoff , 0.0 , 1.0);
     // fFoam = fFoam * fFoam ; 
    fFoam = 1.0 - pow(fDist , fFoam * fFoamScale2);
    // fFoam = fFoam / fDist ; 
   return float3 (vFlow * 0.6 , fFoam);
}

float4 SampleWaterNormal(float2 vUV , float2 vFlowOffset , float fMag , float fFoam)
 {
    float2 vFilterWidth = max(abs(ddx(vUV)) , abs(ddy(vUV)));
       float fFilterWidth = max(vFilterWidth.x , vFilterWidth.y);

    float fScale = (1.0 / (1.0 + fFilterWidth * fFilterWidth * 2000.0));
    float fGradientAscent = 0.25 + (fFoam * -1.5);
    float3 dxy = FBM_DXY(vUV * 20.0 , vFlowOffset * 20.0 , 0.75 + fFoam * 0.25 , fGradientAscent);
    fScale *= max(0.25 , 1.0 - fFoam * 5.0); // flatten normal in foam 
    float3 vBlended = lerp(float3 (0.0 , 1.0 , 0.0) , normalize(float3 (dxy.x , fMag , dxy.y)) , fScale);
    return float4 (normalize(vBlended) , dxy.z * fScale);
 }

float SampleWaterFoam(float2 vUV , float2 vFlowOffset , float fFoam)
 {
    float f = FBM_DXY(vUV * 30.0 , vFlowOffset * 50.0 , 0.8 , -0.5).z;
    float fAmount = 0.2;
    f = max(0.0 , (f - fAmount) / fAmount);
    return pow(0.5 , f);
 }


float4 SampleFlowingNormal( const float2 vUV ,  const float2 vFlowRate ,  const float fFoam ,  const float time , 
    out float fOutFoamTex)
 {
    float fMag = 2.5 / (1.0 + dot(vFlowRate , vFlowRate) * 5.0);
    float t0 = frac(time);
    float t1 = frac(time + 0.5);

    float i0 = floor(time);
    float i1 = floor(time + 0.5);

    float o0 = t0 - 0.5;
    float o1 = t1 - 0.5;

    float2 vUV0 = vUV + Hash2(i0);
    float2 vUV1 = vUV + Hash2(i1);

    float4 sample0 = SampleWaterNormal(vUV0 , vFlowRate * o0 , fMag , fFoam);
    float4 sample1 = SampleWaterNormal(vUV1 , vFlowRate * o1 , fMag , fFoam);

    float weight = abs(t0 - 0.5) * 2.0;
    // weight = smoothstep ( 0.0 , 1.0 , weight ) ; 

   float foam0 = SampleWaterFoam(vUV0 , vFlowRate * o0 * 0.25 , fFoam);
   float foam1 = SampleWaterFoam(vUV1 , vFlowRate * o1 * 0.25 , fFoam);

   float4 result = lerp(sample0 , sample1 , weight);
   result.xyz = normalize(result.xyz);

   fOutFoamTex = lerp(foam0 , foam1 , weight);

   return result;
}

float2 GetWindowCoord( const in float2 vUV)
 {
     float2 vWindow = vUV * 2.0 - 1.0;
     vWindow.x *= _ScreenParams.x / _ScreenParams.y;

     return vWindow;
 }

float3 GetCameraRayDir( const in float2 vWindow ,  const in float3 vCameraPos ,  const in float3 vCameraTarget)
 {
     float3 vForward = normalize(vCameraTarget - vCameraPos);
     float3 vRight = normalize(cross(float3 (0.0 , 1.0 , 0.0) , vForward));
     float3 vUp = normalize(cross(vForward , vRight));

     float3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * 2.0);

     return vDir;
 }

float3 ApplyVignetting( const in float2 vUV ,  const in float3 vInput)
 {
     float2 vOffset = (vUV - 0.5) * sqrt(2.0);

     float fDist = dot(vOffset , vOffset);

     static const float kStrength = 0.8;

     float fShade = lerp(1.0 , 1.0 - kStrength , fDist);

     return vInput * fShade;
 }

float3 Tonemap(float3 x)
 {
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return (x * (a * x + b)) / (x * (c * x + d) + e);
 }

struct Intersection
 {
    float m_dist;
    float m_objId;
    float3 m_pos;
 };

void RaymarchScene(float3 vRayOrigin , float3 vRayDir , out Intersection intersection)
 {
    float stepScale = 1.0;
#ifdef ENABLE_CONE_STEPPING 
    float2 vRayProfile = float2 (sqrt(dot(vRayDir.xz , vRayDir.xz)) , vRayDir.y);
    float2 vGradVec = normalize(float2 (1.0 , 2.0)); // represents the biggest gradient in our heightfield 
    float2 vGradPerp = float2 (vGradVec.y , -vGradVec.x);

    float fRdotG = dot(vRayProfile , vGradPerp);
    float fOdotG = dot(float2 (0.0 , 1.0) , vGradPerp);

    stepScale = -fOdotG / fRdotG;

    if (stepScale < 0.0)
     {
        intersection.m_objId = OBJ_ID_SKY;
        intersection.m_dist = k_fFarClip;
        return;
     }
#endif 

    intersection.m_dist = 0.01;
    intersection.m_objId = OBJ_ID_SKY;

    float fSceneDist = 0.0;

    float oldT = 0.01;
    for (int iter = 0; iter < k_raymarchSteps; iter++)
     {
        float3 vPos = vRayOrigin + vRayDir * intersection.m_dist;

        // into sky - early out 
       if (vRayDir.y > 0.0)
        {
           if (vPos.y > 1.0)
            {
               intersection.m_objId = OBJ_ID_SKY;
               intersection.m_dist = k_fFarClip;
               break;
            }
        }


       fSceneDist = GetSceneDistance(vPos);

       oldT = intersection.m_dist;
       intersection.m_dist += fSceneDist * stepScale;

       intersection.m_objId = OBJ_ID_GROUND;
       if (fSceneDist <= 0.01)
        {
           break;
        }

       if (intersection.m_dist > k_fFarClip)
        {
           intersection.m_objId = OBJ_ID_SKY;
           intersection.m_dist = k_fFarClip;
           break;
        }


    }

   intersection.m_pos = vRayOrigin + vRayDir * intersection.m_dist;
}

float3 GetSceneNormal( const in float3 vPos)
 {
    static const float fDelta = 0.001;

    float3 vDir1 = float3 (1.0 , 0.0 , -1.0);
    float3 vDir2 = float3 (-1.0 , 0.0 , 1.0);
    float3 vDir3 = float3 (-1.0 , 0.0 , -1.0);

    float3 vOffset1 = vDir1 * fDelta;
    float3 vOffset2 = vDir2 * fDelta;
    float3 vOffset3 = vDir3 * fDelta;

    float3 vPos1 = vPos + vOffset1;
    float3 vPos2 = vPos + vOffset2;
    float3 vPos3 = vPos + vOffset3;

    float f1 = GetSceneDistance(vPos1);
    float f2 = GetSceneDistance(vPos2);
    float f3 = GetSceneDistance(vPos3);

    vPos1.y -= f1;
    vPos2.y -= f2;
    vPos3.y -= f3;

    float3 vNormal = cross(vPos1 - vPos2 , vPos3 - vPos2);

    return normalize(vNormal);
 }


void TraceWater(float3 vRayOrigin , float3 vRayDir , out Intersection intersection)
 {
      intersection.m_dist = k_fFarClip;

    float t = -vRayOrigin.y / vRayDir.y;
    if (t > 0.0)
     {
        intersection.m_dist = t;
     }

    intersection.m_objId = 0;

    intersection.m_pos = vRayOrigin + vRayDir * intersection.m_dist;
 }

struct Surface
 {
    float3 m_pos;
    float3 m_normal;
    float3 m_albedo;
    float3 m_specR0;
    float m_gloss;
    float m_specScale;
 };

#ifdef ENABLE_NIMITZ_TRIANGLE_NOISE 
// https: // www.shadertoy.com / view / 4ts3z2 

float tri(in float x) { return abs(frac(x) - .5); }
float3 tri3(in float3 p) { return float3 (tri(p.z + tri(p.y)) , tri(p.z + tri(p.x)) , tri(p.y + tri(p.x))); }

float triNoise(in float3 p)
 {
    float z = 1.4;
     float rz = 0.;
    float3 bp = p;
     for (float i = 0.; i <= 4.; i++)
      {
        float3 dg = tri3(bp * 2.);
        p += dg;

        bp *= 1.8;
          z *= 1.5;
          p *= 1.2;

        rz += (tri(p.z + tri(p.x + tri(p.y)))) / z;
        bp += 0.14;
      }
     return rz;
 }
#endif 

void GetSurfaceInfo(Intersection intersection , out Surface surface)
 {
    surface.m_pos = intersection.m_pos;
    surface.m_normal = GetSceneNormal(intersection.m_pos);

#ifdef ENABLE_NIMITZ_TRIANGLE_NOISE 
    float3 vNoisePos = surface.m_pos * float3 (0.4 , 0.3 , 1.0);
     surface.m_normal = normalize(surface.m_normal + triNoise(vNoisePos));
    float fNoise = triNoise(vNoisePos);
    fNoise = pow(fNoise , 0.15);
    surface.m_albedo = lerp(float3 (.7 , .8 , .95) , float3 (.1 , .1 , .05) , fNoise);
#else 
    #if 0 
    surface.m_albedo = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , intersection.m_pos.xz).rgb;
    surface.m_albedo = surface.m_albedo * surface.m_albedo;
    #else 
    float3 vWeights = surface.m_normal * surface.m_normal;
    float3 col = float3 (0.0 , 0.0 , 0.0);
    float3 _sample;
    _sample = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , intersection.m_pos.xz).rgb;
    col += _sample * _sample * vWeights.y;
    _sample = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , intersection.m_pos.xy).rgb;
    col += _sample * _sample * vWeights.z;
    _sample = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , intersection.m_pos.yz).rgb;
    col += _sample * _sample * vWeights.x;
    col /= vWeights.x + vWeights.y + vWeights.z;
    surface.m_albedo = col;
    #endif 
#endif 

    surface.m_specR0 = float3 (0.001 , 0.001 , 0.001);
    surface.m_gloss = 0.0;
    surface.m_specScale = 1.0;
 }

float GIV(float dotNV , float k)
 {
     return 1.0 / ((dotNV + 0.0001) * (1.0 - k) + k);
 }

float GetSunShadow( const float3 vPos)
 {
    float3 vSunDir = GetSunDir();

    Intersection shadowInt;
    float k_fShadowDist = 2.0;
    RaymarchScene(vPos + vSunDir * k_fShadowDist , -vSunDir , shadowInt);

    float fShadowFactor = 1.0;
    if (shadowInt.m_dist < (k_fShadowDist - 0.1))
     {
        fShadowFactor = 0.0;
     }

    return fShadowFactor;
 }

void AddSunLight(Surface surf ,  const float3 vViewDir ,  const float fShadowFactor , inout float3 vDiffuse , inout float3 vSpecular)
 {
    float3 vSunDir = GetSunDir();

     float3 vH = normalize(vViewDir + vSunDir);
     float fNdotL = clamp(dot(GetSunDir() , surf.m_normal) , 0.0 , 1.0);
     float fNdotV = clamp(dot(vViewDir , surf.m_normal) , 0.0 , 1.0);
     float fNdotH = clamp(dot(surf.m_normal , vH) , 0.0 , 1.0);

    float diffuseIntensity = fNdotL;

    vDiffuse += g_sunColour * diffuseIntensity * fShadowFactor;
    // vDiffuse = fShadowFactor * float3 ( 100.0 ) ; 

   float alpha = 1.0 - surf.m_gloss;
   // D 

  float alphaSqr = alpha * alpha;
  float pi = 3.14159;
  float denom = fNdotH * fNdotH * (alphaSqr - 1.0) + 1.0;
  float d = alphaSqr / (pi * denom * denom);

  float k = alpha / 2.0;
  float vis = GIV(fNdotL , k) * GIV(fNdotV , k);

  float fSpecularIntensity = d * vis * fNdotL;
  vSpecular += g_sunColour * fSpecularIntensity * fShadowFactor;
}

void AddSkyLight(Surface surf , inout float3 vDiffuse , inout float3 vSpecular)
 {
    float skyIntensity = max(0.0 , surf.m_normal.y * 0.3 + 0.7);
    vDiffuse += g_skyColour * skyIntensity;
 }

float3 GetFresnel(float3 vView , float3 vNormal , float3 vR0 , float fGloss)
 {
    float NdotV = max(0.0 , dot(vView , vNormal));

    return vR0 + (float3 (1.0 , 1.0 , 1.0) - vR0) * pow(1.0 - NdotV , 5.0) * pow(fGloss , 20.0);
 }

float3 GetWaterExtinction(float dist)
 {
    float fOpticalDepth = dist * 6.0;

    float3 vExtinctCol = 1.0 - float3 (0.5 , 0.4 , 0.1);
    float3 vExtinction = exp2(-fOpticalDepth * vExtinctCol);

    return vExtinction;
 }

float3 GetSkyColour(float3 vRayDir)
 {
     float3 vSkyColour = lerp(k_bgSkyColourDown , k_bgSkyColourUp , clamp(vRayDir.y , 0.0 , 1.0));
    float fSunDotV = dot(GetSunDir() , vRayDir);
    float fDirDot = clamp(fSunDotV * 0.5 + 0.5 , 0.0 , 1.0);
    vSkyColour += g_sunColour * (1.0 - exp2(fDirDot * -0.5)) * 2.0;

    return vSkyColour;
 }

float3 GetEnvColour(float3 vRayDir , float fGloss)
 {
     return lerp(k_envFloorColor , k_bgSkyColourUp , clamp(vRayDir.y * (1.0 - fGloss * 0.5) * 0.5 + 0.5 , 0.0 , 1.0));
 }


float3 GetRayColour( const in float3 vRayOrigin ,  const in float3 vRayDir , out Intersection intersection)
 {
    RaymarchScene(vRayOrigin , vRayDir , intersection);

    if (intersection.m_objId == OBJ_ID_SKY)
     {
        return GetSkyColour(vRayDir);
     }

    Surface surface;
    GetSurfaceInfo(intersection , surface);

    float3 vIgnore = float3 (0.0 , 0.0 , 0.0);
    float3 vResult = float3 (0.0 , 0.0 , 0.0);
    float fSunShadow = 1.0;
    AddSunLight(surface , -vRayDir , fSunShadow , vResult , vIgnore);
    AddSkyLight(surface , vResult , vIgnore);
    return vResult * surface.m_albedo;
 }

float3 GetRayColour( const in float3 vRayOrigin ,  const in float3 vRayDir)
 {
     Intersection intersection;
    return GetRayColour(vRayOrigin , vRayDir , intersection);
 }

float3 GetSceneColour( const in float3 vRayOrigin ,  const in float3 vRayDir)
 {
     Intersection primaryInt;
    RaymarchScene(vRayOrigin , vRayDir , primaryInt);

     float fFogDistance = 0.0;
    float3 vResult = float3 (0.0 , 0.0 , 0.0);

    float fSunDotV = dot(GetSunDir() , vRayDir);

    if (primaryInt.m_objId == OBJ_ID_SKY)
     {
        vResult = GetSkyColour(vRayDir);
        fFogDistance = k_fFarClip;
     }
    else
     {
        Intersection waterInt;
        TraceWater(vRayOrigin , vRayDir , waterInt);

        float3 vReflectRayOrigin;
        float3 vSpecNormal;
        float3 vTransmitLight;

        Surface specSurface;
        float3 vSpecularLight = float3 (0.0 , 0.0 , 0.0);

    #ifdef ENABLE_WATER 
        float3 vFlowRateAndFoam = GetFlowRate(waterInt.m_pos.xz);
        float2 vFlowRate = vFlowRateAndFoam.xy;
        #ifdef ENABLE_FOAM 
        float fFoam = vFlowRateAndFoam.z;
        float fFoamScale = 1.5;
        float fFoamOffset = 0.2;
        fFoam = clamp((fFoam - fFoamOffset) * fFoamScale , 0.0 , 1.0);
        fFoam = fFoam * fFoam * 0.5;
        #else 
        float fFoam = 0.0;
        #endif 

        float fWaterFoamTex = 1.0;
        float4 vWaterNormalAndHeight = SampleFlowingNormal(waterInt.m_pos.xz , vFlowRate , fFoam , g_fTime , fWaterFoamTex);

        if (vRayDir.y < -0.01)
         {
            // lie about the water intersection depth 
           waterInt.m_dist -= (0.04 * (1.0 - vWaterNormalAndHeight.w) / vRayDir.y);
        }

       if (waterInt.m_dist < primaryInt.m_dist)
        {
           fFogDistance = waterInt.m_dist;
           float3 vWaterNormal = vWaterNormalAndHeight.xyz;

           vReflectRayOrigin = waterInt.m_pos;
           vSpecNormal = vWaterNormal;

           float3 vRefractRayOrigin = waterInt.m_pos;
           float3 vRefractRayDir = refract(vRayDir , vWaterNormal , 1.0 / 1.3333);

           Intersection refractInt;
           float3 vRefractLight = GetRayColour(vRefractRayOrigin , vRefractRayDir , refractInt); // note : dont need sky 

           float fEdgeAlpha = clamp((1.0 + vWaterNormalAndHeight.w * 0.25) - refractInt.m_dist * 10.0 , 0.0 , 1.0);
           fFoam *= 1.0 - fEdgeAlpha;

           // add extra extinction for the light travelling to the pointExtended underwater 
          float3 vExtinction = GetWaterExtinction(refractInt.m_dist + abs(refractInt.m_pos.y));

          specSurface.m_pos = waterInt.m_pos;
          specSurface.m_normal = normalize(vWaterNormal + GetSunDir() * fFoam); // would rather have SSS for foam 
          specSurface.m_albedo = float3 (1.0 , 1.0 , 1.0);
          specSurface.m_specR0 = float3 (0.01 , 0.01 , 0.01);

          float2 vFilterWidth = max(abs(ddx(waterInt.m_pos.xz)) , abs(ddy(waterInt.m_pos.xz)));
               float fFilterWidth = max(vFilterWidth.x , vFilterWidth.y);
          float fGlossFactor = exp2(-fFilterWidth * 0.3);
          specSurface.m_gloss = 0.99 * fGlossFactor;
          specSurface.m_specScale = 1.0;

          float3 vSurfaceDiffuse = float3 (0.0 , 0.0 , 0.0);

          float fSunShadow = 1.0;
      #ifdef ENABLE_WATER_RECEIVE_SHADOW 
          fSunShadow = GetSunShadow(waterInt.m_pos);
      #endif 
          AddSunLight(specSurface , -vRayDir , fSunShadow , vSurfaceDiffuse , vSpecularLight);
          AddSkyLight(specSurface , vSurfaceDiffuse , vSpecularLight);

          float3 vInscatter = vSurfaceDiffuse * (1.0 - exp(-refractInt.m_dist * 0.1)) * (1.0 + fSunDotV);
          vTransmitLight = vRefractLight.rgb;
          vTransmitLight += vInscatter;
          vTransmitLight *= vExtinction;


  #ifdef ENABLE_FOAM 
          float fFoamBlend = 1.0 - pow(fWaterFoamTex , fFoam * 5.0); // * ( 1.0 - fWaterFoamTex ) ) ; 
          vTransmitLight = lerp(vTransmitLight , vSurfaceDiffuse * 0.8 , fFoamBlend);
          specSurface.m_specScale = clamp(1.0 - fFoamBlend * 4.0 , 0.0 , 1.0);
  #endif 
       }
      else
  #endif // #ifdef ENABLE_WATER 
       {
          fFogDistance = primaryInt.m_dist;

          Surface primarySurface;
          GetSurfaceInfo(primaryInt , primarySurface);

          vSpecNormal = primarySurface.m_normal;
          vReflectRayOrigin = primaryInt.m_pos;

          float fWetness = 1.0 - clamp((vReflectRayOrigin.y + 0.025) * 5.0 , 0.0 , 1.0);
          primarySurface.m_gloss = lerp(primarySurface.m_albedo.r , 1.0 , fWetness);
          primarySurface.m_albedo = lerp(primarySurface.m_albedo , primarySurface.m_albedo * 0.8 , fWetness);

          vTransmitLight = float3 (0.0 , 0.0 , 0.0);
          float fSunShadow = 1.0;
     #ifdef ENABLE_LANDSCAPE_RECEIVE_SHADOW 
          fSunShadow = GetSunShadow(primaryInt.m_pos);
     #endif 
          AddSunLight(primarySurface , -vRayDir , fSunShadow , vTransmitLight , vSpecularLight);
          AddSkyLight(primarySurface , vTransmitLight , vSpecularLight);
          vTransmitLight *= primarySurface.m_albedo;
          specSurface = primarySurface;
       }

      float3 vReflectRayDir = reflect(vRayDir , vSpecNormal);
      float3 vReflectLight = GetRayColour(vReflectRayOrigin , vReflectRayDir);

      vReflectLight = lerp(GetEnvColour(vReflectRayDir , specSurface.m_gloss) , vReflectLight , pow(specSurface.m_gloss , 40.0));

      float3 vFresnel = GetFresnel(-vRayDir , vSpecNormal , specSurface.m_specR0 , specSurface.m_gloss);

      vSpecularLight += vReflectLight;
      vResult = lerp(vTransmitLight , vSpecularLight , vFresnel * specSurface.m_specScale);
   }


  if (fFogDistance >= k_fFarClip)
   {
      fFogDistance = 100.0;
      vResult = smoothstep(0.9995 , 0.9999 , fSunDotV) * g_sunColour * 200.0;
   }

  float3 vFogColour = GetSkyColour(vRayDir);

  float3 vFogExtCol = exp2(k_vFogExt * -fFogDistance);
  float3 vFogInCol = exp2(k_vFogIn * -fFogDistance);
  vResult = vResult * (vFogExtCol)+vFogColour * (1.0 - vFogInCol);

  return vResult;
}

// Code from https: // www.shadertoy.com / view / ltlSWf 
void BlockRender(in float2 fragCoord)
 {
    static const float blockRate = 15.0;
    static const float blockSize = 64.0;
    float frame = floor(_Time.y * blockRate);
    float2 blockRes = floor(_ScreenParams.xy / blockSize) + float2 (1.0 , 1.0);
    float blockX = frac(frame / blockRes.x) * blockRes.x;
    float blockY = frac(floor(frame / blockRes.x) / blockRes.y) * blockRes.y;
    // Don't draw anything outside the current block. 
   if ((fragCoord.x - blockX * blockSize >= blockSize) ||
         (fragCoord.x - (blockX - 1.0) * blockSize < blockSize) ||
         (fragCoord.y - blockY * blockSize >= blockSize) ||
         (fragCoord.y - (blockY - 1.0) * blockSize < blockSize))
    {
       discard;
    }
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     g_fTime = _Time.y;

 #ifdef ENABLE_SCREENSHOT_MODE 
     BlockRender(fragCoord.xy);
     float fBaseTime = k_screenshotTime;
 #else 
     float fBaseTime = _Time.y;
 #endif 
     g_fTime = fBaseTime;

     float fCameraTime = g_fTime;

     // Static camera locations 
    // fCameraTime = 146.0 ; // some rocks 

   float2 vUV = fragCoord.xy / _ScreenParams.xy;

    float3 vCameraTarget = float3 (0.0 , -0.5 , 0.0);

   vCameraTarget.x -= fCameraTime * 0.5;

   float3 vCameraPos = vCameraTarget + float3 (0.0 , 0.0 , 0.0);

   float fHeading = fCameraTime * 0.1;
   float fDist = 1.5 - cos(fCameraTime * 0.1 + 2.0) * 0.8;

   if (iMouse.z > 0.0)
    {
       fHeading = iMouse.x * 10.0 / _ScreenParams.x;
       fDist = 5.0 - iMouse.y * 5.0 / _ScreenParams.y;
    }

   vCameraPos.y += 1.0 + fDist * fDist * 0.01;

   vCameraPos.x += sin(fHeading) * fDist;
   vCameraPos.z += cos(fHeading) * fDist;

   vCameraTarget.z += GetRiverMeander(vCameraTarget.x);
   vCameraPos.z += GetRiverMeander(vCameraPos.x);

   vCameraPos.y = max(vCameraPos.y , GetTerrainHeightSimple(vCameraPos) + 0.2);

   float3 vRayOrigin = vCameraPos;
    float3 vRayDir = GetCameraRayDir(GetWindowCoord(vUV) , vCameraPos , vCameraTarget);

#ifndef ENABLE_SUPERSAMPLE_MODE 
     float3 vResult = GetSceneColour(vRayOrigin , vRayDir);
#else 
     float3 vResult = float3 (0.0 , 0.0 , 0.0);
    float fTot = 0.0;
    for (int i = 0; i < k_superSampleCount; i++)
     {
        g_fTime = fBaseTime + (fTot / 10.0) / 30.0;
        float3 vCurrRayDir = vRayDir;
        float3 vRandom = float3 (SmoothNoise(fragCoord.xy + fTot) ,
                        SmoothNoise(fragCoord.yx + fTot + 42.0) ,
                        SmoothNoise(fragCoord.xx + fragCoord.yy + fTot + 42.0)) * 2.0 - 1.0;
        vRandom = normalize(vRandom);
        vCurrRayDir += vRandom * 0.001;
        vCurrRayDir = normalize(vCurrRayDir);
         vResult += GetSceneColour(vRayOrigin , vCurrRayDir);
        fTot += 1.0;
     }
    vResult /= fTot;
#endif 

     vResult = ApplyVignetting(vUV , vResult);

     float3 vFinal = Tonemap(vResult * 3.0);

    vFinal = vFinal * 1.1 - 0.1;

    fragColor = float4 (vFinal, 1.0);
    fragColor.xyz -= 0.1;// = float4 (vFinal, 1.0);
     return fragColor;
 }
//
//void mainVR(out float4 fragColor , in float2 fragCoord , in float3 fragRayOri , in float3 fragRayDir)
// {
//    g_fTime = _Time.y;
//
//    fragRayOri = fragRayOri.zyx;
//    fragRayDir = fragRayDir.zyx;
//
//    fragRayOri.z *= -1.0;
//    fragRayDir.z *= -1.0;
//
//    fragRayOri *= 0.1;
//
//    fragRayOri.y += 0.2;
//
//    fragRayOri.x -= g_fTime * 0.1;
//    fragRayOri.z += GetRiverMeander(fragRayOri.x);
//
//
//    float3 vResult = GetSceneColour(fragRayOri , fragRayDir);
//
//     float3 vFinal = Tonemap(vResult * 3.0);
//
//    vFinal = vFinal * 1.1 - 0.1;
//
//     fragColor = float4 (vFinal , 1.0);
// return fragColor;
//}

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