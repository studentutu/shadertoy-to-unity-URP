Shader "UmutBebek/URP/ShaderToy/Sirenian Dawn XsyGWV BufferA"
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
            ITR("ITR", float) = 90
FAR("FAR", float) = 400.
lgt("lgt", vector) = (-.523 , .41 , -.747)

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

            //Blend One Zero
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
            float ITR;
float FAR;
float4 lgt;


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

float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
{
    //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
    float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
    return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
}

// Sirenian Dawn by nimitz ( twitter: @stormoid ) 
// https: // www.shadertoy.com / view / XsyGWV 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 



#define time _Time.y 




 // form iq , see: http: // www.iquilezles.org / www / articles / morenoise / morenoise.htm 
float3 noised(in float2 x)
 {
    float2 p = floor(x);
    float2 f = frac(x);
    float2 u = f * f * (3.0 - 2.0 * f);
     float a = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (0.5 , 0.5)) / 256.0 , 0.0).x;
     float b = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (1.5 , 0.5)) / 256.0 , 0.0).x;
     float c = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (0.5 , 1.5)) / 256.0 , 0.0).x;
     float d = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (p + float2 (1.5 , 1.5)) / 256.0 , 0.0).x;
     return float3 (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y ,
                    6.0 * f * (1.0 - f) * (float2 (b - a , c - a) + (a - b - c + d) * u.yx));
 }

float terrain(in float2 p)
 {
    float rz = 0.;
    float z = 1.;
     float2 d = float2 (0.0 , 0.0);
    float scl = 2.95;
    float zscl = -.4;
    float zz = 5.;
    for (int i = 0; i < 5; i++)
     {
        float3 n = noised(p);
        d += pow(abs(n.yz) , float2 (zz, zz));
        d -= smoothstep(-.5 , 1.5 , n.yz);
        zz -= 1.;
        rz += z * n.x / (dot(d , d) + .85);
        z *= zscl;
        zscl *= .8;
        p = mul(float2x2(0.80, 0.60, -0.60, 0.80) , p) * scl;
     }

    rz /= smoothstep(1.5 , -.5 , rz) + .75;
    return rz;
 }

float map(float3 p)
 {
    return p.y - (terrain(p.zx * 0.07)) * 2.7 - 1.;
 }

/* The idea is simple , as the ray gets further from the eye , I increase
    the step size of the raymarching and lower the target precision ,
    this allows for better performance with virtually no loss in visual quality. */
float march(in float3 ro , in float3 rd , out float itrc)
 {
    float t = 0.;
    float d = map(rd * t + ro);
    float precis = 0.0001;
    for (int i = 0; i <= ITR; i++)
     {
        if (abs(d) < precis || t > FAR) break;
        precis = t * 0.0001;
        float rl = max(t * 0.02 , 1.);
        t += d * rl;
        d = map(rd * t + ro) * 0.7;
        itrc++;
     }

    return t;
 }

float3 rotx(float3 p , float a) {
    float s = sin(a) , c = cos(a);
    return float3 (p.x , c * p.y - s * p.z , s * p.y + c * p.z);
 }

float3 roty(float3 p , float a) {
    float s = sin(a) , c = cos(a);
    return float3 (c * p.x + s * p.z , p.y , -s * p.x + c * p.z);
 }

float3 rotz(float3 p , float a) {
    float s = sin(a) , c = cos(a);
    return float3 (c * p.x - s * p.y , s * p.x + c * p.y , p.z);
 }

float3 normal(in float3 p , in float ds)
 {
    float2 e = float2 (-1. , 1.) * 0.0005 * pow(ds , 1.);
     return normalize(e.yxx * map(p + e.yxx) + e.xxy * map(p + e.xxy) +
                          e.xyx * map(p + e.xyx) + e.yyy * map(p + e.yyy));
 }

