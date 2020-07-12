Shader "UmutBebek/URP/ShaderToy/Bricks Game MddGzf MainImage"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        txBallPosVel("txBallPosVel", vector) = (0 , 0,0,0)
txPaddlePos("txPaddlePos", vector) = (1 , 0,0,0)
txPoints("txPoints", vector) = (2 , 0,0,0)
txState("txState", vector) = (3 , 0,0,0)
txLastHit("txLastHit", vector) = (4 , 0,0,0)
txBricks("txBricks", vector) = (0 , 1 , 13 , 12)
ballRadius("ballRadius", float) = 0.035
paddleSize("paddleSize", float) = 0.30
paddleWidth("paddleWidth", float) = 0.06
paddlePosY("paddlePosY", float) = -0.90
brickW("brickW", float) = 0.1538461538461538461
brickH("brickH", float) = 0.066666666666666666666
shadowOffset("shadowOffset", vector) = (-0.03 , 0.03,0,0)


    }

        SubShader
        {
            // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
            // "UniversalRenderPipeline"
            Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"
        "Queue"="Transparent"}
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
               /* ZWrite[_ZWrite]
                Cull[_Cull]*/

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
            float4 txBallPosVel;
float4 txPaddlePos;
float4 txPoints;
float4 txState;
float4 txLastHit;
float4 txBricks;
float ballRadius;
float paddleSize;
float paddleWidth;
float paddlePosY;
float brickW;
float brickH;
float4 shadowOffset;



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

                   // Created by inigo quilez - iq / 2016 
// License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 

// 
// Game rendering. Regular 2D distance field rendering. 
// 


// storage register / texel addresses 











                   const int font[] = { 0x75557, 0x22222, 0x74717, 0x74747, 0x11574, 0x71747, 0x71757, 0x74444, 0x75757, 0x75747 };
                   const int powers[] = { 1, 10, 100, 1000, 10000 };


// -- -- -- -- -- -- -- -- 



// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 
// distance functions 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float udSegment(in float2 p , in float2 a , in float2 b)
 {
    float2 pa = p - a , ba = b - a;
    float h = clamp(dot(pa , ba) / dot(ba , ba) , 0.0 , 1.0);
    return length(pa - ba * h);
 }

float udHorizontalSegment(in float2 p , in float xa , in float xb , in float y)
 {
    float2 pa = p - float2 (xa , y);
    float ba = xb - xa;
    pa.x -= ba * clamp(pa.x / ba , 0.0 , 1.0);
    return length(pa);
 }

