Shader "UmutBebek/URP/ShaderToy/Generators Xtf3Rn"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        RAY_STEPS("RAY_STEPS", float) = 70
SHADOW_STEPS("SHADOW_STEPS", float) = 50
BRIGHTNESS("BRIGHTNESS", float) = .9
GAMMA("GAMMA", float) = 1.3
SATURATION("SATURATION", float) = .85
detail("detail", float) = .00005
lightdir("lightdir", vector) = (0.5 , -0.3 , -1.)
ambdir("ambdir", vector) = (0. , 0. , 1.)
origin("origin", vector) = (0. , 3.11 , 0.)
energy("energy", vector) = (0.01,0.01,0.01,1)
vibration("vibration", float) = 0.
det("det", float) = 0.0
LIGHT_COLOR("LIGHT_COLOR ", vector) = (.85 , .9 , 1.,1)
AMBIENT_COLOR("AMBIENT_COLOR ", vector) = (.8 , .83 , 1.,1)
FLOOR_COLOR("FLOOR_COLOR ", vector) = (1. , .7 , .9,1)
ENERGY_COLOR("ENERGY_COLOR ", vector) = (1. , .7 , .4,1)
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
            float RAY_STEPS;
float SHADOW_STEPS;
float BRIGHTNESS;
float GAMMA;
float SATURATION;
float detail;
float4 lightdir;
float4 ambdir;
float4 origin;
float4 energy;
float vibration;
float det;
float4 LIGHT_COLOR;
float4 AMBIENT_COLOR;
float4 FLOOR_COLOR;
float4 ENERGY_COLOR;


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

                   // "GENERATORS REDUX" by Kali 

// Same fractal as "Ancient Temple" + rotations , improved shading 
// ( better coloring , AO and shadows ) , some lighting effects , and a path for the camera 
// following a liquid metal ball. 


#define ENABLE_HARD_SHADOWS // turn off to enable faster AO soft shadows 
 // #define ENABLE_VIBRATION 
#define ENABLE_POSTPROCESS // Works better on window view rather than full screen 











#define t _Time.y * .25 






float3 pth1;


float2x2 rot(float a) {
     return float2x2 (cos(a) , sin(a) , -sin(a) , cos(a));
 }


float3 path(float ti) {
return float3 (sin(ti) , .3 - sin(ti * .632) * .3 , cos(ti * .5)) * .5;
 }

float Sphere(float3 p , float3 rd , float r) { // A RAY TRACED SPHERE 
     float b = dot(-p , rd);
     float inner = b * b - dot(p , p) + r * r;
     if (inner < 0.0) return -1.0;
     return b - sqrt(inner);
 }

float2 de(float3 pos) {
     float hid = 0.;
     float3 tpos = pos;
     tpos.xz = abs(.5 - mod(tpos.xz , 1.));
     float4 p = float4 (tpos , 1.);
     float y = max(0. , .35 - abs(pos.y - 3.35)) / .35;
     for (int i = 0; i < 7; i++) { // LOWERED THE ITERS 
          p.xyz = abs(p.xyz) - float3 (-0.02 , 1.98 , -0.02);
          p = p * (2.0 + vibration * y) / clamp(dot(p.xyz , p.xyz) , .4 , 1.) - float4 (0.5 , 1. , 0.4 , 0.);
          p.xz = mul(p.xz,float2x2 (-0.416 , -0.91 , 0.91 , -0.416));
      }
     float fl = pos.y - 3.013;
     float fr = (length(max(abs(p.xyz) - float3 (0.1 , 5.0 , 0.1) , float3 (0.0 , 0.0 , 0.0))) - 0.05) / p.w; // RETURN A RRECT 
      // float fr = length ( p.xyz ) / p.w ; 
     float d = min(fl , fr);
     d = min(d , -pos.y + 3.95);
     if (abs(d - fl) < .001) hid = 1.;
     return float2 (d , hid);
 }


float3 normal(float3 p) {
     float3 e = float3 (0.0 , det , 0.0);

     return normalize(float3 (
               de(p + e.yxx).x - de(p - e.yxx).x ,
               de(p + e.xyx).x - de(p - e.xyx).x ,
               de(p + e.xxy).x - de(p - e.xxy).x
                )
           );
 }

float shadow(float3 pos , float3 sdir) { // THIS ONLY RUNS WHEN WITH HARD SHADOWS 
     float sh = 1.0;
     float totdist = 2.0 * det;
     float dist = 10.;
     float t1 = Sphere((pos - .005 * sdir) - pth1 , -sdir , 0.015);
     if (t1 > 0. && t1 < .5) {
          float3 sphglowNorm = normalize(pos - t1 * sdir - pth1);
          sh = 1. - pow(max(.0 , dot(sphglowNorm , sdir)) * 1.2 , 3.);
      }
          for (int steps = 0; steps < SHADOW_STEPS; steps++) {
               if (totdist < .6 && dist > detail) {
                    float3 p = pos - totdist * sdir;
                    dist = de(p).x;
                    sh = min(sh , max(50. * dist / totdist , 0.0));
                    totdist += max(.01 , dist);
                }
           }

    return clamp(sh , 0.1 , 1.0);
 }


