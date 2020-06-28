Shader "UmutBebek/URP/ShaderToy/Julia - Quaternion 1 MsfGRr"
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

           // Created by inigo quilez - iq / 2013 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 

// A port of my 2007 demo Kindernoiser: https: // www.youtube.com / watch?v = 9AX8gNyrSWc ( http: // www.pouet.net / prod.php?which = 32549 ) 
// 
// More ( oudated , half broken ) info here: http: // iquilezles.org / www / articles / juliasets3d / juliasets3d.htm 

// Julia - Quaternion 1 : https: // www.shadertoy.com / view / MsfGRr 
// Julia - Quaternion 2 : https: // www.shadertoy.com / view / lsl3W2 
// Julia - Quaternion 3 : https: // www.shadertoy.com / view / 3tsyzl 

// antialias level ( 1 , 2 , 3... ) 
//#if HW_PERFORMANCE == 0 
//#define AA 1 
//#else 
#define AA 2 // Set AA to 1 if your machine is too slow 
//#endif 


 // 0: numerical normals ( central differences ) 
 // 1: analytic normals 
 // 2: analytic normals optimized 
#define METHOD 2 


float4 qsqr(in float4 a) // square a quaterion 
 {
    return float4 (a.x * a.x - a.y * a.y - a.z * a.z - a.w * a.w ,
                 2.0 * a.x * a.y ,
                 2.0 * a.x * a.z ,
                 2.0 * a.x * a.w);
 }

float4 qmul(in float4 a , in float4 b)
 {
    return float4 (
        a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w ,
        a.y * b.x + a.x * b.y + a.z * b.w - a.w * b.z ,
        a.z * b.x + a.x * b.z + a.w * b.y - a.y * b.w ,
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y);

 }

float4 qconj(in float4 a)
 {
    return float4 (a.x , -a.yzw);
 }

#define numIterations 11

float map(in float3 p , out float4 oTrap , in float4 c)
 {
    float4 z = float4 (p , 0.0);
    float md2 = 1.0;
    float mz2 = dot(z , z);

    float4 trap = float4 (abs(z.xyz) , dot(z , z));

    float n = 1.0;
    for (int i = 0; i < numIterations; i++)
     {
        // dz - > 2·z·dz , meaning |dz| - > 2·|z|·|dz| 
        // Now we take the 2.0 out of the loop and do it at the end with an exp2 
       md2 *= mz2;
       // z - > z^2 + c 
      z = qsqr(z) + c;

      trap = min(trap , float4 (abs(z.xyz) , dot(z , z)));

      mz2 = dot(z , z);
      if (mz2 > 4.0) break;
      n += 1.0;
   }

  oTrap = trap;

  return 0.25 * sqrt(mz2 / md2) * exp2(-n) * log(mz2); // d = 0.5·|z|·log|z| / |dz| 
}

#if METHOD == 0 
float3 calcNormal(in float3 pos , in float4 c)
 {
    float4 kk;
    float2 e = float2 (1.0 , -1.0) * 0.5773 * 0.001;
    return normalize(e.xyy * map(pos + e.xyy , kk , c) +
                           e.yyx * map(pos + e.yyx , kk , c) +
                           e.yxy * map(pos + e.yxy , kk , c) +
                           e.xxx * map(pos + e.xxx , kk , c));
 }
#endif 

#if METHOD == 1 
float3 calcNormal(in float3 p , in float4 c)
 {
    float4 z = float4 (p , 0.0);

    // identity derivative 
   mat4x4 J = mat4x4(1 , 0 , 0 , 0 ,
                     0 , 1 , 0 , 0 ,
                     0 , 0 , 1 , 0 ,
                     0 , 0 , 0 , 1);

      for (int i = 0; i < numIterations; i++)
    {
          // chain rule of jacobians ( removed the 2 factor ) 
         J = J * mat4x4(z.x , -z.y , -z.z , -z.w ,
                      z.y , z.x , 0.0 , 0.0 ,
                      z.z , 0.0 , z.x , 0.0 ,
                      z.w , 0.0 , 0.0 , z.x);

         // z - > z2 + c 
        z = qsqr(z) + c;

        if (dot(z , z) > 4.0) break;
     }

    return normalize((J * z).xyz);
 }
