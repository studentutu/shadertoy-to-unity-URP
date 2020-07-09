Shader "UmutBebek/URP/ShaderToy/Goo lllBDM BufferA"
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
            pi("pi", float) = 3.14159

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
            float pi;

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

           // MIT License: https: // opensource.org / licenses / MIT 

float3x3 rotate(in float3 v , in float angle) {
     float c = cos(angle);
     float s = sin(angle);
     return float3x3 (c + (1.0 - c) * v.x * v.x , (1.0 - c) * v.x * v.y - s * v.z , (1.0 - c) * v.x * v.z + s * v.y ,
           (1.0 - c) * v.x * v.y + s * v.z , c + (1.0 - c) * v.y * v.y , (1.0 - c) * v.y * v.z - s * v.x ,
           (1.0 - c) * v.x * v.z - s * v.y , (1.0 - c) * v.y * v.z + s * v.x , c + (1.0 - c) * v.z * v.z
           );
 }

float3 hash(float3 p) {
     p = float3 (dot(p , float3 (127.1 , 311.7 , 74.7)) ,
                 dot(p , float3 (269.5 , 183.3 , 246.1)) ,
                 dot(p , float3 (113.5 , 271.9 , 124.6)));
     return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
 }

// Gradient noise from iq 
// return value noise ( in x ) and its derivatives ( in yzw ) 
float4 noised(float3 x) {
    float3 p = floor(x);
    float3 w = frac(x);
    float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    float3 ga = hash(p + float3 (0.0 , 0.0 , 0.0));
    float3 gb = hash(p + float3 (1.0 , 0.0 , 0.0));
    float3 gc = hash(p + float3 (0.0 , 1.0 , 0.0));
    float3 gd = hash(p + float3 (1.0 , 1.0 , 0.0));
    float3 ge = hash(p + float3 (0.0 , 0.0 , 1.0));
     float3 gf = hash(p + float3 (1.0 , 0.0 , 1.0));
    float3 gg = hash(p + float3 (0.0 , 1.0 , 1.0));
    float3 gh = hash(p + float3 (1.0 , 1.0 , 1.0));

    float va = dot(ga , w - float3 (0.0 , 0.0 , 0.0));
    float vb = dot(gb , w - float3 (1.0 , 0.0 , 0.0));
    float vc = dot(gc , w - float3 (0.0 , 1.0 , 0.0));
    float vd = dot(gd , w - float3 (1.0 , 1.0 , 0.0));
    float ve = dot(ge , w - float3 (0.0 , 0.0 , 1.0));
    float vf = dot(gf , w - float3 (1.0 , 0.0 , 1.0));
    float vg = dot(gg , w - float3 (0.0 , 1.0 , 1.0));
    float vh = dot(gh , w - float3 (1.0 , 1.0 , 1.0));

    return float4 (va + u.x * (vb - va) + u.y * (vc - va) + u.z * (ve - va) + u.x * u.y * (va - vb - vc + vd) + u.y * u.z * (va - vc - ve + vg) + u.z * u.x * (va - vb - ve + vf) + (-va + vb + vc - vd + ve - vf - vg + vh) * u.x * u.y * u.z , // value 
                 ga + u.x * (gb - ga) + u.y * (gc - ga) + u.z * (ge - ga) + u.x * u.y * (ga - gb - gc + gd) + u.y * u.z * (ga - gc - ge + gg) + u.z * u.x * (ga - gb - ge + gf) + (-ga + gb + gc - gd + ge - gf - gg + gh) * u.x * u.y * u.z + // derivatives 
                 du * (float3 (vb , vc , ve) - va + u.yzx * float3 (va - vb - vc + vd , va - vc - ve + vg , va - vb - ve + vf) + u.zxy * float3 (va - vb - ve + vf , va - vb - vc + vd , va - vc - ve + vg) + u.yzx * u.zxy * (-va + vb + vc - vd + ve - vf - vg + vh)));
 }

float map(float3 p) {
    // ugly hacky slow distance field with bad gradients 
   float d = p.y;
   float c = max(0.0 , pow(distance(p.xz , float2 (0 , 16)) , 1.0));
   float cc = pow(smoothstep(20.0 , 5.0 , c) , 2.0);
   // p.xz *= cc ; 
  float4 n = noised(float3 (p.xz * 0.07 , _Time.y * 0.5));
  float nn = n.x * (length((n.yzw)));
  n = noised(float3 (p.xz * 0.173 , _Time.y * 0.639));
  nn += 0.25 * n.x * (length((n.yzw)));
  nn = smoothstep(-0.5 , 0.5 , nn);
  d = d - 6.0 * nn * (cc);
  return d;
}

float err(float dist) {
    dist = dist / 100.0;
    return min(0.01 , dist * dist);
 }

float3 dr(float3 origin , float3 direction , float3 position) {
    const int iterations = 3;
    for (int i = 0; i < iterations; i++) {
        position = position + direction * (map(position) - err(distance(origin , position)));
     }
    return position;
 }

