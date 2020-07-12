Shader "UmutBebek/URP/ShaderToy/Geodesic tiling llVXRd"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        MOUSE_CONTROL("MOUSE_CONTROL", float) = 1
Type("Type", int) = 5
sqrt3("sqrt3", float) = 1.7320508075688772
i3("i3", float) = 0.5773502691896258
TAU("TAU", float) = 6.283185307179586
faceRadius("faceRadius", float) = 0.3819660112501051
SCENE_DURATION("SCENE_DURATION", float) = 6.
CROSSFADE_DURATION("CROSSFADE_DURATION", float) = 2.
FACE_COLOR("FACE_COLOR", vector) = (.9 , .9 , 1.)
BACK_COLOR("BACK_COLOR", vector) = (.1 , .1 , .15)
BACKGROUND_COLOR("BACKGROUND_COLOR", vector) = (.0 , .005 , .03)
MAX_TRACE_DISTANCE("MAX_TRACE_DISTANCE", float) = 8. // max trace distance 
INTERSECTION_PRECISION("INTERSECTION_PRECISION", float) = .001 // precision of the intersection 
NUM_OF_TRACE_STEPS("NUM_OF_TRACE_STEPS", int) = 100
FUDGE_FACTOR("FUDGE_FACTOR", float) = .9 // Default is 1 , reduce to fix overshoots 
GAMMA("GAMMA", float) = 2.2

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
    float MOUSE_CONTROL;

int Type;
float sqrt3;
float i3;
float TAU;
float faceRadius;
float SCENE_DURATION;
float CROSSFADE_DURATION;
float4 FACE_COLOR;
float4 BACK_COLOR;
float4 BACKGROUND_COLOR;
float MAX_TRACE_DISTANCE;
float INTERSECTION_PRECISION;
int NUM_OF_TRACE_STEPS;
float FUDGE_FACTOR;
float GAMMA;


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

                    #define MODEL_ROTATION float2 ( .3 , .25 ) 
