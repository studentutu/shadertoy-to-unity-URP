Shader "UmutBebek/URP/ShaderToy/Remnant X 4sjSW1"
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

           // Remnant X 
// by David Hoskins. 
// Thanks to boxplorer and the folks at 'Fractalforums.com' 
// HD Video: - https: // www.youtube.com / watch?v = BjkK9fLXXo0 

// #define STEREO 

float3 sunDir = normalize(float3 (0.35 , 0.1 , 0.3));
float3 sunColour = float3 (1.0 , .95 , .8);
#define SCALE 2.8 
#define MINRAD2 .25 
float minRad2 = clamp(MINRAD2 , 1.0e-9 , 1.0);
#define scale ( float4 ( SCALE , SCALE , SCALE , abs ( SCALE ) ) / minRad2 ) 
float absScalem1 = abs(SCALE - 1.0);
float AbsScaleRaisedTo1mIters = pow(abs(SCALE) , float(1 - 10));
float3 surfaceColour1 = float3 (.8 , .0 , 0.);
float3 surfaceColour2 = float3 (.4 , .4 , 0.5);
float3 surfaceColour3 = float3 (.5 , 0.3 , 0.00);
float3 fogCol = float3 (0.4 , 0.4 , 0.4);
float gTime;


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float Noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

     float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z) + f.xy;
     float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , -99.0).yx;
     return lerp(rg.x , rg.y , f.z);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float Map(float3 pos)
 {

     float4 p = float4 (pos , 1);
     float4 p0 = p; // p.w is the distance estimate 

     for (int i = 0; i < 9; i++)
      {
          p.xyz = clamp(p.xyz , -1.0 , 1.0) * 2.0 - p.xyz;

          float r2 = dot(p.xyz , p.xyz);
          p *= clamp(max(minRad2 / r2 , minRad2) , 0.0 , 1.0);

          // scale , translate 
         p = p * scale + p0;
     }
    return ((length(p.xyz) - absScalem1) / p.w - AbsScaleRaisedTo1mIters);
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3 Colour(float3 pos , float sphereR)
 {
     float3 p = pos;
     float3 p0 = p;
     float trap = 1.0;

     for (int i = 0; i < 6; i++)
      {

          p.xyz = clamp(p.xyz , -1.0 , 1.0) * 2.0 - p.xyz;
          float r2 = dot(p.xyz , p.xyz);
          p *= clamp(max(minRad2 / r2 , minRad2) , 0.0 , 1.0);

          p = p * scale.xyz + p0.xyz;
          trap = min(trap , r2);
      }
     // |c.x|: log final distance ( fractional iteration count ) 
     // |c.y|: spherical orbit trap at ( 0 , 0 , 0 ) 
    float2 c = clamp(float2 (0.3333 * log(dot(p , p)) - 1.0 , sqrt(trap)) , 0.0 , 1.0);

   float t = mod(length(pos) - gTime * 150. , 16.0);
   surfaceColour1 = lerp(surfaceColour1 , float3 (.4 , 3.0 , 5.) , pow(smoothstep(0.0 , .3 , t) * smoothstep(0.6 , .3 , t) , 10.0));
    return lerp(lerp(surfaceColour1 , surfaceColour2 , c.y) , surfaceColour3 , c.x);
}


// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3 GetNormal(float3 pos , float distance)
 {
    distance *= 0.001 + .0001;
     float2 eps = float2 (distance , 0.0);
     float3 nor = float3 (
         Map(pos + eps.xyy) - Map(pos - eps.xyy) ,
         Map(pos + eps.yxy) - Map(pos - eps.yxy) ,
         Map(pos + eps.yyx) - Map(pos - eps.yyx));
     return normalize(nor);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float GetSky(float3 pos)
 {
    pos *= 2.3;
     float t = Noise(pos);
    t += Noise(pos * 2.1) * .5;
    t += Noise(pos * 4.3) * .25;
    t += Noise(pos * 7.9) * .125;
     return t;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float BinarySubdivision(in float3 rO , in float3 rD , float2 t)
 {
    float halfwayT;

    for (int i = 0; i < 6; i++)
     {

        halfwayT = dot(t , float2 (.5 , .5));
        float d = Map(rO + halfwayT * rD);
        // if ( abs ( d ) < 0.001 ) break ; 
       t = lerp(float2 (t.x , halfwayT) , float2 (halfwayT , t.y) , step(0.0005 , d));

    }

    return halfwayT;
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float2 Scene(in float3 rO , in float3 rD , in float2 fragCoord)
 {
     float t = .05 + 0.05 * SAMPLE_TEXTURE2D(_Channel0 , sampler_Channel0 , fragCoord.xy / _ScreenParams.xy).y;
     float3 p = float3 (0.0 , 0.0 , 0.0);
    float oldT = 0.0;
    bool hit = false;
    float glow = 0.0;
    float2 dist;
     for (int j = 0; j < 100; j++)
      {
          if (t > 12.0) break;
        p = rO + t * rD;

          float h = Map(p);

          if (h < 0.0005)
           {
            dist = float2 (oldT , t);
            hit = true;
            break;
         }
            glow += clamp(.05 - h , 0.0 , .4);
        oldT = t;
           t += h + t * 0.001;
       }
    if (!hit)
        t = 1000.0;
    else t = BinarySubdivision(rO , rD , dist);
    return float2 (t , clamp(glow * .25 , 0.0 , 1.0));

 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float Hash(float2 p)
 {
     return frac(sin(dot(p , float2 (12.9898 , 78.233))) * 33758.5453) - .5;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3 PostEffects(float3 rgb , float2 xy)
 {
    // Gamma first... 


    // Then... 
   #define CONTRAST 1.08 
   #define SATURATION 1.5 
   #define BRIGHTNESS 1.5 
   rgb = lerp(float3 (.5 , .5 , .5) , 
       lerp(float3 (dot(float3 (.2125, .7154, .0721), rgb * BRIGHTNESS),
           dot(float3 (.2125, .7154, .0721), rgb * BRIGHTNESS),
           dot(float3 (.2125, .7154, .0721), rgb * BRIGHTNESS)) , rgb * BRIGHTNESS , SATURATION) , CONTRAST);
   // Noise... 
   // rgb = clamp ( rgb + Hash ( xy * _Time.y ) * .1 , 0.0 , 1.0 ) ; 
   // Vignette... 
  rgb *= .5 + 0.5 * pow(20.0 * xy.x * xy.y * (1.0 - xy.x) * (1.0 - xy.y) , 0.2);

 rgb = pow(rgb , float3 (0.47 , 0.47 , 0.47));
  return rgb;
}

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float Shadow(in float3 ro , in float3 rd)
 {
     float res = 1.0;
    float t = 0.05;
     float h;

    for (int i = 0; i < 8; i++)
      {
          h = Map(ro + rd * t);
          res = min(6.0 * h / t , res);
          t += h;
      }
    return max(res , 0.0);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3x3 RotationMatrix(float3 axis , float angle)
 {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return float3x3 (oc * axis.x * axis.x + c , oc * axis.x * axis.y - axis.z * s , oc * axis.z * axis.x + axis.y * s ,
                oc * axis.x * axis.y + axis.z * s , oc * axis.y * axis.y + c , oc * axis.y * axis.z - axis.x * s ,
                oc * axis.z * axis.x - axis.y * s , oc * axis.y * axis.z + axis.x * s , oc * axis.z * axis.z + c);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3 LightSource(float3 spotLight , float3 dir , float dis)
 {
    float g = 0.0;
    if (length(spotLight) < dis)
     {
          g = pow(max(dot(normalize(spotLight) , dir) , 0.0) , 500.0);
     }

    return float3 (.6 , .6 , .6) * g;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
float3 CameraPath(float t)
 {
    float3 p = float3 (-.78 + 3. * sin(2.14 * t) , .05 + 2.5 * sin(.942 * t + 1.3) , .05 + 3.5 * cos(3.594 * t));
     return p;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

sunDir = normalize(float3 (0.35, 0.1, 0.3));
sunColour = float3 (1.0, .95, .8);
minRad2 = clamp(MINRAD2, 1.0e-9, 1.0);
absScalem1 = abs(SCALE - 1.0);
AbsScaleRaisedTo1mIters = pow(abs(SCALE), float(1 - 10));
surfaceColour1 = float3 (.8, .0, 0.);
surfaceColour2 = float3 (.4, .4, 0.5);
surfaceColour3 = float3 (.5, 0.3, 0.00);
fogCol = float3 (0.4, 0.4, 0.4);


 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float m = (iMouse.x / _ScreenParams.x) * 300.0;
      gTime = (_Time.y + m) * .01 + 15.00;
     float2 xy = fragCoord.xy / _ScreenParams.xy;
      float2 uv = (-1.0 + 2.0 * xy) * float2 (_ScreenParams.x / _ScreenParams.y , 1.0);


      #ifdef STEREO 
      float isRed = mod(fragCoord.x + mod(fragCoord.y , 2.0) , 2.0);
      #endif 

      float3 cameraPos = CameraPath(gTime);
     float3 camTar = CameraPath(gTime + .01);

      float roll = 13.0 * sin(gTime * .5 + .4);
      float3 cw = normalize(camTar - cameraPos);

      float3 cp = float3 (sin(roll) , cos(roll) , 0.0);
      float3 cu = normalize(cross(cw , cp));

      float3 cv = normalize(cross(cu , cw));
     cw = mul(RotationMatrix(cv , sin(-gTime * 20.0) * .7) , cw);
      float3 dir = normalize(uv.x * cu + uv.y * cv + 1.3 * cw);

      #ifdef STEREO 
      cameraPos += .008 * cu * isRed; // move camera to the right 
      #endif 

     float3 spotLight = CameraPath(gTime + .03) + float3 (sin(gTime * 18.4) , cos(gTime * 17.98) , sin(gTime * 22.53)) * .2;
      float3 col = float3 (0.0 , 0.0 , 0.0);
     float3 sky = float3 (0.03 , .04 , .05) * GetSky(dir);
      float2 ret = Scene(cameraPos , dir , fragCoord);

     if (ret.x < 900.0)
      {
           float3 p = cameraPos + ret.x * dir;
           float3 nor = GetNormal(p , ret.x);

             float3 spot = spotLight - p;
           float atten = length(spot);

         spot /= atten;

         float shaSpot = Shadow(p , spot);
         float shaSun = Shadow(p , sunDir);

             float bri = max(dot(spot , nor) , 0.0) / pow(atten , 1.5) * .15;
         float briSun = max(dot(sunDir , nor) , 0.0) * .3;

        col = Colour(p , ret.x);
        col = (col * bri * shaSpot) + (col * briSun * shaSun);

        float3 ref = reflect(dir , nor);
        col += pow(max(dot(spot , ref) , 0.0) , 10.0) * 2.0 * shaSpot * bri;
        col += pow(max(dot(sunDir , ref) , 0.0) , 10.0) * 2.0 * shaSun * bri;
      }

     col = lerp(sky , col , min(exp(-ret.x + 1.5) , 1.0));
     col += float3 (pow(abs(ret.y), 2.), pow(abs(ret.y), 2.), pow(abs(ret.y), 2.)) * float3 (.02 , .04 , .1);

     col += LightSource(spotLight - cameraPos , dir , ret.x);
      col = PostEffects(col , xy);


      #ifdef STEREO 
      col *= float3 (isRed , 1.0 - isRed , 1.0 - isRed);
      #endif 

      fragColor = float4 (col, 1.0);
      fragColor.xyz -= 0.15;
  return fragColor;
 }

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

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