Shader "UmutBebek/URP/ShaderToy/Mengersponge wtfcWN"
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

        #define float2(x) float2(x, x)
        #define float3(x) float3(x, x, x)
        #define float4(x) float4(x, x, x, x)

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

         #define MAX_STEPS 100 
#define MAX_DIST 100. 
#define SURF_DIST .01 
#define MAX_ITER 5 

float sdRoundBox(float3 p , float3 b , float r)
 {
  float3 q = abs(p) - b;
  return length(max(q , 0.0)) + min(max(q.x , max(q.y , q.z)) , 0.0) - r;
 }


float sdBox(float3 p , float3 b)
 {
  float3 q = abs(p) - b;
  return length(max(q , 0.0)) + min(max(q.x , max(q.y , q.z)) , 0.0);
 }

float sdSphere(float3 p , float r) {

    return length(p) - r;
 }

float3 rotateY(float3 p , float alpha) {
     float px = p.x;
    float c = cos(alpha);
    float s = sin(alpha);

      p.x = c * px - s * p.z;
    p.z = s * px + c * p.z;

    return p;
 }

float3 rotateX(float3 p , float alpha) {
     float py = p.y;
    float c = cos(alpha);
    float s = sin(alpha);

      p.y = c * py - s * p.z;
    p.z = s * py + c * p.z;

    return p;
 }


float sdMenger(float3 p) {
    float size = 2.;
     p.z -= 3.;
    p = rotateY(p , _Time.y * .5);
    float3 s[] = { float3 (1 , 1 , 1) , float3 (1 , 1 , 0) };

    for (int iter = 0; iter < MAX_ITER; ++iter) {
        // float d = MAX_DIST ; 
          float alpha = (iMouse.x - .5 * _ScreenParams.x) / _ScreenParams.x * 3.14;
          p = rotateY(p , alpha);
          float beta = (iMouse.y - .5 * _ScreenParams.y) / _ScreenParams.y * 3.14;
          p = rotateX(p , beta);
          // float3 pos = float3 ( 0. , 0. , 0. ) ; 

          p = abs(p);
          if (p.y > p.x) p.yx = p.xy;
          if (p.z > p.y) p.zy = p.yz;

          /* for ( int k = 0 ; k < 2 ; k ++ ) {
               float dist = length ( p - size * s[k] ) ;
               if ( dist < d ) {
                   pos = size * s[k] ;
                   d = dist ;
               }


           }

          p -= pos ; */

          if (p.z > .5 * size) p -= size * s[0];
          else p -= size * s[1];
          size /= 3.;

       }
      return sdBox(p , float3 (1.5 * size , 1.5 * size , 1.5 * size));
   }

  float sdPlane(float3 p , float3 n) {
      n = normalize(n);
        return dot(p , n);
   }


  float GetDist(float3 p) {
      float d2 = sdPlane(p + float3 (0 , 6 , 0) , float3 (0 , 1 , 0));
      float d1 = sdMenger(p);

      return min(d1 , d2);
   }

  float3 GetColor(float3 p) {
   float d1 = sdMenger(p);
   float d2 = sdPlane(p + float3 (0 , 6 , 0) , float3 (0 , 1 , 0));

      if (d1 < d2) return float3 (1 , 1 , 1); ;

      float3 col = float3 (.7 , .7 , .9);
      if ((mod(p.x , 10.) > 5. && mod(p.z , 10.) > 5.) || (mod(p.x , 10.) < 5. && mod(p.z , 10.) < 5.))
          col = float3 (.5 , .5 , .5);

      return col;

   }

  float RayMarch(float3 ro , float3 rd) {
      float dO = 0.;

      for (int i = 0; i < MAX_STEPS; i++) {
       float3 p = ro + rd * dO;
          float dS = GetDist(p);
          dO += dS;
          if (dO > MAX_DIST || dS < SURF_DIST) break;

       }
      return dO;
   }

  float3 GetNormal(float3 p) {
       float d = GetDist(p);
      float2 e = float2 (.01 , 0);

      float3 n = d - float3 (
          GetDist(p - e.xyy) ,
          GetDist(p - e.yxy) ,
          GetDist(p - e.yyx));

       return normalize(n);
   }

  float shadow(in float3 ro , in float3 rd , float mint , float maxt , float k)
   {
      float res = 1.0;
      for (float t = mint; t < maxt; )
       {
          float h = GetDist(ro + rd * t);
          if (h < 0.001)
              return 0.0;
          res = min(res , k * h / t);
          t += h;
       }
      return res;
   }

  half4 LitPassFragment(Varyings input) : SV_Target  {
  half4 fragColor = half4 (1 , 1 , 1 , 1);
  float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float3 ro = float3 (0 , 5 , -12);
      float2 uv = (fragCoord - .5 * _ScreenParams.xy) / _ScreenParams.y;
      float3 cubecol = float3 (1. , .0 , .0);
      float3 rd = normalize(float3 (uv.x , uv.y - .5 , 1));


       float d = RayMarch(ro , rd);
      float3 p = ro + rd * d;

      // Get Light 
     float3 lightPos = float3 (10 , 20 , -20);
     float3 l = normalize(lightPos - p);
     float3 n = GetNormal(p);
     float cosphi = dot(n , l);
     float3 v = normalize(-l + 2. * cosphi * n);
     float3 col = GetColor(p);
     float po = 15.;
     float amb = 0.1;
     float t = pow(clamp(dot(v , -rd) , 0. , 1.) , po);
     col = (1. - t) * (amb + (1. - amb) * cosphi) * col + t * float3 (1. , 1. , 1.);

     // shadow 
    t = shadow(p , l , SURF_DIST * 2. , MAX_DIST , 4.);
    col *= t;

    // fog 
   t = pow(min(d / MAX_DIST , 1.) , 2.);
   col = (1. - t) * col + t * float3 (.9 , .9 , .9);

   fragColor = float4 (col, 1.0);
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