#define CAMERA_ROTATION float2 ( .5 , .5 ) 

                   float2x2 cart2hex;
                   float2x2 hex2cart;
                   // 0: Defaults 
                   // 1: Model 
                   // 2: Camera 


                   // #define DEBUG 

                   // 1 , 2 , or 3 
                   // #define LOOP 1 


                   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
                   // HG_SDF 
                   // https: // www.shadertoy.com / view / Xs3GRB 
                   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

                  void pR(inout float2 p , float a) {
                      p = cos(a) * p + sin(a) * float2 (p.y , -p.x);
                   }

                  float pReflect(inout float3 p , float3 planeNormal , float offset) {
                      float t = dot(p , planeNormal) + offset;
                      if (t < 0.) {
                          p = p - (2. * t) * planeNormal;
                       }
                      return sign(t);
                   }

                  float smax(float a , float b , float r) {
                      float m = max(a , b);
                      if ((-a < r) && (-b < r)) {
                          return max(m , -(r - sqrt((r + a) * (r + a) + (r + b) * (r + b))));
                       }
                  else {
                  return m;
               }
           }


                  // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
                  // Icosahedron domain mirroring 
                  // Adapted from knighty https: // www.shadertoy.com / view / MsKGzw 
                  // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



                 float3 facePlane;
                 float3 uPlane;
                 float3 vPlane;


                 float3 nc;
                 float3 pab;
                 float3 pbc;
                 float3 pca;

                 void initIcosahedron() { // setup folding planes and vertex 
                     float cospin = cos(PI / float(Type)) , scospin = sqrt(0.75 - cospin * cospin);
                     nc = float3 (-0.5 , -cospin , scospin); // 3rd folding plane. The two others are xz and yz planes 
                     pbc = float3 (scospin , 0. , 0.5); // No normalization in order to have 'barycentric' coordinates work evenly 
                     pca = float3 (0. , scospin , cospin);
                     pbc = normalize(pbc); pca = normalize(pca); // for slightly better DE. In reality it's not necesary to apply normalization : ) 
                      pab = float3 (0 , 0 , 1);

                     facePlane = pca;
                     uPlane = cross(float3 (1 , 0 , 0) , facePlane);
                     vPlane = float3 (1 , 0 , 0);
                  }

                 void pModIcosahedron(inout float3 p) {
                     p = abs(p);
                     pReflect(p , nc , 0.);
                     p.xy = abs(p.xy);
                     pReflect(p , nc , 0.);
                     p.xy = abs(p.xy);
                     pReflect(p , nc , 0.);
                  }


                 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
                 // Triangle tiling 
                 // Adapted from mattz https: // www.shadertoy.com / view / 4d2GzV 
                 // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 







                #define PHI ( 1.618033988749895 ) 


                struct TriPoints {
                     float2 a;
                    float2 b;
                    float2 c;
                    float2 center;
                    float2 ab;
                    float2 bc;
                    float2 ca;
                 };

                TriPoints closestTriPoints(float2 p) {
                    float2 pTri = mul( cart2hex , p);
                    float2 pi = floor(pTri);
                    float2 pf = frac(pTri);

                    float split1 = step(pf.y , pf.x);
                    float split2 = step(pf.x , pf.y);

                    float2 a = float2 (split1 , 1);
                    float2 b = float2 (1 , split2);
                    float2 c = float2 (0 , 0);

                    a += pi;
                    b += pi;
                    c += pi;

                    a = mul(hex2cart , a);
                    b = mul(hex2cart , b);
                    c = mul(hex2cart , c);

                    float2 center = (a + b + c) / 3.;

                     float2 ab = (a + b) / 2.;
                    float2 bc = (b + c) / 2.;
                    float2 ca = (c + a) / 2.;

                    TriPoints tp;
                    tp.a = a;
                    tp.b = b;
                    tp.c = c;
                    tp.center = center;
                    tp.ab = ab;
                    tp.bc = bc;
                    tp.ca = ca;
                    return tp;
                 }


                // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
                // Geodesic tiling 
                // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

               struct TriPoints3D {
                    float3 a;
                   float3 b;
                   float3 c;
                    float3 center;
                   float3 ab;
                   float3 bc;
                   float3 ca;
                };

               float3 intersection(float3 n , float3 planeNormal , float planeOffset) {
                   float denominator = dot(planeNormal , n);
                   float t = (dot(float3 (0 , 0 , 0) , planeNormal) + planeOffset) / -denominator;
                   return n * t;
                }

               // // Edge length of an icosahedron with an inscribed sphere of radius of 1 
               // float edgeLength = 1. / ( ( sqrt ( 3. ) / 12. ) * ( 3. + sqrt ( 5. ) ) ) ; 
               // // Inner radius of the icosahedron's face 
               // float faceRadius = ( 1. / 6. ) * sqrt ( 3. ) * edgeLength ; 


               // 2D coordinates on the icosahedron face 
              float2 icosahedronFaceCoordinates(float3 p) {
                  float3 pn = normalize(p);
                  float3 i = intersection(pn , facePlane , -1.);
                  return float2 (dot(i , uPlane) , dot(i , vPlane));
               }

              // Project 2D icosahedron face coordinates onto a sphere 
             float3 faceToSphere(float2 facePoint) {
                  return normalize(facePlane + (uPlane * facePoint.x) + (vPlane * facePoint.y));
              }

             TriPoints3D geodesicTriPoints(float3 p , float subdivisions) {
                 // Get 2D cartesian coordiantes on that face 
                float2 uv = icosahedronFaceCoordinates(p);

                // Get points on the nearest triangle tile 
                float uvScale = subdivisions / faceRadius / 2.;
               TriPoints points = closestTriPoints(uv * uvScale);

               // Project 2D triangle coordinates onto a sphere 
              float3 a = faceToSphere(points.a / uvScale);
              float3 b = faceToSphere(points.b / uvScale);
              float3 c = faceToSphere(points.c / uvScale);
              float3 center = faceToSphere(points.center / uvScale);
              float3 ab = faceToSphere(points.ab / uvScale);
              float3 bc = faceToSphere(points.bc / uvScale);
              float3 ca = faceToSphere(points.ca / uvScale);

              TriPoints3D tp;
              tp.a = a;
              tp.b = b;
              tp.c = c;
              tp.center = center;
              tp.ab = ab;
              tp.bc = bc;
              tp.ca = ca;
              return tp;
              //return TriPoints3D(a , b , c , center , ab , bc , ca);
           }


             // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
             // Spectrum colour palette 
             // IQ https: // www.shadertoy.com / view / ll2GD3 
             // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

            float3 pal(in float t , in float3 a , in float3 b , in float3 c , in float3 d) {
                return a + b * cos(6.28318 * (c * t + d));
             }

            float3 spectrum(float n) {
                return pal(n , float3 (0.5 , 0.5 , 0.5) , float3 (0.5 , 0.5 , 0.5) , float3 (1.0 , 1.0 , 1.0) , float3 (0.0 , 0.33 , 0.67));
             }


            // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
            // Model / Camera Rotation 
            // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

           float3x3 sphericalMatrix(float theta , float phi) {
               float cx = cos(theta);
               float cy = cos(phi);
               float sx = sin(theta);
               float sy = sin(phi);
               return float3x3 (
                   cy , -sy * -sx , -sy * cx ,
                   0 , cx , sx ,
                   sy , cy * -sx , cy * cx
                );
            }

           float3x3 mouseRotation(bool enable , float2 xy) {
               if (enable) {
                   float2 mouse = iMouse.xy / _ScreenParams.xy;

                   if (mouse.x != 0. && mouse.y != 0.) {
                       xy.x = mouse.x;
                       xy.y = mouse.y;
                    }
                }
               float rx , ry;

               rx = (xy.y + .5) * PI;
               ry = (-xy.x) * 2. * PI;

               return sphericalMatrix(rx , ry);
            }

           float3x3 modelRotation() {
               float3x3 m = mouseRotation(MOUSE_CONTROL == 1 , MODEL_ROTATION);
               return m;
            }

           float3x3 cameraRotation() {
               float3x3 m = mouseRotation(MOUSE_CONTROL == 2 , CAMERA_ROTATION);
               return m;
            }


           // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
           // Animation 
           // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 




          float time;

          struct HexSpec {
              float roundTop;
              float roundCorner;
               float height;
              float thickness;
              float gap;
           };

          HexSpec newHexSpec(float subdivisions) {
              HexSpec hs;
              hs.roundTop = .05 / subdivisions;
              hs.roundCorner = .1 / subdivisions;
              hs.height = 2.;
              hs.thickness = 2.;
              hs.gap = .005;
              return hs;
           }

          // Animation 1 

         float animSubdivisions1() {
              return lerp(2.4 , 3.4 , cos(time * PI) * .5 + .5);
          }

         HexSpec animHex1(float3 hexCenter , float subdivisions) {
             HexSpec spec = newHexSpec(subdivisions);

             float offset = time * 3. * PI;
             offset -= subdivisions;
             float blend = dot(hexCenter , pca);
             blend = cos(blend * 30. + offset) * .5 + .5;
             spec.height = lerp(1.75 , 2. , blend);

             spec.thickness = spec.height;

             return spec;
          }

         // Animation 2 

        float animSubdivisions2() {
            return lerp(1. , 2.3 , sin(time * PI / 2.) * .5 + .5);
         }

        HexSpec animHex2(float3 hexCenter , float subdivisions) {
            HexSpec spec = newHexSpec(subdivisions);

            float blend = hexCenter.y;
            spec.height = lerp(1.6 , 2. , sin(blend * 10. + time * PI) * .5 + .5);

            spec.roundTop = .02 / subdivisions;
            spec.roundCorner = .09 / subdivisions;
            spec.thickness = spec.roundTop * 4.;
            spec.gap = .01;

            return spec;
         }

        // Animation 3 

       float animSubdivisions3() {
            return 5.;
        }

       HexSpec animHex3(float3 hexCenter , float subdivisions) {
           HexSpec spec = newHexSpec(subdivisions);

           float blend = acos(dot(hexCenter , pab)) * 10.;
           blend = cos(blend + time * PI) * .5 + .5;
           spec.gap = lerp(.01 , .4 , blend) / subdivisions;

           spec.thickness = spec.roundTop * 2.;

            return spec;
        }

       // Transition between animations 

      float sineInOut(float t) {
        return -0.5 * (cos(PI * t) - 1.0);
       }

      float transitionValues(float a , float b , float c) {
          #ifdef LOOP 
              #if LOOP == 1 
                  return a;
              #endif 
              #if LOOP == 2 
                  return b;
              #endif 
              #if LOOP == 3 
                  return c;
              #endif 
          #endif 
          float t = time / SCENE_DURATION;
          float scene = floor(mod(t , 3.));
          float blend = frac(t);
          float delay = (SCENE_DURATION - CROSSFADE_DURATION) / SCENE_DURATION;
          blend = max(blend - delay , 0.) / (1. - delay);
          blend = sineInOut(blend);
          float ab = lerp(a , b , blend);
          float bc = lerp(b , c , blend);
          float cd = lerp(c , a , blend);
          float result = lerp(ab , bc , min(scene , 1.));
          result = lerp(result , cd , max(scene - 1. , 0.));
          return result;
       }

      HexSpec transitionHexSpecs(HexSpec a , HexSpec b , HexSpec c) {
          float roundTop = transitionValues(a.roundTop , b.roundTop , c.roundTop);
          float roundCorner = transitionValues(a.roundCorner , b.roundCorner , c.roundCorner);
           float height = transitionValues(a.height , b.height , c.height);
          float thickness = transitionValues(a.thickness , b.thickness , c.thickness);
          float gap = transitionValues(a.gap , b.gap , c.gap);
          HexSpec hs;
          hs.roundTop = roundTop;
          hs.roundCorner = roundCorner;
          hs.height = height;
          hs.thickness = thickness;
          hs.gap = gap;
          return hs;
       }


      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      // Modelling 
      // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 





     struct Model {
         float dist;
         float3 albedo;
         float glow;
      };

     Model hexModel(
         float3 p ,
         float3 hexCenter ,
         float3 edgeA ,
         float3 edgeB ,
         HexSpec spec
      ) {
         float d;

         float edgeADist = dot(p , edgeA) + spec.gap;
         float edgeBDist = dot(p , edgeB) - spec.gap;
         float edgeDist = smax(edgeADist , -edgeBDist , spec.roundCorner);

         float outerDist = length(p) - spec.height;
         d = smax(edgeDist , outerDist , spec.roundTop);

         float innerDist = length(p) - spec.height + spec.thickness;
         d = smax(d , -innerDist , spec.roundTop);

         float3 color;

         float faceBlend = (spec.height - length(p)) / spec.thickness;
         faceBlend = clamp(faceBlend , 0. , 1.);
         color = lerp(FACE_COLOR , BACK_COLOR , step(.5 , faceBlend));

         float3 edgeColor = spectrum(dot(hexCenter , pca) * 5. + length(p) + .8);
          float edgeBlend = smoothstep(-.04 , -.005 , edgeDist);
         color = lerp(color , edgeColor , edgeBlend);

         Model model;
         model.dist = d;
         model.albedo = color;
         model.glow = edgeBlend;
         return model;
      }

     // checks to see which intersection is closer 
    Model opU(Model m1 , Model m2) {
        if (m1.dist < m2.dist) {
            return m1;
         }
    else {
    return m2;
 }
}

