Shader "UmutBebek/URP/ShaderToy/Wet stone ldSSzV"
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
               float darken = 0.10;
               item.x = max(item.x - darken, 0);
               item.y = max(item.y - darken, 0);
               item.z = max(item.z - darken, 0);
               return item;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           /*
"Wet stone" by Alexander Alekseev aka TDM - 2014
License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License.
Contact: tdmaav@gmail.com
 */

#define SMOOTH 
#define AA 

static const int NUM_STEPS = 32;
static const int AO_SAMPLES = 4;
static const float2 AO_PARAM = float2 (1.2 , 3.5);
static const float2 CORNER_PARAM = float2 (0.25 , 40.0);
static const float INV_AO_SAMPLES = 1.0 / float(AO_SAMPLES);
static const float TRESHOLD = 0.1;
static const float EPSILON = 1e-3;
static const float LIGHT_INTENSITY = 0.25;
static const float3 RED = float3 (1.0 , 0.7 , 0.7) * LIGHT_INTENSITY;
static const float3 ORANGE = float3 (1.0 , 0.67 , 0.43) * LIGHT_INTENSITY;
static const float3 BLUE = float3 (0.54 , 0.77 , 1.0) * LIGHT_INTENSITY;
static const float3 WHITE = float3 (1.2 , 1.07 , 0.98) * LIGHT_INTENSITY;

static const float DISPLACEMENT = 0.1;

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
float3 saturation(float3 c , float t) {
    return lerp(float3 (dot(c , float3 (0.2126 , 0.7152 , 0.0722)),
        dot(c, float3 (0.2126, 0.7152, 0.0722)),
        dot(c, float3 (0.2126, 0.7152, 0.0722))) , c , t);
 }
float hash11(float p) {
    return frac(sin(p * 727.1) * 435.545);
 }
float hash12(float2 p) {
     float h = dot(p , float2 (127.1 , 311.7));
    return frac(sin(h) * 437.545);
 }
float3 hash31(float p) {
     float3 h = float3 (127.231 , 491.7 , 718.423) * p;
    return frac(sin(h) * 435.543);
 }

// 3d noise 
float noise_3(in float3 p) {
    float3 i = floor(p);
    float3 f = frac(p);
     float3 u = f * f * (3.0 - 2.0 * f);

    float2 ii = i.xy + i.z * float2 (5.0, 5.0);
    float a = hash12(ii + float2 (0.0 , 0.0));
     float b = hash12(ii + float2 (1.0 , 0.0));
    float c = hash12(ii + float2 (0.0 , 1.0));
     float d = hash12(ii + float2 (1.0 , 1.0));
    float v1 = lerp(lerp(a , b , u.x) , lerp(c , d , u.x) , u.y);

    ii += float2 (5.0, 5.0);
    a = hash12(ii + float2 (0.0 , 0.0));
     b = hash12(ii + float2 (1.0 , 0.0));
    c = hash12(ii + float2 (0.0 , 1.0));
     d = hash12(ii + float2 (1.0 , 1.0));
    float v2 = lerp(lerp(a , b , u.x) , lerp(c , d , u.x) , u.y);

    return max(lerp(v1 , v2 , u.z) , 0.0);
 }

// fBm 
float fbm3(float3 p , float a , float f) {
    return noise_3(p);
 }

float fbm3_high(float3 p , float a , float f) {
    float ret = 0.0;
    float amp = 1.0;
    float frq = 1.0;
    for (int i = 0; i < 5; i++) {
        float n = pow(noise_3(p * frq) , 2.0);
        ret += n * amp;
        frq *= f;
        amp *= a * (pow(n , 0.2));
     }
    return ret;
 }

// lighting 
float diffuse(float3 n , float3 l , float p) { return pow(max(dot(n , l) , 0.0) , p); }
float specular(float3 n , float3 l , float3 e , float s) {
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e , n) , l) , 0.0) , s) * nrm;
 }

// distance functions 
float plane(float3 gp , float4 p) {
     return dot(p.xyz , gp + p.xyz * p.w);
 }
float sphere(float3 p , float r) {
     return length(p) - r;
 }
float capsule(float3 p , float r , float h) {
    p.y -= clamp(p.y , -h , h);
     return length(p) - r;
 }
float cylinder(float3 p , float r , float h) {
     return max(abs(p.y / h) , capsule(p , r , h));
 }
float box(float3 p , float3 s) {
     p = abs(p) - s;
    return max(max(p.x , p.y) , p.z);
 }
float rbox(float3 p , float3 s) {
     p = abs(p) - s;
    return length(p - min(p , 0.0));
 }
float quad(float3 p , float2 s) {
     p = abs(p) - float3 (s.x , 0.0 , s.y);
    return max(max(p.x , p.y) , p.z);
 }

// boolean operations 
float boolUnion(float a , float b) { return min(a , b); }
float boolIntersect(float a , float b) { return max(a , b); }
float boolSub(float a , float b) { return max(a , -b); }

// smooth operations. thanks to iq 
float boolSmoothIntersect(float a , float b , float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
    return lerp(a , b , h) + k * h * (1.0 - h);
 }
float boolSmoothSub(float a , float b , float k) {
    return boolSmoothIntersect(a , -b , k);
 }

// world 
float rock(float3 p) {
    float d = sphere(p , 1.0);
    for (int i = 0; i < 9; i++) {
        float ii = float(i);
        float r = 2.5 + hash11(ii);
        float3 v = normalize(hash31(ii) * 2.0 - 1.0);
        #ifdef SMOOTH 
        d = boolSmoothSub(d , sphere(p + v * r , r * 0.8) , 0.03);
        #else 
         d = boolSub(d , sphere(p + v * r , r * 0.8));
        #endif 
     }
    return d;
 }

