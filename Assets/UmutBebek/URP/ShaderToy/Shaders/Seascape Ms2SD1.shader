Shader "UmutBebek/URP/ShaderToy/Seascape Ms2SD1"
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
            NUM_STEPS("NUM_STEPS", int) = 8

EPSILON("EPSILON", float) = 0.1
ITER_GEOMETRY("ITER_GEOMETRY", int) = 3
ITER_FRAGMENT("ITER_FRAGMENT", int) = 5
SEA_HEIGHT("SEA_HEIGHT", float) = 0.6
SEA_CHOPPY("SEA_CHOPPY", float) = 4.0
SEA_SPEED("SEA_SPEED", float) = 0.8
SEA_FREQ("SEA_FREQ", float) = 0.16
SEA_BASE("SEA_BASE", vector) = (0.0,0.09,0.18)
SEA_WATER_COLOR("SEA_WATER_COLOR", vector) = (0.48,0.54,0.36)


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
            int NUM_STEPS;

float EPSILON;
int ITER_GEOMETRY;
int ITER_FRAGMENT;
float SEA_HEIGHT;
float SEA_CHOPPY;
float SEA_SPEED;
float SEA_FREQ;
float4 SEA_BASE;
float4 SEA_WATER_COLOR;


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
* "Seascape" by Alexander Alekseev aka TDM - 2014
* License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License.
* Contact: tdmaav@gmail.com
*/




#define EPSILON_NRM ( 0.1 / _ScreenParams.x ) 
#define AA 

// sea 
//const float2x2 octave_m = float2x2(1.6, 1.2, -1.2, 1.6);







#define SEA_TIME ( 1.0 + _Time.y * SEA_SPEED ) 


 // math 
float3x3 fromEuler(float3 ang) {
     float2 a1 = float2 (sin(ang.x) , cos(ang.x));
    float2 a2 = float2 (sin(ang.y) , cos(ang.y));
    float2 a3 = float2 (sin(ang.z) , cos(ang.z));
    float3x3 m;
    m[0] = float3 (a1.y * a3.y + a1.x * a2.x * a3.x , a1.y * a2.x * a3.x + a3.y * a1.x , -a2.y * a3.x);
     m[1] = float3 (-a2.y * a1.x , a1.y * a2.y , a2.x);
     m[2] = float3 (a3.y * a1.x * a2.x + a1.y * a3.x , a1.x * a3.x - a1.y * a3.y * a2.x , a2.y * a3.y);
     return m;
 }
float hash(float2 p) {
     float h = dot(p , float2 (127.1 , 311.7));
    return frac(sin(h) * 43758.5453123);
 }
float noise(in float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
     float2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * lerp(lerp(hash(i + float2 (0.0 , 0.0)) ,
                     hash(i + float2 (1.0 , 0.0)) , u.x) ,
                lerp(hash(i + float2 (0.0 , 1.0)) ,
                     hash(i + float2 (1.0 , 1.0)) , u.x) , u.y);
 }

// lighting 
float diffuse(float3 n , float3 l , float p) {
    return pow(dot(n , l) * 0.4 + 0.6 , p);
 }
float specular(float3 n , float3 l , float3 e , float s) {
    float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e , n) , l) , 0.0) , s) * nrm;
 }

// sky 
float3 getSkyColor(float3 e) {
    e.y = (max(e.y , 0.0) * 0.8 + 0.2) * 0.8;
    return float3 (pow(1.0 - e.y , 2.0) , 1.0 - e.y , 0.6 + (1.0 - e.y) * 0.4) * 1.1;
 }

// sea 
float sea_octave(float2 uv , float choppy) {
    uv += noise(uv);
    float2 wv = 1.0 - abs(sin(uv));
    float2 swv = abs(cos(uv));
    wv = lerp(wv , swv , wv);
    return pow(1.0 - pow(wv.x * wv.y , 0.65) , choppy);
 }

float map(float3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    float2 uv = p.xz; uv.x *= 0.75;

    float d , h = 0.0;
    for (int i = 0; i < ITER_GEOMETRY; i++) {
         d = sea_octave((uv + SEA_TIME) * freq , choppy);
         d += sea_octave((uv - SEA_TIME) * freq , choppy);
        h += d * amp;
         uv = mul(uv, float2x2(1.6, 1.2, -1.2, 1.6));
         freq *= 1.9; 
         amp *= 0.22;
        choppy = lerp(choppy , 1.0 , 0.2);
     }
    return p.y - h;
 }

