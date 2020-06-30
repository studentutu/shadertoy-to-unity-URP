Shader "Custom/Tribute - Journey ldlcRf"
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
            COLOR_SCHEME("COLOR_SCHEME", float) = 1
RGB("RGB", vector) = (0,0,0)
_FogMul("_FogMul", float) = -0.00800
_FogPow("_FogPow", float) = 1.00000
_IncorrectGammaCorrect("_IncorrectGammaCorrect", float) = 1.00000
_LightDir("_LightDir", vector) = (-0.23047 , 0.87328 , -0.42927)
_Brightness("_Brightness", float) = 0.40000
_Contrast("_Contrast", float) = 0.83000
_Saturation("_Saturation", float) = 1.21000
_SunStar("_SunStar", vector) = (14.7 , 1.47 , 0.1)
_SunSize("_SunSize", float) = 26.00000
_SunScale("_SunScale", float) = 15.00000
_ExposureOffset("_ExposureOffset", float) = 11.10000
_ExposurePower("_ExposurePower", float) = 0.52000
_ExposureStrength("_ExposureStrength", float) = 0.09000
_SunColor("_SunColor", vector) = (1 , 0.95441 , 0.77206)
_Zenith("_Zenith", vector) = (0.77941 , 0.5898 , 0.41263)
_ZenithFallOff("_ZenithFallOff", float) = 2.36000
_Nadir("_Nadir", vector) = (1 , 0.93103 , 0)
_NadirFallOff("_NadirFallOff", float) = 1.91000
_Horizon("_Horizon", vector) = (0.96324 , 0.80163 , 0.38954)
_CharacterAOParams("_CharacterAOParams", vector) = (0.03 , 7.36 , 0)
_CharacterMainColor("_CharacterMainColor", vector) = (0.60294 , 0.1515 , 0.062067)
_CharacterTerrainCol("_CharacterTerrainCol", vector) = (0.35294 , 0.16016 , 0.12197)
_CharacterCloakDarkColor("_CharacterCloakDarkColor", vector) = (0.25735 , 0.028557 , 0.0056769)
_CharacterYellowColor("_CharacterYellowColor", vector) = (0.88971 , 0.34975 , 0)
_CharacterWhiteColor("_CharacterWhiteColor", vector) = (0.9928 , 1 , 0.47794)
_CharacterBloomScale("_CharacterBloomScale", float) = 0.70000
_CharacterDiffScale("_CharacterDiffScale", float) = 1.50000
_CharacterFreScale("_CharacterFreScale", float) = 1.77000
_CharacterFrePower("_CharacterFrePower", float) = 3.84000
_CharacterFogScale("_CharacterFogScale", float) = 4.55000
_CloudTransparencyMul("_CloudTransparencyMul", float) = 0.90000
_CloudCol("_CloudCol", vector) = (1 , 0.84926 , 0.69853)
_BackCloudCol("_BackCloudCol", vector) = (0.66176 , 0.64807 , 0.62284)
_CloudSpecCol("_CloudSpecCol", vector) = (0.17647 , 0.062284 , 0.062284)
_BackCloudSpecCol("_BackCloudSpecCol", vector) = (0.11029 , 0.05193 , 0.020275)
_CloudFogStrength("_CloudFogStrength", float) = 0.50000
_TombMainColor("_TombMainColor", vector) = (0.64706 , 0.38039 , 0.27451)
_TombScarfColor("_TombScarfColor", vector) = (0.38971 , 0.10029 , 0.10029)
_PyramidCol("_PyramidCol", vector) = (0.69853 , 0.40389 , 0.22086)
_PyramidHeightFog("_PyramidHeightFog", vector) = (38.66 , 1.3,0)
_TerrainCol("_TerrainCol", vector) = (0.56618 , 0.29249 , 0.1915)
_TerrainSpecColor("_TerrainSpecColor", vector) = (1 , 0.77637 , 0.53676)
_TerrainSpecPower("_TerrainSpecPower", float) = 55.35000
_TerrainSpecStrength("_TerrainSpecStrength", float) = 1.56000
_TerrainGlitterRep("_TerrainGlitterRep", float) = 7.00000
_TerrainGlitterPower("_TerrainGlitterPower", float) = 3.20000
_TerrainRimColor("_TerrainRimColor", vector) = (0.16176 , 0.13131 , 0.098724)
_TerrainRimPower("_TerrainRimPower", float) = 5.59000
_TerrainRimStrength("_TerrainRimStrength", float) = 1.61000
_TerrainRimSpecPower("_TerrainRimSpecPower", float) = 2.88000
_TerrainFogPower("_TerrainFogPower", float) = 2.11000
_TerrainShadowParams("_TerrainShadowParams", vector) = (0.12 , 5.2 , 88.7 , 0.28)
_TerrainAOParams("_TerrainAOParams", vector) = (0.01 , 0.02 , 2)
_TerrainShadowColor("_TerrainShadowColor", vector) = (0.48529 , 0.13282 , 0)
_TerrainDistanceShadowColor("_TerrainDistanceShadowColor", vector) = (0.70588 , 0.4644 , 0.36851)
_TerrainDistanceShadowPower("_TerrainDistanceShadowPower", float) = 0.11000
_FlyingHelperMainColor("_FlyingHelperMainColor", vector) = (0.85294 , 0.11759 , 0.012543)
_FlyingHelperCloakDarkColor("_FlyingHelperCloakDarkColor", vector) = (1 , 0.090909 , 0)
_FlyingHelperYellowColor("_FlyingHelperYellowColor", vector) = (1 , 0.3931 , 0)
_FlyingHelperWhiteColor("_FlyingHelperWhiteColor", vector) = (1 , 1 , 1)
_FlyingHelperBloomScale("_FlyingHelperBloomScale", float) = 2.61000
_FlyingHelperFrePower("_FlyingHelperFrePower", float) = 1.00000
_FlyingHelperFreScale("_FlyingHelperFreScale", float) = 0.85000
_FlyingHelperFogScale("_FlyingHelperFogScale", float) = 1.75000
_CameraFOV("_CameraFOV", vector) = (1.038 , 0.78984 , -1)
_CameraPos("_CameraPos", vector) = (1.0 , 2.2 , 18.6)
_CameraMovement("_CameraMovement", vector) = (0.15 , 0.1 , 0.2 , 0.25)
_WindDirection("_WindDirection", vector) = (-0.27 , -0.12 , 0)
_DrawDistance("_DrawDistance", float) = 70.00000
_MaxSteps("_MaxSteps", float) = 64.00000
_SunPosition("_SunPosition", vector) = (0.2 , 56 , -40.1)
_CharacterRotation("_CharacterRotation", float) = 0.17000
_CharacterPosition("_CharacterPosition", vector) = (0.52 , 2.35 , 17.6)
_CharacterScale("_CharacterScale", vector) = (0.4 , 0.53 , 0.38)
_MainClothRotation("_MainClothRotation", float) = 0.30000
_MainClothScale("_MainClothScale", vector) = (0.3 , 0.68 , 0.31)
_MainClothPosition("_MainClothPosition", vector) = (0 , -0.12 , 0)
_MainClothBotCutPos("_MainClothBotCutPos", vector) = (0 , -0.52 , 0)
_MainClothDetail("_MainClothDetail", vector) = (6 , 0.04 , 1.3)
_HeadScarfRotation("_HeadScarfRotation", float) = -0.19000
_HeadScarfPosition("_HeadScarfPosition", vector) = (-0.005 , -0.16 , -0.01)
_HeadScarfScale("_HeadScarfScale", vector) = (0.18 , 0.2 , 0.03)
_HeadRotationX("_HeadRotationX", float) = -0.30000
_HeadRotationY("_HeadRotationY", float) = 0.29000
_HeadRotationZ("_HeadRotationZ", float) = 0.00000
_HeadPos("_HeadPos", vector) = (0 , -0.04 , 0.01)
_LongScarfPos("_LongScarfPos", vector) = (0.01 , -0.15 , 0.09)
_LongScarfScale("_LongScarfScale", vector) = (0.05 , 1.25 , 0.001)
_LongScarfWindStrength("_LongScarfWindStrength", vector) = (0.3 , 4.52 , 5.2 , 0.02)
_LongScarfRotX("_LongScarfRotX", float) = 1.43000
_LongScarfMaxRad("_LongScarfMaxRad", float) = 1.99000
_FacePosition("_FacePosition", vector) = (0 , -0.01 , 0.05)
_FaceSize("_FaceSize", vector) = (0.038 , 0.05 , 0.03)
_UpperLeftLegA("_UpperLeftLegA", vector) = (-0.02 , -0.37 , 0.01)
_UpperLeftLegB("_UpperLeftLegB", vector) = (-0.02 , -0.67 , -0.059999)
_UpperLeftLegParams("_UpperLeftLegParams", vector) = (0.026 , 1 , 1)
_LowerLeftLegA("_LowerLeftLegA", vector) = (-0.02 , -0.67 , -0.059999)
_LowerLeftLegB("_LowerLeftLegB", vector) = (-0.02 , -0.77 , 0.12)
_LowerLeftLegParams("_LowerLeftLegParams", vector) = (0.028 , 0.03 , 0.01)
_UpperRightLegA("_UpperRightLegA", vector) = (0.07 , -0.5 , 0.02)
_UpperRightLegB("_UpperRightLegB", vector) = (0.07 , -0.61 , 0.09)
_UpperRightLegParams("_UpperRightLegParams", vector) = (0.026 , 1 , 1)
_LowerRightLegA("_LowerRightLegA", vector) = (0.07 , -0.61 , 0.09)
_LowerRightLegB("_LowerRightLegB", vector) = (0.07 , -0.91 , 0.22)
_LowerRightLegParams("_LowerRightLegParams", vector) = (0.028 , 0.03 , 0.01)
_BodyPos("_BodyPos", vector) = (0 , -0.45 , -0.03)
_CharacterTrailOffset("_CharacterTrailOffset", vector) = (0.72 , 0.01 , 0.06)
_CharacterTrailScale("_CharacterTrailScale", vector) = (0.001 , 0 , 0.5)
_CharacterTrailWave("_CharacterTrailWave", vector) = (1.97 , 0 , 0.34)
_CharacterHeightTerrainMix("_CharacterHeightTerrainMix", vector) = (1.95 , -30,0)
_CloudNoiseStrength("_CloudNoiseStrength", vector) = (0.2 , 0.16 , 0.1)
_FrontCloudsPos("_FrontCloudsPos", vector) = (9.91 , 8.6 , -12.88)
_FrontCloudsOffsetA("_FrontCloudsOffsetA", vector) = (-9.1 , 3.04 , 0)
_FrontCloudsOffsetB("_FrontCloudsOffsetB", vector) = (-2.97 , 3.72 , -0.05)
_FrontCloudParams("_FrontCloudParams", vector) = (5.02 , 3.79 , 5)
_FrontCloudParamsA("_FrontCloudParamsA", vector) = (3.04 , 0.16 , 2)
_FrontCloudParamsB("_FrontCloudParamsB", vector) = (1.34 , 0.3 , 3.15)
_BackCloudsPos("_BackCloudsPos", vector) = (29.99 , 13.61 , -18.8)
_BackCloudsOffsetA("_BackCloudsOffsetA", vector) = (24.87 , -1.49 , 0)
_BackCloudParams("_BackCloudParams", vector) = (7.12 , 4.26 , 1.68)
_BackCloudParamsA("_BackCloudParamsA", vector) = (6.37 , 2.23 , 2.07)
_PlaneParams("_PlaneParams", vector) = (7.64 , 10.85 , 3.76)
_CloudGlobalParams("_CloudGlobalParams", vector) = (0.123 , 2.1 , 0.5)
_CloudBackGlobalParams("_CloudBackGlobalParams", vector) = (0.16 , 1.4 , -0.01)
_CloudNormalMod("_CloudNormalMod", vector) = (0.26 , -0.13 , 1.22)
_CloudSpecPower("_CloudSpecPower", float) = 24.04000
_CloudPyramidDistance("_CloudPyramidDistance", float) = 0.14500
_TombPosition("_TombPosition", vector) = (5 , 5 , 9.28)
_TombScale("_TombScale", vector) = (0.07 , 0.5 , 0.006)
_TombBevelParams("_TombBevelParams", vector) = (0.44 , 0.66 , 0.01)
_TombRepScale("_TombRepScale", float) = 0.79000
_TombCutOutScale("_TombCutOutScale", vector) = (0.39 , 0.06 , -14.92)
_TombScarfOffset("_TombScarfOffset", vector) = (0 , 0.46 , 0)
_TombScarfWindParams("_TombScarfWindParams", vector) = (-1.61 , 6 , 0.05)
_TombScarfScale("_TombScarfScale", vector) = (0.03 , 0.002 , 0.5)
_TombScarfRot("_TombScarfRot", float) = -0.88000
_PyramidPos("_PyramidPos", vector) = (0 , 10.9 , -50)
_PyramidScale("_PyramidScale", vector) = (34.1 , 24.9 , 18)
_PrismScale("_PrismScale", vector) = (1 , 1.9 , 1)
_PyramidNoisePrams("_PyramidNoisePrams", vector) = (1.5 , 1 , 1)
_PrismEyeScale("_PrismEyeScale", vector) = (0.7 , 1.9 , 51.5)
_PyramidEyeOffset("_PyramidEyeOffset", vector) = (2.0 , -4.9 , 0)
_PrismEyeWidth("_PrismEyeWidth", float) = 5.86000
_TerrainMaxDistance("_TerrainMaxDistance", float) = 30.04000
_SmallDetailStrength("_SmallDetailStrength", float) = 0.00600
_SmallWaveDetail("_SmallWaveDetail", vector) = (3.19 , 16 , 6.05)
_WindSpeed("_WindSpeed", vector) = (2 , 0.6,0)
_MediumDetailStrength("_MediumDetailStrength", float) = 0.05000
_MediumWaveDetail("_MediumWaveDetail", vector) = (2 , 50,0)
_MediumWaveOffset("_MediumWaveOffset", vector) = (0.3 , -2 , 0.1)
_LargeWaveDetail("_LargeWaveDetail", vector) = (0.25 , 0.73,0)
_LargeWavePowStre("_LargeWavePowStre", vector) = (0.6 , 2.96 , -2.08)
_LargeWaveOffset("_LargeWaveOffset", vector) = (-3.65 , 4.41 , -11.64)
_FlyingHelperPos("_FlyingHelperPos", vector) = (2.15 , 4.68 , 14.4)
_FlyingHelperScale("_FlyingHelperScale", vector) = (0.25 , 0.001 , 0.3)
_FlyingHelperMovement("_FlyingHelperMovement", vector) = (0.44 , 1.44 , -2.98)
_FlyingHelperScarfScale("_FlyingHelperScarfScale", vector) = (0.1 , 0.001 , 1.5)
_FlyingHelperScarfWindParams("_FlyingHelperScarfWindParams", vector) = (-0.06 , 0.31 , 0.47)
_FlyingHelperScarfWindDetailParams("_FlyingHelperScarfWindDetailParams", vector) = (3.93 , 0.005 , -45.32)
_FlyingHelperSideScarfOffset("_FlyingHelperSideScarfOffset", vector) = (0.16 , -0.01 , 0)
_FlyingHelperSideScarfScale("_FlyingHelperSideScarfScale", vector) = (0.06 , 0.001 , 0.8)
_FlyingScarfSideWindParams("_FlyingScarfSideWindParams", vector) = (2.46 , -1.59 , -0.05 , 0.21)
MAT_PYRAMID("MAT_PYRAMID", float) = 1.0
MAT_TERRAIN("MAT_TERRAIN", float) = 10.0
MAT_TERRAIN_TRAIL("MAT_TERRAIN_TRAIL", float) = 11.0
MAT_BACK_CLOUDS("MAT_BACK_CLOUDS", float) = 20.0
MAT_FRONT_CLOUDS("MAT_FRONT_CLOUDS", float) = 21.0
MAT_TOMB("MAT_TOMB", float) = 30.0
MAT_TOMB_SCARF("MAT_TOMB_SCARF", float) = 31.0
MAT_FLYING_HELPERS("MAT_FLYING_HELPERS", float) = 40.0
MAT_FLYING_HELPER_SCARF("MAT_FLYING_HELPER_SCARF", float) = 41.0
MAT_CHARACTER_BASE("MAT_CHARACTER_BASE", float) = 50.0
MAT_CHARACTER_MAIN_CLOAK("MAT_CHARACTER_MAIN_CLOAK", float) = 51.0
MAT_CHARACTER_NECK_SCARF("MAT_CHARACTER_NECK_SCARF", float) = 52.0
MAT_CHARACTER_LONG_SCARF("MAT_CHARACTER_LONG_SCARF", float) = 53.0
MAT_CHARACTER_FACE("MAT_CHARACTER_FACE", float) = 54.0

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
    float4 _Channel3_ST;
    TEXTURE2D(_Channel3);       SAMPLER(sampler_Channel3);

    float4 iMouse;
    float COLOR_SCHEME;
