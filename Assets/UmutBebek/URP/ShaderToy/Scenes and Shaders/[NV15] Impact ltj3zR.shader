Shader "UmutBebek/URP/ShaderToy/[NV15] Impact ltj3zR"
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
            MAX_TRACE_DISTANCE("MAX_TRACE_DISTANCE", float) = 6.0 // max trace distance 
INTERSECTION_PRECISION("INTERSECTION_PRECISION", float) = 0.00001 // precision of the intersection 
NUM_OF_TRACE_STEPS("NUM_OF_TRACE_STEPS", int) = 100
loopSpeed("loopSpeed", float) = .1
loopTime("loopTime", float) = 5.
impactTime("impactTime", float) = 1.
impactFade("impactFade", float) = .3
fadeOutTime("fadeOutTime", float) = .01
fadeInTime("fadeInTime", float) = .2
whiteTime("whiteTime", float) = .3 // fade to white 
NUM_PLANETS("NUM_PLANETS", int) = 1
planet("planet", vector) = (0.,0.,0.)
sun("sun", vector) = (0.,0.,0.)
FOG_STEPS("FOG_STEPS", float) = 20

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
    float MAX_TRACE_DISTANCE;
float INTERSECTION_PRECISION;
int NUM_OF_TRACE_STEPS;
float loopSpeed;
float loopTime;
float impactTime;
float impactFade;
float fadeOutTime;
float fadeInTime;
float whiteTime;
int NUM_PLANETS;
float4 planet;
float4 sun;
float FOG_STEPS;

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

// Mostly taken from 
// http: // www.iquilezles.org / www / index.htm 
// https: // www.shadertoy.com / user / iq 


















// Trying to sync by using AND's code from 
// https: // www.shadertoy.com / view / 4sSSWz 
#define WARMUP_TIME ( 2.0 ) 

 // Shadertoy's sound is a bit out of sync every time you run it : ( 
#define SOUND_OFFSET ( -0.0 ) 








float impactLU[58];



float planetNoise(in float3 x)
 {
   float3 p = floor(x);
   float3 f = frac(x);
f = f * f * (3.0 - 2.0 * f);

float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
return lerp(rg.x , rg.y , f.z);
 }


float displacement(float3 p)
 {
     p += float3 (1.0 , 0.0 , 0.8);

    const float3x3 m = float3x3 (0.00 , 0.80 , 0.60 ,
                    -0.80 , 0.36 , -0.48 ,
                    -0.60 , -0.48 , 0.64);
    // float m = .1412 ; 
  float f;
  f = 0.5000 * planetNoise(p);
  p = mul(m , p) * 2.02;
  f += 0.2500 * planetNoise(p); 
  p = mul(m, p) * 2.03;
  f += 0.1250 * planetNoise(p); 
  p = mul(m, p) * 2.01;
  f += 0.0625 * planetNoise(p);

float n = planetNoise(p * 3.5);
   f += 0.03 * n * n;

   return f;
 }



// -- -- -- - 
// Extra Util Functions 
// -- -- -- - 


float3 hsv(float h , float s , float v)
 {

  return lerp(float3 (1.0 , 1.0 , 1.0) , clamp((abs(frac(
    h + float3 (3.0 , 2.0 , 1.0) / 3.0) * 6.0 - 3.0) - 1.0) , 0.0 , 1.0) , s) * v;
 }




float hash(float n)
 {
     return frac(sin(n) * 43758.5453);
 }

float noise(in float3 x)
 {
     float3 p = floor(x);
     float3 f = frac(x);

     f = f * f * (3.0 - 2.0 * f);

     float n = p.x + p.y * 57.0 + 113.0 * p.z;

     float res = lerp(lerp(lerp(hash(n + 0.0) , hash(n + 1.0) , f.x) ,
                              lerp(hash(n + 57.0) , hash(n + 58.0) , f.x) , f.y) ,
                         lerp(lerp(hash(n + 113.0) , hash(n + 114.0) , f.x) ,
                              lerp(hash(n + 170.0) , hash(n + 171.0) , f.x) , f.y) , f.z);
     return res;
 }





