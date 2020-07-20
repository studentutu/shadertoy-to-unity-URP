Shader "UmutBebek/URP/ShaderToy/2d signed distance functions 4dfXDn"
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

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           /* *

Hi all ,

This is just my playground for a bunch of 2D stuff:

Some distance functions and blend functions
Cone marched 2D Soft shadows
Use the mouse to control the 3rd light

*/



// // // // // // // // // // // // // // // // // // // 
// Combine distance field functions // 
// // // // // // // // // // // // // // // // // // // 


float smoothMerge(float d1 , float d2 , float k)
 {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k , 0.0 , 1.0);
    return lerp(d2 , d1 , h) - k * h * (1.0 - h);
 }


float merge(float d1 , float d2)
 {
     return min(d1 , d2);
 }


float mergeExclude(float d1 , float d2)
 {
     return min(max(-d1 , d2) , max(-d2 , d1));
 }


float substract(float d1 , float d2)
 {
     return max(-d1 , d2);
 }


float intersect(float d1 , float d2)
 {
     return max(d1 , d2);
 }


// // // // // // // // // // // // // // // 
// Rotation and translation // 
// // // // // // // // // // // // // // // 


float2 rotateCCW(float2 p , float a)
 {
     float2x2 m = float2x2 (cos(a) , sin(a) , -sin(a) , cos(a));
     return mul (p , m);
 }


float2 rotateCW(float2 p , float a)
 {
     float2x2 m = float2x2 (cos(a) , -sin(a) , sin(a) , cos(a));
     return mul (p , m);
 }


float2 translate(float2 p , float2 t)
 {
     return p - t;
 }


// // // // // // // // // // // // // // // 
// Distance field functions // 
// // // // // // // // // // // // // // // 


float pie(float2 p , float angle)
 {
     angle = radians(angle) / 2.0;
     float2 n = float2 (cos(angle) , sin(angle));
     return abs(p).x * n.x + p.y * n.y;
 }


float circleDist(float2 p , float radius)
 {
     return length(p) - radius;
 }


float triangleDist(float2 p , float radius)
 {
     return max(abs(p).x * 0.866025 +
                       p.y * 0.5 , -p.y)
                     - radius * 0.5;
 }


float triangleDist(float2 p , float width , float height)
 {
     float2 n = normalize(float2 (height , width / 2.0));
     return max(abs(p).x * n.x + p.y * n.y - (height * n.y) , -p.y);
 }


float semiCircleDist(float2 p , float radius , float angle , float width)
 {
     width /= 2.0;
     radius -= width;
     return substract(pie(p , angle) ,
                          abs(circleDist(p , radius)) - width);
 }


float boxDist(float2 p , float2 size , float radius)
 {
     size -= float2 (radius, radius);
     float2 d = abs(p) - size;
       return min(max(d.x , d.y) , 0.0) + length(max(d , 0.0)) - radius;
 }


float lineDist(float2 p , float2 start , float2 end , float width)
 {
     float2 dir = start - end;
     float lngth = length(dir);
     dir /= lngth;
     float2 proj = max(0.0 , min(lngth , dot((start - p) , dir))) * dir;
     return length((start - p) - proj) - (width / 2.0);
 }


// // // // // // // // // // // / 
// Masks for drawing // 
// // // // // // // // // // // / 


float fillMask(float dist)
 {
     return clamp(-dist , 0.0 , 1.0);
 }


float innerBorderMask(float dist , float width)
 {
    // dist += 1.0 ; 
   float alpha1 = clamp(dist + width , 0.0 , 1.0);
   float alpha2 = clamp(dist , 0.0 , 1.0);
   return alpha1 - alpha2;
}


float outerBorderMask(float dist , float width)
 {
    // dist += 1.0 ; 
   float alpha1 = clamp(dist , 0.0 , 1.0);
   float alpha2 = clamp(dist - width , 0.0 , 1.0);
   return alpha1 - alpha2;
}