#endif 

#if METHOD == 2 
float3 calcNormal(in float3 p , in float4 c)
 {
    float4 z = float4 (p , 0.0);

    // identity derivative 
   float4 J0 = float4 (1 , 0 , 0 , 0);
   float4 J1 = float4 (0 , 1 , 0 , 0);
   float4 J2 = float4 (0 , 0 , 1 , 0);

      for (int i = 0; i < numIterations; i++)
    {
       float4 cz = qconj(z);

       // chain rule of jacobians ( removed the 2 factor ) 
      J0 = float4 (dot(J0 , cz) , dot(J0.xy , z.yx) , dot(J0.xz , z.zx) , dot(J0.xw , z.wx));
      J1 = float4 (dot(J1 , cz) , dot(J1.xy , z.yx) , dot(J1.xz , z.zx) , dot(J1.xw , z.wx));
      J2 = float4 (dot(J2 , cz) , dot(J2.xy , z.yx) , dot(J2.xz , z.zx) , dot(J2.xw , z.wx));

      // z - > z2 + c 
     z = qsqr(z) + c;

     if (dot(z , z) > 4.0) break;
  }

  float3 v = float3 (dot(J0 , z) ,
                dot(J1 , z) ,
                dot(J2 , z));

 return normalize(v);
}
#endif 