// Taken from https: // www.shadertoy.com / view / 4ts3z2 
float tri(in float x) { return abs(frac(x) - .5); }
float3 tri3(in float3 p) { return float3 (tri(p.z + tri(p.y * 1.)) , tri(p.z + tri(p.x * 1.)) , tri(p.y + tri(p.x * 1.))); }


// Taken from https: // www.shadertoy.com / view / 4ts3z2 
float triNoise3D(in float3 p , in float spd)
 {
    float z = 1.4;
     float rz = 0.;
    float3 bp = p;
     for (float i = 0.; i <= 3.; i++)
      {
        float3 dg = tri3(bp * 2.);
        p += (dg + _Time.y * .1 * spd);

        bp *= 1.8;
          z *= 1.5;
          p *= 1.2;
          // p.xz *= m2 ; 

         rz += (tri(p.z + tri(p.x + tri(p.y)))) / z;
         bp += 0.14;
       }
      return rz;
  }



// -- -- 
// Camera Stuffs 
// -- -- 
float3x3 calcLookAtMatrix(in float3 ro , in float3 ta , in float roll)
 {
    float3 ww = normalize(ta - ro);
    float3 uu = normalize(cross(ww , float3 (sin(roll) , cos(roll) , 0.0)));
    float3 vv = normalize(cross(uu , ww));
    return float3x3 (uu , vv , ww);
 }

void doCamera(out float3 camPos , out float3 camTar , in float time , in float timeInLoop , in float mouseX)
 {
    float an = 0.3 + 10.0 * mouseX;
    float r = time;

    float extraSweep = pow((clamp(timeInLoop , 1. , 3.) - 3.) , 2.);
    float x = (timeInLoop / 2. + 2.) * cos(1.3 + .4 * timeInLoop - .3 * extraSweep);
    float z = (timeInLoop / 2. + 2.) * sin(1.3 + .4 * timeInLoop - .3 * extraSweep);

    float3 offset = float3 (hash(time) - .5 , hash(time * 2.) - .5 , hash(time * 3.) - .5);

     camPos = float3 (x , .7 , z) + .1 * offset * pow(extraSweep * .4 , 10.);
    camTar = float3 (timeInLoop / 2. , 0.0 , 0.0);
 }



// -- -- 
// Distance Functions 
// http: // iquilezles.org / www / articles / distfunctions / distfunctions.htm 
// -- -- 



float sdSphere(float3 p , float s)
 {
  return length(p) - s; // + .1 * sin ( p.x * p.y * p.z * 10. + _Time.y ) ; // * ( 1. + .4 * triNoise3D ( p * .1 , .3 ) + .2 * triNoise3D ( p * .3 , .3 ) ) ; 
 }

float sdPlanet(float3 p , float s)
 {

    return length(p) - s + .1 * triNoise3D(p * .5 , .01) + .04 * sin(p.x * p.y * p.z * 10. + _Time.y); ; // + .03 * noise ( sin ( p ) * 10. + p ) + .03 * sin ( p.x * p.y * p.z * 10. + _Time.y ) + .02 * sin ( p.x + p.y + p.z * 2. + _Time.y ) ; // * ( 1. + .4 * triNoise3D ( p * .1 , .3 ) + .2 * triNoise3D ( p * .3 , .3 ) ) 

 }

// checks to see which intersection is closer 
// and makes the y of the float2 be the proper id 
float2 opU(float2 d1 , float2 d2) {

     return (d1.x < d2.x) ? d1 : d2;

 }






// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
// Modelling 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float2 map(float3 pos) {

    float3 rot = float3 (0. , 0. , 0.); // float3 ( _Time.y * .05 + 1. , _Time.y * .02 + 2. , _Time.y * .03 ) ; 
     // Rotating box 
         // float2 res = float2 ( rotatedBox ( pos , rot , float3 ( 0.7 , 0.7 , 0.7 ) , .1 ) , 1.0 ) ; 

    float2 res = float2 (sdPlanet(pos , .8) , 1.);

    // for ( int i = 0 ; i < NUM_PLANETS ; i ++ ) { 
         float2 res2 = float2 (sdSphere(pos - planet , .1) , 2.);
             res = opU(res , res2);
             // } 

                return res;

         }



        float2 calcIntersection(in float3 ro , in float3 rd) {


            float h = INTERSECTION_PRECISION * 2.0;
            float t = 0.0;
             float res = -1.0;
            float id = -1.;

            for (int i = 0; i < NUM_OF_TRACE_STEPS; i++) {

                if (h < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE) break;
                     float2 m = map(ro + rd * t);
                h = m.x;
                t += h;
                id = m.y;

             }

            if (t < MAX_TRACE_DISTANCE) res = t;
            if (t > MAX_TRACE_DISTANCE) id = -1.0;

            return float2 (res , id);

         }

        // Calculates the normal by taking a very small distance , 
        // remapping the function , and getting normal for that 
       float3 calcNormal(in float3 pos) {

            float3 eps = float3 (0.001 , 0.0 , 0.0);
            float3 nor = float3 (
                map(pos + eps.xyy).x - map(pos - eps.xyy).x ,
                map(pos + eps.yxy).x - map(pos - eps.yxy).x ,
                map(pos + eps.yyx).x - map(pos - eps.yyx).x);
            return normalize(nor);

        }



       // -- -- -- 
       // Volumetric funness 
       // -- -- -- 

      float posToFloat(float3 p) {

          float f = triNoise3D(p * .2 + float3 (_Time.y * .01 , 0. , 0.) , .1);
          return f;

       }



      // box rendering for title at end 
     float inBox(float2 p , float2 loc , float boxSize) {

         if (
             p.x < loc.x + boxSize / 2. &&
             p.x > loc.x - boxSize / 2. &&
             p.y < loc.y + boxSize / 2. &&
             p.y > loc.y - boxSize / 2.
          ) {

          return 1.;

          }

         return 0.;

      }


     float2 getTextLookup(float lu) {

         float posNeg = abs(lu) / lu;

         float x = floor(abs(lu) / 100.);
         float y = abs(lu) - (x * 100.);

         y = floor(y / 10.);
         y *= ((abs(lu) - (x * 100.) - (y * 10.)) - .5) * 2.;

         return float2 (x * posNeg , y);

      }


     float impact(float2 p , float stillness) {


         float f = 0.;

         for (int i = 0; i < 58; i++) {

             for (int j = 0; j < 3; j++) {

                 float size = (-5. + (10. * float(j))) * stillness + 10.;
                 float2 lu = getTextLookup(impactLU[i]) * size;
                 f += inBox(p , float2 (_ScreenParams.x / 2., _ScreenParams.y / 2.) + lu , size);

              }

          }

         return f / 3.;


      }


     float4 overlayFog(float3 ro , float3 rd , float2 screenPos , float hit) {

         float lum = 0.;
         float3 col = float3 (0. , 0. , 0.);

         // float nSize = .000002 * hit ; 
             // float n = ( noise ( float3 ( 2.0 * screenPos , abs ( sin ( _Time.y * 10. ) ) * .1 ) ) * nSize ) - .5 * nSize ; 
        for (int i = 0; i < FOG_STEPS; i++) {

            float3 p = ro * (1.) + rd * (MAX_TRACE_DISTANCE / float(FOG_STEPS)) * float(i);

            float2 m = map(p);

            if (m.x < 0.0) { return float4 (col , lum) / float(FOG_STEPS); }


            // Fading the fog in , so that we dont get banding 
           float ss = pow(clamp(pow(m.x * 10. , 3.) , 0. , 5.) / 5. , 1.); // m.x ; // smoothstep ( m.x , 0.2 , .5 ) / .5 ; 


           float planetFog = 0.;
           planetFog += (10. / (length(p - planet) * length(planet)));

           // Check to see if we are in the corona 
          if (length(p) < 1.4 && length(p) > .8) {

              float d = (1.4 - length(p)) / .6;
              lum += ss * 20. * posToFloat(p * (3. / length(p))) * d; // 30. / length ( p ) ; 
              col += ss * float3 (1. , .3 , 0.1) * 50. * d * posToFloat(p * (3. / length(p))); // * lum ; 

           }

          // TODO: MAKE THIS BETTER!!!! 
          // float fleck = noise ( ( 1. / pow ( length ( p ) , 6. ) ) * p * 3. ) ; // * noise ( length ( p ) * p * 3. ) ; 
          // if ( fleck > .8 ) { return float4 ( float3 ( .2 , 0. , 0. ) * col / float ( i ) , lum ) ; } 

         lum += ss * pow(planetFog , 2.) * .3 * posToFloat(p * .3 * planetFog + float3 (100., 100., 100.)); // // + sin ( p.y * 3. ) + sin ( p.z * 5. ) ; 
         col += ss * planetFog * hsv(lum * .7 * (1. / float(FOG_STEPS)) + .5 , 1. , 1.);
      }

     return float4 (col , lum) / float(FOG_STEPS);

  }





     /* float3 doLighting ( float3 ro , float3 rd ) {



     } */


    half4 LitPassFragment(Varyings input) : SV_Target  {
    half4 fragColor = half4 (1 , 1 , 1 , 1);
    float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

    // 1000 and 100 are the x positions 
    // 10 is y position 
    // 1 is y sign 
    // I 
   impactLU[0] = -1621.;
    impactLU[1] = -1611.;
    impactLU[2] = -1600.;
    impactLU[3] = -1610.;
    impactLU[4] = -1620.;


    // M 
   impactLU[5] = -1221.;
    impactLU[6] = -1211.;
    impactLU[7] = -1201.;
    impactLU[8] = -1210.;
    impactLU[9] = -1220.;

   impactLU[10] = -1021.;
    impactLU[11] = -1011.;
    impactLU[12] = -1001.;
    impactLU[13] = -1010.;
    impactLU[14] = -1020.;

   impactLU[15] = -821.;
    impactLU[16] = -811.;
    impactLU[17] = -801.;
    impactLU[18] = -810.;
    impactLU[19] = -820.;

    // P 
   impactLU[20] = -421.;
    impactLU[21] = -411.;
    impactLU[22] = -401.;
    impactLU[23] = -410.;
    impactLU[24] = -420.;

    impactLU[25] = -221.;
    impactLU[26] = -211.;
    impactLU[27] = -201.;


    // A 
  impactLU[28] = 221.;
   impactLU[29] = 211.;
   impactLU[30] = 201.;
   impactLU[31] = 210.;
   impactLU[32] = 220.;

  impactLU[33] = 321.;

  impactLU[34] = 421.;
   impactLU[35] = 411.;
   impactLU[36] = 401.;
   impactLU[37] = 410.;
   impactLU[38] = 420.;


   // extra hooks for p and m... 
  impactLU[39] = -321.;
  impactLU[40] = -1121.;
  impactLU[41] = -921.;


  // C 

  impactLU[42] = 821.;
impactLU[43] = 811.;
impactLU[44] = 801.;
impactLU[45] = 810.;
impactLU[46] = 820.;

  impactLU[47] = 921.;
impactLU[48] = 1021.;

  impactLU[49] = 920.;
impactLU[50] = 1020.;


// T 

impactLU[51] = 1521.;
impactLU[52] = 1511.;
impactLU[53] = 1501.;
impactLU[54] = 1510.;
impactLU[55] = 1520.;

  impactLU[56] = 1421.;
impactLU[57] = 1621.;




float2 p = (-_ScreenParams.xy + 2.0 * fragCoord.xy) / _ScreenParams.y;
float2 m = iMouse.xy / _ScreenParams.xy;


float time = max(0.0 , _Time.y - WARMUP_TIME);

float tInput = time;
float timeInLoop = loopTime - time * loopSpeed;


// float r = 5. - mod ( tInput , 5. ) ; 


float extraSweep = pow((clamp(timeInLoop , 1. , 3.) - 3.) , 2.);
// float extraSweep = 2. - clamp ( timeInLoop , 1. , 2. ) ; 
float r = 4. - extraSweep * 1.;


planet.x = r * (cos(.3 + .03 * timeInLoop));
planet.z = r * (sin(.3 + .03 * timeInLoop));


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
// camera 
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 

// camera movement 
float3 ro , ta;
doCamera(ro , ta , tInput , timeInLoop , m.x);

// camera matrix 
float3x3 camMat = calcLookAtMatrix(ro , ta , 0.0); // 0.0 is the camera roll 

  // create view ray 
 float3 rd = normalize(mul(camMat , float3 (p.xy , 2.0))); // 2.0 is the lens length 

 // float2 res = calcIntersection ( ro , rd ) ; 

float3 col = float3 (0. , 0. , 0.);

if (timeInLoop > impactTime) {

    float2 res = calcIntersection(ro , rd);

    if (res.y == 1. || res.y == 2.) {

       float3 pos = ro + rd * res.x;
       float3 nor = calcNormal(pos);

       float3 lightDir = pos - planet.xyz;

       float lightL = length(lightDir);
       lightDir = normalize(lightDir);


       float match = max(0. , dot(-nor , lightDir));

       float3 refl = reflect(lightDir , nor);
       float reflMatch = max(0. , dot(-rd , refl));
       float eyeMatch = 1. - max(0. , dot(-rd , nor));


       // float 

      float3 ambi = float3 (.1 , 0.1 , 0.1);
      float3 lamb = float3 (1. , .5 , .3) * match;
      float3 spec = float3 (1. , .3 , .2) * pow(reflMatch , 20.);
      float3 rim = float3 (1. , .3 , .1) * pow(eyeMatch , 3.);
      col = rim + ((ambi + lamb + spec) * 3. / lightL); // nor * .5 + .5 ; 

    }
else {


        // background 
       float neb = pow(triNoise3D((sin(rd) - float3 (156.29, 156.29, 156.29)) * 1. , .1) , 3.);
       col = neb * hsv(neb + .6 , 1. , 2.);

      }

     float hit = 0.;
     if (res.y == 1. || res.y == 2.) { hit = 1.; }

     float4 fog = overlayFog(ro , rd , fragCoord.xy , hit);
     col += .6 * fog.xyz * fog.w;

  }


// Fading in / fading out 
float fadeIn = ((loopTime - clamp(timeInLoop , loopTime - fadeInTime , loopTime))) / fadeInTime;

float fadeOut = ((loopTime - clamp((loopTime - timeInLoop) , loopTime - fadeOutTime , loopTime))) / fadeOutTime;


// Gives us a straight fade to white 
// to hide some weird noise we were 
// seeing 
float aaa = 10. * (impactTime + whiteTime - timeInLoop);
if (timeInLoop < impactTime + whiteTime) { col += float3 (aaa,aaa,aaa); }



// TEXT 
if (timeInLoop < impactTime) {

    col = float3 (1. , 1. , 1.);

    float imp = impact(fragCoord.xy , max(0.2 , timeInLoop - fadeOutTime) - .2);
    float textFade = pow(max(0. , timeInLoop - (impactTime - impactFade)) / impactFade , 2.);
      col = float3 (textFade, textFade, textFade);

     float3 ro , ta;
     doCamera(ro , ta , 0. , 0. , m.x);

     // camera matrix 
    float3x3 camMat = calcLookAtMatrix(ro , ta , 0.0); // 0.0 is the camera roll 

     // create view ray 
    float3 rd = normalize(mul(camMat , float3 (p.xy , 2.0))); // 2.0 is the lens length 

     // getting color for text 
    float neb = pow(triNoise3D((sin(rd) - float3 (156.29, 156.29, 156.29)) * 1. , 1.4) , 2.);
    col += (1. - textFade) * imp * 4. * neb * hsv(neb - .1 , 1. , 2.);
    col += (1. - textFade) * neb * hsv(neb + .8 , 1. , 2.);
    // col = float3 ( fragCoord.x , , 1. ) ; 
     // col = SAMPLE_TEXTURE2D ( _Channel0 , sampler_Channel0 , sin ( fragCoord.xy * 10. ) ) .xyz ; // float3 ( 1. , 1. , 1. ) ; 
 }

 fragColor = min(fadeOut , fadeIn) * float4 (col , 1.0);

return fragColor - 0.1;
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