float calcAO(const float3 pos , const float3 nor) {
     float aodet = detail * 40.;
     float totao = 0.0;
    float sca = 14.0;
    for (int aoi = 0; aoi < 5; aoi++) {
        float hr = aodet * float(aoi * aoi);
        float3 aopos = nor * hr + pos;
        float dd = de(aopos).x;
        totao += -(dd - hr) * sca;
        sca *= 0.7;
     }
    return clamp(1.0 - 5.0 * totao , 0. , 1.0);
 }

float _texture(float3 p) {
     p = abs(.5 - frac(p * 10.));
     float3 c = float3 (3., 3., 3.);
     float es , l = es = 0.;
     for (int i = 0; i < 10; i++) {
               p = abs(p + c) - abs(p - c) - p;
               p /= clamp(dot(p , p) , .0 , 1.);
               p = p * -1.5 + c;
               if (mod(float(i) , 2.) < 1.) {
                    float pl = l;
                    l = length(p);
                    es += exp(-1. / abs(l - pl));
                }
      }
     return es;
 }

float3 light(in float3 p , in float3 dir , in float3 n , in float hid) { // PASSING IN THE NORMAL 
     #ifdef ENABLE_HARD_SHADOWS 
          float sh = shadow(p , lightdir);
     #else 
          float sh = calcAO(p , -2.5 * lightdir); // USING AO TO MAKE VERY SOFT SHADOWS 
     #endif 
     float ao = calcAO(p , n);
     float diff = max(0. , dot(lightdir , -n)) * sh;
     float y = 3.35 - p.y;
     float3 amb = max(.5 , dot(dir , -n)) * .5 * AMBIENT_COLOR;
     if (hid < .5) {
          amb += max(0.2 , dot(float3 (0. , 1. , 0.) , -n)) * FLOOR_COLOR * pow(max(0. , .2 - abs(3. - p.y)) / .2 , 1.5) * 2.;
          amb += energy * pow(max(0. , .4 - abs(y)) / .4 , 2.) * max(0.2 , dot(float3 (0. , -sign(y) , 0.) , -n)) * 2.;
      }
     float3 r = reflect(lightdir , n);
     float spec = pow(max(0. , dot(dir , -r)) * sh , 10.);
     float3 col;
     float energysource = pow(max(0. , .04 - abs(y)) / .04 , 4.) * 2.;
     if (hid > 1.5) { col = float3 (1. , 1. , 1.); spec = spec * spec; }
     else {
          float k = _texture(p) * .23 + .2;
          k = min(k , 1.5 - energysource);
          col = lerp(float3 (k , k * k , k * k * k) , float3 (k, k, k) , .3);
          if (abs(hid - 1.) < .001) col *= FLOOR_COLOR * 1.3;
      }
     col = col * (amb + diff * LIGHT_COLOR) + spec * LIGHT_COLOR;
     if (hid < .5) {
          col = max(col , energy * 2. * energysource);
      }
     col *= min(1. , ao + length(energy) * .5 * max(0. , .1 - abs(y)) / .1);
     return col;
 }