float3 RGB;
float _FogMul;
float _FogPow;
float _IncorrectGammaCorrect;
float4 _LightDir;
float _Brightness;
float _Contrast;
float _Saturation;
float4 _SunStar;
float _SunSize;
float _SunScale;
float _ExposureOffset;
float _ExposurePower;
float _ExposureStrength;
float4 _SunColor;
float4 _Zenith;
float _ZenithFallOff;
float4 _Nadir;
float _NadirFallOff;
float4 _Horizon;
float4 _CharacterAOParams;
float4 _CharacterMainColor;
float4 _CharacterTerrainCol;
float4 _CharacterCloakDarkColor;
float4 _CharacterYellowColor;
float4 _CharacterWhiteColor;
float _CharacterBloomScale;
float _CharacterDiffScale;
float _CharacterFreScale;
float _CharacterFrePower;
float _CharacterFogScale;
float _CloudTransparencyMul;
float4 _CloudCol;
float4 _BackCloudCol;
float4 _CloudSpecCol;
float4 _BackCloudSpecCol;
float _CloudFogStrength;
float4 _TombMainColor;
float4 _TombScarfColor;
float4 _PyramidCol;
float4 _PyramidHeightFog;
float4 _TerrainCol;
float4 _TerrainSpecColor;
float _TerrainSpecPower;
float _TerrainSpecStrength;
float _TerrainGlitterRep;
float _TerrainGlitterPower;
float4 _TerrainRimColor;
float _TerrainRimPower;
float _TerrainRimStrength;
float _TerrainRimSpecPower;
float _TerrainFogPower;
float4 _TerrainShadowParams;
float4 _TerrainAOParams;
float4 _TerrainShadowColor;
float4 _TerrainDistanceShadowColor;
float _TerrainDistanceShadowPower;
float4 _FlyingHelperMainColor;
float4 _FlyingHelperCloakDarkColor;
float4 _FlyingHelperYellowColor;
float4 _FlyingHelperWhiteColor;
float _FlyingHelperBloomScale;
float _FlyingHelperFrePower;
float _FlyingHelperFreScale;
float _FlyingHelperFogScale;
float4 _CameraFOV;
float4 _CameraPos;
float4 _CameraMovement;
float4 _WindDirection;
float _DrawDistance;
float _MaxSteps;
float4 _SunPosition;
float _CharacterRotation;
float4 _CharacterPosition;
float4 _CharacterScale;
float _MainClothRotation;
float4 _MainClothScale;
float4 _MainClothPosition;
float4 _MainClothBotCutPos;
float4 _MainClothDetail;
float _HeadScarfRotation;
float4 _HeadScarfPosition;
float4 _HeadScarfScale;
float _HeadRotationX;
float _HeadRotationY;
float _HeadRotationZ;
float4 _HeadPos;
float4 _LongScarfPos;
float4 _LongScarfScale;
float4 _LongScarfWindStrength;
float _LongScarfRotX;
float _LongScarfMaxRad;
float4 _FacePosition;
float4 _FaceSize;
float4 _UpperLeftLegA;
float4 _UpperLeftLegB;
float4 _UpperLeftLegParams;
float4 _LowerLeftLegA;
float4 _LowerLeftLegB;
float4 _LowerLeftLegParams;
float4 _UpperRightLegA;
float4 _UpperRightLegB;
float4 _UpperRightLegParams;
float4 _LowerRightLegA;
float4 _LowerRightLegB;
float4 _LowerRightLegParams;
float4 _BodyPos;
float4 _CharacterTrailOffset;
float4 _CharacterTrailScale;
float4 _CharacterTrailWave;
float4 _CharacterHeightTerrainMix;
float4 _CloudNoiseStrength;
float4 _FrontCloudsPos;
float4 _FrontCloudsOffsetA;
float4 _FrontCloudsOffsetB;
float4 _FrontCloudParams;
float4 _FrontCloudParamsA;
float4 _FrontCloudParamsB;
float4 _BackCloudsPos;
float4 _BackCloudsOffsetA;
float4 _BackCloudParams;
float4 _BackCloudParamsA;
float4 _PlaneParams;
float4 _CloudGlobalParams;
float4 _CloudBackGlobalParams;
float4 _CloudNormalMod;
float _CloudSpecPower;
float _CloudPyramidDistance;
float4 _TombPosition;
float4 _TombScale;
float4 _TombBevelParams;
float _TombRepScale;
float4 _TombCutOutScale;
float4 _TombScarfOffset;
float4 _TombScarfWindParams;
float4 _TombScarfScale;
float _TombScarfRot;
float4 _PyramidPos;
float4 _PyramidScale;
float4 _PrismScale;
float4 _PyramidNoisePrams;
float4 _PrismEyeScale;
float4 _PyramidEyeOffset;
float _PrismEyeWidth;
float _TerrainMaxDistance;
float _SmallDetailStrength;
float4 _SmallWaveDetail;
float4 _WindSpeed;
float _MediumDetailStrength;
float4 _MediumWaveDetail;
float4 _MediumWaveOffset;
float4 _LargeWaveDetail;
float4 _LargeWavePowStre;
float4 _LargeWaveOffset;
float4 _FlyingHelperPos;
float4 _FlyingHelperScale;
float4 _FlyingHelperMovement;
float4 _FlyingHelperScarfScale;
float4 _FlyingHelperScarfWindParams;
float4 _FlyingHelperScarfWindDetailParams;
float4 _FlyingHelperSideScarfOffset;
float4 _FlyingHelperSideScarfScale;
float4 _FlyingScarfSideWindParams;
float MAT_PYRAMID;
float MAT_TERRAIN;
float MAT_TERRAIN_TRAIL;
float MAT_BACK_CLOUDS;
float MAT_FRONT_CLOUDS;
float MAT_TOMB;
float MAT_TOMB_SCARF;
float MAT_FLYING_HELPERS;
float MAT_FLYING_HELPER_SCARF;
float MAT_CHARACTER_BASE;
float MAT_CHARACTER_MAIN_CLOAK;
float MAT_CHARACTER_NECK_SCARF;
float MAT_CHARACTER_LONG_SCARF;
float MAT_CHARACTER_FACE;

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

