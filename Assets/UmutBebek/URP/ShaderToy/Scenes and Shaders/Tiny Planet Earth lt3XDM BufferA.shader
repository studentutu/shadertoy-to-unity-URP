Shader "UmutBebek/URP/ShaderToy/Tiny Planet: Earth lt3XDM BufferA"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        [MaterialToggle]autoRotate("autoRotate", float) = 1
[MaterialToggle]showBackground("showBackground", float) = 1
[MaterialToggle]showPlanet("showPlanet", float) = 1
[MaterialToggle]showClouds("showClouds", float) = 1
[MaterialToggle]debugMaterials("debugMaterials", float) = 0
pi("pi", float) = 3.1415926535
degrees("degrees", float) = pi / 180.0
inf("inf", float) = 1.0 / 1e - 10
verticalFieldOfView("verticalFieldOfView", float) = 25.0 * degrees
w_i("w_i", vector) = Vector3(1.0 , 1.3 , 0.6) / 1.7464
B_i("B_i", vector) = Biradiance3(2.9)
planetCenter("planetCenter", vector) = Point3(0)
planetMaxRadius("planetMaxRadius", float) = 1.0
cloudMinRadius("cloudMinRadius", float) = 0.85
atmosphereColor("atmosphereColor", vector) = Color3(0.3 , 0.6 , 1.0) * 1.6
ROCK("ROCK", vector) = Material(Color3(0.50 , 0.35 , 0.15) , 0.0 , 0.0)
TREE("TREE", vector) = Material(Color3(0.05 , 1.15 , 0.10) , 0.2 , 0.1)
SAND("SAND", vector) = Material(Color3(1.00 , 1.00 , 0.85) , 0.0 , 0.0)
ICE("ICE", vector) = Material(Color3(0.85 , 1.00 , 1.20) , 0.2 , 0.6)

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
            float autoRotate;
float showBackground;
float showPlanet;
float showClouds;
float debugMaterials;
float Vector2;
float Point3;
float Vector3;
float Color3;
float Radiance3;
float Radiance4;
float Irradiance3;
float Power3;
float Biradiance3;
float pi;
float degrees;
float inf;
float verticalFieldOfView;
float4 w_i;
float4 B_i;
float4 planetCenter;
float planetMaxRadius;
float cloudMinRadius;
float4 atmosphereColor;
float4 ROCK;
float4 TREE;
float4 SAND;
float4 ICE;


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









