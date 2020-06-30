Shader "UmutBebek/URP/ShaderToy/Cloud Ten XtS3DD"
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
            moy("moy", float) = 0.
lgt("lgt", vector) = (0,0,0,0)

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
            float moy;
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

// Cloud Ten 
// by nimitz 2015 ( twitter: @stormoid ) 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License 
// Contact the author for other licensing options 

#define time _Time.y 
float2x2 mm2(in float a) { float c = cos(a) , s = sin(a); return float2x2 (c , s , -s , c); }
float noise(float t) { return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , float2 (t , .0) / _Channel0_ST.xy , 0.0).x; }


float noise(in float3 p)
 {
    float3 ip = floor(p);
    float3 fp = frac(p);
     fp = fp * fp * (3.0 - 2.0 * fp);
     float2 tap = (ip.xy + float2 (37.0 , 17.0) * ip.z) + fp.xy;
     float2 rz = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (tap + 0.5) / 256.0 , 0.0).yx;
     return lerp(rz.x , rz.y , fp.z);
 }

float fbm(in float3 x)
 {
    float rz = 0.;
    float a = .35;
    for (int i = 0; i < 2; i++)
     {
        rz += noise(x) * a;
        a *= .35;
        x *= 4.;
     }
    return rz;
 }

float path(in float x) { return sin(x * 0.01 - 3.1415) * 28. + 6.5; }
float map(float3 p) {
    return p.y * 0.07 + (fbm(p * 0.3) - 0.1) + sin(p.x * 0.24 + sin(p.z * .01) * 7.) * 0.22 + 0.15 + sin(p.z * 0.08) * 0.05;
 }

float march(in float3 ro , in float3 rd)
 {
    float precis = .3;
    float h = 1.;
    float d = 0.;
    for (int i = 0; i < 17; i++)
     {
        if (abs(h) < precis || d > 70.) break;
        d += h;
        float3 pos = ro + rd * d;
        pos.y += .5;
         float res = map(pos) * 7.;
        h = res;
     }
     return d;
 }


float mapV(float3 p) { return clamp(-map(p) , 0. , 1.); }
float4 marchV(in float3 ro , in float3 rd , in float t , in float3 bgc)
 {
     float4 rz = float4 (0.0 , 0.0 , 0.0 , 0.0);

     for (int i = 0; i < 150; i++)
      {
          if (rz.a > 0.99 || t > 200.) break;

          float3 pos = ro + t * rd;
        float den = mapV(pos);

        float4 col = float4 (lerp(float3 (.8 , .75 , .85) , float3 (.0 , .0 , .0) , den) , den);
        col.xyz *= lerp(bgc * bgc * 2.5 , lerp(float3 (0.1 , 0.2 , 0.55) , float3 (.8 , .85 , .9) , moy * 0.4) , clamp(-(den * 40. + 0.) * pos.y * .03 - moy * 0.5 , 0. , 1.));
        col.rgb += clamp((1. - den * 6.) + pos.y * 0.13 + .55 , 0. , 1.) * 0.35 * lerp(bgc , float3 (1 , 1 , 1) , 0.7); // Fringes 
        col += clamp(den * pos.y * .15 , -.02 , .0); // Depth occlusion 
        col *= smoothstep(0.2 + moy * 0.05 , .0 , mapV(pos + 1. * lgt)) * .85 + 0.15; // Shadows 

          col.a *= .95;
          col.rgb *= col.a;
          rz = rz + col * (1.0 - rz.a);

        t += max(.3 , (2. - den * 30.) * t * 0.011);
      }

     return clamp(rz , 0. , 1.);
 }

float pent(in float2 p) {
    float2 q = abs(p);
    return max(max(q.x * 1.176 - p.y * 0.385 , q.x * 0.727 + p.y) , -p.y * 1.237) * 1.;
 }

float3 lensFlare(float2 p , float2 pos)
 {
     float2 q = p - pos;
    float dq = dot(q , q);
    float2 dist = p * (length(p)) * 0.75;
     float ang = atan2(q.x , q.y);
    float2 pp = lerp(p , dist , 0.5);
    float sz = 0.01;
    float rz = pow(abs(frac(ang * .8 + .12) - 0.5) , 3.) * (noise(ang * 15.)) * 0.5;
    rz *= smoothstep(1.0 , 0.0 , dot(q , q));
    rz *= smoothstep(0.0 , 0.01 , dot(q , q));
    rz += max(1.0 / (1.0 + 30.0 * pent(dist + 0.8 * pos)) , .0) * 0.17;
     rz += clamp(sz - pow(pent(pp + 0.15 * pos) , 1.55) , .0 , 1.) * 5.0;
     rz += clamp(sz - pow(pent(pp + 0.1 * pos) , 2.4) , .0 , 1.) * 4.0;
     rz += clamp(sz - pow(pent(pp - 0.05 * pos) , 1.2) , .0 , 1.) * 4.0;
    rz += clamp(sz - pow(pent((pp + .5 * pos)) , 1.7) , .0 , 1.) * 4.0;
    rz += clamp(sz - pow(pent((pp + .3 * pos)) , 1.9) , .0 , 1.) * 3.0;
    rz += clamp(sz - pow(pent((pp - .2 * pos)) , 1.3) , .0 , 1.) * 4.0;
    return float3 (clamp(rz , 0. , 1.), clamp(rz, 0., 1.), clamp(rz, 0., 1.));
 }