/*
Before you continue reading , feast your eyes on these beautiful Color Schemes ( 0 , 1 , 2 )
*/

// Modify the number to 0 , 1 , 2 or 3 and press play button at bottom for different schemes. 


/*
    This shader is just a tribute to "Journey" game by That Game Company. Some answers:
    1 ) No , I do not have any affiliation with That Game Company.
    2 ) Yes , Journey is one of the best games ever made
    3 ) It has taken me around 3 - 4 months from start to finish , evenings and weekends
    4 ) Most of the time was spent getting the details right
    5 ) Yes , the character needs more work. One day I will finish it
    6 ) Yes , if anybody comes up with something cool to add , I would love to improve : )
    7 ) There is nothing mathemagically amazing in this shader. I hope you do find it pretty though!
    8 ) Yes , the code is fairly ugly. But look at the colors - PRETTY!
    9 ) If you have any other questions , I will be happy to answer

    This shader started as a learning playground , but around January , I finished my second round of Journey
    and thought , well why the hell not , and so here we are.

    Special thanks to Thibault Girard and Jack Hamilton for their artistic input. Also bigs up to Peter Pimley
    for his constant optimism.

    You are hereby granted your wish to follow me on twitter: @shakemayster

    Other authors ( With BIG thanks !!! )
    Dave_Hoskins
    Dila
    Maurogik
    FabriceNeyret2
*/


//#define mul(a, b ) b * a 
//#define saturate ( a ) clamp ( a , 0.0 , 1.0 ) 



// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Play with these at your own risk. Expect , unexpected results! 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 


        // Material ID definitions 


       #define TEST_MAT_LESS( a , b ) a < ( b + 0.1 ) 
       #define TEST_MAT_GREATER( a , b ) a > ( b - 0.1 ) 

        // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
        // Primitive functions by IQ 
        // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
       float sdRoundBox(float3 p , float3 b , float r)
        {
            return length(max(abs(p) - b , 0.0)) - r;
        }

       float sdSphere(float3 p , float s)
        {
            return length(p) - s;
        }

       float sdPlane(float3 p)
        {
            return p.y;
        }

       float sdBox(float3 p , float3 b)
        {
            float3 d = abs(p) - b;
            return min(max(d.x , max(d.y , d.z)) , 0.0) +
                 length(max(d , 0.0));
        }

       float sdCylinder(float3 p , float2 h)
        {
            float2 d = abs(float2 (length(p.xz) , p.y)) - h;
            return min(max(d.x , d.y) , 0.0) + length(max(d , 0.0));
        }

       float sdPlane(float3 p , float4 n)
        {
           // n must be normalized 
          return dot(p , n.xyz) + n.w;
      }

     float2 sdSegment(in float3 p , float3 a , float3 b)
      {
          float3 pa = p - a , ba = b - a;
          float h = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.0);
          return float2 (length(pa - ba * h) , h);
      }

     float sdEllipsoid(in float3 p , in float3 r)
      {
          return (length(p / r) - 1.0) * min(min(r.x , r.y) , r.z);
      }

     float sdTriPrism(float3 p , float2 h)
      {
         float3 q = abs(p);
     #if 0 
         return max(q.z - h.y , max(q.x * 0.866025 + p.y * 0.5 , -p.y) - h.x * 0.5);
     #else 
         float d1 = q.z - h.y;
         float d2 = max(q.x * 0.866025 + p.y * 0.5 , -p.y) - h.x * 0.5;
         return length(max(float2 (d1 , d2) , 0.0)) + min(max(d1 , d2) , 0.);
     #endif 
      }

     // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
     // distance field operations 
     // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
    float2 min_mat(float2 d1 , float2 d2)
     {
         return (d1.x < d2.x) ? d1 : d2;
     }

    float smin(float a , float b , float k)
     {
        float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
        return lerp(b , a , h) - k * h * (1.0 - h);
     }

    float2 smin_mat(float2 a , float2 b , float k , float c)
     {
        float h = clamp(0.5 + 0.5 * (b.x - a.x) / k , 0.0 , 1.0);
        float x = lerp(b.x , a.x , h) - k * h * (1.0 - h);
        return float2 (x , (h < c) ? b.y : a.y);
     }

    float smax(float a , float b , float k)
     {
         float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
         return lerp(a , b , h) + k * h * (1.0 - h);
     }

    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
    // Rotations 
    // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
   void rX(inout float3 p , float a) {
       float3 q = p;
       float c = cos(a);
       float s = sin(a);
       p.y = c * q.y - s * q.z;
       p.z = s * q.y + c * q.z;
    }

   void rY(inout float3 p , float a) {
       float3 q = p;
       float c = cos(a);
       float s = sin(a);
       p.x = c * q.x + s * q.z;
       p.z = -s * q.x + c * q.z;
    }

   void rZ(inout float3 p , float a) {
       float3 q = p;
       float c = cos(a);
       float s = sin(a);
       p.x = c * q.x + s * q.y;
       p.y = -s * q.x + c * q.y;
    }

   // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
   // Value noise and its derivatives: https: // www.shadertoy.com / view / MdX3Rr 
   // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
  float3 noised(in float2 x)
   {
      float2 f = frac(x);
      float2 u = f * f * (3.0 - 2.0 * f);

  #if 0 
      // texel fetch version 
     int2 p = int2 (floor(x));
     float a = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , (p + int2 (0 , 0)) & 255 , 0).x;
      float b = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , (p + int2 (1 , 0)) & 255 , 0).x;
      float c = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , (p + int2 (0 , 1)) & 255 , 0).x;
      float d = SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , (p + int2 (1 , 1)) & 255 , 0).x;
 #else 
      // SAMPLE_TEXTURE2D version 
     float2 p = floor(x);
      float a = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (0.5 , 0.5)) / 256.0 , 0.0).x;
      float b = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (1.5 , 0.5)) / 256.0 , 0.0).x;
      float c = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (0.5 , 1.5)) / 256.0 , 0.0).x;
      float d = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (1.5 , 1.5)) / 256.0 , 0.0).x;
 #endif 

      return float3 (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y ,
                     6.0 * f * (1.0 - f) * (float2 (b - a , c - a) + (a - b - c + d) * u.yx));
  }

  // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
  // Noise function: https: // www.shadertoy.com / view / 4sfGRH 
  // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
 float pn(float3 p) {
     float3 i = floor(p);
      float4 a = dot(i , float3 (1. , 57. , 21.)) + float4 (0. , 57. , 21. , 78.);
     float3 f = cos((p - i) * 3.141592653589793) * (-.5) + .5;
      a = lerp(sin(cos(a) * a) , sin(cos(1. + a) * (1. + a)) , f.x);
     a.xy = lerp(a.xz , a.yw , f.y);
      return lerp(a.x , a.y , f.z);
  }

 // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
 // Sin Wave approximation http: // http.developer.nvidia.com / GPUGems3 / gpugems3_ch16.html 
 // == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float4 SmoothCurve(float4 x) {
  return x * x * (3.0 - 2.0 * x);
 }

float4 TriangleWave(float4 x) {
  return abs(frac(x + 0.5) * 2.0 - 1.0);
 }

float4 SmoothTriangleWave(float4 x) {
  return SmoothCurve(TriangleWave(x));
 }

float SmoothTriangleWave(float x)
 {
  return SmoothCurve(TriangleWave(float4 (x , x , x , x))).x;
 }