#define time ( _Time.y ) 


                   // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // / 
                   // Morgan's standard Shadertoy helpers 














                  float square(float x) { return x * x; }
                  float pow3(float x) { return x * square(x); }
                  float pow4(float x) { return square(square(x)); }
                  float pow8(float x) { return square(pow4(x)); }
                  float pow5(float x) { return x * square(square(x)); }
                  float infIfNegative(float x) { return (x >= 0.0) ? x : inf; }

                  struct Ray { Point3 origin; Vector3 direction; };
                  struct Material { Color3 color; float metal; float smoothness; };
                  struct Surfel { Point3 position; Vector3 normal; Material material; };
                  struct Sphere { Point3 center; float radius; Material material; };

                  /* * Analytic ray - sphere intersection. */
                 bool intersectSphere(Point3 C , float r , Ray R , inout float nearDistance , inout float farDistance) { Point3 P = R.origin; Vector3 w = R.direction; Vector3 v = P - C; float b = 2.0 * dot(w , v); float c = dot(v , v) - square(r); float d = square(b) - 4.0 * c; if (d < 0.0) { return false; } float dsqrt = sqrt(d); float t0 = infIfNegative((-b - dsqrt) * 0.5); float t1 = infIfNegative((-b + dsqrt) * 0.5); nearDistance = min(t0 , t1); farDistance = max(t0 , t1); return (nearDistance < inf); }

                 // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // / 
                 // The following are from https: // www.shadertoy.com / view / 4dS3Wd 
                float hash(float p) { p = frac(p * 0.011); p *= p + 7.5; p *= p + p; return frac(p); }
                float hash(float2 p) { float3 p3 = frac(float3 (p.xyx) * 0.13); p3 += dot(p3 , p3.yzx + 3.333); return frac((p3.x + p3.y) * p3.z); }
                float noise(float x) { float i = floor(x); float f = frac(x); float u = f * f * (3.0 - 2.0 * f); return lerp(hash(i) , hash(i + 1.0) , u); }
                float noise(float2 x) { float2 i = floor(x); float2 f = frac(x); float a = hash(i); float b = hash(i + float2 (1.0 , 0.0)); float c = hash(i + float2 (0.0 , 1.0)); float d = hash(i + float2 (1.0 , 1.0)); float2 u = f * f * (3.0 - 2.0 * f); return lerp(a , b , u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y; }
                float noise(float3 x) { const float3 step = float3 (110 , 241 , 171); float3 i = floor(x); float3 f = frac(x); float n = dot(i , step); float3 u = f * f * (3.0 - 2.0 * f); return lerp(lerp(lerp(hash(n + dot(step , float3 (0 , 0 , 0))) , hash(n + dot(step , float3 (1 , 0 , 0))) , u.x) , lerp(hash(n + dot(step , float3 (0 , 1 , 0))) , hash(n + dot(step , float3 (1 , 1 , 0))) , u.x) , u.y) , lerp(lerp(hash(n + dot(step , float3 (0 , 0 , 1))) , hash(n + dot(step , float3 (1 , 0 , 1))) , u.x) , lerp(hash(n + dot(step , float3 (0 , 1 , 1))) , hash(n + dot(step , float3 (1 , 1 , 1))) , u.x) , u.y) , u.z); }

                #define DEFINE_FBM ( name , OCTAVES ) float name ( float3 x ) { float v = 0.0 ; float a = 0.5 ; float3 shift = float3 ( 100 , 100 , 100 ) ; for ( int i = 0 ; i < OCTAVES ; ++ i ) { v += a * noise ( x ) ; x = x * 2.0 + shift ; a *= 0.5 ; } return v ; } 
                DEFINE_FBM(fbm3 , 3)
                DEFINE_FBM(fbm5 , 5)
                DEFINE_FBM(fbm6 , 6)

                    // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // / 



                    // Directional light source 





                    // Including clouds 







                    // This can g1 negative in order to make derivatives smooth. Always 
                    // clamp before using as a density. Must be kept in sync with Buf A code. 
                   float cloudDensity(Point3 X , float t) {
                       Point3 p = X * float3 (1.5 , 2.5 , 2.0);
                        return fbm5(p + 1.5 * fbm3(p - t * 0.047) - t * float3 (0.03 , 0.01 , 0.01)) - 0.42;
                    }

                   Color3 shadowedAtmosphereColor(float2 fragCoord , float3 _ScreenParams , float minVal) {
                       float2 rel = 0.65 * (fragCoord.xy - _ScreenParams.xy * 0.5) / _ScreenParams.y;
                       const float maxVal = 1.0;

                       float a = min(1.0 ,
                                     pow(max(0.0 , 1.0 - dot(rel , rel) * 6.5) , 2.4) +
                                     max(abs(rel.x - rel.y) - 0.35 , 0.0) * 12.0 +
                                      max(0.0 , 0.2 + dot(rel , float2 (2.75))) +
                                     0.0
                                     );

                       float planetShadow = lerp(minVal , maxVal , a);

                       return atmosphereColor * planetShadow;

                    }

                   // Planet implicit surface ray tracer 
                   // by Morgan McGuire , @CasualEffects , http: // casual - effects.com 
                   // 
                   // Prototype for a new Graphics Codex programming project. 
                   // 
                   // The key functions are the scene ( ) distance estimator in Buf A and 
                   // the renderClouds ( ) shading in Buf B. Everything else is relatively 
                   // standard ray marching infrastructure. 

                  float3x3 planetRotation;






                  /* *
                  Conservative distance estimator for the entire scene. Returns true if
                  the surface is closer than distance. Always updates distance and material.
                  The material code compiles out when called from a context that ignores it.
                  */
                 bool scene(Point3 X , inout float distance , inout Material material , const bool shadow) {
                     Material planetMaterial;

                     // Move to the planet's reference frame ( ideally , we'd just trace in the 
                     // planet's reference frame and avoid these operations per distance 
                     // function evaluation , but this makes it easy to integrate with a 
                     // standard framework ) 
                    X = planetRotation * (X - planetCenter);
                    Point3 surfaceLocation = normalize(X);

                    // Compute t = distance estimator to the planet surface using a spherical height field , 
                    // in which elevation = radial distance 
                    // 
                     // Estimate * conservative * distance as always less than that to the bounding sphere 
                    // ( i.e. , push down ) . Work on range [0 , 1] , and then scale by planet radius at the end 

                    float mountain = clamp(1.0 - fbm6(surfaceLocation * 4.0) + (max(abs(surfaceLocation.y) - 0.6 , 0.0)) * 0.03 , 0.0 , 1.0);
                   mountain = pow3(mountain) * 0.25 + 0.8;

                   const float water = 0.85;
                   float elevation = mountain;

                   Vector3 normal = normalize(cross(ddx(surfaceLocation * mountain) , ddy(surfaceLocation * mountain)));

                   // Don't pay for fine details in the shadow tracing pass 
                   if (!shadow) {
                      if (elevation < water) {
                          float relativeWaterDepth = min(1.0 , (water - mountain) * 30.0);
                          const float waveMagnitude = 0.0014;
                          const float waveLength = 0.01;

                          // Create waves. Shallow - water waves conform to coasts. Deep - water waves follow global wind patterns. 
                         const Color3 shallowWaterColor = Color3(0.4 , 1.0 , 1.9);
                         // How much the waves conform to beaches 
                        const float shallowWaveRefraction = 4.0;
                        float shallowWavePhase = (surfaceLocation.y - mountain * shallowWaveRefraction) * (1.0 / waveLength);

                        const Color3 deepWaterColor = Color3(0 , 0.1 , 0.7);
                        float deepWavePhase = (atan2(surfaceLocation.z , surfaceLocation.x) + noise(surfaceLocation * 15.0) * 0.075) * (1.5 / waveLength);

                        // This is like a lerp , but it gives a large middle region in which both wave types are active at nearly full magnitude 
                       float wave = (cos(shallowWavePhase + time * 1.5) * sqrt(1.0 - relativeWaterDepth) +
                                      cos(deepWavePhase + time * 2.0) * 2.5 * (1.0 - abs(surfaceLocation.y)) * square(relativeWaterDepth)) *
                           waveMagnitude;

                       elevation = water + wave;

                       // Set material , making deep water darker 
                      planetMaterial = Material(lerp(shallowWaterColor , deepWaterColor , pow(relativeWaterDepth , 0.4)) , 0.5 * relativeWaterDepth , 0.7);

                      // Lighten polar water color 
                     planetMaterial.color = lerp(planetMaterial.color , Color3(0.7 , 1.0 , 1.2) , square(clamp((abs(surfaceLocation.y) - 0.65) * 3.0 , 0.0 , 1.0)));
                  }
         else {
         float materialNoise = noise(surfaceLocation * 200.0);

         float slope = clamp(2.0 * (1.0 - dot(normal , surfaceLocation)) , 0.0 , 1.0);

         bool iceCap = abs(surfaceLocation.y) + materialNoise * 0.2 > 0.98;
         bool rock = (elevation + materialNoise * 0.1 > 0.94) || (slope > 0.3);
         bool mountainTop = (elevation + materialNoise * 0.05 - slope * 0.05) > (planetMaxRadius * 0.92);

         // Beach 
        bool sand = (elevation < water + 0.006) && (noise(surfaceLocation * 8.0) > 0.3);

        // Equatorial desert 
       sand = sand || (elevation < 0.89) &&
            (noise(surfaceLocation * 1.5) * 0.15 + noise(surfaceLocation * 73.0) * 0.25 > abs(surfaceLocation.y));

       if (rock) {
           // Rock 
          planetMaterial = ROCK;
       }
else {
           // Trees 
          planetMaterial = TREE;
       }

      if (iceCap || mountainTop) {
          // Ice ( allow to slightly exceed physical conservation in the blueExtended channel 
          // to simulate subsurface effects ) 
         planetMaterial = ICE;
      }
else if (!rock && sand) {
planetMaterial = SAND;
}
else if (!rock && (_ScreenParams.x > 420.0)) {
          // High frequency bumps for trees when in medium resolution 
         elevation += noise(surfaceLocation * 150.0) * 0.02;
      }

      // Add high - frequency material detail 
     if (!sand && !iceCap) {
         planetMaterial.color *= lerp(noise(surfaceLocation * 256.0) , 1.0 , 0.4);
      }

  }
}

elevation *= planetMaxRadius;

float sampleElevation = length(X);
float t = sampleElevation - elevation;

// Be a little more conservative because a radial heightfield is not a great 
// distance estimator. 
t *= 0.8;

// Compute output variables 
bool closer = (t < distance);
distance = closer ? t : distance;
if (closer) { material = planetMaterial; }
return closer;
}


                 // Version that ignores materials 
                bool scene(Point3 X , inout float distance) {
                    Material ignoreMaterial;
                    return scene(X , distance , ignoreMaterial , true);
                 }

                float distanceEstimator(Point3 X) {
                    float d = inf;
                    Material ignoreMaterial;
                    scene(X , d , ignoreMaterial , false);
                    return d;
                 }

                // Weird structure needed because WebGL does not support BREAK in a FOR loop 
               bool intersectSceneLoop(Ray R , float minDist , float maxDist , inout Surfel surfel) {
                   const int maxIterations = 75;

                   // Making this too large causes bad results because we use 
                   // screen - space derivatives for normal estimation. 

                  const float closeEnough = 0.0011;
                  const float minStep = closeEnough;
                  float closest = inf;
                  float tForClosest = 0.0;
                  float t = minDist;

                  for (int i = 0; i < maxIterations; ++i) {
                      surfel.position = R.direction * t + R.origin;

                      float dt = inf;
                      scene(surfel.position , dt);
                      if (dt < closest) {
                           closest = dt;
                          tForClosest = t;
                       }

                      t += max(dt , minStep);
                      if (dt < closeEnough) {
                          return true;
                       }
              else if (t > maxDist) {
              return false;
           }
       }

                  // "Screen space" optimization from Mercury for shading a reasonable 
                  // pointExtended in the event of failure due to iteration count 
                 if (closest < closeEnough * 5.0) {
                     surfel.position = R.direction * tForClosest + R.origin;
                     return true;
                  }

                 return false;
              }


             bool intersectScene(Ray R , float minDist , float maxDist , inout Surfel surfel) {
                 if (intersectSceneLoop(R , minDist , maxDist , surfel)) {
                     const float eps = 0.0001;

                     float d = inf;
                     scene(surfel.position , d , surfel.material , false);
                     surfel.normal =
                         normalize(Vector3(distanceEstimator(surfel.position + Vector3(eps , 0 , 0)) ,
                                           distanceEstimator(surfel.position + Vector3(0 , eps , 0)) ,
                                           distanceEstimator(surfel.position + Vector3(0 , 0 , eps))) -
                                           d);
                     return true;
                  }
             else {
             return false;
          }
      }


     bool shadowed(Ray R , float minDist , float maxDist) {
         const int maxIterations = 30;
         const float closeEnough = 0.0011 * 4.0;
         const float minStep = closeEnough;
         float t = 0.0;

         for (int i = 0; i < maxIterations; ++i) {
             float dt = inf;
             scene(R.direction * t + R.origin , dt);
             t += max(dt , minStep);
             if (dt < closeEnough) {
                 return true;
              }
     else if (t > maxDist) {
     return false;
  }
}

return false;
}



void computeReflectivities(Material material , out Color3 p_L , out Color3 p_G , out float glossyExponent) {
     p_L = lerp(material.color , Color3(0.0) , material.metal);
     p_G = lerp(Color3(0.04) , material.color , material.metal);
     glossyExponent = exp2(material.smoothness * 15.0);
 }


Radiance3 shade(Surfel surfel , Vector3 w_i , Vector3 w_o , Biradiance3 B_i) {
     Vector3 n = surfel.normal;

    float cos_i = dot(n , w_i);
    if (cos_i < 0.0) {
        // Backface , don't bother shading or shadow casting 
       return Radiance3(0.0);
    }

    // Cast a shadow ray 
   Ray shadowRay = Ray(surfel.position + (surfel.normal + w_o) * 0.003 , w_i);
   float shadowDist , ignore;
   // Find the outer bounding sphere on the atmosphere and trace shadows up to it 
  intersectSphere(planetCenter , planetMaxRadius , shadowRay , shadowDist , ignore);
  if (shadowed(shadowRay , 0.0 , shadowDist)) {
      return Radiance3(0.0);
   }

   Color3 p_L , p_G;
   float glossyExponent;
   computeReflectivities(surfel.material , p_L , p_G , glossyExponent);

   // Compute the light contribution from the directional source 
  Vector3 w_h = normalize(w_i + w_o);
  return cos_i * B_i *
      // Lambertian 
      (p_L * (1.0 / pi) +

          // Glossy 
       pow(max(0.0 , dot(n , w_h)) , glossyExponent) * p_G * (glossyExponent + 8.0) / (14.0 * pi));
}


/* * Returns true if the world - space ray hits the planet */
bool renderPlanet(Ray eyeRay , float minDistanceToPlanet , float maxDistanceToPlanet , inout Radiance3 L_o , inout Point3 hitPoint) {
    Surfel surfel;

    if (intersectScene(eyeRay , minDistanceToPlanet , maxDistanceToPlanet , surfel)) {
        // Render the planet 
       Radiance3 L_directOut = shade(surfel , w_i , -eyeRay.direction , B_i);

       // Clouds vary fairly slowly in elevation , so we can just measure at the 
       // surface as an estimate of the density above the surface 
      float cloudShadow = pow4(1.0 - clamp(cloudDensity(surfel.position , time) , 0.0 , 1.0));

      // "Ambient" 
     Irradiance3 E_indirectIn = max(Irradiance3(0) , Irradiance3(0.4) - 0.4 * Irradiance3(surfel.normal.yxx));
     Radiance3 L_indirectOut =
         lerp(E_indirectIn * surfel.material.color ,
             lerp(Color3(1.0) , surfel.material.color , surfel.material.metal) * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , reflect(w_i , surfel.normal)).rgb * 2.7 , surfel.material.smoothness) * (1.0 / pi);

     hitPoint = surfel.position;
     L_o = (L_directOut + L_indirectOut) * cloudShadow;

     if (debugMaterials) {
         L_o = surfel.material.color;
      }

     return true;
  }
else {
        // Missed the bounding sphere or final ray - march 
       return false;
    }
}