float udRoundBox(in float2 p , in float2 c , in float2 b , in float r)
 {
  return length(max(abs(p - c) - b , 0.0)) - r;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 
// utility 
// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float hash1(in float n)
 {
    return frac(sin(n) * 138.5453123);
 }

// Digit data by P_Malin ( https: // www.shadertoy.com / view / 4sf3RN ) 


int PrintInt(in float2 uv , in int value)
 {
    const int maxDigits = 3;
    if (abs(uv.y - 0.5) < 0.5)
     {
        int iu = int(floor(uv.x));
        if (iu >= 0 && iu < maxDigits)
         {
            int n = (value / powers[maxDigits - iu - 1]) % 10;
            uv.x = frac(uv.x); // ( uv.x - float ( iu ) ) ; 
            int2 p = int2 (floor(uv * float2 (4.0 , 5.0)));
            return (font[n] >> (p.x + p.y * 4)) & 1;
         }
     }
    return 0;
 }

// == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = 

float doBrick(in int2 id , out float3 col , out float glo , out float2 cen)
 {
    float alp = 0.0;

    glo = 0.0;
    col = float3 (0.0 , 0.0 , 0.0);
    cen = float2 (0.0 , 0.0);

    if (id.x > 0 && id.x < 13 && id.y >= 0 && id.y < 12)
     {
        float2 brickHere = pointSampleTex2D(_Channel0 , sampler_Channel0 , txBricks.xy + id ).xy;

        alp = 1.0;
        glo = 0.0;
        if (brickHere.x < 0.5)
         {
            float t = max(0.0 , _Time.y - brickHere.y - 0.1);
            alp = exp(-2.0 * t);
            glo = exp(-4.0 * t);
         }

        if (alp > 0.001)
         {
            float fid = hash1(float(id.x * 3 + id.y * 16));
            col = float3 (0.5 , 0.5 , 0.6) + 0.4 * sin(fid * 2.0 + 4.5 + float3 (0.0 , 1.0 , 1.0));
            if (hash1(fid * 13.1) > 0.85)
             {
                col = 1.0 - 0.9 * col;
                col.xy += 0.2;
             }
         }

        cen = float2 (-1.0 + float(id.x) * brickW + 0.5 * brickW ,
                     1.0 - float(id.y) * brickH - 0.5 * brickH);
     }

    return alp;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 uv = (2.0 * fragCoord - _ScreenParams.xy) / _ScreenParams.y;
     float px = 2.0 / _ScreenParams.y;

     // -- -- -- -- -- -- -- -- -- -- -- -- 
     // load game state 
     // -- -- -- -- -- -- -- -- -- -- -- -- 
    float2 ballPos = pointSampleTex2D(_Channel0 , sampler_Channel0 , txBallPosVel ).xy;
    float paddlePos = pointSampleTex2D(_Channel0 , sampler_Channel0 , txPaddlePos ).x;
    float points = pointSampleTex2D(_Channel0 , sampler_Channel0 , txPoints ).x;
    float state = pointSampleTex2D(_Channel0 , sampler_Channel0 , txState ).x;
    float3 lastHit = pointSampleTex2D(_Channel0 , sampler_Channel0 , txLastHit ).xyz;


    // -- -- -- -- -- -- -- -- -- -- -- -- 
    // draw 
    // -- -- -- -- -- -- -- -- -- -- -- -- 
   float3 col = float3 (0.0 , 0.0 , 0.0);
   float3 emi = float3 (0.0 , 0.0 , 0.0);

   // board 
   {
      col = 0.6 * float3 (0.4 , 0.6 , 0.7) * (1.0 - 0.4 * length(uv));
      col *= 1.0 - 0.1 * smoothstep(0.0 , 1.0 , sin(uv.x * 80.0) * sin(uv.y * 80.0)) * (1.0 - smoothstep(1.0 , 1.01 , abs(uv.x)));
   }

   // bricks 
   {
      float b = brickW * 0.17;

      // soft shadow 
      {
         float2 st = uv + shadowOffset;
         int2 id = int2 (floor(float2 ((1.0 + st.x) / brickW , (1.0 - st.y) / brickH)));

         float3 bcol; float2 bcen; float bglo;

         float sha = 0.0;
         for (int j = -1; j <= 1; j++)
          for (int i = -1; i <= 1; i++)
           {
             int2 idr = id + int2 (i , j);
             float alp = doBrick(idr , bcol , bglo , bcen);
             float f = udRoundBox(st , bcen , 0.5 * float2 (brickW , brickH) - b , b);
             float s = 1.0 - smoothstep(-brickH * 0.5 , brickH * 1.0 , f);
             s = lerp(0.0 , s , alp);
             sha = max(sha , s);
          }
         col = lerp(col , col * 0.4 , sha);
      }


     int2 id = int2 (floor(float2 ((1.0 + uv.x) / brickW , (1.0 - uv.y) / brickH)));

     // shape 
     {
        float3 bcol; float2 bcen; float bglo;
        float alp = doBrick(id , bcol , bglo , bcen);
        if (alp > 0.0001)
         {
            float f = udRoundBox(uv , bcen , 0.5 * float2 (brickW , brickH) - b , b);
            bglo += 0.6 * smoothstep(-4.0 * px , 0.0 , f);

            bcol *= 0.7 + 0.3 * smoothstep(-4.0 * px , -2.0 * px , f);
            bcol *= 0.5 + 1.7 * bglo;
            col = lerp(col , bcol , alp * (1.0 - smoothstep(-px , px , f)));
         }
     }

     // gather glow 
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++)
     {
        int2 idr = id + int2 (i , j);
        float3 bcol = float3 (0.0 , 0.0 , 0.0); float2 bcen; float bglo;
        float alp = doBrick(idr , bcol , bglo , bcen);
        float f = udRoundBox(uv , bcen , 0.5 * float2 (brickW , brickH) - b , b);
        emi += bcol * bglo * exp(-600.0 * f * f);
     }
 }


   // ball 
   {
      float hit = exp(-4.0 * (_Time.y - lastHit.y));

      // shadow 
     float f = 1.0 - smoothstep(ballRadius * 0.5 , ballRadius * 2.0 , length(uv - ballPos + shadowOffset));
     col = lerp(col , col * 0.4 , f);

     // shape 
    f = length(uv - ballPos) - ballRadius;
    float3 bcol = float3 (1.0 , 0.6 , 0.2);
    bcol *= 1.0 + 0.7 * smoothstep(-3.0 * px , -1.0 * px , f);
    bcol *= 0.7 + 0.3 * hit;
    col = lerp(col , bcol , 1.0 - smoothstep(0.0 , px , f));

    emi += bcol * 0.75 * hit * exp(-500.0 * f * f);
 }


   // paddle 
   {
      float hit = exp(-4.0 * (_Time.y - lastHit.x)) * sin(20.0 * (_Time.y - lastHit.x));
      float hit2 = exp(-4.0 * (_Time.y - lastHit.x));
      float y = uv.y + 0.04 * hit * (1.0 - pow(abs(uv.x - paddlePos) / (paddleSize * 0.5) , 2.0));

      // shadow 
     float f = udHorizontalSegment(float2 (uv.x , y) + shadowOffset , paddlePos - paddleSize * 0.5 , paddlePos + paddleSize * 0.5 , paddlePosY);
     f = 1.0 - smoothstep(paddleWidth * 0.5 * 0.5 , paddleWidth * 0.5 * 2.0 , f);
     col = lerp(col , col * 0.4 , f);

     // shape 
    f = udHorizontalSegment(float2 (uv.x , y) , paddlePos - paddleSize * 0.5 , paddlePos + paddleSize * 0.5 , paddlePosY) - paddleWidth * 0.5;
    float3 bcol = float3 (1.0 , 0.6 , 0.2);
    bcol *= 1.0 + 0.7 * smoothstep(-3.0 * px , -1.0 * px , f);
    bcol *= 0.7 + 0.3 * hit2;
    col = lerp(col , bcol , 1.0 - smoothstep(-px , px , f));
    emi += bcol * 0.75 * hit2 * exp(-500.0 * f * f);

 }


   // borders 
   {
      float f = abs(abs(uv.x) - 1.02);
      f = min(f , udHorizontalSegment(uv , -1.0 , 1.0 , 1.0));
      f *= 2.0;
      float a = 0.8 + 0.2 * sin(2.6 * _Time.y) + 0.1 * sin(4.0 * _Time.y);
      float hit = exp(-4.0 * (_Time.y - lastHit.z));
      // 
     a *= 1.0 - 0.3 * hit;
     col += a * 0.5 * float3 (0.6 , 0.30 , 0.1) * exp(-30.0 * f * f);
     col += a * 0.5 * float3 (0.6 , 0.35 , 0.2) * exp(-150.0 * f * f);
     col += a * 1.7 * float3 (0.6 , 0.50 , 0.3) * exp(-900.0 * f * f);
  }

   // score 
   {
      float f = float(PrintInt((uv - float2 (-1.5 , 0.8)) * 10.0 , int(points)));
      col = lerp(col , float3 (1.0 , 1.0 , 1.0) , f);
   }


   // add emmission 
  col += emi;


  // -- -- -- -- -- -- -- -- -- -- -- -- 
  // game over 
  // -- -- -- -- -- -- -- -- -- -- -- -- 
 col = lerp(col , float3 (1.0 , 0.5 , 0.2) , state * (0.5 + 0.5 * sin(30.0 * _Time.y)));

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