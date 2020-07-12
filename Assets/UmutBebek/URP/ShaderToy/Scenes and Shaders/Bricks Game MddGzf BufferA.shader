Shader "UmutBebek/URP/ShaderToy/Bricks Game MddGzf BufferA"
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
gameSpeed("gameSpeed", float) = 3.0
inputSpeed("inputSpeed", float) = 2.0
KEY_SPACE("KEY_SPACE", int) = 0
KEY_LEFT("KEY_LEFT", int) = 0
KEY_RIGHT("KEY_RIGHT", int) = 0

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

            ZWrite On
     Blend SrcAlpha OneMinusSrcAlpha
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
float gameSpeed;
float inputSpeed;
int KEY_SPACE;
int KEY_LEFT;
int KEY_RIGHT;


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
// Gameplay computation. 
// 
// The gameplay buffer is 14x14 pixels. The whole game is run / played for each one of these 
// pixels. A filter in the end of the shader takes only the bit of infomration that needs 
// to be stored in each texl of the game - logic texture. 

// storage register / texel addresses 





















// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float hash1(float n) { return frac(sin(n) * 138.5453123); }

// intersect a disk sweept in a linear segment with a line / plane. 
float iPlane(in float2 ro , in float2 rd , float rad , float3 pla)
 {
    float a = dot(rd , pla.xy);
    if (a > 0.0) return -1.0;
    float t = (rad - pla.z - dot(ro , pla.xy)) / a;
    if (t >= 1.0) t = -1.0;
    return t;
 }