// // // // // // // / 
// The scene // 
// // // // // // // / 


float sceneDist(float2 p)
 {
     float c = circleDist(translate(p , float2 (100 , 250)) , 40.0);
     float b1 = boxDist(translate(p , float2 (200 , 250)) , float2 (40 , 40) , 0.0);
     float b2 = boxDist(translate(p , float2 (300 , 250)) , float2 (40 , 40) , 10.0);
     float l = lineDist(p , float2 (370 , 220) , float2 (430 , 280) , 10.0);
     float t1 = triangleDist(translate(p , float2 (500 , 210)) , 80.0 , 80.0);
     float t2 = triangleDist(rotateCW(translate(p , float2 (600 , 250)) , _Time.y) , 40.0);

     float m = merge(c , b1);
     m = merge(m , b2);
     m = merge(m , l);
     m = merge(m , t1);
     m = merge(m , t2);

     float b3 = boxDist(translate(p , float2 (100 , sin(_Time.y * 3.0 + 1.0) * 40.0 + 100.0)) ,
                                      float2 (40 , 15) , 0.0);
     float c2 = circleDist(translate(p , float2 (100 , 100)) , 30.0);
     float s = substract(b3 , c2);

     float b4 = boxDist(translate(p , float2 (200 , sin(_Time.y * 3.0 + 2.0) * 40.0 + 100.0)) ,
                                      float2 (40 , 15) , 0.0);
     float c3 = circleDist(translate(p , float2 (200 , 100)) , 30.0);
     float i = intersect(b4 , c3);

     float b5 = boxDist(translate(p , float2 (300 , sin(_Time.y * 3.0 + 3.0) * 40.0 + 100.0)) ,
                                      float2 (40 , 15) , 0.0);
     float c4 = circleDist(translate(p , float2 (300 , 100)) , 30.0);
     float a = merge(b5 , c4);

     float b6 = boxDist(translate(p , float2 (400 , 100)) , float2 (40 , 15) , 0.0);
     float c5 = circleDist(translate(p , float2 (400 , 100)) , 30.0);
     float sm = smoothMerge(b6 , c5 , 10.0);

     float sc = semiCircleDist(translate(p , float2 (500 , 100)) , 40.0 , 90.0 , 10.0);

    float b7 = boxDist(translate(p , float2 (600 , sin(_Time.y * 3.0 + 3.0) * 40.0 + 100.0)) ,
                                      float2 (40 , 15) , 0.0);
     float c6 = circleDist(translate(p , float2 (600 , 100)) , 30.0);
     float e = mergeExclude(b7 , c6);

     m = merge(m , s);
     m = merge(m , i);
     m = merge(m , a);
     m = merge(m , sm);
     m = merge(m , sc);
    m = merge(m , e);

     return m;
 }


float sceneSmooth(float2 p , float r)
 {
     float accum = sceneDist(p);
     accum += sceneDist(p + float2 (0.0 , r));
     accum += sceneDist(p + float2 (0.0 , -r));
     accum += sceneDist(p + float2 (r , 0.0));
     accum += sceneDist(p + float2 (-r , 0.0));
     return accum / 5.0;
 }


// // // // // // // // // // // 
// Shadow and light // 
// // // // // // // // // // // 