float noise(in float2 x) { return SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , x * .01).x; }
float fbm(in float2 p)
 {
     float z = .5;
     float rz = 0.;
     for (float i = 0.; i < 3.; i++)
      {
        rz += (sin(noise(p) * 5.) * 0.5 + 0.5) * z;
          z *= 0.5;
          p = p * 2.;
      }
     return rz;
 }

float bnoise(in float2 p) { return fbm(p * 3.); }
float3 bump(in float3 p , in float3 n , in float ds)
 {
    float2 e = float2 (0.005 * ds , 0);
    float n0 = bnoise(p.zx);
    float3 d = float3 (bnoise(p.zx + e.xy) - n0 , 1. , bnoise(p.zx + e.yx) - n0) / e.x * 0.025;
    d -= n * dot(n , d);
    n = normalize(n - d);
    return n;
 }

float curv(in float3 p , in float w)
 {
    float2 e = float2 (-1. , 1.) * w;
    float t1 = map(p + e.yxx) , t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx) , t4 = map(p + e.yyy);
    return .15 / e.y * (t1 + t2 + t3 + t4 - 4. * map(p));
 }

// Based on: http: // www.iquilezles.org / www / articles / fog / fog.htm 
float3 fog(float3 ro , float3 rd , float3 col , float ds)
 {
    float3 pos = ro + rd * ds;
    float mx = (fbm(pos.zx * 0.1 - time * 0.05) - 0.5) * .2;

    const float b = 1.;
    float den = 0.3 * exp(-ro.y * b) * (1.0 - exp(-ds * rd.y * b)) / rd.y;
    float sdt = max(dot(rd , lgt) , 0.);
    float3 fogColor = lerp(float3 (0.5 , 0.2 , 0.15) * 1.2 , float3 (1.1 , 0.6 , 0.45) * 1.3 , pow(sdt , 2.0) + mx * 0.5);
    return lerp(col , fogColor , clamp(den + mx , 0. , 1.));
 }

float linstep(in float mn , in float mx , in float x) {
     return clamp((x - mn) / (mx - mn) , 0. , 1.);
 }

// Complete hack , but looks good enough : ) 
float3 scatter(float3 ro , float3 rd)
 {
    float sd = max(dot(lgt , rd) * 0.5 + 0.5 , 0.);
    float dtp = 13. - (ro + rd * (FAR)).y * 3.5;
    float hori = (linstep(-1500. , 0.0 , dtp) - linstep(11. , 500. , dtp)) * 1.;
    hori *= pow(sd , .04);

    float3 col = float3 (0 , 0 , 0);
    col += pow(hori , 200.) * float3 (1.0 , 0.7 , 0.5) * 3.;
    col += pow(hori , 25.) * float3 (1.0 , 0.5 , 0.25) * .3;
    col += pow(hori , 7.) * float3 (1.0 , 0.4 , 0.25) * .8;

    return col;
 }

float3 nmzHash33(float3 q)
 {
    //uvec3 p = uvec3(int3 (q));
    int3 p = int3(int3 (q));
    //p = p * uvec3(374761393U , 1103515245U , 668265263U) + p.zxy + p.yzx;
    p = p * int3(374761393U , 1103515245U , 668265263U) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3U));
    return float3 (p ^ (p >> 16U)) * (1.0 / float3 (0xffffffffU, 0xffffffffU, 0xffffffffU));
 }