half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
 // Rotate over time 
float yaw = -((iMouse.x / _ScreenParams.x) * 2.5 - 1.25) + (autoRotate ? -time * 0.015 : 0.0);
float pitch = ((iMouse.y > 0.0 ? iMouse.y : _ScreenParams.y * 0.3) / _ScreenParams.y) * 2.5 - 1.25;
 planetRotation =
    float3x3 (cos(yaw) , 0 , -sin(yaw) , 0 , 1 , 0 , sin(yaw) , 0 , cos(yaw)) *
    float3x3 (1 , 0 , 0 , 0 , cos(pitch) , sin(pitch) , 0 , -sin(pitch) , cos(pitch));


Vector2 invResolution = 1.0 / _ScreenParams.xy;

// Outgoing light 
Radiance3 L_o;

Surfel surfel;

Ray eyeRay = Ray(Point3(0.0 , 0.0 , 5.0) , normalize(Vector3(fragCoord.xy - _ScreenParams.xy / 2.0 , _ScreenParams.y / (-2.0 * tan(verticalFieldOfView / 2.0)))));

Point3 hitPoint;
float minDistanceToPlanet , maxDistanceToPlanet;

bool hitBounds = (showClouds || showPlanet) && intersectSphere(planetCenter , planetMaxRadius , eyeRay , minDistanceToPlanet , maxDistanceToPlanet);