void Bend(inout float3 vPos , float2 vWind , float fBendScale)
 {
     float fLength = length(vPos);
     float fBF = vPos.y * fBendScale;
     fBF += 1.0;
     fBF *= fBF;
     fBF = fBF * fBF - fBF;
     float3 vNewPos = vPos;
     vNewPos.xz += vWind.xy * fBF;
     vPos.xyz = normalize(vNewPos.xyz) * fLength;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Modified cone versions for scarf and main cloak 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdScarfCone(in float3 p , in float h , in float r1 , in float r2)
 {
    float d1 = -p.y - h;
    float q = (p.y - h);
    float si = 0.5 * (r1 - r2) / h;
    p.z = lerp(p.z , p.z * 0.2 , q);
    float d2 = max(sqrt(dot(p.xz , p.xz) * (1.0 - si * si)) + q * si - r2 , q);
    return length(max(float2 (d1 , d2) , 0.0)) + min(max(d1 , d2) , 0.);
 }

float2 sdCloakCone(in float3 p , in float h , in float r1 , in float r2)
 {
    float d1 = -p.y - h;
    float q = (p.y - h);
    r2 = (q * r2) + 0.08;
    float si = 0.5 * (r1 - r2) / h;
    float d2 = max(sqrt(dot(p.xz , p.xz) * (1.0 - si * si)) + q * si - r2 , q);
    return float2 (length(max(float2 (d1 , d2) , 0.0)) + min(max(d1 , d2) , 0.) , q);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Character 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float3 headScarfMatUVW;
float sdHeadScarf(float3 pos)
 {

    float3 headScarfPos = pos - _HeadScarfPosition;
    rX(headScarfPos , _HeadScarfRotation);

    float distanceToTop = min(0.0 , (pos.y + 0.01));

    // Put a slight twist in the middle. Gives the feel that the head scarf 
    // is sitting on shoulders. Very subtle , but I can see it :D 
   float midBend = abs(frac(distanceToTop + 0.5) * 2.0 - 1.0);
   headScarfPos.x += (cos(2.0 + headScarfPos.y * 50.0) * 0.05 * midBend);
   headScarfPos.z += (sin(2.0 + headScarfPos.y * 50.0) * 0.03 * midBend);

   // Apply wind to head Scarf 
  headScarfPos += SmoothTriangleWave(float4 (pos.xyz * 5.0 + _Time.y , 1.0)).xyz * 0.05 * distanceToTop;

  // Scarf shape 
 float headScarf = sdScarfCone(headScarfPos , _HeadScarfScale.x , _HeadScarfScale.y , _HeadScarfScale.z);
 headScarf = max(headScarf , -sdScarfCone(headScarfPos , _HeadScarfScale.x , _HeadScarfScale.y , _HeadScarfScale.z - 0.011));

 // Cut out the bottom of the head scarf. I have no idea what I was thinking , when I wrote this 
float3 cutOutPos = headScarfPos - float3 (0.0 , 0.08 , 0.0);
float3 r = float3 (0.12 , 0.8 , 0.2);
float smallestSize = min(min(r.x , r.y) , r.z);
 float3 dp = cutOutPos / r;
float h = min(1.0 , abs(1.0 - abs(dp.y)));

// Apply some crazy power until it looks like a scarf sitting on shoulders 
h = pow(h , 5.5);

float rad = h;
float d = length(cutOutPos / r);

float cutOut = (d - rad) * smallestSize;
headScarf = max(headScarf , cutOut);

// material information 
float materialVal = 1.0 - pow(d - rad , 0.02);
 headScarfMatUVW = smoothstep(-1.0 , 1.0 , materialVal / _HeadScarfScale);

 // Chop the top off , to make room for head 
float3 headPos = pos - float3 (0.0 , 0.25 , 0.0);
float head = sdBox(headPos , float3 (0.2 , 0.19 , 0.2));
headScarf = max(headScarf , -head);

return headScarf;
}
float3 mainCloakMatUVW;
float sdMainCloak(float3 pos)
 {
    float3 cloakPos = pos - _MainClothPosition;
    float q = min(0.0 , (cloakPos.y + 0.05));
    rX(cloakPos , _MainClothRotation);

    // Apply detailing 
   cloakPos += SmoothTriangleWave(float4 (pos.xyz * _MainClothDetail.x + _Time.y , 1.0)).xyz * _MainClothDetail.y * q;

   // Add main Wind direction 
  Bend(cloakPos , _WindDirection.xy , _MainClothDetail.z);

  float2 cloak = sdCloakCone(cloakPos , _MainClothScale.y , _MainClothScale.x , _MainClothScale.z);
  // Cut out the internals of the cloak 
 cloak.x = max(cloak.x , -sdCloakCone(cloakPos , _MainClothScale.y * 1.05 , _MainClothScale.x * 0.95 , _MainClothScale.z * 1.01).x);

 // UV Information 
mainCloakMatUVW = smoothstep(-1.0 , 1.0 , cloakPos / _MainClothScale);

// Cut out the top section 
float3 headPos = cloakPos - float3 (0.0 , 0.69 , 0.0);
float head = sdBox(headPos , float3 (0.2 , 0.67 , 0.2));
 cloak.x = max(cloak.x , -head);

 // Cut the bottom 
float bottomCut = sdPlane(cloakPos - _MainClothBotCutPos);
cloak.x = max(cloak.x , -bottomCut);

return cloak.x;
}

float earWigs(in float3 pos)
 {
    // Symmetrical ear wigs. Is that even a word... Ear Wigs! 
  pos.x = abs(pos.x);

  float2 earWig = sdSegment(pos , float3 (0.02 , 0.11 , 0.0) , float3 (0.07 , 0.16 , 0.05));
  float ear = earWig.x - 0.026 + (earWig.y * 0.03);
  return ear;
}


float sdHead(float3 pos)
 {
    float3 headPos = pos - _HeadPos;

    // Slight tilt 
   rY(headPos , _HeadRotationY); // 1.2 
   rX(headPos , _HeadRotationX);

   float head = sdCylinder(headPos , float2 (0.05 , 0.13));
   head = smin(earWigs(headPos) , head , 0.04);
   return head;
}

float3 longScarfMatUVW;
float sdScarf(float3 pos)
 {
    float3 scarfPos = pos - _LongScarfPos;
    float3 scale = _LongScarfScale;


    float distanceToPoint = max(0.0 , length(scarfPos) - 0.04);
    scarfPos.x += (sin(scarfPos.z * _LongScarfWindStrength.x + _Time.y) * 0.1 * distanceToPoint);
    scarfPos.y += (sin(scarfPos.z * _LongScarfWindStrength.y + _Time.y) * 0.1 * distanceToPoint);

    // Apply detailing 
   scarfPos += SmoothTriangleWave(float4 (pos.xyz * _LongScarfWindStrength.z + _Time.y , 1.0)).xyz * _LongScarfWindStrength.w * distanceToPoint;

   // Essentially a box pivoted at a specific pointExtended 
  float3 scarfOffset = float3 (0.0 , 0.0 , -scale.y);

  rX(scarfPos , _LongScarfRotX);
  float scarf = sdBox(scarfPos - scarfOffset.xzy , scale);

  longScarfMatUVW = smoothstep(-1.0 , 1.0 , (scarfPos - scarfOffset.xzy) / scale);

  return max(scarf , sdSphere(scarfPos , _LongScarfMaxRad));
}

float sdLegs(in float3 pos)
 {
    float2 upperLeftLeg = sdSegment(pos , _UpperLeftLegA , _UpperLeftLegB);
    float leftLeg = upperLeftLeg.x - _UpperLeftLegParams.x;
    float2 lowerLeftLeg = sdSegment(pos , _LowerLeftLegA , _LowerLeftLegB);
    leftLeg = smin(leftLeg , lowerLeftLeg.x - _LowerLeftLegParams.x + (lowerLeftLeg.y * _LowerLeftLegParams.y) , _LowerLeftLegParams.z);

    // cut bottom of left leg otherwise looks nasty with harsh tip 
   leftLeg = max(leftLeg , -(length(pos - _LowerLeftLegB) - 0.06));

   float2 upperRightLeg = sdSegment(pos , _UpperRightLegA , _UpperRightLegB);
   float rightLeg = upperRightLeg.x - _UpperRightLegParams.x;
   float2 lowerRightLeg = sdSegment(pos , _LowerRightLegA , _LowerRightLegB);
   rightLeg = smin(rightLeg , lowerRightLeg.x - _LowerRightLegParams.x + (lowerRightLeg.y * _LowerRightLegParams.y) , _LowerRightLegParams.z);

   return min(leftLeg , rightLeg);
}

float2 sdFace(float3 pos , float2 currentDistance)
 {
    float3 headPos = pos - float3 (0.0 , -0.05 , 0.0);
    rX(headPos , _HeadRotationX);
    rY(headPos , _HeadRotationY);

    // head hole - Fire in the hole! 
    // OK this does not look right. Actually looks like there was "fire in the hole" for 
    // the poor travellers face. Need to come back to it one day and finish it. Maybe! 
   float3 headHole = headPos - float3 (0.0 , 0.1 , -0.07);
   float hole = sdEllipsoid(headHole , float3 (0.05 , 0.03 , 0.04));
   hole = smin(hole , sdEllipsoid(headHole - float3 (0.0 , -0.03 , 0.0) , float3 (0.03 , 0.03 , 0.04)) , 0.05);

   // Cut it OUT! 
  float character = smax(currentDistance.x , -hole , 0.001);

  // face. Meh just an ellipsoid. Need to add eyes and bandana 
 float face = sdEllipsoid(headHole - _FacePosition.xyz , _FaceSize);
 return smin_mat(float2 (face , MAT_CHARACTER_FACE) , float2 (character , currentDistance.y) , 0.01 , 0.2);
}

float2 sdCharacter(float3 pos)
 {
    // Now we are in character space - Booo YA! - I never ever say Boooo YA!. Peter Pimley 
    // says that. Peter: have you been putting comments in my code? 
   pos -= _CharacterPosition;
   float3 scale = _CharacterScale;
   float scaleMul = min(scale.x , min(scale.y , scale.z));

   rY(pos , _CharacterRotation);

   pos /= scale;

   float mainCloak = sdMainCloak(pos);
   float2 mainCloakMat = float2 (mainCloak , MAT_CHARACTER_MAIN_CLOAK);

   float headScarf = sdHeadScarf(pos);
   float2 headScarfMat = float2 (headScarf , MAT_CHARACTER_NECK_SCARF);

   float longScarf = sdScarf(pos);
   float2 longScarfMat = float2 (longScarf , MAT_CHARACTER_LONG_SCARF);
   headScarfMat = smin_mat(headScarfMat , longScarfMat , 0.02 , 0.1);

   float head = sdHead(pos);
   float2 headMat = float2 (head , MAT_CHARACTER_BASE);
   headScarfMat = smin_mat(headScarfMat , headMat , 0.05 , 0.75);

   float2 characterMat = min_mat(mainCloakMat , headScarfMat);
   characterMat = sdFace(pos , characterMat);

   float2 legsMat = float2 (sdLegs(pos) , MAT_CHARACTER_BASE);
   characterMat = min_mat(characterMat , legsMat);

   // chope the bottom. This is to chop the bottom of right leg. Though 
   // I have positioned the character so that the right leg is hidden by terrain. 
   // Commenting it out for now 
// characterMat.x = max ( characterMat.x , - sdPlane ( pos - float3 ( 0.0 , - 0.85 , 0.0 ) ) ) ; 
   characterMat.x *= scaleMul;


   return characterMat;
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Clouds 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdCloud(in float3 pos , float3 cloudPos , float rad , float spread , float phaseOffset , float3 globalParams)
 {
    // Clouds are simple. A bunch of spheres with varying phase offset , size and 
    // frequency values. They are also scaled along the z - Axis so more like circles 
    // than spheres. With additional noise to make them look fluffy. 
    // While rendering them we "perturb" #SpellCheck the normals to get strong specular 
    // highlights 

    // Add noise to the clouds 
   pos += pn(pos) * _CloudNoiseStrength;
   pos = pos - cloudPos;

   // Make us 2d - ish - My artists have confirmed me: 2D is COOL! 
  pos.z /= globalParams.x;

  // Repeat the space 
 float repitition = rad * 2.0 + spread;
 float3 repSpace = pos - mod(pos - repitition * 0.5 , repitition);

 // Create the overall shape to create clouds on 
pos.y += sin(phaseOffset + repSpace.x * 0.23) * globalParams.y;

// Creates clouds with offset on the main path 
pos.y += sin(phaseOffset + repSpace.x * 0.9) * globalParams.z;

// repeated spheres 
pos.x = frac((pos.x + repitition * 0.5) / repitition) * repitition - repitition * 0.5;

// return the spheres 
float sphere = length(pos) - rad;
return sphere * globalParams.x;
}

float2 sdClouds(in float3 pos)
 {
    // Two layers of clouds. A layer in front of the big pyramid 
  float c1 = sdCloud(pos , _FrontCloudsPos , _FrontCloudParams.x , _FrontCloudParams.y , _FrontCloudParams.z , _CloudGlobalParams);
  float c2 = sdCloud(pos , _FrontCloudsPos + _FrontCloudsOffsetA , _FrontCloudParamsA.x , _FrontCloudParamsA.y , _FrontCloudParamsA.z , _CloudGlobalParams);
  float c3 = sdCloud(pos , _FrontCloudsPos + _FrontCloudsOffsetB , _FrontCloudParamsB.x , _FrontCloudParamsB.y , _FrontCloudParamsB.z , _CloudGlobalParams);
  float frontClouds = min(c3 , min(c1 , c2));

  // This plane hides the empty spaces between the front cloud spheres. Not needed 
  // for back spheres , they are covered by front spheres 
    float mainPlane = length(pos.z - _FrontCloudsPos.z) / _CloudGlobalParams.x + (pos.y - _PlaneParams.y + sin(_PlaneParams.x + pos.x * 0.23) * _PlaneParams.z); // - rad ; 
    frontClouds = min(mainPlane * _CloudGlobalParams.x , frontClouds);

    // Second layer behind the big Pyramid 
  float c4 = sdCloud(pos , _BackCloudsPos , _BackCloudParams.x , _BackCloudParams.y , _BackCloudParams.z , _CloudBackGlobalParams);
  float c5 = sdCloud(pos , _BackCloudsPos + _BackCloudsOffsetA , _BackCloudParamsA.x , _BackCloudParamsA.y , _BackCloudParamsA.z , _CloudBackGlobalParams);
  float backClouds = min(c4 , c5);
  return min_mat(float2 (frontClouds , MAT_FRONT_CLOUDS) , float2 (backClouds , MAT_BACK_CLOUDS));
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// This should really be called Kites. No such thing as Flying Helplers... 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float3 helperScarfMatUVW;
float sdHelperScarf(float3 pos , float3 scarfOffset , float3 originalPos)
 {
    float3 scarfPos = pos - scarfOffset;

    float3 scale = _FlyingHelperScarfScale;

    // How far are we from pivot of scarf 
   float distanceToPoint = length(scarfPos);

   // Apply some motion 
  scarfPos += SmoothTriangleWave(float4 (pos.xyz * _FlyingHelperScarfWindDetailParams.x + _Time.y , 1.0)).xyz * _FlyingHelperScarfWindDetailParams.y * distanceToPoint;

  float2 wave;
  wave.x = SmoothTriangleWave(scarfPos.z * _FlyingHelperScarfWindParams.x);
  wave.y = SmoothTriangleWave(scarfPos.z * _FlyingHelperScarfWindParams.z);

  scarfPos.xy += (wave * _FlyingHelperScarfWindParams.y * distanceToPoint);
  float3 pivotOffset = float3 (0.0 , 0.0 , scale.z);
  float scarf = sdBox(scarfPos - pivotOffset , scale);

  // Move us along the z - axis because we chop a sphere in the box. Shows borders otherwise 
 float3 UVWOffset = float3 (0.0 , 0.0 , 1.0);
 helperScarfMatUVW = smoothstep(-1.0 , 1.0 , (scarfPos + UVWOffset - pivotOffset.xzy) / scale);

 // Two scarf on each side of the big'un 
pivotOffset.z = _FlyingHelperSideScarfScale.z;

 wave.y = originalPos.x > 0.0 ? wave.y * _FlyingScarfSideWindParams.x : wave.y * _FlyingScarfSideWindParams.y;
 scarfPos.xy += scarfPos.x > 0.0 ? wave * _FlyingScarfSideWindParams.z : wave * _FlyingScarfSideWindParams.w;

 // legit mirroring! 
scarfPos.x = -abs(scarfPos.x);
float sideScarfs = sdBox(scarfPos - pivotOffset + _FlyingHelperSideScarfOffset , _FlyingHelperSideScarfScale);

// Just override the helperScarfMatUVW value for side scarfs. Too tired to create another variable and use that , not too tired 
// to write this long comment of no value 
helperScarfMatUVW = scarf < sideScarfs ? helperScarfMatUVW : smoothstep(-1.0 , 1.0 , (scarfPos - pivotOffset + _FlyingHelperSideScarfOffset) / _FlyingHelperSideScarfScale);

// Combine'em 
scarf = min(scarf , sideScarfs);
return scarf;
}

float2 sdFlyingHelpers(float3 pos)
 {
     float3 originalPos = pos;
     float flyingHelper = _DrawDistance;

     // Using pos.x to determine , whether we are rendering left or right scarf. 
    float3 helperPos = _FlyingHelperPos;
    helperPos = pos.x > 0.0 ? helperPos - _FlyingHelperMovement : helperPos;

    // Rest is just mirroring 
   pos.x = abs(pos.x);
   pos = pos - helperPos;

   float helperScarf = sdHelperScarf(pos , float3 (0.0 , 0.0 , 0.0) , originalPos);

   // Main helper is a box with a cutout sphere at back. In - game it is more sophisticated. But 
   // I am running out of time. Maybe will do a proper one , one day! 
  float helper = sdBox(pos , _FlyingHelperScale);
  helper = max(helper , -sdSphere(pos - float3 (0.0 , 0.0 , _FlyingHelperScale.z) , _FlyingHelperScale.z));

  // Material and combine scarf with main body 
 float2 helperMat = smin_mat(float2 (helper , MAT_FLYING_HELPERS) , float2 (helperScarf , MAT_FLYING_HELPER_SCARF) , 0.01 , 0.1);
 helperScarfMatUVW = helper < helperScarf ? smoothstep(-1.0 , 1.0 , (pos + float3 (0.0 , 0.0 , _FlyingHelperScale.z * 0.5)) / _FlyingHelperScale) : helperScarfMatUVW;

 return helperMat;
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// The big mountain in the distance. Again , not a pyramid 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdBigMountain(in float3 pos)
 {
    float scaleMul = min(_PyramidScale.x , min(_PyramidScale.y , _PyramidScale.z));
    float3 posPyramid = pos - _PyramidPos;

    // Apply noise derivative , then we can use a blocky looking SAMPLE_TEXTURE2D to make the mountain 
    // look edgy ( for lack of better word ) 
   float derNoise = sin(noised(posPyramid.xz * _PyramidNoisePrams.x).x) * _PyramidNoisePrams.y;
   posPyramid.x = posPyramid.x + derNoise;

   posPyramid /= _PyramidScale;
   float pyramid = sdTriPrism(posPyramid , _PrismScale.xy) * scaleMul;

   // The piercing eye. Which is just an inverted pyrmaid on top of main pyramid. 
  float eyeScale = _PyramidScale.x;

  float3 posEye = pos;
  posEye.y = _PrismEyeScale.z - pos.y;
  posEye.x = pos.x * _PrismEyeWidth;

   float eye = sdTriPrism((posEye - _PyramidEyeOffset) / eyeScale , _PrismEyeScale.xy) * eyeScale;
   return max(pyramid , -eye);
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Main desert shape 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdLargeWaves(in float3 pos)
 {
    // The main shape of terrain. Just sin waves , along X and Z axis , with a power 
    // curve to make the shape more pointy 

   // Manipulate the height as we go in the distance 
   // We want terrain to be a specific way closer to character , showing a path , but the path 
   // gets muddier as wo go in the distance. 

  float distZ = abs(pos.z - _CameraPos.z);
  float distX = abs(pos.x - _CameraPos.x);
  float dist = (distZ)+(distX * 0.1);
  dist = dist * dist * 0.01;

  float detailNoise = noised(pos.xz).x * -2.5;
   float largeWaves = (sin(_LargeWaveOffset.z + pos.z * _LargeWaveDetail.y + pos.z * 0.02)
                          * sin((_LargeWaveOffset.x + dist) + (pos.x * _LargeWaveDetail.x)) * 0.5) + 0.5;
  largeWaves = -_LargeWaveOffset.y + pow(largeWaves , _LargeWavePowStre.x) * _LargeWavePowStre.y - detailNoise * 0.1; // - ( - pos.z * _LargeWavePowStre.z ) ; // 

   // Smoothly merge with the bottom plane of terrain 
  largeWaves = smin(largeWaves , _LargeWavePowStre.z , 0.2);
  largeWaves = (largeWaves - dist);
  return largeWaves * 0.9;
}

float sdSmallWaves(in float3 pos)
 {
    // The small waves are used for adding detail to the main shape of terrain 
   float distanceToCharacter = length(pos.xz - _CharacterPosition.xz);

   // movement to give feel of wind blowing 
  float detailNoise = noised(pos.xz).x * _SmallWaveDetail.z;
   float smallWaves = sin(pos.z * _SmallWaveDetail.y + detailNoise + _Time.y * _WindSpeed.y) *
                          sin(pos.x * _SmallWaveDetail.x + detailNoise + _Time.y * _WindSpeed.x) * _SmallDetailStrength; // * min ( 1.0 , distanceToCharacter ) ; 

   return smallWaves * 0.9;
}

float sdTerrain(in float3 pos)
 {
     float smallWaves = sdSmallWaves(pos);
     float largeWaves = sdLargeWaves(pos);

    return (smallWaves + largeWaves);
 }

float2 sdDesert(in float3 pos , in float terrain)
 {
    float distanceToPos = length(pos.xz - _CameraPos.xz);
    if (distanceToPos > _TerrainMaxDistance)
        return float2 (_DrawDistance , 0.0);

        float mat = 9.0; // length ( pos.xyz ) > 9.0 ? 10.0 : 40.0 ; 
    return float2 (pos.y + terrain , MAT_TERRAIN);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Character trail in the sand 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdCharacterTrail(float3 pos , in float terrain)
 {
     float3 trailOffset = (_CharacterPosition);
     trailOffset.yz += (_CharacterTrailOffset).yz;
    trailOffset.y = -terrain + _CharacterTrailOffset.y;

    float3 trailPos = pos - trailOffset;
    float distanceToPoint = length(trailPos);
    trailPos.x -= _CharacterTrailOffset.x * distanceToPoint;

    // Make it wavy 
   trailPos.x += (SmoothTriangleWave(trailPos.z * _CharacterTrailWave.x) * _CharacterTrailWave.z * distanceToPoint);

   float trail = sdBox(trailPos - float3 (0.0 , 0.0 , _CharacterTrailScale.z) , _CharacterTrailScale);
   return trail;
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// The tombs 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdTombScarf(float3 pos , float3 scarfOffset , float t)
 {
    // scarfs , done same as other scarfs 

  float3 scarfPos = pos - scarfOffset;

  scarfPos = (mul(float4x4(0.9362437, 0, -0.3513514, 0,
      0, 1, 0, 0,
      0.3513514, 0, 0.9362437, 0,
      0, 0, 0, 1), 
      float4 (scarfPos , 1.0))).xyz;

  float3 scale = _TombScarfScale;
  scale.z += (t + 1.0) * 0.2;

  // How far are we from pivot of scarf 
 float distanceToPoint = max(0.0 , length(scarfPos) - 0.1);

 // Make the scarf thicker as it goes out 
scale.x += distanceToPoint * 0.04;

// Apply some motion 
scarfPos.x += (sin(pos.z * _TombScarfWindParams.x + _Time.y) * _TombScarfWindParams.z * distanceToPoint);
scarfPos.y += (sin(pos.z * _TombScarfWindParams.y + _Time.y) * _TombScarfWindParams.z * distanceToPoint);

 float3 pivotOffset = float3 (0.0 , 0.0 , scale.z);
rX(scarfPos , _TombScarfRot + ((t - 0.5) * 0.15) + SmoothTriangleWave((_Time.y + 1.45) * 0.1) * 0.3);

float scarf = sdBox(scarfPos - pivotOffset , scale);
return scarf;
}

float2 sdTombs(in float3 p)
 {
     float2 mainTomb = float2 (_DrawDistance , MAT_TOMB);

     // We draw two tombs , t goes - 1 - > 1 so we can use negative and positive values 
     // to mainpulate them both individually 
    for (float t = -1.0; t <= 1.0; t += 2.0)
     {
         float3 tombPos = (_TombPosition + float3 (-0.25 * t , t * 0.05 , 0.1 * t));

         float3 pos = p - tombPos;
         rZ(pos , 0.1 * t);

         float tombScarf = sdTombScarf(pos , _TombScarfOffset , t + 1.0);

         pos.x = abs(pos.x);

         // Taper them beyond a certain height. Rest is just a rounded box 
        pos.x += abs(pos.y > _TombBevelParams.x ? (pos.y - _TombBevelParams.x) * _TombBevelParams.y : 0.0);
        float tTomb = sdRoundBox(pos , _TombScale , _TombBevelParams.z);

        // Cut out a sphere at top 
       tTomb = max(tTomb , -sdSphere(pos - float3 (0.0 , _TombCutOutScale.x , 0.0) , _TombCutOutScale.y));

       // create scarfs at cut off points 
      float2 tTombMat = min_mat(float2 (tTomb , MAT_TOMB) , float2 (tombScarf , MAT_TOMB_SCARF));
      mainTomb = min_mat(mainTomb , tTombMat);
  }
 return mainTomb;
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// The main map function 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float2 map(in float3 pos)
 {
     float2 character = sdCharacter(pos);
     float2 res = character;

     // I am assuming that since character covers a large portion of screen 
     // This early out should help and same with the terrain. Assumption only , 
     // need to look into it 
   if (res.x > 0.01)
    {
        float desert = sdTerrain(pos);
        float2 terrain = sdDesert(pos , desert);
        float2 trail = float2 (-sdCharacterTrail(pos , desert) , MAT_TERRAIN_TRAIL);
        terrain.y = terrain.x > trail.x ? terrain.y : trail.y;
         terrain.x = smax(terrain.x , trail.x , 0.05);

         res = min_mat(res , terrain);
       if (terrain.x > 0.01)
        {
              float2 tombs = sdTombs(pos);
           res = smin_mat(res , tombs , 0.2 , 0.15);

           float2 pyramid = float2 (sdBigMountain(pos) , MAT_PYRAMID);
           res = min_mat(res , pyramid);

           float2 clouds = sdClouds(pos);
           res = min_mat(res , clouds);

           float2 flyingHelpers = sdFlyingHelpers(pos);
           res = min_mat(res , flyingHelpers);
        }
     }
   return res;
}


// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Used for generating normals. As it turns out that only the big mountain doesn't need 
// normals. Everything else does. Hey Ho! 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float2 mapSimple(in float3 pos)
 {
     return map(pos);
     /*
   float2 character = sdCharacter ( pos ) ;
   float2 flyingHelpers = float2 ( sdFlyingHelpers ( pos ) , 50.0 ) ;
   float2 clouds = sdClouds ( pos ) ;
       float desert = sdTerrain ( pos ) ;
   float2 terrain = sdDesert ( pos , desert ) ;
   terrain.x = smax ( terrain.x , - sdCharacterTrail ( pos , desert ) , 0.1 ) ;
   float2 tombs = float2 ( sdTombs ( pos ) , 50.0 ) ;

   float2 res = character ;
   min_mat ( res , flyingHelpers ) ;
    res = min_mat ( res , clouds ) ;
   res = min_mat ( res , terrain ) ;
   res = min_mat ( res , flyingHelpers ) ;
   res = smin_mat ( res , tombs , 0.2 , 0.15 ) ;
   return res ;
    */
}

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Raycasting: https: // www.shadertoy.com / view / Xds3zN 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float3 castRay(float3 ro , float3 rd)
 {
    float tmin = 0.1;
    float tmax = _DrawDistance;

    float t = tmin;
    float m = -1.0;
    float p = 0.0;
    float maxSteps = _MaxSteps;
    float j = 0.0;
    for (float i = 0.0; i < _MaxSteps; i += 1.0)
     {
        j = i;
         float precis = 0.0005 * t;
         float2 res = map(ro + rd * t);
        if (res.x < precis || t > tmax)
             break;
        t += res.x;
         m = res.y;
     }
     p = j / maxSteps;
    if (t > tmax) m = -1.0;
    return float3 (t , m , p);
 }

float3 calcNormal(in float3 pos)
 {
    float2 e = float2 (1.0 , -1.0) * 0.5773 * 0.0005;
    return normalize(e.xyy * mapSimple(pos + e.xyy).x +
                           e.yyx * mapSimple(pos + e.yyx).x +
                           e.yxy * mapSimple(pos + e.yxy).x +
                           e.xxx * mapSimple(pos + e.xxx).x);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Ambient Occlusion , only applied to the Traveller 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float AmbientOcclusion(float3 p , float3 N , float stepSize , float k)
 {
    float r = 0.0;
    float t = 0.0;

    for (int i = 0; i < 2; i++)
     {
        t += stepSize;
        r += (1.0 / pow(2.0 , t)) * (t - sdCharacter(p + (N * t)).x);
     }
    return max(0.0 , 1.0 - (k * r));
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Simplified version of Traveller for shadow casting 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float sdCharacterShadow(float3 pos)
 {
    pos -= _CharacterPosition;
    float3 scale = _CharacterScale;
    float scaleMul = min(scale.x , min(scale.y , scale.z));

    rY(pos , _CharacterRotation);

    pos /= scale;

    float mainCloak = sdMainCloak(pos);
    float longScarf = sdScarf(pos);

    return min(mainCloak , longScarf) * scaleMul;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Only character , flying helpers and tombs cast shadows. Only terrain recieves shadows 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float softShadow(in float3 ro , in float3 rd , float mint , float maxt , float k)
 {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 100; ++i)
     {
        if (t >= maxt) {
            break;
         }
         float flyingHelpers = sdFlyingHelpers(ro + rd * t).x;
         float tombs = sdTombs(ro + rd * t).x;
        float h = min(sdCharacterShadow(ro + rd * t) , min(flyingHelpers , tombs));
        if (h < 0.001)
            return 0.1;
        res = min(res , k * h / t);
        t += h;
     }
     return res;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// Hi Hussain! 
// Again , somebody wrote Hi Hussain here. It wasn't me , but hi back atcha! 
// Sky 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float3 sky(float3 ro , float3 rd)
 {
    // Sun calculation 
   float sunDistance = length(_SunPosition);

   float3 delta = _SunPosition.xyz - (ro + rd * sunDistance);
   float dist = length(delta);

   // Turn Sun into a star , because the big mountain has a star like shape 
   // coming from top 
  delta.xy *= _SunStar.xy;
  float sunDist = length(delta);
  float spot = 1.0 - smoothstep(0.0 , _SunSize , sunDist);
  float3 sun = clamp(_SunScale * spot * spot * spot , 0.0 , 1.0) * _SunColor.rgb;

  // Changing color on bases of distance from Sun. To get a strong halo around 
  // the sun 
    float expDist = clamp((dist - _ExposureOffset) * _ExposureStrength , 0.0 , 1.0);
    float expControl = pow(expDist , _ExposurePower);

    // Sky colors 
   float y = rd.y;
   float zen = 1.0 - pow(min(1.0 , 1.0 - y) , _ZenithFallOff);
   float3 zenithColor = _Zenith.rgb * zen;
   zenithColor = lerp(_SunColor.rgb , zenithColor , expControl);

   float nad = 1.0 - pow(min(1.0 , 1.0 + y) , _NadirFallOff);
   float3 nadirColor = _Nadir.rgb * nad;

   float hor = 1.0 - zen - nad;
   float3 horizonColor = _Horizon.rgb * hor;

   // Add stars for Color Scheme 3 
float stars = 0.0;
#if COLOR_SCHEME == 3 
    float3 starPos = ro + ((rd + float3 (_Time.y * 0.001 , 0.0 , 0.0)) * sunDistance);
    starPos.xyz += _Time.y * 0.01 + noised(starPos.xy) * 3.0;

    starPos = mod(starPos , 1.5) - 0.75;
    stars = length(starPos);

     float starsA = (step(0.9 , 1.0 - stars) * 1.0 - (stars)) * 2.0;
     float starsB = (step(0.93 , 1.0 - stars) * 1.0 - (stars)) * 1.5;
     stars = starsA + starsB;

    stars = stars * pow(zen * expControl , 5.0);
    stars = step(0.01 , stars) * stars * 2.0;
#endif 
    return stars + (sun * _SunStar.z + zenithColor + horizonColor + nadirColor);
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
// The rendering , based on: https: // www.shadertoy.com / view / Xds3zN 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == 
float3 render(in float3 ro , in float3 rd)
 {
    // res.z contains the iteration count / max iterations. This gives kind of a nice glow 
    // effect around foreground objects. Looks particularly nice on sky , with clouds in 
    // front and also on terrain. Gives rim kind of look! 
   float3 res = castRay(ro , rd);
   float3 skyCol = sky(ro , rd);
   float3 col = skyCol;

   #if defined ( DEBUG_PERFORMANCE ) 
   return (res.z);
   #endif 

   float t = res.x;
   float m = res.y;

   float3 pos = ro + t * rd;

   // Return sky 
  if (m < 0.0)
   {
      // Bloom for the background clouds. We want Big Mountain to be engulfed with fog. So just chop out 
      // areas around right and left side of BigMountain for creating fake bloom for background clouds by 
      // using the iteration count needed to generate the distance function 
     float rightSideCloudDist = length((ro + rd * length(_SunPosition)) - float3 (45.0 , -5.0 , _SunPosition.z));
     float leftSideCloudDist = length((ro + rd * length(_SunPosition)) - float3 (-50.0 , -5.0 , _SunPosition.z));
     if (rightSideCloudDist < 40.0)
      {
          float smoothCloudBloom = 1.0 - smoothstep(0.8 , 1.0 , rightSideCloudDist / 40.0);
          return col + res.z * res.z * 0.2 * smoothCloudBloom;
      }
     else if (leftSideCloudDist < 40.0)
      {
          float smoothCloudBloom = 1.0 - smoothstep(0.8 , 1.0 , leftSideCloudDist / 40.0);
          return col + res.z * res.z * 0.2 * smoothCloudBloom;
      }
   else
          return col;
 }

float skyFog = 1.0 - exp(_FogMul * t * pow(pos.y , _FogPow));
#if defined ( DEBUG_FOG ) 
return (skyFog);
#endif 

// Render the big mountain. Keep track of it's color , so we can use it for transparency for clouds later 
float3 pyramidCol = float3 (0.0 , 0.0 , 0.0);
pyramidCol = lerp(_PyramidCol , skyCol , skyFog * 0.5);

if (TEST_MAT_LESS(m , MAT_PYRAMID))
 {
    // Height fog , with strong fade to sky 
   float nh = (pos.y / _PyramidHeightFog.x);
   nh = nh * nh * nh * nh * nh;
   float heightFog = pow(clamp(1.0 - (nh) , 0.0 , 1.0) , _PyramidHeightFog.y);
   heightFog = clamp(heightFog , 0.0 , 1.0);
   pyramidCol = lerp(pyramidCol , skyCol , heightFog);
   return pyramidCol;
}

// Calculate normal after calculating sky and big mountain 
float3 nor = calcNormal(pos);
// Terrain: https: // archive.org / details / GDC2013Edwards 
if (TEST_MAT_LESS(m , MAT_TERRAIN_TRAIL))
 {
     float shadow = softShadow(pos - (rd * 0.01) , _LightDir.xyz , _TerrainShadowParams.x , _TerrainShadowParams.y , _TerrainShadowParams.z);
     shadow = clamp(shadow + _TerrainShadowParams.w , 0.0 , 1.0);

     float3 shadowCol = lerp(shadow * _TerrainShadowColor , _TerrainDistanceShadowColor , pow(skyFog , _TerrainFogPower * _TerrainDistanceShadowPower));

     // Strong rim lighting 
    float rim = (1.0 - saturate(dot(nor , -rd)));
    rim = saturate(pow(rim , _TerrainRimPower)) * _TerrainRimStrength;
    float3 rimColor = rim * _TerrainRimColor;

    // Specular highlights 
   float3 ref = reflect(rd , nor);
  float3 halfDir = normalize(_LightDir + rd);

  // The strong ocean specular highlight 
 float mainSpec = clamp(dot(ref , halfDir) , 0.0 , 1.0);
 if (TEST_MAT_LESS(m , MAT_TERRAIN))
     mainSpec = pow(mainSpec , _TerrainSpecPower) * _TerrainSpecStrength * 2.0;
 else
     mainSpec = pow(mainSpec , _TerrainSpecPower) * _TerrainSpecStrength * 4.0;

 float textureGlitter = SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , pos.xz * _TerrainGlitterRep , 2.2).x * 1.15;
 textureGlitter = pow(textureGlitter , _TerrainGlitterPower);
 mainSpec *= textureGlitter;

 // The glitter around terrain , looks decent based on rim value 
float rimSpec = (pow(rim , _TerrainRimSpecPower)) * textureGlitter;
float3 specColor = (mainSpec + rimSpec) * _TerrainSpecColor;
 float3 terrainCol = lerp((rimColor + specColor * shadow) + _TerrainCol , skyCol , pow(skyFog , _TerrainFogPower)) + res.z * 0.2;

 // maybe add a fake AO from player , just a sphere should do! 
return lerp(shadowCol , terrainCol , shadow);
}

// Clouds 
if (TEST_MAT_LESS(m , MAT_FRONT_CLOUDS))
 {
    // Modify the normals so that they create strong specular highlights 
    // towards the top edge of clouds 
   nor = normalize(nor + _CloudNormalMod);
   float dotProd = dot(nor , float3 (1.0 , -3.5 , 1.0));

   float spec = 1.0 - clamp(pow(dotProd , _CloudSpecPower) , 0.0 , 1.0);
   spec *= 2.0;
   float3 cloudCol = spec * _CloudSpecCol + _CloudCol;

   // Transparency for mountain 
  if (sdBigMountain(pos + (rd * t * _CloudPyramidDistance)) < 0.2)
    {
        cloudCol = lerp(pyramidCol , cloudCol , _CloudTransparencyMul);
   }

  // Mixing for backdrop mountains. Backdrop mountains take more color from Sky. Foreground mountains 
  // retain their own color values , so I can adjust their darkness 
 float3 inCloudCol = lerp(cloudCol , _BackCloudCol + skyCol * 0.5 + spec * _BackCloudSpecCol , MAT_FRONT_CLOUDS - m);
 return lerp(inCloudCol , skyCol , skyFog * _CloudFogStrength);
}

// Tombs 
if (TEST_MAT_LESS(m , MAT_TOMB_SCARF))
 {
    // Simple strong diffuse 
   float diff = clamp(dot(nor , _LightDir) + 1.0 , 0.0 , 1.0);
   float3 col = lerp(_TombMainColor , _TombScarfColor * 2.0 , m - MAT_TOMB);
   return lerp(diff * col , skyCol , skyFog);
}

// Flying Helpers 
if (TEST_MAT_LESS(m , MAT_FLYING_HELPER_SCARF))
 {
     float fres = pow(clamp(1.0 + dot(nor , rd) + 0.75 , 0.0 , 1.0) , _FlyingHelperFrePower) * _FlyingHelperFreScale;
     float diff = clamp(dot(nor , _LightDir) + 1.5 , 0.0 , 1.0);
     float3 col = _FlyingHelperYellowColor;

     // The main head 
    if (TEST_MAT_LESS(m , MAT_FLYING_HELPERS))
     {
         col = _FlyingHelperMainColor;

         // Yellow borders 
        float outerBorder = step(0.95 , abs(helperScarfMatUVW.x * 2.0 - 1.0));
        col = lerp(col * diff , _FlyingHelperYellowColor , outerBorder);

        // cubes in middle 
       float rectsY = abs(helperScarfMatUVW.z * 2.0 - 1.0);
       float rectsX = abs(helperScarfMatUVW.x * 2.0 - 1.0);

       float circles = 1.0 - (length(float2 (rectsY , rectsX)) - 0.1);
       circles = step(0.5 , circles);

       // Ideally want to do a separate bass for bloom. maybe one day 
      float bloomCircle = 1.0 - (length(float2 (rectsY , rectsX)) - 0.1);
      float bloom = max(bloomCircle - 0.5 , 0.0);

      rectsY = step(0.5 , abs(rectsY * 2.0 - 1.0));
      rectsX = 1.0 - step(0.5 , abs(helperScarfMatUVW.x * 2.0 - 1.0));

      float rects = min(rectsX , rectsY);

      float symbolsX = frac(rects / (helperScarfMatUVW.z * 20.0) * 20.0);
      float symbolsY = frac(rects / (helperScarfMatUVW.x * 2.0) * 2.0);
      float symbolsZ = frac(rects / ((helperScarfMatUVW.z + 0.1) * 16.0) * 16.0);
      float symbolsW = frac(rects / ((helperScarfMatUVW.x + 0.1) * 3.0) * 3.0);

      float symbols = symbolsY;
      symbols = max(symbols , symbolsZ);
      symbols = min(symbols , max(symbolsX , symbolsW));
      symbols = step(0.5 , symbols);

      symbols = min(symbols , circles);

      // float rects = min ( rectsX , max ( circles , rectsY ) ) ; 

     col = lerp(col , _FlyingHelperYellowColor , circles);
     col = lerp(col , _FlyingHelperWhiteColor * 2.0 , symbols) + bloom * _FlyingHelperBloomScale;
 }
else
 {
        // The scarfs , just have a yellow border 
       float outerBorder = step(0.9 , abs(helperScarfMatUVW.x * 2.0 - 1.0));
       col = lerp(_FlyingHelperMainColor * diff , _FlyingHelperYellowColor , outerBorder);
   }
  return lerp(fres * col , skyCol , skyFog * _FlyingHelperFogScale);
}

// Character 
if (TEST_MAT_GREATER(m , MAT_CHARACTER_BASE))
 {
     float diff = _CharacterDiffScale * clamp(dot(nor , _LightDir) , 0.0 , 1.0);

     // Why did I fudge these normals , I can't remember. It does look good though , so keep it : ) 
    nor = normalize(nor + float3 (0.3 , -0.1 , 1.0));
    nor.y *= 0.3;

    float fres = pow(clamp(1.0 + dot(nor , rd) + 0.75 , 0.0 , 1.0) , _CharacterFrePower) * _CharacterFreScale;
    float3 col = _CharacterMainColor;

    // Just base color 
   if (TEST_MAT_LESS(m , MAT_CHARACTER_BASE))
    {
       // Add sand fade to legs. Mixing terrain color at bottom of legs 
      float heightTerrainMix = pow((pos.y / _CharacterHeightTerrainMix.x) , _CharacterHeightTerrainMix.y);
      heightTerrainMix = clamp(heightTerrainMix , 0.0 , 1.0);
      col = lerp(_CharacterMainColor , _CharacterTerrainCol , heightTerrainMix);
  }
   // Main Cloak 
  else if (TEST_MAT_LESS(m , MAT_CHARACTER_MAIN_CLOAK))
   {
       // Cone kind of shapes 
      float rectsX = frac(atan2(mainCloakMatUVW.x / mainCloakMatUVW.z, mainCloakMatUVW.x / mainCloakMatUVW.z) * 7.0);
      rectsX = abs(rectsX * 2.0 - 1.0);
      float rects = rectsX;
      rects = step(0.5 , rects * (1.0 - mainCloakMatUVW.y * 3.5));
      col = lerp(col , _CharacterCloakDarkColor , rects);

      // Yellow borders , two lines 
     float outerBorder = step(0.915 , abs(mainCloakMatUVW.y * 2.0 - 1.0));
     float betweenBorders = step(0.88 , abs(mainCloakMatUVW.y * 2.0 - 1.0));
     float innerBorder = step(0.87 , abs(mainCloakMatUVW.y * 2.0 - 1.0));

     innerBorder = min(innerBorder , 1.0 - betweenBorders);

     col = lerp(col , _CharacterCloakDarkColor , betweenBorders);
     col = lerp(col , _CharacterYellowColor , outerBorder);
     col = lerp(col , _CharacterYellowColor , innerBorder);

     // The verticle cubes / lines running across the bottom of cloak 
    float cubes = abs(frac(atan2(mainCloakMatUVW.x / mainCloakMatUVW.z, mainCloakMatUVW.x / mainCloakMatUVW.z) * 10.0) * 2.0 - 1.0);
    cubes = min(betweenBorders , step(0.9 , cubes));
    col = lerp(col , _CharacterYellowColor , cubes);
}
   // headscarf 
  else if (TEST_MAT_LESS(m , MAT_CHARACTER_NECK_SCARF))
   {
       col = lerp(col , _CharacterYellowColor , step(0.7 , headScarfMatUVW.y));
   }
   // Long Scarf 
  else if (TEST_MAT_LESS(m , MAT_CHARACTER_LONG_SCARF))
   {
       col = _CharacterYellowColor;

       // Yellow borders , two lines 
      float outerBorder = step(0.9 , abs(longScarfMatUVW.x * 2.0 - 1.0));
      float innerBorder = step(0.7 , abs(longScarfMatUVW.x * 2.0 - 1.0));

      innerBorder = min(innerBorder , 1.0 - step(0.8 , abs(longScarfMatUVW.x * 2.0 - 1.0)));

      // Mix borders 
     col = lerp(col , _CharacterMainColor , outerBorder);
     col = lerp(col , _CharacterMainColor , innerBorder);

     // cubes in middle 
    float rectsY = abs(frac(longScarfMatUVW.y / 0.10) * 2.0 - 1.0); // - 0.5 * 0.10 ; 
    float rectsX = abs(longScarfMatUVW.x * 2.0 - 1.0);

    float circles = 1.0 - (length(float2 (rectsY , rectsX)) - 0.1);
    circles = step(0.5 , circles);

    float bloomCircle = 1.0 - (length(float2 (rectsY , rectsX * 0.7)) - 0.1);
    float bloom = max(bloomCircle - 0.45 , 0.0);

    rectsY = step(0.5 , abs(rectsY * 2.0 - 1.0));
    rectsX = 1.0 - step(0.5 , abs(longScarfMatUVW.x * 2.0 - 1.0));

    float rects = min(rectsX , rectsY);

    // There are better ways of doing symbols. Spend some time on it , buddy! 
   float symbolsX = frac(rects / (longScarfMatUVW.y * 0.17) * 10.0);
   float symbolsY = frac(rects / (longScarfMatUVW.x * 18.5) * 10.0);

   float symbols = symbolsX;
   symbols = max(symbols , symbolsY);
   symbols = step(0.5 , symbols);

   symbols = min(symbols , circles);

   // float rects = min ( rectsX , max ( circles , rectsY ) ) ; 
  col = lerp(col , _CharacterMainColor , circles);
  col = lerp(col , _CharacterWhiteColor * 2.0 , symbols) + bloom * _CharacterBloomScale;

  // White glow and disintegrating the scarf , showing depleting scarf energy. Needs bloom effect : ( 
 col = lerp(col , _CharacterMainColor , 1.0 - smoothstep(0.4 , 0.6 , longScarfMatUVW.y));
 float3 whiteMiddle = lerp(col , _CharacterWhiteColor + bloom * _CharacterBloomScale , step(0.48 , longScarfMatUVW.y));
 col = lerp(whiteMiddle , col , step(0.5 , longScarfMatUVW.y));
}
   // Face 
  else if (TEST_MAT_LESS(m , MAT_CHARACTER_FACE))
   {
       col = float3 (0 , 0 , 0);
   }
  float ao = AmbientOcclusion(pos - (rd * 0.01) , nor , _CharacterAOParams.x , _CharacterAOParams.y);
  return ao * lerp((fres + diff) * col , skyCol , skyFog * _CharacterFogScale);
}
return float3 (clamp(col * 0.0 , 0.0 , 1.0));
}


float rand(float n)
 {
     return frac(sin(n) * 43758.5453123);
 }

float noise(float p)
 {
     float fl = floor(p);
     float fc = frac(p);
    fc = fc * fc * (3.0 - 2.0 * fc);
    return lerp(rand(fl) , rand(fl + 1.0) , fc);
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// Move camera using noise. This is probably quite expensive way of doing it : ( 
float unitNoiseX = (noise(_Time.y * _CameraMovement.w) * 2.0) - 1.0;
float unitNoiseY = (noise((_Time.y * _CameraMovement.w) + 32.0) * 2.0) - 1.0;
float unitNoiseZ = (noise((_Time.y * _CameraMovement.w) + 48.0) * 2.0) - 1.0;
float3 ro = _CameraPos + float3 (unitNoiseX , unitNoiseY , unitNoiseZ) * _CameraMovement.xyz;


float3 screenRay = float3 (fragCoord / _ScreenParams.xy , 1.0);
float2 screenCoord = screenRay.xy * 2.0 - 1.0;

// Screen ray frustum aligned 
screenRay.xy = screenCoord * _CameraFOV.xy;
screenRay.x *= 1.35;
 screenRay.z = -_CameraFOV.z;
 screenRay /= abs(_CameraFOV.z);

 // In camera space 
 float3 rd = normalize(
     mul(float4x4(1, 0, 0, 1.04,
         0, 0.9684963, 0.2490279, 2.2,
         0, 0.2490279, -0.9684963, 18.6,
         0, 0, 0, 1), 
         float4 (screenRay , 0.0))).xyz;

 // Do the render 
float4 col = float4 (render(ro , rd) , 0.0);

// No it does not need gamma correct or tone mapping or any other effect that you heard about 
// and thought was cool. This is not realistic lighting 

// vignette 
float vig = pow(1.0 - 0.4 * dot(screenCoord , screenCoord) , 0.6) * 1.25;
vig = min(vig , 1.0);
col *= vig;

// Final color 
fragColor = col;
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