Model geodesicModel(float3 p) {

    pModIcosahedron(p);

    float subdivisions = transitionValues(
        animSubdivisions1() ,
        animSubdivisions2() ,
        animSubdivisions3()
         );
     TriPoints3D points = geodesicTriPoints(p , subdivisions);

     float3 edgeAB = normalize(cross(points.center , points.ab));
     float3 edgeBC = normalize(cross(points.center , points.bc));
    float3 edgeCA = normalize(cross(points.center , points.ca));

    Model model , part;
    HexSpec spec;

     spec = transitionHexSpecs(
        animHex1(points.b , subdivisions) ,
        animHex2(points.b , subdivisions) ,
        animHex3(points.b , subdivisions)
     );
    part = hexModel(p , points.b , edgeAB , edgeBC , spec);
    model = part;

     spec = transitionHexSpecs(
        animHex1(points.c , subdivisions) ,
        animHex2(points.c , subdivisions) ,
        animHex3(points.c , subdivisions)
     );
    part = hexModel(p , points.c , edgeBC , edgeCA , spec);
    model = opU(model , part);

     spec = transitionHexSpecs(
        animHex1(points.a , subdivisions) ,
        animHex2(points.a , subdivisions) ,
        animHex3(points.a , subdivisions)
     );
    part = hexModel(p , points.a , edgeCA , edgeAB , spec);
    model = opU(model , part);

     return model;
 }

