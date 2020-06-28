Shader "UmutBebek/URP/ShaderToy/Real-Time Atmospheric Scattering wllyW4"
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

             //#define PI 3.14159265359 

            // Dimensions 
           #define PLANET_RADIUS 6371e3 
           #define ATMOSPHERE_HEIGHT 100e3 
           #define RAYLEIGH_HEIGHT 8e3 
           #define MIE_HEIGHT 1.2e3 
           #define OZONE_PEAK_LEVEL 30e3 
           #define OZONE_FALLOFF 3e3 
            // Scattering coefficients 
           #define BETA_RAY float3 ( 3.8e - 6 , 13.5e - 6 , 33.1e - 6 ) // float3 ( 5.5e - 6 , 13.0e - 6 , 22.4e - 6 ) 
           #define BETA_MIE float3 ( 21e - 6 , 21e - 6 , 21e - 6 ) 
           #define BETA_OZONE float3 ( 2.04e - 5 , 4.97e - 5 , 1.95e - 6 ) 
           #define G 0.75 
            // Samples 
           #define SAMPLES 8
           #define LIGHT_SAMPLES 2 // Set to more than 1 for a realistic , less vibrant sunset 

            // Other 
           #define SUN_ILLUMINANCE 128000.0 
           #define MOON_ILLUMINANCE 0.32 
           #define SPACE_ILLUMINANCE 0.01 

           const float ATMOSPHERE_RADIUS = PLANET_RADIUS + ATMOSPHERE_HEIGHT;

           /* *
            * Computes entry and exit points of ray intersecting a sphere.
            *
            * @param origin ray origin
            * @param dir normalized ray direction
            * @param radius radius of the sphere
            *
            * @return .x - position of entry pointExtended relative to the ray origin | .y - position of exit pointExtended relative to the ray origin | if there's no intersection at all , .x is larger than .y
            */
          float2 raySphereIntersect(in float3 origin , in float3 dir , in float radius) {
               float a = dot(dir , dir);
               float b = 2.0 * dot(dir , origin);
               float c = dot(origin , origin) - (radius * radius);
               float d = (b * b) - 4.0 * a * c;

               if (d < 0.0) return float2 (1.0 , -1.0);
               return float2 (
                     (-b - sqrt(d)) / (2.0 * a) ,
                     (-b + sqrt(d)) / (2.0 * a)
                );
           }

          /* *
           * Phase function used for Rayleigh scattering.
           *
           * @param cosTheta cosine of the angle between light vector and view direction
           *
           * @return Rayleigh phase function value
           */
         float phaseR(in float cosTheta) {
             return (3.0 * (1.0 + cosTheta * cosTheta)) / (16.0 * PI);
          }

         /* *
          * Henyey - Greenstein phase function , used for Mie scattering.
          *
          * @param cosTheta cosine of the angle between light vector and view direction
          * @param g scattering factor | - 1 to 0 - backward | 0 - isotropic | 0 to 1 - forward
          *
          * @return Henyey - Greenstein phase function value
          */
        float phaseM(in float cosTheta , in float g) {
             float gg = g * g; 
             return (1.0 - gg) / (4.0 * PI * pow(abs(1.0 + gg - 2.0 * g * cosTheta ), 1.5));
         }

        /* *
         * Approximates density values for a given pointExtended around the planet.
         *
         * @param pos position of the pointExtended , for which densities are calculated
         *
         * @return .x - Rayleigh density | .y - Mie density | .z - ozone density
         */
       float3 avgDensities(in float3 pos) {
            float height = length(pos) - PLANET_RADIUS; // Height above surface 
            float3 density;
            density.x = exp(-height / RAYLEIGH_HEIGHT);
            density.y = exp(-height / MIE_HEIGHT);
           density.z = (1.0 / cosh((OZONE_PEAK_LEVEL - height) / OZONE_FALLOFF)) * density.x; // Ozone absorption scales with rayleigh 
           return density;
        }

       /* *
        * Calculates atmospheric scattering value for a ray intersecting the planet.
        *
        * @param pos ray origin
        * @param dir ray direction
        * @param lightDir light vector
        *
        * @return sky color
        */
      float3 atmosphere(
           in float3 pos ,
           in float3 dir ,
           in float3 lightDir
       ) {
          // Intersect the atmosphere 
        float2 intersect = raySphereIntersect(pos , dir , ATMOSPHERE_RADIUS);

        // Accumulators 
       float3 opticalDepth = float3 (0.0 , 0.0 , 0.0); // Accumulated density of particles participating in Rayleigh , Mie and ozone scattering respectively 
      float3 sumR = float3 (0.0 , 0.0 , 0.0);
      float3 sumM = float3 (0.0 , 0.0 , 0.0);

      // Here's the trick - we clamp the sampling length to keep precision at the horizon 
      // This introduces banding , but we can compensate for that by scaling the clamp according to horizon angle 
     float rayPos = max(0.0 , intersect.x);
     float maxLen = ATMOSPHERE_HEIGHT;
     maxLen *= (1.0 - abs(dir.y) * 0.5);
      float stepSize = min(intersect.y - rayPos , maxLen) / float(SAMPLES);
     rayPos += stepSize * 0.5; // Let's sample in the center 

     for (int i = 0; i < SAMPLES; i++) {
         float3 samplePos = pos + dir * rayPos; // Current sampling position 

            // Similar to the primary iteration 
           float2 lightIntersect = raySphereIntersect(samplePos , lightDir , ATMOSPHERE_RADIUS); // No need to check if intersection happened as we already are inside the sphere 

         float3 lightOpticalDepth = float3 (0.0 , 0.0 , 0.0);

         // We're inside the sphere now , hence we don't have to clamp ray pos 
        float lightStep = lightIntersect.y / float(LIGHT_SAMPLES);
        float lightRayPos = lightStep * 0.5; // Let's sample in the center 

        for (int j = 0; j < LIGHT_SAMPLES; j++) {
            float3 lightSamplePos = samplePos + lightDir * (lightRayPos);

               lightOpticalDepth += avgDensities(lightSamplePos) * lightStep;

            lightRayPos += lightStep;
         }

        // Accumulate optical depth 
       float3 densities = avgDensities(samplePos) * stepSize;
       opticalDepth += densities;

       // Accumulate scattered light 
    float3 scattered = exp(-(BETA_RAY * (opticalDepth.x + lightOpticalDepth.x) + BETA_MIE * (opticalDepth.y + lightOpticalDepth.y) + BETA_OZONE * (opticalDepth.z + lightOpticalDepth.z)));
    sumR += scattered * densities.x;
    sumM += scattered * densities.y;

    rayPos += stepSize;
 }

float cosTheta = dot(dir , lightDir);

return max(
    phaseR(cosTheta) * BETA_RAY * sumR + // Rayleigh color 
        phaseM(cosTheta , G) * BETA_MIE * sumM , // Mie color 
     0.0
 );
}

      /* *
       * Draws a blackbody as seen from the planet.
       *
       * @param dir ray direction
       * @param lightDir light vector
       *
       * @return blackbody color
       */
     float3 renderBlackbody(in float3 dir , in float3 lightDir) {
         float cosTheta = dot(dir , lightDir);

         float intensity = smoothstep(0.998 , 0.999 , cosTheta);
         float glow = pow(max(cosTheta , 0.0) , 4.0) * 0.01;

         float fade = smoothstep(0.05 , 0.25 , dir.y);
         float glowFade = smoothstep(0.05 , 0.25 , lightDir.y);

         return float3 (intensity + glow * glowFade , intensity + glow * glowFade , intensity + glow * glowFade) * fade;
      }

     /* *
      * Calculates daylight factor at given sun height.
      *
      * @param sunHeight sun height
      *
      * @return daylight factor in range < 0.0 , 1.0 >
      */
    float getDayFactor(in float sunHeight) {
        return pow(smoothstep(-0.6 , 0.6 , sunHeight) , 8.0);
     }

    /* *
     * Computes shadow light illuminance at given sun height.
     *
     * @param sunHeight sun height
     *
     * @return shadow light illuminance
     */
   float getShadowIlluminance(in float sunHeight) {
       return lerp(MOON_ILLUMINANCE , SUN_ILLUMINANCE , getDayFactor(sunHeight - 0.2));
    }

   /* *
    * Rotates two dimensional coordinate around the origin.
    *
    * @param coord two - component coordinate
    * @param angle rotation angle in radians
    *
    * @return rotated coordinate
    */
  float2 rotate(in float2 coord , float angle) {
      float2 t = float2 (sin(angle) , cos(angle));
      return float2 (coord.x * t.y - coord.y * t.x , dot(coord , t));
   }

  /* *
   * Calculates the view direction of a pixel based on its location.
   *
   * @param uv fragment position in range [0.0 , 1.0] on both axes
   *
   * @return normalized view direction
   */
 float3 viewDir(in float2 uv , in float ratio) {
     uv = uv * 2.0 - 1.0;
      uv.x *= ratio;
      return normalize(float3 (uv.x , uv.y , -1.0));

      // float2 t = ( ( uv * 2.0 ) - float2 ( 1.0 , 1.0 ) ) * float2 ( PI , PI * 0.5 ) ; 
     // return normalize ( float3 ( cos ( t.y ) * cos ( t.x ) , sin ( t.y ) , cos ( t.y ) * sin ( t.x ) ) ) ; 
 }

 /* *
  * Transforms HDR color to LDR space using the ACES operator.
  * Ported from original source:
  * https: // knarkowicz.wordpress.com / 2016 / 01 / 06 / aces - filmic - tone - mapping - curve
  * For a more accurate curve , head to:
  * https: // github.com / TheRealMJP / BakingLab / blob / master / BakingLab / ACES.hlsl
  *
  * @param color HDR color
  *
  * @return LDR color
  */
