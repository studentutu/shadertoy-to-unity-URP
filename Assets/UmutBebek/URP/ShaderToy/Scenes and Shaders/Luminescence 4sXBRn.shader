Shader "UmutBebek/URP/ShaderToy/Luminescence 4sXBRn"
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

           // Luminescence by Martijn Steinrucken aka BigWings - 2017 
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// My entry for the monthly challenge ( May 2017 ) on r / proceduralgeneration 
// Use the mouse to look around. Uncomment the SINGLE define to see one specimen by itself. 
// Code is a bit of a mess , too lazy to clean up. Hope you like it! 

// Music by Klaus Lunde 
// https: // soundcloud.com / klauslunde / zebra - tribute 

// YouTube: The Art of Code - > https: // www.youtube.com / channel / UCcAlTqd9zID6aNX3TzwxJXg 
// Twitter: @The_ArtOfCode 

#define INVERTMOUSE - 1. 

#define MAX_STEPS 100. 
#define VOLUME_STEPS 8. 
 // #define SINGLE 
#define MIN_DISTANCE 0.1 
#define MAX_DISTANCE 100. 
#define HIT_DISTANCE .01 

#define S(x , y , z ) smoothstep ( x , y , z ) 
#define B(x , y , z , w ) S ( x - z , x + z , w ) * S ( y + z , y - z , w ) 
#define sat(x) clamp ( x , 0. , 1. ) 
#define SIN(x) sin ( x ) * .5 + .5 

static const float3 lf = float3 (1. , 0. , 0.);
static const float3 up = float3 (0. , 1. , 0.);
static const float3 fw = float3 (0. , 0. , 1.);

static const float halfpi = 1.570796326794896619;
static const float pi = 3.141592653589793238;
static const float twopi = 6.283185307179586;


float3 accentColor1 = float3 (1. , .1 , .5);
float3 secondColor1 = float3 (.1 , .5 , 1.);

float3 accentColor2 = float3 (1. , .5 , .1);
float3 secondColor2 = float3 (.1 , .5 , .6);

float3 bg; // global background color 
float3 accent; // color of the phosphorecence 

float N1(float x) { return frac(sin(x) * 5346.1764); }
float N2(float x , float y) { return N1(x + y * 23414.324); }

float N3(float3 p) {
    p = frac(p * 0.3183099 + .1);
     p *= 17.0;
    return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
 }

struct ray {
    float3 o;
    float3 d;
 };

struct camera {
    float3 p; // the position of the camera 
    float3 forward; // the camera forward vector 
    float3 left; // the camera left vector 
    float3 up; // the camera up vector 

    float3 center; // the center of the screen , in world coords 
    float3 i; // where the current ray intersects the screen , in world coords 
    ray ray; // the current ray: from cam pos , through current uv projected on screen 
    float3 lookAt; // the lookat pointExtended 
    float zoom; // the zoom factor 
 };

struct de {
    // data type used to pass the various bits of information used to shade a de object 
    float d; // final distance to field 
   float m; // material 
   float3 uv;
   float pump;

   float3 id;
   float3 pos; // the world - space coordinate of the fragment 
};

struct rc {
    // data type used to handle a repeated coordinate 
    float3 id; // holds the floor'ed coordinate of each cell. Used to identify the cell. 
   float3 h; // half of the size of the cell 
   float3 p; // the repeated coordinate 
    // float3 c ; // the center of the cell , world coordinates 
};

rc Repeat(float3 pos , float3 size) {
     rc o;
    o.h = size * .5;
    o.id = floor(pos / size); // used to give a unique id to each cell 
    o.p = mod(pos , size) - o.h;
    // o.c = o.id * size + o.h ; 

   return o;
}

camera cam;


void CameraSetup(float2 uv , float3 position , float3 lookAt , float zoom) {

    cam.p = position;
    cam.lookAt = lookAt;
    cam.forward = normalize(cam.lookAt - cam.p);
    cam.left = cross(up , cam.forward);
    cam.up = cross(cam.forward , cam.left);
    cam.zoom = zoom;

    cam.center = cam.p + cam.forward * cam.zoom;
    cam.i = cam.center + cam.left * uv.x + cam.up * uv.y;

    cam.ray.o = cam.p; // ray origin = camera position 
    cam.ray.d = normalize(cam.i - cam.p); // ray direction is the vector from the cam pos through the pointExtended on the imaginary screen 
 }


// == == == == == == == Functions I borrowed ; ) 

// 3 out , 1 in... DAVE HOSKINS 
float3 N31(float p) {
   float3 p3 = frac(float3 (p, p, p) * float3 (.1031 , .11369 , .13787));
   p3 += dot(p3 , p3.yzx + 19.19);
   return frac(float3 ((p3.x + p3.y) * p3.z , (p3.x + p3.z) * p3.y , (p3.y + p3.z) * p3.x));
 }

