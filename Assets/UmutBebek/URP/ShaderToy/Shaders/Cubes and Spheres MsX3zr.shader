Shader "UmutBebek/URP/ShaderToy/Cubes and Spheres MsX3zr"
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

           // Cubes and Spheres by @paulofalcao 

// Scene Start 

float2 sim2d(
  in float2 p ,
  in float s)
 {
   float2 ret = p;
   ret = p + s / 2.0;
   ret = frac(ret / s) * s - s / 2.0;
   return ret;
 }

float3 stepspace(
  in float3 p ,
  in float s)
 {
  return p - mod(p - s / 2.0 , s);
 }

// Object 
float obj(in float3 p)
 {
  float3 fp = stepspace(p , 2.0); ;
  float d = sin(fp.x * 0.3 + _Time.y * 4.0) + cos(fp.z * 0.3 + _Time.y * 2.0);
  p.y = p.y + d;
  p.xz = sim2d(p.xz , 2.0);
  // c1 is IQ RoundBox from http: // www.iquilezles.org / www / articles / distfunctions / distfunctions.htm 
 float c1 = length(max(abs(p) - float3 (0.6 , 0.6 , 0.6) , 0.0)) - 0.35;
 // c2 is a Sphere 
float c2 = length(p) - 1.0;
float cf = sin(_Time.y) * 0.5 + 0.5;
return lerp(c1 , c2 , cf);
}

// Object Color 
float3 obj_c(float3 p)
 {
  float2 fp = sim2d(p.xz - 1.0 , 4.0);
  if (fp.y > 0.0) fp.x = -fp.x;
  if (fp.x > 0.0) return float3 (0.0 , 0.0 , 0.0);
    else return float3 (1.0 , 1.0 , 1.0);
 }

// Scene End 


// Raymarching Framework Start 

//float PI = 3.14159265;

float3 phong(
  in float3 pt ,
  in float3 prp ,
  in float3 normal ,
  in float3 light ,
  in float3 color ,
  in float spec ,
  in float3 ambLight)
 {
   float3 lightv = normalize(light - pt);
   float diffuse = dot(normal , lightv);
   float3 refl = -reflect(lightv , normal);
   float3 viewv = normalize(prp - pt);
   float specular = pow(max(dot(refl , viewv) , 0.0) , spec);
   return (max(diffuse , 0.0) + ambLight) * color + specular;
 }

float raymarching(
  in float3 prp ,
  in float3 scp ,
  in int maxite ,
  in float precis ,
  in float startf ,
  in float maxd ,
  out int objfound)
 {
  #define float3 e = float3 ( 0.1 , 0 , 0.0 ) ; 
  float s = startf;
  float3 c , p , n;
  float f = startf;
  objfound = 1;
  for (int i = 0; i < 256; i++) {
    if (abs(s) < precis || f > maxd || i > maxite) break;
    f += s;
    p = prp + scp * f;
    s = obj(p);
   }
  if (f > maxd) objfound = -1;
  return f;
 }

float3 camera(
  in float3 prp ,
  in float3 vrp ,
  in float3 vuv ,
  in float vpd ,
  in float2 fragCoord)
 {
  float2 vPos = -1.0 + 2.0 * fragCoord.xy / _ScreenParams.xy;
  float3 vpn = normalize(vrp - prp);
  float3 u = normalize(cross(vuv , vpn));
  float3 v = cross(vpn , u);
  float3 scrCoord = prp + vpn * vpd + vPos.x * u * _ScreenParams.x / _ScreenParams.y + vPos.y * v;
  return normalize(scrCoord - prp);
 }

float3 normal(in float3 p)
 {
    // tetrahedron normal 
   float n_er = 0.01 ; 
   float v1 = obj(float3 (p.x + n_er , p.y - n_er , p.z - n_er));
   float v2 = obj(float3 (p.x - n_er , p.y - n_er , p.z + n_er));
   float v3 = obj(float3 (p.x - n_er , p.y + n_er , p.z - n_er));
   float v4 = obj(float3 (p.x + n_er , p.y + n_er , p.z + n_er));
   return normalize(float3 (v4 + v1 - v3 - v2 , v3 + v4 - v1 - v2 , v2 + v4 - v3 - v1));
  }

 float3 render(
   in float3 prp ,
   in float3 scp ,
   in int maxite ,
   in float precis ,
   in float startf ,
   in float maxd ,
   in float3 background ,
   in float3 light ,
   in float spec ,
   in float3 ambLight ,
   out float3 n ,
   out float3 p ,
   out float f ,
   out int objfound)
  {
   objfound = -1;
   f = raymarching(prp , scp , maxite , precis , startf , maxd , objfound);
   if (objfound > 0) {
     p = prp + scp * f;
     float3 c = obj_c(p);
     n = normal(p);
     float3 cf = phong(p , prp , n , light , c , spec , ambLight);
     return float3 (cf);
    }
   f = maxd;
   return float3 (background); // background color 
  }

 half4 LitPassFragment(Varyings input) : SV_Target  {
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

 // Camera animation 
float3 vuv = float3 (0 , 1 , 0);
float3 vrp = float3 (_Time.y * 4.0 , 0.0 , 0.0);
float mx = iMouse.x / _ScreenParams.x * PI * 2.0;
float my = iMouse.y / _ScreenParams.y * PI / 2.01;
if ((iMouse.x <= 0.0) || (iMouse.y <= 0.0)) { mx = 1.0 , my = 0.5; }; // quick hack to detect no mouse input for thumbnail 
float3 prp = vrp + float3 (cos(my) * cos(mx) , sin(my) , cos(my) * sin(mx)) * 12.0; // Trackball style camera pos 
float vpd = 1.5;
float3 light = prp + float3 (5.0 , 0 , 5.0);

float3 scp = camera(prp , vrp , vuv , vpd , fragCoord);
float3 n , p;
float f;
int o;
float maxe = 0.01 ; 
float startf = 0.1 ; 
float3 backc = float3 ( 0.0 , 0.0 , 0.0 ) ; 
float spec = 8.0 ; 
float3 ambi = float3 ( 0.1 , 0.1 , 0.1 ) ; 

float3 c1 = render(prp , scp , 256 , maxe , startf , 60.0 , backc , light , spec , ambi , n , p , f , o);
c1 = c1 * max(1.0 - f * .015 , 0.0);
float3 c2 = backc;
if (o > 0) {
  scp = reflect(scp , n);
  c2 = render(p + scp * 0.05 , scp , 32 , maxe , startf , 10.0 , backc , light , spec , ambi , n , p , f , o);
 }
c2 = c2 * max(1.0 - f * .1 , 0.0);
fragColor = float4 (c1.xyz * 0.75 + c2.xyz * 0.25 , 1.0);
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