float3 tonemapACES(in float3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e) , 0.0 , 1.0);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = fragCoord.xy / _ScreenParams.xy;
    float ratio = _ScreenParams.x / _ScreenParams.y;
    float2 mouse = iMouse.xy / _ScreenParams.xy;

     float3 pos = float3 (0.0 , PLANET_RADIUS + 2.0 , 0.0);
     float3 dir = viewDir(uv , ratio);
     // Clamp dir.y to mask the dark part of the sky 
     // dir.y = dir.y < 0.03 ? ( dir.y - 0.03 ) * 0.2 + 0.03 : dir.y ; 
     float3 sunDir = iMouse.x == 0.0  && iMouse.y == 0.0 ? float3 (0.0 , -0.03 , -1.0) : viewDir(mouse , ratio);
    dir = normalize(dir);
    sunDir = normalize(sunDir);

    float shadowIlluminance = getShadowIlluminance(sunDir.y);
    // Sky 
   float3 color = atmosphere(pos , dir , sunDir) * shadowIlluminance;
  color += atmosphere(pos , dir , -sunDir) * shadowIlluminance;
  // Blackbodies 
 color += renderBlackbody(dir , sunDir) * shadowIlluminance;
 color += renderBlackbody(dir , -sunDir) * shadowIlluminance;
 // Space ( use a cube map with 3 dimensional rotation in real applications ) 
color += SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , rotate(uv , _Time.y * 0.01) * 2.0).xyz * getDayFactor(dir.y + 0.25) * SPACE_ILLUMINANCE;

// Tonemapping 
float exposure = 16.0 / shadowIlluminance;
exposure = min(exposure , 16.0 / (MOON_ILLUMINANCE * 8.0)); // Clamp the exposure to make night appear darker 
color = tonemapACES(color * exposure);
color = pow(color , float3 (1.0 / 2.2 , 1.0 / 2.2 , 1.0 / 2.2));

fragColor = float4 ((color).x , (color).y , (color).z , 1.0);
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