Model map(float3 p) {
    float3x3 m = modelRotation();
    p = mul (p, m);
    #ifndef LOOP 
         pR(p.xz , time * PI / 16.);
    #endif 
    Model model = geodesicModel(p);
    return model;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// LIGHTING 
// Adapted from IQ https: // www.shadertoy.com / view / Xds3zN 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float3 doLighting(Model model , float3 pos , float3 nor , float3 ref , float3 rd) {
    float3 lightPos = normalize(float3 (.5 , .5 , -1.));
    float3 backLightPos = normalize(float3 (-.5 , -.3 , 1));
    float3 ambientPos = float3 (0 , 1 , 0);

    float3 lig = lightPos;
    float amb = clamp((dot(nor , ambientPos) + 1.) / 2. , 0. , 1.);
    float dif = clamp(dot(nor , lig) , 0.0 , 1.0);
    float bac = pow(clamp(dot(nor , backLightPos) , 0. , 1.) , 1.5);
    float fre = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 2.0);

    float3 lin = float3 (0.0 , 0.0 , 0.0);
    lin += 1.20 * dif * float3 (.9 , .9 , .9);
    lin += 0.80 * amb * float3 (.5 , .7 , .8);
    lin += 0.30 * bac * float3 (.25 , .25 , .25);
    lin += 0.20 * fre * float3 (1 , 1 , 1);

    float3 albedo = model.albedo;
    float3 col = lerp(albedo * lin , albedo , model.glow);

    return col;
 }


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// Ray Marching 
// Adapted from cabbibo https: // www.shadertoy.com / view / Xl2XWt 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 