float3 intersect(float3 ro , float3 rd) {
     float3 p = ro + rd;
     float t = 0.;
     for (int i = 0; i < 150; i++) {
        float d = 0.5 * map(p);
        t += d;
        p += rd * d;
          if (d < 0.01 || t > 60.0) break;
      }

     // discontinuity reduction as described ( somewhat ) in 
     // their 2014 sphere tracing paper 
    p = dr(ro , rd , p);
    return p;
 }

float3 normal(float3 p) {
     float e = 0.01;
     return normalize(float3 (map(p + float3 (e , 0 , 0)) - map(p - float3 (e , 0 , 0)) ,
                           map(p + float3 (0 , e , 0)) - map(p - float3 (0 , e , 0)) ,
                           map(p + float3 (0 , 0 , e)) - map(p - float3 (0 , 0 , e))));
 }

float G1V(float dnv , float k) {
    return 1.0 / (dnv * (1.0 - k) + k);
 }

float ggx(float3 n , float3 v , float3 l , float rough , float f0) {
    float alpha = rough * rough;
    float3 h = normalize(v + l);
    float dnl = clamp(dot(n , l) , 0.0 , 1.0);
    float dnv = clamp(dot(n , v) , 0.0 , 1.0);
    float dnh = clamp(dot(n , h) , 0.0 , 1.0);
    float dlh = clamp(dot(l , h) , 0.0 , 1.0);
    float f , d , vis;
    float asqr = alpha * alpha;
    const float pi = 3.14159;
    float den = dnh * dnh * (asqr - 1.0) + 1.0;
    d = asqr / (pi * den * den);
    dlh = pow(1.0 - dlh , 5.0);
    f = f0 + (1.0 - f0) * dlh;
    float k = alpha / 1.0;
    vis = G1V(dnl , k) * G1V(dnv , k);
    float spec = dnl * d * f * vis;
    return spec;
 }

float subsurface(float3 p , float3 v , float3 n) {
    // float3 d = normalize ( lerp ( v , - n , 0.5 ) ) ; 
    // suggested by Shane 
   float3 d = refract(v , n , 1.0 / 1.5);
   float3 o = p;
   float a = 0.0;

   const float max_scatter = 2.5;
   for (float i = 0.1; i < max_scatter; i += 0.2)
    {
       o += i * d;
       float t = map(o);
       a += t;
    }
   float thickness = max(0.0 , -a);
   const float scatter_strength = 16.0;
    return scatter_strength * pow(max_scatter * 0.5 , 3.0) / thickness;
}

float3 shade(float3 p , float3 v) {
    float3 lp = float3 (50 , 20 , 10);
    float3 ld = normalize(p + lp);

    float3 n = normal(p);
    float fresnel = pow(max(0.0 , 1.0 + dot(n , v)) , 5.0);

    float3 final = float3 (0 , 0 , 0);
    float3 ambient = float3 (0.1 , 0.06 , 0.035);
    float3 albedo = float3 (0.75 , 0.9 , 0.35);
    float3 sky = float3 (0.5 , 0.65 , 0.8) * 2.0;

    float lamb = max(0.0 , dot(n , ld));
    float spec = ggx(n , v , ld , 3.0 , fresnel);
    float ss = max(0.0 , subsurface(p , v , n));

    // artistic license 
   lamb = lerp(lamb , 3.5 * smoothstep(0.0 , 2.0 , pow(ss , 0.6)) , 0.7);
   final = ambient + albedo * lamb + 25.0 * spec + fresnel * sky;
   return float3 (final * 0.5);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 0);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 uv = fragCoord / _ScreenParams.xy;
    float3 a = float3 (0 , 0 , 0);

    // leftover stuff from something else , too lazy to remove 
    // don't ask 
   const float campos = 5.1;
   float lerpi = 0.5 + 0.5 * cos(campos * 0.4 - pi);
   lerpi = smoothstep(0.13 , 1.0 , lerpi);
   float3 c = lerp(float3 (-0 , 217 , 0) , float3 (0 , 4.4 , -190) , pow(lerpi , 1.0));
   float3x3 rot = rotate(float3 (1 , 0 , 0) , pi / 2.0);
   float3x3 ro2 = rotate(float3 (1 , 0 , 0) , -0.008 * pi / 2.0);

   float2 u2 = -1.0 + 2.0 * uv;
   u2.x *= _ScreenParams.x / _ScreenParams.y;

   float3 d = lerp(normalize(mul(float3 (u2 , 20) , rot)) , mul(normalize(float3 (u2 , 20)) , ro2 ), pow(lerpi , 1.11));
   d = normalize(d);

   float3 ii = intersect(c + 145.0 * d , d);
   float3 ss = shade(ii , d);
   a += ss;

   fragColor.rgb = a * (0.99 + 0.02 * hash(float3 (uv , 0.001 * _Time.y)));
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