// intersect a disk sweept in a linear segment with a box 
float3 iBox(in float2 ro , in float2 rd , in float rad , in float2 bce , in float2 bwi)
 {
    float2 m = 1.0 / rd;
    float2 n = m * (ro - bce);
    float2 k = abs(m) * (bwi + rad);
    float2 t1 = -n - k;
    float2 t2 = -n + k;
     float tN = max(t1.x , t1.y);
     float tF = min(t2.x , t2.y);
     if (tN > tF || tF < 0.0) return float3 (-1.0, -1.0, -1.0);
    if (tN >= 1.0) return float3 (-1.0, -1.0, -1.0);
     float2 nor = -sign(rd) * step(t1.yx , t1.xy);
     return float3 (tN , nor);
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

float4 loadValue(in int2 re)
 {
    return pointSampleTex2D(_Channel0 , sampler_Channel0 , re );
 }
void storeValue(in int2 re , in float4 va , inout float4 fragColor , in int2 p)
 {
    fragColor = all(p == re) ? va : fragColor;
 }
void storeValue(in int4 re , in float4 va , inout float4 fragColor , in int2 p)
 {
    fragColor = (p.x >= re.x && p.y >= re.y && p.x <= re.z && p.y <= re.w) ? va : fragColor;
 }

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN))* _ScreenParams.xy;
     int2 ipx = int2 (fragCoord - 0.5);

     // don't compute gameplay outside of the data area 
    if (fragCoord.x > 14.0 || fragCoord.y > 14.0) discard;

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
     // load game state 
     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
   float4 balPosVel = loadValue(txBallPosVel);
   float paddlePos = loadValue(txPaddlePos).x;
   float points = loadValue(txPoints).x;
   float state = loadValue(txState).x;
   float3 lastHit = loadValue(txLastHit).xyz; // paddle , brick , wall 
   float2 brick = loadValue(ipx).xy; // visible , hittime 

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
    // reset 
     // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
    if (iFrame == 0) state = -1.0;

   if (state < -0.5)
    {
       state = 0.0;
       balPosVel = float4 (0.0 , paddlePosY + ballRadius + paddleWidth * 0.5 + 0.001 , 0.6 , 1.0);
       paddlePos = 0.0;
       points = 0.0;
       state = 0.0;
       brick = float2 (1.0 , -5.0);
       lastHit = float3 (-1.0, -1.0, -1.0);


       if (fragCoord.x < 1.0 || fragCoord.x > 12.0)
        {
           brick.x = 0.0;
           brick.y = -10.0;
        }


    }

   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
   // do game 
   // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
   
   // game over ( or won ) , wait for space key press to resume 
  if (state > 0.5)
   {
      float pressSpace = pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (KEY_SPACE , 0.0)).x;
      if (pressSpace > 0.5)
       {
          //state = -1.0;
       }
   }

  // if game mode ( not game over ) , play game 
 else if (state < 0.5)
   {

      // -- -- -- -- -- -- -- -- -- - 
      // paddle 
      // -- -- -- -- -- -- -- -- -- - 
     float oldPaddlePos = paddlePos;
     /*if (iMouse.w > 0.01)
      {*/
         // move with mouse 
        paddlePos = (-1.0 + 2.0 * iMouse.x / _ScreenParams.x) * _ScreenParams.x / _ScreenParams.y;
     /*}
    else
     {*/
         // move with keyboard 
        /*float moveRight = pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (KEY_RIGHT , 0) ).x;
        float moveLeft = pointSampleTex2D(_Channel1 , sampler_Channel1 , int2 (KEY_LEFT , 0) ).x;
        paddlePos += 0.02 * inputSpeed * (moveRight - moveLeft);*/
     /*}*/
    paddlePos = clamp(paddlePos , -1.0 + 0.5 * paddleSize + paddleWidth * 0.5 , 1.0 - 0.5 * paddleSize - paddleWidth * 0.5);

    float moveTotal = sign(paddlePos - oldPaddlePos);

    // -- -- -- -- -- -- -- -- -- - 
    // ball 
      // -- -- -- -- -- -- -- -- -- - 
   float dis = 0.01 * gameSpeed * (iTimeDelta * 60.0);

   // do up to 3 sweep collision detections ( usually 0 or 1 will happen only ) 
  for (int j = 0; j < 3; j++)
   {
      int3 oid = int3 (-1, -1, -1);
      float2 nor;
      float t = 1000.0;

      // test walls 
     const float3 pla1 = float3 (-1.0 , 0.0 , 1.0);
     const float3 pla2 = float3 (1.0 , 0.0 , 1.0);
     const float3 pla3 = float3 (0.0 , -1.0 , 1.0);
     float t1 = iPlane(balPosVel.xy , dis * balPosVel.zw , ballRadius , pla1); if (t1 > 0.0) { t = t1; nor = pla1.xy; oid.x = 1; }
     float t2 = iPlane(balPosVel.xy , dis * balPosVel.zw , ballRadius , pla2); if (t2 > 0.0 && t2 < t) { t = t2; nor = pla2.xy; oid.x = 2; }
     float t3 = iPlane(balPosVel.xy , dis * balPosVel.zw , ballRadius , pla3); if (t3 > 0.0 && t3 < t) { t = t3; nor = pla3.xy; oid.x = 3; }

     // test paddle 
    float3 t4 = iBox(balPosVel.xy , dis * balPosVel.zw , ballRadius , float2 (paddlePos , paddlePosY) , float2 (paddleSize * 0.5 , paddleWidth * 0.5));
    if (t4.x > 0.0 && t4.x < t) { t = t4.x; nor = t4.yz; oid.x = 4; }

    // test bricks 
   int2 idr = int2 (floor(float2 ((1.0 + balPosVel.x) / brickW , (1.0 - balPosVel.y) / brickH)));
   int2 vs = int2 (sign(balPosVel.zw));
   for (int j = 0; j < 3; j++)
   for (int i = 0; i < 3; i++)
    {
       int2 id = idr + int2 (vs.x * i , -vs.y * j);
       if (id.x >= 0 && id.x < 13 && id.y >= 0 && id.y < 12)
        {
           float brickHere = pointSampleTex2D(_Channel0 , sampler_Channel0 , (txBricks.xy + id) ).x;
           if (brickHere > 0.5)
            {
               float2 ce = float2 (-1.0 + float(id.x) * brickW + 0.5 * brickW ,
                                1.0 - float(id.y) * brickH - 0.5 * brickH);
               float3 t5 = iBox(balPosVel.xy , dis * balPosVel.zw , ballRadius , ce , 0.5 * float2 (brickW , brickH));
               if (t5.x > 0.0 && t5.x < t)
                {
                   oid = int3 (5 , id);
                   t = t5.x;
                   nor = t5.yz;
                }
            }
        }
    }

   // no collisions 
  if (oid.x < 0) break;


  // bounce 
 balPosVel.xy += t * dis * balPosVel.zw;
 dis *= 1.0 - t;

 // did hit walls 
if (oid.x < 4)
 {
    balPosVel.zw = reflect(balPosVel.zw , nor);
    lastHit.z = _Time.y;
 }
// did hit paddle 
else if (oid.x < 5)
 {
    balPosVel.zw = reflect(balPosVel.zw , nor);
    // borders bounce back 
        if (balPosVel.x > (paddlePos + paddleSize * 0.5)) balPosVel.z = abs(balPosVel.z);
   else if (balPosVel.x < (paddlePos - paddleSize * 0.5)) balPosVel.z = -abs(balPosVel.z);
   balPosVel.z += 0.37 * moveTotal;
   balPosVel.z += 0.11 * hash1(float(iFrame) * 7.1);
   balPosVel.z = clamp(balPosVel.z , -0.9 , 0.9);
   balPosVel.zw = normalize(balPosVel.zw);

   // 
  lastHit.x = _Time.y;
  lastHit.y = _Time.y;
}
// did hit a brick 
else if (oid.x < 6)
 {
    balPosVel.zw = reflect(balPosVel.zw , nor);
    lastHit.y = _Time.y;
    points += 1.0;
    if (points > 131.5)
     {
        state = 2.0; // won game! 
     }

    if (all(ipx == (txBricks.xy + oid.yz)))
     {
        brick = float2 (0.0 , _Time.y);
     }
 }
}

balPosVel.xy += dis * balPosVel.zw;

// detect miss 
if (balPosVel.y < -1.0)
 {
    state = 1.0; // game over 
 }
}

  // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
  // store game state 
  // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- - 
fragColor = float4 (0.0 , 0.0 , 0.0 , 0.0);


storeValue(txBallPosVel , float4 (balPosVel) , fragColor , ipx);
storeValue(txPaddlePos , float4 (paddlePos , 0.0 , 0.0 , 0.0) , fragColor , ipx);
storeValue(txPoints , float4 (points , 0.0 , 0.0 , 0.0) , fragColor , ipx);
storeValue(txState , float4 (state , 0.0 , 0.0 , 0.0) , fragColor , ipx);
storeValue(txLastHit , float4 (lastHit , 0.0) , fragColor , ipx);
storeValue(txBricks , float4 (brick , 0.0 , 0.0) , fragColor , ipx);
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