float map(float3 p) {
    float d = rock(p) + fbm3(p * 4.0 , 0.4 , 2.96) * DISPLACEMENT;
    d = boolUnion(d , plane(p , float4 (0.0 , 1.0 , 0.0 , 1.0)));
    return d;
 }

float map_detailed(float3 p) {
    float d = rock(p) + fbm3_high(p * 4.0 , 0.4 , 2.96) * DISPLACEMENT;
    d = boolUnion(d , plane(p , float4 (0.0 , 1.0 , 0.0 , 1.0)));
    return d;
 }

// tracing 
float3 getNormal(float3 p , float dens) {
    float3 n;
    n.x = map_detailed(float3 (p.x + EPSILON , p.y , p.z));
    n.y = map_detailed(float3 (p.x , p.y + EPSILON , p.z));
    n.z = map_detailed(float3 (p.x , p.y , p.z + EPSILON));
    return normalize(n - map_detailed(p));
 }
float2 getOcclusion(float3 p , float3 n) {
    float2 r = float2 (0.0 , 0.0);
    for (int i = 0; i < AO_SAMPLES; i++) {
        float f = float(i) * INV_AO_SAMPLES;
        float hao = 0.01 + f * AO_PARAM.x;
        float hc = 0.01 + f * CORNER_PARAM.x;
        float dao = map(p + n * hao) - TRESHOLD;
        float dc = map(p - n * hc) - TRESHOLD;
        r.x += clamp(hao - dao , 0.0 , 1.0) * (1.0 - f);
        r.y += clamp(hc + dc , 0.0 , 1.0) * (1.0 - f);
     }
    r.x = clamp(1.0 - r.x * INV_AO_SAMPLES * AO_PARAM.y , 0.0 , 1.0);
    r.y = clamp(r.y * INV_AO_SAMPLES * CORNER_PARAM.y , 0.0 , 1.0);
    return r;
 }
float2 spheretracing(float3 ori , float3 dir , out float3 p) {
    float2 td = float2 (0.0 , 0.0);
    for (int i = 0; i < NUM_STEPS; i++) {
        p = ori + dir * td.x;
        td.y = map(p);
        if (td.y < TRESHOLD) break;
        td.x += (td.y - TRESHOLD) * 0.9;
     }
    return td;
 }

// stone 
float3 getStoneColor(float3 p , float c , float3 l , float3 n , float3 e) {
    c = min(c + pow(noise_3(float3 (p.x * 20.0 , 0.0 , p.z * 20.0)) , 70.0) * 8.0 , 1.0);
    float ic = pow(1.0 - c , 0.5);
    float3 base = float3 (0.42 , 0.3 , 0.2) * 0.35;
    float3 sand = float3 (0.51 , 0.41 , 0.32) * 0.9;
    float3 color = lerp(base , sand , c);

    float f = pow(1.0 - max(dot(n , -e) , 0.0) , 5.0) * 0.75 * ic;
    color += float3 (diffuse(n , l , 0.5) * WHITE);
    color += float3 (specular(n , l , e , 8.0) * WHITE * 1.5 * ic);
    n = normalize(n - normalize(p) * 0.4);
    color += float3 (specular(n , l , e , 80.0) * WHITE * 1.5 * ic);
    color = lerp(color , float3 (1.0 , 1.0 , 1.0) , f);

    color *= sqrt(abs(p.y * 0.5 + 0.5)) * 0.4 + 0.6;
    color *= (n.y * 0.5 + 0.5) * 0.4 + 0.6;

    return color;
 }

float3 getPixel(in float2 coord , float time) {
    float2 iuv = coord / _ScreenParams.xy * 2.0 - 1.0;
    float2 uv = iuv;
    uv.x *= _ScreenParams.x / _ScreenParams.y;

    // ray 
   float3 ang = float3 (0.0 , 0.2 , time);
   if (iMouse.z > 0.0) ang = float3 (0.0 , clamp(2.0 - iMouse.y * 0.01 , 0.0 , 3.1415) , iMouse.x * 0.01);
    float3x3 rot = fromEuler(ang);

   float3 ori = float3 (0.0 , 0.0 , 2.8);
   float3 dir = normalize(float3 (uv.xy , -2.0));
   ori = mul(ori , rot);
   dir = mul(dir , rot);

   // tracing 
  float3 p;
  float2 td = spheretracing(ori , dir , p);
  float3 n = getNormal(p , td.y);
  float2 occ = getOcclusion(p , n);
  float3 light = normalize(float3 (0.0 , 1.0 , 0.0));

  // color 
 float3 color = float3 (1.0 , 1.0 , 1.0);
 if (td.x < 3.5 && p.y > -0.89) color = getStoneColor(p , occ.y , light , n , dir);
 color *= occ.x;
 return color;
}

// main 
half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float time = _Time.y * 0.3;

 #ifdef AA 
     float3 color = float3 (0.0 , 0.0 , 0.0);
     for (int i = -1; i <= 1; i++)
     for (int j = -1; j <= 1; j++) {
         float2 uv = fragCoord + float2 (i , j) / 3.0;
         color += getPixel(uv , time);
      }
     color /= 9.0;
 #else 
     float3 color = getPixel(fragCoord , time);
 #endif 
     color = sqrt(color);
     color = saturation(color , 1.7);

     // vignette 
    float2 iuv = fragCoord / _ScreenParams.xy * 2.0 - 1.0;
    float vgn = smoothstep(1.2 , 0.7 , abs(iuv.y)) * smoothstep(1.1 , 0.8 , abs(iuv.x));
    color *= 1.0 - (1.0 - vgn) * 0.15;

    fragColor = float4 (color, 1.0);
    fragColor.xyz = makeDarker(fragColor.xyz);
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