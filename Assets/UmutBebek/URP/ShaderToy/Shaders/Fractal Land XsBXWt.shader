Shader "UmutBebek/URP/ShaderToy/Fractal Land XsBXWt"
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
            origin("origin", vector) = (-1.,.7,0.)
det("det", float) = 0.0
RAY_STEPS("RAY_STEPS", float) = 150
BRIGHTNESS("BRIGHTNESS ", float) = 1.2
GAMMA("GAMMA ", float) = 1.4
SATURATION("SATURATION", float) = .65
detail("detail ", float) = .001

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
            float4 origin;
float det;
float RAY_STEPS;

float BRIGHTNESS;
float GAMMA;
float SATURATION;
float detail;
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

// "Fractal Cartoon" - former "DE edge detection" by Kali 

// There are no lights and no AO , only color by normals and dark edges. 

// update: Nyan Cat cameo , thanks to code from mu6k: https: // www.shadertoy.com / view / 4dXGWH 


// #define SHOWONLYEDGES 
#define NYAN 
#define WAVES 
#define BORDER 




#define t _Time.y*.5 






 // 2D rotation function 
float2x2 rot(float a) {
     return float2x2 (cos(a) , sin(a) , -sin(a) , cos(a));
 }

// "Amazing Surface" fractal 
float4 formula(float4 p) {
          p.xz = abs(p.xz + 1.) - abs(p.xz - 1.) - p.xz;
          p.y -= .25;
          p.xy = mul (p.xy, rot(radians(35.)));
          p = p * 2. / clamp(dot(p.xyz , p.xyz) , .2 , 1.);
     return p;
 }

// Distance function 
float de(float3 pos) {
#ifdef WAVES 
     pos.y += sin(pos.z - t * 6.) * .15; // waves! 
#endif 
     float hid = 0.;
     float3 tpos = pos;
     tpos.z = abs(3. - mod(tpos.z , 6.));
     float4 p = float4 (tpos , 1.);
     for (int i = 0; i < 4; i++) { p = formula(p); }
     float fr = (length(max(float2 (0.,0.) , p.yz - 1.5)) - 1.) / p.w;
     float ro = max(abs(pos.x + 1.) - .3 , pos.y - .35);
            ro = max(ro , -max(abs(pos.x + 1.) - .1 , pos.y - .5));
     pos.z = abs(.25 - mod(pos.z , .5));
            ro = max(ro , -max(abs(pos.z) - .2 , pos.y - .3));
            ro = max(ro , -max(abs(pos.z) - .01 , -pos.y + .32));
     float d = min(fr , ro);
     return d;
 }


// Camera path 
float3 path(float ti) {
     ti *= 1.5;
     float3 p = float3 (sin(ti) , (1. - sin(ti * 2.)) * .5 , -ti * 5.) * .5;
     return p;
 }

// Calc normals , and here is edge detection , set to variable "edge" 

float edge = 0.;
float3 normal(float3 p) {
     float3 e = float3 (0.0 , det * 5. , 0.0);

     float d1 = de(p - e.yxx) , d2 = de(p + e.yxx);
     float d3 = de(p - e.xyx) , d4 = de(p + e.xyx);
     float d5 = de(p - e.xxy) , d6 = de(p + e.xxy);
     float d = de(p);
     edge = abs(d - 0.5 * (d2 + d1)) + abs(d - 0.5 * (d4 + d3)) + abs(d - 0.5 * (d6 + d5)); // edge finder 
     edge = min(1. , pow(edge , .55) * 15.);
     return normalize(float3 (d1 - d2 , d3 - d4 , d5 - d6));
 }


// Used Nyan Cat code by mu6k , with some mods 

float4 rainbow(float2 p)
 {
     float q = max(p.x , -0.1);
     float s = sin(p.x * 7.0 + t * 70.0) * 0.08;
     p.y += s;
     p.y *= 1.1;

     float4 c;
     if (p.x > 0.0) c = float4 (0 , 0 , 0 , 0); else
     if (0.0 / 6.0 < p.y && p.y < 1.0 / 6.0) c = float4 (255 , 43 , 14 , 255) / 255.0; else
     if (1.0 / 6.0 < p.y && p.y < 2.0 / 6.0) c = float4 (255 , 168 , 6 , 255) / 255.0; else
     if (2.0 / 6.0 < p.y && p.y < 3.0 / 6.0) c = float4 (255 , 244 , 0 , 255) / 255.0; else
     if (3.0 / 6.0 < p.y && p.y < 4.0 / 6.0) c = float4 (51 , 234 , 5 , 255) / 255.0; else
     if (4.0 / 6.0 < p.y && p.y < 5.0 / 6.0) c = float4 (8 , 163 , 255 , 255) / 255.0; else
     if (5.0 / 6.0 < p.y && p.y < 6.0 / 6.0) c = float4 (122 , 85 , 255 , 255) / 255.0; else
     if (abs(p.y) - .05 < 0.0001) c = float4 (0. , 0. , 0. , 1.); else
     if (abs(p.y - 1.) - .05 < 0.0001) c = float4 (0. , 0. , 0. , 1.); else
          c = float4 (0 , 0 , 0 , 0);
     c.a *= .8 - min(.8 , abs(p.x * .08));
     c.xyz = lerp(c.xyz , float3 (length(c.xyz), length(c.xyz), length(c.xyz)) , .15);
     return c;
 }