// this method does not work , but in my mind , it should 
#if METHOD == 3 
float3 calcNormal(in float3 p , in float4 c)
 {
    float4 z = float4 (p , 0.0);

    float4 dz = float4 (1 , 0 , 0 , 0);

       for (int i = 0; i < numIterations; i++)
     {
           // z' = 2z'z 
            dz = 2.0 * qmul(z , dz);

            // z - > z2 + c 
           z = qsqr(z) + c;

           if (dot(z , z) > 4.0) break;
        }

        float4 v = qconj(qmul(dz , qconj(z)));

       return normalize(v.xyz);
    }
   #endif 



   float intersect(in float3 ro , in float3 rd , out float4 res , in float4 c)
    {
       float4 tmp;
       float resT = -1.0;
        float maxd = 10.0;
       float h = 1.0;
       float t = 0.0;
       for (int i = 0; i < 300; i++)
        {
           if (h < 0.0001 || t > maxd) break;
            h = map(ro + rd * t , tmp , c);
           t += h;
        }
       if (t < maxd) { resT = t; res = tmp; }

        return resT;
    }

   float softshadow(in float3 ro , in float3 rd , float mint , float k , in float4 c)
    {
       float res = 1.0;
       float t = mint;
       for (int i = 0; i < 64; i++)
        {
           float4 kk;
           float h = map(ro + rd * t , kk , c);
           res = min(res , k * h / t);
           if (res < 0.001) break;
           t += clamp(h , 0.01 , 0.5);
        }
       return clamp(res , 0.0 , 1.0);
    }

   float3 render(in float3 ro , in float3 rd , in float4 c)
    {
        const float3 sun = float3 ( 0.577 , 0.577 , 0.577 ) ; 

        float4 tra;
        float3 col;
       float t = intersect(ro , rd , tra , c);
       if (t < 0.0)
        {
             col = float3 (0.7 , 0.9 , 1.0) * (0.7 + 0.3 * rd.y);
             col += float3 (0.8 , 0.7 , 0.5) * pow(clamp(dot(rd , sun) , 0.0 , 1.0) , 48.0);
         }
        else
         {
           float3 mate = float3 (1.0 , 0.8 , 0.7) * 0.3;
           // mate.x = 1.0 - 10.0 * tra.x ; 

        float3 pos = ro + t * rd;
        float3 nor = calcNormal(pos , c);

          float occ = clamp(2.5 * tra.w - 0.15 , 0.0 , 1.0);


        col = float3 (0.0, 0.0, 0.0);

        // sky 
        {
       float co = clamp(dot(-rd , nor) , 0.0 , 1.0);
       float3 ref = reflect(rd , nor);
       // float sha = softshadow ( pos + 0.0005 * nor , ref , 0.001 , 4.0 , c ) ; 
      float sha = occ;
      sha *= smoothstep(-0.1 , 0.1 , ref.y);
      float fre = 0.1 + 0.9 * pow(1.0 - co , 5.0);

        col = mate * 0.3 * float3 (0.8 , 0.9 , 1.0) * (0.6 + 0.4 * nor.y) * occ;
        col += 2.0 * 0.3 * float3 (0.8 , 0.9 , 1.0) * (0.6 + 0.4 * nor.y) * sha * fre;
       }

        // sun 
        {
       const float3 lig = sun ; 
       float dif = clamp(dot(lig , nor) , 0.0 , 1.0);
       float sha = softshadow(pos , lig , 0.001 , 64.0 , c);
       float3 hal = normalize(-rd + lig);
       float co = clamp(dot(hal , lig) , 0.0 , 1.0);
       float fre = 0.04 + 0.96 * pow(1.0 - co , 5.0);
       float spe = pow(clamp(dot(hal , nor) , 0.0 , 1.0) , 32.0);
       col += mate * 3.5 * float3 (1.00 , 0.90 , 0.70) * dif * sha;
       col += 7.0 * 3.5 * float3 (1.00 , 0.90 , 0.70) * spe * dif * sha * fre;
        }

        // extra fill 
        {
       const float3 lig = float3 ( - 0.707 , 0.000 , - 0.707 ) ; 
         float dif = clamp(0.5 + 0.5 * dot(lig , nor) , 0.0 , 1.0);
       col += mate * 1.5 * float3 (0.14 , 0.14 , 0.14) * dif * occ;
        }

        // fake SSS 
        {
       float fre = clamp(1. + dot(rd , nor) , 0.0 , 1.0);
       col += mate * mate * 0.6 * fre * fre * (0.2 + 0.8 * occ);
        }
    }

    return pow(abs(col) , float3 (0.4545, 0.4545, 0.4545));
}

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
// anim 
float time = _Time.y * .15;
float4 c = 0.45 * cos(float4 (0.5 , 3.9 , 1.4 , 1.1) + time * float4 (1.2 , 1.7 , 1.3 , 2.5)) - float4 (0.3 , 0.0 , 0.0 , 0.0);

// camera 
float r = 1.5 + 0.15 * cos(0.0 + 0.29 * time);
float3 ro = float3 (r * cos(0.3 + 0.37 * time) ,
                    0.3 + 0.8 * r * cos(1.0 + 0.33 * time) ,
                              r * cos(2.2 + 0.31 * time));
float3 ta = float3 (0.0 , 0.0 , 0.0);
float cr = 0.1 * cos(0.1 * time);


// render 
float3 col = float3 (0.0, 0.0, 0.0);
for (int j = 0; j < AA; j++)
for (int i = 0; i < AA; i++)
 {
    float2 p = (-_ScreenParams.xy + 2.0 * (fragCoord + float2 (float(i) , float(j)) / float(AA))) / _ScreenParams.y;

    float3 cw = normalize(ta - ro);
    float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
    float3 cu = normalize(cross(cw , cp));
    float3 cv = normalize(cross(cu , cw));
    float3 rd = normalize(p.x * cu + p.y * cv + 2.0 * cw);

    col += render(ro , rd , c);
 }
col /= float(AA * AA);

float2 uv = fragCoord.xy / _ScreenParams.xy;
 col *= 0.7 + 0.3 * pow(abs(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y)) , 0.25);

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