// Very happy with this star function , cheap and smooth 
float3 stars(in float3 p)
 {
    float3 c = float3 (0. , 0. , 0.);
    float res = _ScreenParams.x * 0.8;

     for (float i = 0.; i < 3.; i++)
     {
        float3 q = frac(p * (.15 * res)) - 0.5;
        float3 id = floor(p * (.15 * res));
        float2 rn = nmzHash33(id).xy;
        float c2 = 1. - smoothstep(0. , .6 , length(q));
        c2 *= step(rn.x , .0005 + i * i * 0.001);
        c += c2 * (lerp(float3 (1.0 , 0.49 , 0.1) , float3 (0.75 , 0.9 , 1.) , rn.y) * 0.25 + 0.75);
        p *= 1.4;
     }
    return c * c * .7;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = q - 0.5;
     p.x *= _ScreenParams.x / _ScreenParams.y;
     float2 mo = iMouse.xy / _ScreenParams.xy - .5;
    mo = (mo == float2 (-.5, -.5)) ? mo = float2 (-.2 , 0.3) : mo;
    mo.x *= 1.2;
    mo -= float2 (1.2 , -0.1);
     mo.x *= _ScreenParams.x / _ScreenParams.y;
    mo.x += sin(time * 0.15) * 0.2;

    float3 ro = float3 (650. , sin(time * 0.2) * 0.25 + 10. , -time);
    float3 eye = normalize(float3 (cos(mo.x) , -0.5 + mo.y , sin(mo.x)));
    float3 right = normalize(float3 (cos(mo.x + 1.5708) , 0. , sin(mo.x + 1.5708)));
    float3 up = normalize(cross(right , eye));
     float3 rd = normalize((p.x * right + p.y * up) * 1.05 + eye);
    rd.y += abs(p.x * p.x * 0.015);
    rd = normalize(rd);

    float count = 0.;
     float rz = march(ro , rd , count);

    float3 scatt = scatter(ro , rd);

    float3 bg = stars(rd) * (1.0 - clamp(dot(scatt , float3 (1.3, 1.3, 1.3)) , 0. , 1.));
    float3 col = bg;

    float3 pos = ro + rz * rd;
    float3 nor = normal(pos , rz);
    if (rz < FAR)
     {
        nor = bump(pos , nor , rz);
        float amb = clamp(0.5 + 0.5 * nor.y , 0.0 , 1.0);
        float dif = clamp(dot(nor , lgt) , 0.0 , 1.0);
        float bac = clamp(dot(nor , normalize(float3 (-lgt.x , 0.0 , -lgt.z))) , 0.0 , 1.0);
        float spe = pow(clamp(dot(reflect(rd , nor) , lgt) , 0.0 , 1.0) , 500.);
        float fre = pow(clamp(1.0 + dot(nor , rd) , 0.0 , 1.0) , 2.0);
        float3 brdf = 1. * amb * float3 (0.10 , 0.11 , 0.12);
        brdf += bac * float3 (0.15 , 0.05 , 0.04);
        brdf += 2.3 * dif * float3 (.9 , 0.4 , 0.25);
        col = float3 (0.25 , 0.25 , 0.3);
        float crv = curv(pos , 2.) * 1.;
        float crv2 = curv(pos , .4) * 2.5;

        col += clamp(crv * 0.9 , -1. , 1.) * float3 (0.25 , .6 , .5);
        col = col * brdf + col * spe * .1 + .1 * fre * col;
        col *= crv * 1. + 1.;
        col *= crv2 * 1. + 1.;
     }

    col = fog(ro , rd , col , rz);
    col = lerp(col , bg , smoothstep(FAR - 150. , FAR , rz));
    col += scatt;

    col = pow(col , float3 (0.93 , 1.0 , 1.0));
    col = lerp(col , smoothstep(0. , 1. , col) , 0.2);
    col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.1) * 0.9 + 0.1;

    float4 past = SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , q);
    float tOver = clamp(iTimeDelta - (1. / 60.) , 0. , 1.);

    // if ( count / pow ( rz , 0.65 ) > 3.3 ) col = lerp ( col , past.rgb , clamp ( 1.0 - _ScreenParams.x * 0.0003 , 0. , 1. ) ) ; 
   if (count / pow(rz , 0.65) > 3.3) col = lerp(col , past.rgb , clamp(0.85 - iTimeDelta * 7. , 0. , 1.));

    fragColor = float4 (col , 1.0);
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