float3x3 rot_x(float a) { float sa = sin(a); float ca = cos(a); return float3x3 (1. , .0 , .0 , .0 , ca , sa , .0 , -sa , ca); }
float3x3 rot_y(float a) { float sa = sin(a); float ca = cos(a); return float3x3 (ca , .0 , sa , .0 , 1. , .0 , -sa , .0 , ca); }
float3x3 rot_z(float a) { float sa = sin(a); float ca = cos(a); return float3x3 (ca , sa , .0 , -sa , ca , .0 , .0 , .0 , 1.); }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = q - 0.5;
     float asp = _ScreenParams.x / _ScreenParams.y;
    p.x *= asp;
     float2 mo = iMouse.xy / _ScreenParams.xy;
     moy = mo.y;
    float st = sin(time * 0.3 - 1.3) * 0.2;
    float3 ro = float3 (0. , -2. + sin(time * .3 - 1.) * 2. , time * 30.);
    ro.x = path(ro.z);
    float3 ta = ro + float3 (0 , 0 , 1);
    float3 fw = normalize(ta - ro);
    float3 uu = normalize(cross(float3 (0.0 , 1.0 , 0.0) , fw));
    float3 vv = normalize(cross(fw , uu));
    const float zoom = 1.;
    float3 rd = normalize(p.x * uu + p.y * vv + -zoom * fw);

    float rox = sin(time * 0.2) * 0.6 + 2.9;
    rox += smoothstep(0.6 , 1.2 , sin(time * 0.25)) * 3.5;
        float roy = sin(time * 0.5) * 0.2;
    float3x3 rotation = rot_x(-roy) * rot_y(-rox + st * 1.5) * rot_z(st);
     float3x3 inv_rotation = rot_z(-st) * rot_y(rox - st * 1.5) * rot_x(roy);
    rd = mul(rd, rotation);
    rd.y -= dot(p , p) * 0.06;
    rd = normalize(rd);

    float3 col = float3 (0. , 0. , 0.);
    lgt.xyz = normalize(float3 (-0.3 , mo.y + 0.1 , 1.));
    float rdl = clamp(dot(rd , lgt) , 0. , 1.);

    float3 hor = lerp(float3 (.9 , .6 , .7) * 0.35 , float3 (.5 , 0.05 , 0.05) , rdl);
    hor = lerp(hor , float3 (.5 , .8 , 1) , mo.y);
    col += lerp(float3 (.2 , .2 , .6) , hor , exp2(-(1. + 3. * (1. - rdl)) * max(abs(rd.y) , 0.))) * .6;
    col += .8 * float3 (1. , .9 , .9) * exp2(rdl * 650. - 650.);
    col += .3 * float3 (1. , 1. , 0.1) * exp2(rdl * 100. - 100.);
    col += .5 * float3 (1. , .7 , 0.) * exp2(rdl * 50. - 50.);
    col += .4 * float3 (1. , 0. , 0.05) * exp2(rdl * 10. - 10.);
    float3 bgc = col;

    float rz = march(ro , rd);

    if (rz < 70.)
     {
        float4 res = marchV(ro , rd , rz - 5. , bgc);
         col = col * (1.0 - res.w) + res.xyz;
     }

    float3 proj = (mul(-lgt.xyz , inv_rotation));
    col += 1.4 * float3 (0.7 , 0.7 , 0.4) * clamp(lensFlare(p , -proj.xy / proj.z * zoom) * proj.z , 0. , 1.);

    float g = smoothstep(0.03 , .97 , mo.x);
    col = lerp(lerp(col , col.brg * float3 (1 , 0.75 , 1) , clamp(g * 2. , 0.0 , 1.0)) , col.bgr , clamp((g - 0.5) * 2. , 0.0 , 1.));

     col = clamp(col , 0. , 1.);
    col = col * 0.5 + 0.5 * col * col * (3.0 - 2.0 * col); // saturation 
    col = pow(col , float3 (0.416667, 0.416667, 0.416667)) * 1.055 - 0.055; // sRGB 
     col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y) , 0.12); // Vign 

     fragColor = float4 (col , 1.0);
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