float shadow(float2 p , float2 pos , float radius)
 {
     float2 dir = normalize(pos - p);
     float dl = length(p - pos);

     // fraction of light visible , starts at one radius ( second half added in the end ) ; 
    float lf = radius * dl;

    // distance traveled 
   float dt = 0.01;

   for (int i = 0; i < 64; ++i)
    {
       // distance to scene at current position 
      float sd = sceneDist(p + dir * dt);

      // early out when this ray is guaranteed to be full shadow 
     if (sd < -radius)
         return 0.0;

     // width of cone - overlap at light 
     // 0 in center , so 50% overlap: add one radius outside of loop to get total coverage 
     // should be ' ( sd / dt ) * dl' , but ' * dl' outside of loop 
    lf = min(lf , sd / dt);

    // move ahead 
   dt += max(1.0 , abs(sd));
   if (dt > dl) break;
}

   // multiply by dl to get the real projected overlap ( moved out of loop ) 
   // add one radius , before between - radius and + radius 
   // normalize to 1 ( / 2 * radius ) 
  lf = clamp((lf * dl + radius) / (2.0 * radius) , 0.0 , 1.0);
  lf = smoothstep(0.0 , 1.0 , lf);
  return lf;
}



float4 drawLight(float2 p , float2 pos , float4 color , float dist , float range , float radius)
 {
    // distance to light 
   float ld = length(p - pos);

   // out of range 
  if (ld > range) return float4 (0.0 , 0.0 , 0.0 , 0.0);

  // shadow and falloff 
 float shad = shadow(p , pos , radius);
 float fall = (range - ld) / range;
 fall *= fall;
 float source = fillMask(circleDist(p - pos , radius));
 return (shad * fall + source) * color;
}


float luminance(float4 col)
 {
     return 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
 }


void setLuminance(inout float4 col , float lum)
 {
     lum /= luminance(col);
     col *= lum;
 }


float AO(float2 p , float dist , float radius , float intensity)
 {
     float a = clamp(dist / radius , 0.0 , 1.0) - 1.0;
     return 1.0 - (pow(abs(a) , 5.0) + 1.0) * intensity + (1.0 - intensity);
     return smoothstep(0.0 , 1.0 , dist / radius);
 }


// // // // // // // // / 
// The program // 
// // // // // // // // / 


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 p = fragCoord.xy + float2 (0.5 , 0.5);
      float2 c = _ScreenParams.xy / 2.0;

      // float dist = sceneSmooth ( p , 5.0 ) ; 
     float dist = sceneDist(p);

     float2 light1Pos = iMouse.xy;
     float4 light1Col = float4 (0.75 , 1.0 , 0.5 , 1.0);
     setLuminance(light1Col , 0.4);

     float2 light2Pos = float2 (_ScreenParams.x * (sin(_Time.y + 3.1415) + 1.2) / 2.4 , 175.0);
     float4 light2Col = float4 (1.0 , 0.75 , 0.5 , 1.0);
     setLuminance(light2Col , 0.5);

     float2 light3Pos = float2 (_ScreenParams.x * (sin(_Time.y) + 1.2) / 2.4 , 340.0);
     float4 light3Col = float4 (0.5 , 0.75 , 1.0 , 1.0);
     setLuminance(light3Col , 0.6);

     // gradient 
    float4 col = float4 (0.5 , 0.5 , 0.5 , 1.0) * (1.0 - length(c - p) / _ScreenParams.x);
    // grid 
   col *= clamp(min(mod(p.y , 10.0) , mod(p.x , 10.0)) , 0.9 , 1.0);
   // ambient occlusion 
  col *= AO(p , sceneSmooth(p , 10.0) , 40.0 , 0.4);
  // col *= 1.0 - AO ( p , sceneDist ( p ) , 40.0 , 1.0 ) ; 
  // light 
 col += drawLight(p , light1Pos , light1Col , dist , 150.0 , 6.0);
 col += drawLight(p , light2Pos , light2Col , dist , 200.0 , 8.0);
 col += drawLight(p , light3Pos , light3Col , dist , 300.0 , 12.0);
 // shape fill 
col = lerp(col , float4 (1.0 , 0.4 , 0.0 , 1.0) , fillMask(dist));
// shape outline 
col = lerp(col , float4 (0.1 , 0.1 , 0.1 , 1.0) , innerBorderMask(dist , 1.5));

fragColor = clamp(col, 0.0, 1.0);
fragColor.xyz -= 0.15;
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