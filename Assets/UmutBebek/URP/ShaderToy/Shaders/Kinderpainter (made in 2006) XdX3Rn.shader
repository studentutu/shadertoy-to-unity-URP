Shader "UmutBebek/URP/ShaderToy/Kinderpainter (made in 2006) XdX3Rn"
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

           // Created by beautypi - beautypi / 2012 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// See: 
// * http: // iquilezles.org / prods / index.htm#kinderpainter 
// * http: // www.pouet.net / prod.php?which = 51762 


float4 fpar00[6];
float4 fpar01[6];

float cylinder(in float4 sph , in float3 ro , in float3 rd)
 {
    float3 d = ro - sph.xyz;
    float a = dot(rd.xz , rd.xz);
    float b = dot(rd.xz , d.xz);
    float c = dot(d.xz , d.xz) - sph.w * sph.w;
    float t;

    t = b * b - a * c;
    if (t > 0.0)
     {
        t = -(b + sqrt(t)) / a;
     }

    return t - .001;

 }


float esfera(in float4 sph , in float3 ro , in float3 rd)
 {
    float3 d = ro - sph.xyz;
    float b = dot(rd , d);
    float c = dot(d , d) - sph.w * sph.w;
    float t = b * b - c;

    if (t > 0.0)
     {
        t = -b - sqrt(t);
     }

    return t - .001;
 }


bool esfera2(in float4 sph , in float3 ro , in float3 rd , in float tmin)
 {
    float3 d = ro - sph.xyz;
    float b = dot(rd , d);
    float c = dot(d , d) - sph.w * sph.w;

    float t = b * b - c;
    bool r = false;

    if (t > 0.0)
     {
        t = -b - sqrt(t);
        r = (t > 0.0) && (t < tmin);
     }

    return r;
 }

bool cylinder2(in float4 sph , in float3 ro , in float3 rd , in float tmin)
 {
    float3 d = ro - sph.xyz;
    float a = dot(rd.xz , rd.xz);
    float b = dot(rd.xz , d.xz);
    float c = dot(d.xz , d.xz) - sph.w * sph.w;
    float t = b * b - a * c;
    bool r = false;
    if (t > 0.0)
     {
        t = -(b + sqrt(t));
        r = (t > 0.0) && (t < (tmin* a));
     }
    return r;
 }

float plane(in float4 pla , in float3 ro , in float3 rd)
 {
    float de = dot(pla.xyz , rd);
    de = sign(de) * max(abs(de) , 0.001);
    float t = -(dot(pla.xyz , ro) + pla.w) / de;
    return t;
 }

float3 calcnor(in float4 obj , in float4 col , in float3 inter , out float2 uv)
 {
    float3 nor;
    if (col.w > 2.5)
     {
        nor.xz = inter.xz - obj.xz;
        nor.y = 0.0;
        nor = nor / obj.w;
        // uv = float2 ( atan2 ( nor.x , nor.z ) / 3.14159 , inter.y ) ; 
       uv = float2 (nor.x , inter.y);
    }
   else if (col.w > 1.5)
    {
       nor = obj.xyz;
       uv = inter.xz * .2;
    }
   else
    {
       nor = inter - obj.xyz;
       nor = nor / obj.w;
       uv = nor.xy;
    }

   return nor;
}

float4 cmov(in float4 a , in float4 b , in bool cond)
 {
    return cond ? b : a;
 }

float cmov(in float a , in float b , in bool cond)
 {
    return cond ? b : a;
 }

int cmov(in int a , in int b , in bool cond)
 {
    return cond ? b : a;
 }

float intersect(in float3 ro , in float3 rd , out float4 obj , out float4 col)
 {
    float tmin = 100000.0;
    float t;

    obj = fpar00[5];
    col = fpar01[5];

    bool isok;

    t = esfera(fpar00[0] , ro , rd);
    isok = (t > 0.001) && (t < tmin);
    obj = cmov(obj , fpar00[0] , isok);
    col = cmov(col , fpar01[0] , isok);
    tmin = cmov(tmin , t , isok);

    t = esfera(fpar00[1] , ro , rd);
    isok = (t > 0.001) && (t < tmin);
    obj = cmov(obj , fpar00[1] , isok);
    col = cmov(col , fpar01[1] , isok);
    tmin = cmov(tmin , t , isok);

    t = cylinder(fpar00[2] , ro , rd);
    isok = (t > 0.001 && t < tmin);
    obj = cmov(obj , fpar00[2] , isok);
    col = cmov(col , fpar01[2] , isok);
    tmin = cmov(tmin , t , isok);

    t = cylinder(fpar00[3] , ro , rd);
    isok = (t > 0.0 && t < tmin);
    obj = cmov(obj , fpar00[3] , isok);
    col = cmov(col , fpar01[3] , isok);
    tmin = cmov(tmin , t , isok);

    t = plane(fpar00[4] , ro , rd);
    isok = (t > 0.001 && t < tmin);
    obj = cmov(obj , fpar00[4] , isok);
    col = cmov(col , fpar01[4] , isok);
    tmin = cmov(tmin , t , isok);

    t = plane(fpar00[5] , ro , rd);
    isok = (t > 0.001 && t < tmin);
    obj = cmov(obj , fpar00[5] , isok);
    col = cmov(col , fpar01[5] , isok);
    tmin = cmov(tmin , t , isok);

    return tmin;
 }