// DE functions from IQ 
float smin(float a , float b , float k)
 {
    float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
    return lerp(b , a , h) - k * h * (1.0 - h);
 }

float smax(float a , float b , float k)
 {
     float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
     return lerp(a , b , h) + k * h * (1.0 - h);
 }

float sdSphere(float3 p , float3 pos , float s) { return (length(p - pos) - s); }

// From http: // mercury.sexy / hg_sdf 
float2 pModPolar(inout float2 p , float repetitions , float fix) {
     float angle = twopi / repetitions;
     float a = atan2(p.y , p.x) + angle / 2.;
     float r = length(p);
     float c = floor(a / angle);
     a = mod(a , angle) - (angle / 2.) * fix;
     p = float2 (cos(a) , sin(a)) * r;

     return p;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- - 


float Dist(float2 P , float2 P0 , float2 P1) {
    // 2d pointExtended - line distance 

    float2 v = P1 - P0;
   float2 w = P - P0;

   float c1 = dot(w , v);
   float c2 = dot(v , v);

   if (c1 <= 0.) // before P0 
        return length(P - P0);

   float b = c1 / c2;
   float2 Pb = P0 + b * v;
   return length(P - Pb);
}

float3 ClosestPoint(float3 ro , float3 rd , float3 p) {
    // returns the closest pointExtended on ray r to pointExtended p 
   return ro + max(0. , dot(p - ro , rd)) * rd;
}

float2 RayRayTs(float3 ro1 , float3 rd1 , float3 ro2 , float3 rd2) {
    // returns the two t's for the closest pointExtended between two rays 
   // ro + rd * t1 = ro2 + rd2 * t2 

  float3 dO = ro2 - ro1;
  float3 cD = cross(rd1 , rd2);
  float v = dot(cD , cD);

  float t1 = dot(cross(dO , rd2) , cD) / v;
  float t2 = dot(cross(dO , rd1) , cD) / v;
  return float2 (t1 , t2);
}

float DistRaySegment(float3 ro , float3 rd , float3 p1 , float3 p2) {
    // returns the distance from ray r to line segment p1 - p2 
  float3 rd2 = p2 - p1;
  float2 t = RayRayTs(ro , rd , p1 , rd2);

  t.x = max(t.x , 0.);
  t.y = clamp(t.y , 0. , length(rd2));

  float3 rp = ro + rd * t.x;
  float3 sp = p1 + rd2 * t.y;

  return length(rp - sp);
}

float2 sph(float3 ro , float3 rd , float3 pos , float radius) {
    // does a ray sphere intersection 
   // returns a float2 with distance to both intersections 
   // if both a and b are MAX_DISTANCE then there is no intersection 

  float3 oc = pos - ro;
  float l = dot(rd , oc);
  float det = l * l - dot(oc , oc) + radius * radius;
  if (det < 0.0) return float2 (MAX_DISTANCE, MAX_DISTANCE);

  float d = sqrt(det);
  float a = l - d;
  float b = l + d;

  return float2 (a , b);
}


float3 background(float3 r) {

    float x = atan2(r.x , r.z); // from - pi to pi 
     float y = pi * 0.5 - acos(r.y); // from - 1 / 2pi to 1 / 2pi 

    float3 col = bg * (1. + y);

     float t = _Time.y; // add god rays 

    float a = sin(r.x);

    float beam = sat(sin(10. * x + a * y * 5. + t));
    beam *= sat(sin(7. * x + a * y * 3.5 - t));

    float beam2 = sat(sin(42. * x + a * y * 21. - t));
    beam2 *= sat(sin(34. * x + a * y * 17. + t));

    beam += beam2;
    col *= 1. + beam * .05;

    return col;
 }




float remap(float a , float b , float c , float d , float t) {
     return ((t - a) / (b - a)) * (d - c) + c;
 }



de map(float3 p , float3 id) {

    float t = _Time.y * 2.;

    float N = N3(id);

    de o;
    o.m = 0.;

    float x = (p.y + N * twopi) * 1. + t;
    float r = 1.;

    float pump = cos(x + cos(x)) + sin(2. * x) * .2 + sin(4. * x) * .02;

    x = t + N * twopi;
    p.y -= (cos(x + cos(x)) + sin(2. * x) * .2) * .6;
    p.xz *= 1. + pump * .2;

    float d1 = sdSphere(p , float3 (0. , 0. , 0.) , r);
    float d2 = sdSphere(p , float3 (0. , -.5 , 0.) , r);

    o.d = smax(d1 , -d2 , .1);
    o.m = 1.;

    if (p.y < .5) {
        float sway = sin(t + p.y + N * twopi) * S(.5 , -3. , p.y) * N * .3;
        p.x += sway * N; // add some sway to the tentacles 
        p.z += sway * (1. - N);

        float3 mp = p;
         mp.xz = pModPolar(mp.xz , 6. , 0.);

        float d3 = length(mp.xz - float2 (.2 , .1)) - remap(.5 , -3.5 , .1 , .01 , mp.y);
         if (d3 < o.d) o.m = 2.;
        d3 += (sin(mp.y * 10.) + sin(mp.y * 23.)) * .03;

        float d32 = length(mp.xz - float2 (.2 , .1)) - remap(.5 , -3.5 , .1 , .04 , mp.y) * .5;
        d3 = min(d3 , d32);
        o.d = smin(o.d , d3 , .5);

        if (p.y < .2) {
             float3 op = p;
              op.xz = pModPolar(op.xz , 13. , 1.);

             float d4 = length(op.xz - float2 (.85 , .0)) - remap(.5 , -3. , .04 , .0 , op.y);
              if (d4 < o.d) o.m = 3.;
            o.d = smin(o.d , d4 , .15);
         }
     }
    o.pump = pump;
    o.uv = p;

    o.d *= .8;
    return o;
 }

float3 calcNormal(de o) {
     float3 eps = float3 (0.01 , 0.0 , 0.0);
     float3 nor = float3 (
         map(o.pos + eps.xyy , o.id).d - map(o.pos - eps.xyy , o.id).d ,
         map(o.pos + eps.yxy , o.id).d - map(o.pos - eps.yxy , o.id).d ,
         map(o.pos + eps.yyx , o.id).d - map(o.pos - eps.yyx , o.id).d);
     return normalize(nor);
 }

de CastRay(ray r) {
    float d = 0.;
    float dS = MAX_DISTANCE;

    float3 pos = float3 (0. , 0. , 0.);
    float3 n = float3 (0. , 0. , 0.);
    de o , s;

    float dC = MAX_DISTANCE;
    float3 p;
    rc q;
    float t = _Time.y;
    float3 grid = float3 (6. , 30. , 6.);

    for (float i = 0.; i < MAX_STEPS; i++) {
        p = r.o + r.d * d;

        #ifdef SINGLE 
        s = map(p , float3 (0. , 0. , 0.));
        #else 
        p.y -= t; // make the move up 
        p.x += t; // make cam fly forward 

        q = Repeat(p , grid);

        float3 rC = ((2. * step(0. , r.d) - 1.) * q.h - q.p) / r.d; // ray to cell boundary 
        dC = min(min(rC.x , rC.y) , rC.z) + .01; // distance to cell just past boundary 

        float N = N3(q.id);
        q.p += (N31(N) - .5) * grid * float3 (.5 , .7 , .5);

          if (Dist(q.p.xz , r.d.xz , float2 (0. , 0.)) < 1.1)
              // if ( DistRaySegment ( q.p , r.d , float3 ( 0. , - 6. , 0. ) , float3 ( 0. , - 3.3 , 0 ) ) < 1.1 ) 
                  s = map(q.p , q.id);
             else
                 s.d = dC;


             #endif 

             if (s.d < HIT_DISTANCE || d > MAX_DISTANCE) break;
             d += min(s.d , dC); // move to distance to next cell or surface , whichever is closest 
          }

         if (s.d < HIT_DISTANCE) {
             o.m = s.m;
             o.d = d;
             o.id = q.id;
             o.uv = s.uv;
             o.pump = s.pump;

             #ifdef SINGLE 
             o.pos = p;
             #else 
             o.pos = q.p;
             #endif 
          }

         return o;
      }

     float VolTex(float3 uv , float3 p , float scale , float pump) {
         // uv = the surface pos 
         // p = the volume shell pos 

         p.y *= scale;

        float s2 = 5. * p.x / twopi;
        float id = floor(s2);
        s2 = frac(s2);
        float2 ep = float2 (s2 - .5 , p.y - .6);
        float ed = length(ep);
        float e = B(.35 , .45 , .05 , ed);

            float s = SIN(s2 * twopi * 15.);
         s = s * s; s = s * s;
        s *= S(1.4 , -.3 , uv.y - cos(s2 * twopi) * .2 + .3) * S(-.6 , -.3 , uv.y);

        float t = _Time.y * 5.;
        float mask = SIN(p.x * twopi * 2. + t);
        s *= mask * mask * 2.;

        return s + e * pump * 2.;
     }

    float4 JellyTex(float3 p) {
        float3 s = float3 (atan2(p.x , p.z) , length(p.xz) , p.y);

        float b = .75 + sin(s.x * 6.) * .25;
        b = lerp(1. , b , s.y * s.y);

        p.x += sin(s.z * 10.) * .1;
        float b2 = cos(s.x * 26.) - s.z - .7;

        b2 = S(.1 , .6 , b2);
        return float4 (b + b2, b + b2, b + b2, b + b2);
     }

    float3 render(float2 uv , ray camRay , float depth) {
        // outputs a color 

       bg = background(cam.ray.d);

       float3 col = bg;
       de o = CastRay(camRay);

       float t = _Time.y;
       float3 L = up;


       if (o.m > 0.) {
           float3 n = calcNormal(o);
           float lambert = sat(dot(n , L));
           float3 R = reflect(camRay.d , n);
           float fresnel = sat(1. + dot(camRay.d , n));
           float trans = (1. - fresnel) * .5;
           float3 ref = background(R);
           float fade = 0.;

           if (o.m == 1.) { // hood color 
               float density = 0.;
               for (float i = 0.; i < VOLUME_STEPS; i++) {
                   float sd = sph(o.uv , camRay.d , float3 (0. , 0. , 0.) , .8 + i * .015).x;
                   if (sd != MAX_DISTANCE) {
                       float2 intersect = o.uv.xz + camRay.d.xz * sd;

                       float3 uv = float3 (atan2(intersect.x , intersect.y) , length(intersect.xy) , o.uv.z);
                       density += VolTex(o.uv , uv , 1.4 + i * .03 , o.pump);
                    }
                }
               float4 volTex = float4 (accent , density / VOLUME_STEPS);


               float3 dif = JellyTex(o.uv).rgb;
               dif *= max(.2 , lambert);

               col = lerp(col , volTex.rgb , volTex.a);
               col = lerp(col , float3 (dif) , .25);

               col += fresnel * ref * sat(dot(up , n));

               // fade 
              fade = max(fade , S(.0 , 1. , fresnel));
           }
  else if (o.m == 2.) { // inside tentacles 
  float3 dif = accent;
    col = lerp(bg , dif , fresnel);

  col *= lerp(.6 , 1. , S(0. , -1.5 , o.uv.y));

  float prop = o.pump + .25;
  prop *= prop * prop;
  col += pow(1. - fresnel , 20.) * dif * prop;


  fade = fresnel;
}
else if (o.m == 3.) { // outside tentacles 
 float3 dif = accent;
float d = S(100. , 13. , o.d);
  col = lerp(bg , dif , pow(1. - fresnel , 5.) * d);
}

fade = max(fade , S(0. , 100. , o.d));
col = lerp(col , bg , fade);

if (o.m == 4.)
    col = float3 (1. , 0. , 0.);
}
else
   col = bg;

return col;
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

accentColor1 = float3 (1., .1, .5);
secondColor1 = float3 (.1, .5, 1.);

accentColor2 = float3 (1., .5, .1);
secondColor2 = float3 (.1, .5, .6);

 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float t = _Time.y * .04;

     float2 uv = (fragCoord.xy / _ScreenParams.xy);
     uv -= .5;
     uv.y *= _ScreenParams.y / _ScreenParams.x;

     float2 m = iMouse.xy / _ScreenParams.xy;

     if (m.x < 0.05 || m.x > .95) { // move cam automatically when mouse is not used 
          m = float2 (t * .25 , SIN(t * pi) * .5 + .5);
      }

     accent = lerp(accentColor1 , accentColor2 , SIN(t * 15.456));
     bg = lerp(secondColor1 , secondColor2 , SIN(t * 7.345231));

     float turn = (.1 - m.x) * twopi;
     float s = sin(turn);
     float c = cos(turn);
     float3x3 rotX = float3x3 (c , 0. , s , 0. , 1. , 0. , s , 0. , -c);

     #ifdef SINGLE 
     float camDist = -10.;
     #else 
     float camDist = -.1;
     #endif 

     float3 lookAt = float3 (0. , -1. , 0.);

     float3 camPos = mul(float3 (0. , INVERTMOUSE * camDist * cos((m.y) * pi) , camDist) , rotX);

     CameraSetup(uv , camPos + lookAt , lookAt , 1.);

     float3 col = render(uv , cam.ray , 0.);

     col = pow(col , float3 (lerp(1.5, 2.6, SIN(t + pi)), lerp(1.5, 2.6, SIN(t + pi)), lerp(1.5, 2.6, SIN(t + pi)))); // post - processing 
     float d = 1. - dot(uv , uv); // vignette 
     col *= (d * d * d) + .1;

     fragColor = float4 (col , 1.);
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