float map_detailed(float3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    float2 uv = p.xz; uv.x *= 0.75;

    float d , h = 0.0;
    for (int i = 0; i < ITER_FRAGMENT; i++) {
         d = sea_octave((uv + SEA_TIME) * freq , choppy);
         d += sea_octave((uv - SEA_TIME) * freq , choppy);
        h += d * amp;
         uv = mul(uv, float2x2(1.6, 1.2, -1.2, 1.6));
         freq *= 1.9; 
         amp *= 0.22;
        choppy = lerp(choppy , 1.0 , 0.2);
     }
    return p.y - h;
 }

float3 getSeaColor(float3 p , float3 n , float3 l , float3 eye , float3 dist) {
    float fresnel = clamp(1.0 - dot(n , -eye) , 0.0 , 1.0);
    fresnel = pow(fresnel , 3.0) * 0.5;

    float3 reflected = getSkyColor(reflect(eye , n));
    float3 refracted = SEA_BASE + diffuse(n , l , 80.0) * SEA_WATER_COLOR.xyz * 0.12;

    float3 color = lerp(refracted , reflected , fresnel);

    float atten = max(1.0 - dot(dist , dist) * 0.001 , 0.0);
    color += SEA_WATER_COLOR.xyz * (p.y - SEA_HEIGHT) * 0.18 * atten;

    color += float3 (specular(n , l , eye , 60.0), specular(n, l, eye, 60.0), specular(n, l, eye, 60.0));

    return color;
 }

// tracing 
float3 getNormal(float3 p , float eps) {
    float3 n;
    n.y = map_detailed(p);
    n.x = map_detailed(float3 (p.x + eps , p.y , p.z)) - n.y;
    n.z = map_detailed(float3 (p.x , p.y , p.z + eps)) - n.y;
    n.y = eps;
    return normalize(n);
 }

float heightMapTracing(float3 ori , float3 dir , out float3 p) {
    float tm = 0.0;
    float tx = 1000.0;
    float hx = map(ori + dir * tx);
    if (hx > 0.0) return tx;
    float hm = map(ori + dir * tm);
    float tmid = 0.0;
    for (int i = 0; i < NUM_STEPS; i++) {
        tmid = lerp(tm , tx , hm / (hm - hx));
        p = ori + dir * tmid;
         float hmid = map(p);
          if (hmid < 0.0) {
             tx = tmid;
            hx = hmid;
         }
else {
tm = tmid;
hm = hmid;
}
}
return tmid;
}

float3 getPixel(in float2 coord , float time) {
    float2 uv = coord / _ScreenParams.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= _ScreenParams.x / _ScreenParams.y;

    // ray 
   float3 ang = float3 (sin(time * 3.0) * 0.1 , sin(time) * 0.2 + 0.3 , time);
   float3 ori = float3 (0.0 , 3.5 , time * 5.0);
   float3 dir = normalize(float3 (uv.xy , -2.0)); dir.z += length(uv) * 0.14;
   dir = mul(normalize(dir), fromEuler(ang));

   // tracing 
  float3 p;
  heightMapTracing(ori , dir , p);
  float3 dist = p - ori;
  float3 n = getNormal(p , dot(dist , dist) * EPSILON_NRM);
  float3 light = normalize(float3 (0.0 , 1.0 , 0.8));

  // color 
 return lerp(
     getSkyColor(dir) ,
     getSeaColor(p , n , light , dir , dist) ,
      pow(smoothstep(0.0 , -0.02 , dir.y) , 0.2));
}

// main 
half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float time = _Time.y * 0.3 + iMouse.x * 0.01;

#ifdef AA 
    float3 color = float3 (0.0, 0.0, 0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
             float2 uv = fragCoord + float2 (i , j) / 3.0;
              color += getPixel(uv , time);
         }
     }
    color /= 9.0;
#else 
    float3 color = getPixel(fragCoord , time);
#endif 

    // post 
    fragColor = float4 (pow(color , float3 (0.65, 0.65, 0.65)) , 1.0);
return fragColor-0.1;
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