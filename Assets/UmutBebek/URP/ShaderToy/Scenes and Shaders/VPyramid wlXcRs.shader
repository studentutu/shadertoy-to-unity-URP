Shader "UmutBebek/URP/ShaderToy/VPyramid wlXcRs"
{
    Properties
    {
        _BaseMap("Base (RGB)", 2D) = "" {}
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

            float4 _BaseMap_ST;
            TEXTURE2D(_BaseMap);       SAMPLER(sampler_BaseMap);

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
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                // We just use the homogeneous clip position from the vertex input
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            #define FLT_MAX 3.402823466e+38
            #define FLT_MIN 1.175494351e-38
            #define DBL_MAX 1.7976931348623158e+308
            #define DBL_MIN 2.2250738585072014e-308

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

            // Variable Pyramid 
// largely IQ's code , adjusted slightly for my requirements ( scalable , box aligned and with a working base ) 

float sdBox(float3 p , float3 b)
 {
  float3 q = abs(p) - b;
  return length(max(q , 0.0)) + min(max(q.x , max(q.y , q.z)) , 0.0);
 }


// Better boundbox function , thankyou IQ : ) 
float sdBoundBox(float3 p , float3 b , float edge)
 {
    edge *= 0.5;
    p = abs(p);
    float d1 = sdBox(p - float3 (0.0 , b.y - edge , b.z - edge) , float3 (b.x , edge , edge));
    float d2 = sdBox(p - float3 (b.x - edge , 0.0 , b.z - edge) , float3 (edge , b.y , edge));
    float d3 = sdBox(p - float3 (b.x - edge , b.y - edge , 0.0) , float3 (edge , edge , b.z));
    return min(min(d1 , d2) , d3);
 }


// signed distance to a pyramid bs = xz size , h = y size 
float sdPyramid(in float3 p , in float bs , in float h)
 {
    // box adjust 
   p.y += h;
   float3 p2 = p;
   h *= 2.0;
   bs *= 2.0;
   h /= bs;
   p /= bs;

   float m2 = h * h + 0.25;

   // symmetry 
  p.xz = abs(p.xz); // do p = abs ( p ) instead for double pyramid 
  p.xz = (p.z > p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  // project into face plane ( 2D ) 
 float3 q = float3 (p.z , h * p.y - 0.5 * p.x , h * p.x + 0.5 * p.y);

 float s = max(-q.x , 0.0);
 float t = clamp((q.y - 0.5 * q.x) / (m2 + 0.25) , 0.0 , 1.0);

 float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
  float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

 float d2 = max(-q.y , q.x * m2 + q.y * 0.5) < 0.0 ? 0.0 : min(a , b);

 // recover 3D and scale , and add sign 
float d = sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z , -p.y));

// adjust distance for scale 
// return bs * d ; 

// hacked on the base 
float2 fx = abs(p2.xz) - float2 (bs * 0.5 , bs * 0.5);
float d1 = length(max(fx , 0.0)) + min(max(fx.x , fx.y) , 0.0);
 float2 w = float2 (d1 , abs(p2.y) - 0.0001);
d1 = min(max(w.x , w.y) , 0.0) + length(max(w , 0.0));
return min(d1 , bs * d);

}

float map(in float3 pos)
 {
    float3 size = 0.5 + sin(float3 (_Time.y , _Time.y * 1.5 , _Time.y * 2.0)) * 0.5;
    float xs = 0.5 + (size.x);
    float zs = 0.5 + (size.y);
    float ys = 0.5 + (0.5 * size.z);

    float d1 = sdPyramid(pos , xs , ys);

    if (iMouse.z > 0.5)
        return d1;

    float boff = 0.3; // bounding box offset 
    float bthick = 0.075; // bounding box thickness 
    float d3 = sdBoundBox(pos , float3 (xs + boff , ys + boff , xs + boff) , bthick);
    d1 = min(d1 , d3);
    return d1;
 }

// http: // iquilezles.org / www / articles / normalsSDF / normalsSDF.htm 
float3 calcNormal(in float3 pos)
 {
    float2 e = float2 (1.0 , -1.0) * 0.5773;
    const float eps = 0.001;
    return normalize(e.xyy * map(pos + e.xyy * eps) +
                           e.yyx * map(pos + e.yyx * eps) +
                           e.yxy * map(pos + e.yxy * eps) +
                           e.xxx * map(pos + e.xxx * eps));
 }

#define AA 2 

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// camera movement 
float an = 0.5 * _Time.y;
float3 ro = float3 (5.0 * cos(an) , -2.5 , 5.0 * sin(an));
float3 ta = float3 (0.0 , 0.0 , 0.0);
// camera matrix 
float3 ww = normalize(ta - ro);
float3 uu = normalize(cross(ww , float3 (0.0 , 1.0 , 0.0)));
float3 vv = normalize(cross(uu , ww));



float3 tot = float3 (0.0 , 0.0 , 0.0);

#if AA > 1 
for (int m = 0; m < AA; m++)
for (int n = 0; n < AA; n++)
 {
    // pixel coordinates 
   float2 o = float2 (float(m) , float(n)) / float(AA) - 0.5;
   float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + o)) / _ScreenParams.y;
   #else 
   float2 p = (-_ScreenParams.xy + 2.0 * fragCoord) / _ScreenParams.y;
   #endif 

   // create view ray 
 float3 rd = normalize(p.x * uu + p.y * vv + 1.8 * ww);

 // raymarch 
const float tmax = 30.0;
float t = 0.0;
for (int i = 0; i < 128; i++)
 {
    float3 pos = ro + t * rd;
    float h = map(pos);
    if (h < 0.0001 || t > tmax) break;
    t += h;
 }

// shading / lighting 
float v = 1.0 - abs(p.y);
float3 col = float3 (v * 0.1 , v * 0.1 , v * 0.1);
if (t < tmax)
 {
    float3 pos = ro + t * rd;
    float3 nor = calcNormal(pos);
    float dif = clamp(dot(nor , float3 (0.7 , 0.6 , 0.4)) , 0.0 , 1.0);
    float amb = 0.5 + 0.5 * dot(nor , float3 (0.0 , 0.8 , 0.6));
    col = float3 (0.2 , 0.3 , 0.4) * amb + float3 (0.8 , 0.7 , 0.5) * dif;
 }

// gamma 
col = sqrt(col);
 tot += col;
#if AA > 1 
 }
tot /= float(AA * AA);
#endif 

 fragColor = float4 ((tot).x , (tot).y , (tot).z , 1.0);
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