float4 nyan(float2 p)
 {
     float2 uv = p * float2 (0.4 , 1.0);
     float ns = 3.0;
     float nt = _Time.y * ns; nt -= mod(nt , 240.0 / 256.0 / 6.0); nt = mod(nt , 240.0 / 256.0);
     float ny = mod(_Time.y * ns , 1.0); ny -= mod(ny , 0.75); ny *= -0.05;
     float4 color = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , float2 (uv.x / 3.0 + 210.0 / 256.0 - nt + 0.05 , .5 - uv.y - ny));
     if (uv.x < -0.3) color.a = 0.0;
     if (uv.x > 0.2) color.a = 0.0;
     return color;
 }


// Raymarching and 2D graphics 

float3 raymarch(in float3 from , in float3 dir)

 {
     edge = 0.;
     float3 p , norm;
     float d = 100.;
     float totdist = 0.;
     for (int i = 0; i < RAY_STEPS; i++) {
          if (d > det && totdist < 25.0) {
               p = from + totdist * dir;
               d = de(p);
               det = detail * exp(.13 * totdist);
               totdist += d;
           }
      }
     float3 col = float3 (0.,0.,0.);
     p -= (det - d) * dir;
     norm = normal(p);
#ifdef SHOWONLYEDGES 
     col = 1. - float3 (edge); // show wireframe version 
#else 
     col = (1. - abs(norm)) * max(0. , 1. - edge * .8); // set normal as color with dark edges 
#endif 
     totdist = clamp(totdist , 0. , 26.);
     dir.y -= .02;
     float sunsize = 7. - max(0. , SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , float2 (.6 , .2)).x) * 5.; // responsive sun size 
     float an = atan2(dir.x , dir.y) + _Time.y * 1.5; // angle for drawing and rotating sun 
     float s = pow(clamp(1.0 - length(dir.xy) * sunsize - abs(.2 - mod(an , .4)) , 0. , 1.) , .1); // sun 
     float sb = pow(clamp(1.0 - length(dir.xy) * (sunsize - .2) - abs(.2 - mod(an , .4)) , 0. , 1.) , .1); // sun border 
     float sg = pow(clamp(1.0 - length(dir.xy) * (sunsize - 4.5) - .5 * abs(.2 - mod(an , .4)) , 0. , 1.) , 3.); // sun rays 
     float y = lerp(.45 , 1.2 , pow(smoothstep(0. , 1. , .75 - dir.y) , 2.)) * (1. - sb * .5); // gradient sky 

      // set up background with sky and sun 
     float3 backg = float3 (0.5 , 0. , 1.) * ((1. - s) * (1. - sg) * y + (1. - sb) * sg * float3 (1. , .8 , 0.15) * 3.);
           backg += float3 (1. , .9 , .1) * s;
           backg = max(backg , sg * float3 (1. , .9 , .5));

     col = lerp(float3 (1. , .9 , .3) , col , exp(-.004 * totdist * totdist)); // distant fading to sun color 
     if (totdist > 25.) col = backg; // hit background 
     col = pow(col , float3 (GAMMA, GAMMA, GAMMA)) * BRIGHTNESS;
     col = lerp(float3 (length(col), length(col), length(col)) , col , SATURATION);
#ifdef SHOWONLYEDGES 
     col = 1. - float3 (length(col));
#else 
     col *= float3 (1. , .9 , .85);
#ifdef NYAN 
     dir.yx = mul(dir.yx, rot(dir.x));
     float2 ncatpos = (dir.xy + float2 (-3. + mod(-t , 6.) , -.27));
     float4 ncat = nyan(ncatpos * 5.);
     float4 rain = rainbow(ncatpos * 10. + float2 (.8 , .5));
     if (totdist > 8.) col = lerp(col , max(float3 (.2, .2, .2) , rain.xyz) , rain.a * .9);
     if (totdist > 8.) col = lerp(col , max(float3 (.2, .2, .2) , ncat.xyz) , ncat.a * .9);
#endif 
#endif 
     return col;
 }

// get camera position 
float3 move(inout float3 dir) {
     float3 go = path(t);
     float3 adv = path(t + .7);
     float hd = de(adv);
     float3 advec = normalize(adv - go);
     float an = adv.x - go.x; an *= min(1. , abs(adv.z - go.z)) * sign(adv.z - go.z) * .7;
     dir.xy = mul(dir.xy, float2x2 (cos(an) , sin(an) , -sin(an) , cos(an)));
    an = advec.y * 1.7;
     dir.yz = mul(dir.yz, float2x2 (cos(an) , sin(an) , -sin(an) , cos(an)));
     an = atan2(advec.x , advec.z);
     dir.xz = mul(dir.xz, float2x2 (cos(an) , sin(an) , -sin(an) , cos(an)));
     return go;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 uv = fragCoord.xy / _ScreenParams.xy * 2. - 1.;
     float2 oriuv = uv;
     uv.y *= _ScreenParams.y / _ScreenParams.x;
     float2 mouse = (iMouse.xy / _ScreenParams.xy - .5) * 3.;
     if (iMouse.z < 1.) mouse = float2 (0. , -0.05);
     float fov = .9 - max(0. , .7 - _Time.y * .3);
     float3 dir = normalize(float3 (uv * fov , 1.));
     dir.yz = mul(dir.yz, rot(mouse.y));
     dir.xz = mul(dir.xz, rot(mouse.x));
     float3 from = origin + move(dir);
     float3 color = raymarch(from , dir);
     #ifdef BORDER 
     color = lerp(float3 (0., 0., 0.) , color , pow(max(0. , .95 - length(oriuv * oriuv * oriuv * float2 (1.05 , 1.1))) , .3));
     #endif 
     fragColor = float4 (color , 1.);
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