struct CastRay {
    float3 origin;
    float3 direction;
 };

struct Ray {
    float3 origin;
    float3 direction;
    float len;
 };

struct Hit {
    Ray ray;
    Model model;
    float3 pos;
    bool isBackground;
    float3 normal;
    float3 color;
 };

float3 calcNormal(in float3 pos) {
    float3 eps = float3 (0.001 , 0.0 , 0.0);
    float3 nor = float3 (
        map(pos + eps.xyy).dist - map(pos - eps.xyy).dist ,
        map(pos + eps.yxy).dist - map(pos - eps.yxy).dist ,
        map(pos + eps.yyx).dist - map(pos - eps.yyx).dist);
    return normalize(nor);
 }

Hit raymarch(CastRay castRay) {

    float currentDist = INTERSECTION_PRECISION * 2.0;
    Model model;

    Ray ray;
    ray.origin = castRay.origin;
    ray.direction = castRay.direction;
    ray.len = 0.;

    for (int i = 0; i < NUM_OF_TRACE_STEPS; i++) {
        if (currentDist < INTERSECTION_PRECISION || ray.len > MAX_TRACE_DISTANCE) {
            break;
         }
        model = map(ray.origin + ray.direction * ray.len);
        currentDist = model.dist;
        ray.len += currentDist * FUDGE_FACTOR;
     }

    bool isBackground = false;
    float3 pos = float3 (0 , 0 , 0);
    float3 normal = float3 (0 , 0 , 0);
    float3 color = float3 (0 , 0 , 0);

    if (ray.len > MAX_TRACE_DISTANCE) {
        isBackground = true;
     }
else {
pos = ray.origin + ray.direction * ray.len;
normal = calcNormal(pos);
}
    Hit hit;
    hit.ray = ray;
    hit.model = model;
        hit.pos = pos;
    hit.isBackground = isBackground;
    hit.normal = normal;
    hit.color = color;
    return hit;
}


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// Rendering 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