float3 raymarch(in float3 from , in float3 dir)

 {
     float ey = mod(t * .5 , 1.);
     float glow , eglow , ref , sphdist , totdist = glow = eglow = ref = sphdist = 0.;
     float2 d = float2 (1. , 0.);
     float3 p , col = float3 (0. , 0. , 0.);
     float3 origdir = dir , origfrom = from , sphNorm;

     // FAKING THE SQUISHY BALL BY MOVING A RAY TRACED BALL 
    float3 wob = cos(dir * 500.0 * length(from - pth1) + (from - pth1) * 250. + _Time.y * 10.) * 0.0005;
    float t1 = Sphere(from - pth1 + wob , dir , 0.015);
    float tg = Sphere(from - pth1 + wob , dir , 0.02);
    if (t1 > 0.) {
         ref = 1.0; from += t1 * dir; sphdist = t1;
         sphNorm = normalize(from - pth1 + wob);
         dir = reflect(dir , sphNorm);
     }
    else if (tg > 0.) {
         float3 sphglowNorm = normalize(from + tg * dir - pth1 + wob);
         glow += pow(max(0. , dot(sphglowNorm , -dir)) , 5.);
     };

    for (int i = 0; i < RAY_STEPS; i++) {
         if (d.x > det && totdist < 3.0) {
              p = from + totdist * dir;
              d = de(p);
              det = detail * (1. + totdist * 60.) * (1. + ref * 5.);
              totdist += d.x;
              energy.xyz = ENERGY_COLOR * (1.5 + sin(_Time.y * 20. + p.z * 10.)) * .25;
              if (d.x < 0.015) glow += max(0. , .015 - d.x) * exp(-totdist);
              if (d.y < .5 && d.x < 0.03) { // ONLY DOING THE GLOW WHEN IT IS CLOSE ENOUGH 
                   float glw = min(abs(3.35 - p.y - ey) , abs(3.35 - p.y + ey)); // 2 glows at once 
                   eglow += max(0. , .03 - d.x) / .03 *
                    (pow(max(0. , .05 - glw) / .05 , 5.)
                    + pow(max(0. , .15 - abs(3.35 - p.y)) / .15 , 8.)) * 1.5;
               }
          }
     }
    float l = pow(max(0. , dot(normalize(-dir.xz) , normalize(lightdir.xz))) , 2.);
    l *= max(0.2 , dot(-dir , lightdir));
    float3 backg = .5 * (1.2 - l) + LIGHT_COLOR * l * .7;
    backg *= AMBIENT_COLOR;
    if (d.x <= det) {
         float3 norm = normal(p - abs(d.x - det) * dir); // DO THE NORMAL CALC OUTSIDE OF LIGHTING ( since we already have the sphere normal ) 
         col = light(p - abs(d.x - det) * dir , dir , norm , d.y) * exp(-.2 * totdist * totdist);
         col = lerp(col , backg , 1.0 - exp(-1. * pow(totdist , 1.5)));
     }
else {
 col = backg;
}
float3 lglow = LIGHT_COLOR * pow(l , 30.) * .5;
col += glow * (backg + lglow) * 1.3;
col += pow(eglow , 2.) * energy * .015;
col += lglow * min(1. , totdist * totdist * .3);
if (ref > 0.5) {
     float3 sphlight = light(origfrom + sphdist * origdir , origdir , sphNorm , 2.);
     col = lerp(col * .3 + sphlight * .7 , backg , 1.0 - exp(-1. * pow(sphdist , 1.5)));
 }
return col;
}

float3 move(inout float2x2 rotview1 , inout float2x2 rotview2) {
     float3 go = path(t);
     float3 adv = path(t + .7);
     float3 advec = normalize(adv - go);
     float an = atan2(advec.x , advec.z);
     rotview1 = float2x2 (cos(an) , sin(an) , -sin(an) , cos(an));
            an = advec.y * 1.7;
     rotview2 = float2x2 (cos(an) , sin(an) , -sin(an) , cos(an));
     return go;
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
lightdir = normalize(lightdir);
ambdir= normalize(ambdir);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

      pth1 = path(t + .3) + origin + float3 (0. , .01 , 0.);
      float2 uv = fragCoord.xy / _ScreenParams.xy * 2. - 1.;
      float2 uv2 = uv;
 #ifdef ENABLE_POSTPROCESS 
      uv *= 1. + pow(length(uv2 * uv2 * uv2 * uv2) , 4.) * .07;
 #endif 
      uv.y *= _ScreenParams.y / _ScreenParams.x;
      float2 mouse = (iMouse.xy / _ScreenParams.xy - .5) * 3.;
      if (iMouse.z < 1.) mouse = float2 (0. , 0.);
      float2x2 rotview1 , rotview2;
      float3 from = origin + move(rotview1 , rotview2);
      float3 dir = normalize(float3 (uv * .8 , 1.));
      dir.yz = mul(dir.yz, rot(mouse.y));
      dir.xz = mul(dir.xz, rot(mouse.x));
      dir.yz = mul(dir.yz, rotview2);
      dir.xz = mul(dir.xz, rotview1);
      float3 color = raymarch(from , dir);
      color = clamp(color , float3 (.0 , .0 , .0) , float3 (1. , 1. , 1.));
      color = pow(color , float3 (GAMMA, GAMMA, GAMMA)) * BRIGHTNESS;
      color = lerp(float3 (length(color), length(color), length(color)) , color , SATURATION);
 #ifdef ENABLE_POSTPROCESS 
      float3 rain = pow(SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv2 + _Time.y * 7.25468).rgb , float3 (1.5, 1.5, 1.5));
      color = lerp(rain , color , clamp(_Time.y * .5 - .5 , 0. , 1.));
      color *= 1. - pow(length(uv2 * uv2 * uv2 * uv2) * 1.1 , 6.);
      uv2.y *= _ScreenParams.y / 360.0;
      color.r *= (.5 + abs(.5 - mod(uv2.y , .021) / .021) * .5) * 1.5;
      color.g *= (.5 + abs(.5 - mod(uv2.y + .007 , .021) / .021) * .5) * 1.5;
      color.b *= (.5 + abs(.5 - mod(uv2.y + .014 , .021) / .021) * .5) * 1.5;
      color *= .9 + rain * .35;
 #endif 
      fragColor = float4 (color , 1.);
      fragColor.xyz -= 0.15;
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