bool intersectShadow(in float3 ro , in float3 rd , in float l)
 {
    float t;

    bool4 sss;

    sss.x = esfera2(fpar00[0] , ro , rd , l);
    sss.y = esfera2(fpar00[1] , ro , rd , l);
    sss.z = cylinder2(fpar00[2] , ro , rd , l);
    sss.w = cylinder2(fpar00[3] , ro , rd , l);

    return any(sss);
 }

float4 basicShade(in float3 inter , in float4 obj ,
                 in float4 col , in float3 rd ,
                 in float4 luz ,
                 out float4 ref)
 {
    float2 uv;

    float3 nor = calcnor(obj , col , inter , uv);

    ref.xyz = reflect(rd , nor);
    float spe = dot(ref.xyz , luz.xyz);
    spe = max(spe , 0.0);
    spe = spe * spe;
    spe = spe * spe;

    float dif = clamp(dot(nor , luz.xyz) , 0.0 , 1.0);
     bool sh = intersectShadow(inter , luz.xyz , luz.w);
    if (sh)
     {
        dif = 0.0;
          spe = 0.0;
     }

    col *= SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , uv);

    // amb + dif + spec 

   float dif2 = clamp(dot(nor , luz.xyz * normalize(float3 (-1.0 , 0.1 , -1.0))) , 0.0 , 1.0);

    col = col * (0.2 * float4 (0.4 , 0.50 , 0.6 , 1.0) * (0.8 + 0.2 * nor.y) +
               0.6 * float4 (1.0 , 1.00 , 1.0 , 1.0) * dif2 +
               1.3 * float4 (1.0 , 0.95 , 0.8 , 1.0) * dif) + .5 * spe;

    // fresnel 
   dif = clamp(dot(nor , -rd) , 0.0 , 1.0);
   ref.w = dif;
   dif = 1.0 - dif * dif;
    dif = pow(dif , 4.0);
   col += 1.0 * float4 (dif, dif, dif, dif)*col * (sh ? 0.5 : 1.0);

   return col;
}

float3 render(in float2 fragCoord)
 {
    float4 luz;
    float4 obj;
     float4 col;
    float3 nor;
    float4 ref;

     float2 q = fragCoord.xy / _ScreenParams.xy;
    float2 p = -1.0 + 2.0 * q;
    p *= float2 (_ScreenParams.x / _ScreenParams.y , 1.0);

    fpar00[0] = float4 (1.2 * sin(6.2831 * .33 * _Time.y + 0.0) , 0.0 ,
                      1.8 * sin(6.2831 * .39 * _Time.y + 1.0) , 1);
    fpar00[1] = float4 (1.5 * sin(6.2831 * .31 * _Time.y + 4.0) ,
                      1.0 * sin(6.2831 * .29 * _Time.y + 1.9) ,
                      1.8 * sin(6.2831 * .29 * _Time.y + 0.0) , 1);
    fpar00[2] = float4 (-1.2 , 0.0 , -0.0 , 0.4);
    fpar00[3] = float4 (1.2 , 0.0 , -0.0 , 0.4);
    fpar00[4] = float4 (0.0 , 1.0 , 0.0 , 2.0);
    fpar00[5] = float4 (0.0 , -1.0 , 0.0 , 2.0);


    fpar01[0] = float4 (0.9 , 0.8 , 0.6 , 1.0);
    fpar01[1] = float4 (1.0 , 0.6 , 0.4 , 1.0);
    fpar01[2] = float4 (0.8 , 0.6 , 0.5 , 3.0);
    fpar01[3] = float4 (0.5 , 0.5 , 0.7 , 3.0);
    fpar01[4] = float4 (1.0 , 0.9 , 0.9 , 2.0);
    fpar01[5] = float4 (1.0 , 0.9 , 0.9 , 2.0);

    float an = .15 * _Time.y - 6.2831 * iMouse.x / _ScreenParams.x;
    float di = iMouse.y / _ScreenParams.y;
    float2 sc = float2 (cos(an) , sin(an));
    float3 rd = normalize(float3 (p.x * sc.x - sc.y , p.y , sc.x + p.x * sc.y));
    float3 ro = (3.5 - di * 2.5) * float3 (sc.y , 0.0 , -sc.x);

    float tmin = intersect(ro , rd , obj , col);

    float3 inter = ro + rd * tmin;

    luz.xyz = float3 (0.0 , 1.5 , -3.0) - inter;
    luz.w = length(luz.xyz);
    luz.xyz = luz.xyz / luz.w;

    col = basicShade(inter , obj , col , rd , luz , ref);

#if 0 
    float4 col2;
    float4 ref2;
    tmin = intersect(inter , ref.xyz , obj , col2);
    inter = inter + ref.xyz * tmin;
    luz.xyz = float3 (0.0 , 1.5 , -1.0) - inter;
    luz.w = length(luz.xyz);
    luz.xyz = luz.xyz / luz.w;
    col2 = basicShade(inter , obj , col2 , ref.xyz , luz , ref2);

    col = lerp(col , col2 , .5 - .5 * ref.w);
#endif 

    col = sqrt(col);

     col *= 0.6 + 0.4 * pow(abs(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y)) , 0.25);

    return col.xyz;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// render this with four sampels per pixel 
float3 col0 = render((fragCoord.xy + float2 (0.0 , 0.0)));
float3 col1 = render((fragCoord.xy + float2 (0.5 , 0.0)));
float3 col2 = render((fragCoord.xy + float2 (0.0 , 0.5)));
float3 col3 = render((fragCoord.xy + float2 (0.5 , 0.5)));
float3 col = 0.25 * (col0 + col1 + col2 + col3);

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