void shadeSurface(inout Hit hit) {

    float3 color = BACKGROUND_COLOR;

    if (hit.isBackground) {
        hit.color = color;
        return;
     }

    float3 ref = reflect(hit.ray.direction , hit.normal);

    #ifdef DEBUG 
        color = hit.normal * 0.5 + 0.5;
    #else 
        color = doLighting(
            hit.model ,
            hit.pos ,
            hit.normal ,
            ref ,
            hit.ray.direction
         );
    #endif 

    hit.color = color;
 }

float3 render(Hit hit) {
    shadeSurface(hit);
     return hit.color;
 }


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// Camera 
// https: // www.shadertoy.com / view / Xl2XWt 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float3x3 calcLookAtMatrix(in float3 ro , in float3 ta , in float roll)
 {
    float3 ww = normalize(ta - ro);
    float3 uu = normalize(cross(ww , float3 (sin(roll) , cos(roll) , 0.0)));
    float3 vv = normalize(cross(uu , ww));
    return float3x3 (uu , vv , ww);
 }

void doCamera(out float3 camPos , out float3 camTar , out float camRoll , in float time , in float2 mouse) {
    float dist = 5.5;
    camRoll = 0.;
    camTar = float3 (0 , 0 , 0);
    camPos = float3 (0 , 0 , -dist);
    camPos = mul(camPos, cameraRotation());
    camPos += camTar;
 }


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// Gamma 
// https: // www.shadertoy.com / view / Xds3zN 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 



float3 gamma(float3 color , float g) {
    return pow(color , float3 (g, g, g));
 }

float3 linearToScreen(float3 linearRGB) {
    return gamma(linearRGB , 1.0 / GAMMA);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

cart2hex = float2x2(1, 0, i3, 2. * i3);
hex2cart = float2x2(1, 0, -.5, .5 * sqrt3);

 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     time = _Time.y;

     #ifdef LOOP 
         #if LOOP == 1 
             time = mod(time , 2.);
         #endif 
         #if LOOP == 2 
             time = mod(time , 4.);
         #endif 
         #if LOOP == 3 
             time = mod(time , 2.);
          #endif 
     #endif 

     initIcosahedron();

     float2 p = (-_ScreenParams.xy + 2.0 * fragCoord.xy) / _ScreenParams.y;
     float2 m = iMouse.xy / _ScreenParams.xy;

     float3 camPos = float3 (0. , 0. , 2.);
     float3 camTar = float3 (0. , 0. , 0.);
     float camRoll = 0.;

     // camera movement 
    doCamera(camPos , camTar , camRoll , _Time.y , m);

    // camera matrix 
   float3x3 camMat = calcLookAtMatrix(camPos , camTar , camRoll); // 0.0 is the camera roll 

    // create view ray 
   float3 rd = normalize(mul(camMat , float3 (p.xy , 2.0))); // 2.0 is the lens length 

   CastRay cr;
   cr.origin = camPos;
   cr.direction = rd;
   Hit hit = raymarch(cr);

   float3 color = render(hit);

   #ifndef DEBUG 
       color = linearToScreen(color);
   #endif 

   fragColor = float4 (color , 1.0);
   fragColor.xyz -= 0.1;
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