Color3 shadowedAtmosphere = shadowedAtmosphereColor(fragCoord , _ScreenParams , 0.5);

if (hitBounds && renderPlanet(eyeRay , minDistanceToPlanet , maxDistanceToPlanet , L_o , hitPoint)) {
    // Tint planet with atmospheric scattering 
   L_o = lerp(L_o , shadowedAtmosphere , min(0.8 , square(1.0 - (hitPoint.z - planetCenter.z) * (1.0 / planetMaxRadius))));
   // Update distance 
  maxDistanceToPlanet = min(maxDistanceToPlanet , dot(eyeRay.direction , hitPoint - eyeRay.origin));
}
else if (showBackground) {
    // Background starfield 
   float galaxyClump = (pow(noise(fragCoord.xy * (30.0 * invResolution.x)) , 3.0) * 0.5 +
       pow(noise(100.0 + fragCoord.xy * (15.0 * invResolution.x)) , 5.0)) / 1.5;
   L_o = Color3(galaxyClump * pow(hash(fragCoord.xy) , 1500.0) * 80.0);

   // Color stars 
  L_o.r *= sqrt(noise(fragCoord.xy) * 1.2);
  L_o.g *= sqrt(noise(fragCoord.xy * 4.0));

  // Twinkle 
 L_o *= noise(time * 0.5 + fragCoord.yx * 10.0);
 float2 delta = (fragCoord.xy - _ScreenParams.xy * 0.5) * invResolution.y * 1.1;
 float atmosphereRadialAttenuation = min(1.0 , 0.06 * pow8(max(0.0 , 1.0 - (length(delta) - 0.9) / 0.9)));

 // Gradient around planet 
float radialNoise = lerp(1.0 , noise(normalize(delta) * 40.0 + _Time.y * 0.5) , 0.14);
L_o += radialNoise * atmosphereRadialAttenuation * shadowedAtmosphere;
}

fragColor.xyz = L_o;
fragColor.a = maxDistanceToPlanet;
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