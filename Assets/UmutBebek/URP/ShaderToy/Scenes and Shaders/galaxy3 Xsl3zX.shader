Shader "UmutBebek/URP/ShaderToy/galaxy3 Xsl3zX"
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

           float3 makeDarker(float3 item) {
               return item *= 0.90;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // -- - Galaxy -- - Fabrice NEYRET august 2013 

static const float RETICULATION = 3.; // strenght of dust SAMPLE_TEXTURE2D 
static const float NB_ARMS = 5.; // number of arms 
 // static const float ARM = 3. ; // contrast in / out arms 
static const float COMPR = .1; // compression in arms 
static const float SPEED = .1;
static const float GALAXY_R = 1. / 2.;
static const float BULB_R = 1. / 4.;
static const float3 GALAXY_COL = float3 (.9 , .9 , 1.); // ( 1. , .8 , .5 ) ; 
static const float3 BULB_COL = float3 (1. , .8 , .8);
static const float3 SKY_COL = .5 * float3 (.1 , .3 , .5);

#define t _Time.y 

// -- - base noise 
float tex(float2 uv)
 {
     float n = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , uv , 0.).r;

#define MODE 3 // kind of noise SAMPLE_TEXTURE2D 
#if MODE == 0 // unsigned 
     #define A 2. 
     return n;
#elif MODE == 1 // signed 
     #define A 3. 
     return 2. * n - 1.;
#elif MODE == 2 // bulbs 
     #define A 3. 
     return abs(2. * n - 1.);
#elif MODE == 3 // wires 
     #define A 1.5 
     return 1. - abs(2. * n - 1.);
#endif 
 }


// -- - perlin turbulent noise + rotation 
float noise(float2 uv)
 {
     float v = 0.;
     float a = -SPEED * t , co = cos(a) , si = sin(a);
     float2x2 M = float2x2 (co , -si , si , co);
     static const int L = 7;
     float s = 1.;
     for (int i = 0; i < L; i++)
      {
          uv = mul(M , uv);
          float b = tex(uv * s);
          v += 1. / s * pow(b , RETICULATION);
          s *= 2.;
      }

    return v / 2.;
 }

bool keyToggle(int ascii)
 {
     return (SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , float2 ((.5 + float(ascii)) / 256. , 0.75)).x > 0.);
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.y - float2 (.8 , .5);
      float3 col;

      // spiral stretching with distance 
     float rho = length(uv); // polar coords 
     float ang = atan2(uv.y , uv.x);
     float shear = 2. * log(rho); // logarythmic spiral 
     float c = cos(shear) , s = sin(shear);
     float2x2 R = float2x2 (c , -s , s , c);

     // galaxy profile 
    float r; // disk 
    r = rho / GALAXY_R; float dens = exp(-r * r);
    r = rho / BULB_R; float bulb = exp(-r * r);
    float phase = NB_ARMS * (ang - shear);
    // arms = spirals compression 
   ang = ang - COMPR * cos(phase) + SPEED * t;
   uv = rho * float2 (cos(ang) , sin(ang));
   // stretched SAMPLE_TEXTURE2D must be darken by d ( new_ang ) / d ( ang ) 
  float spires = 1. + NB_ARMS * COMPR * sin(phase);
  // pires = lerp ( 1. , sin ( phase ) , ARM ) ; 
 dens *= .7 * spires;

 // gaz SAMPLE_TEXTURE2D 
float gaz = noise(.09 * 1.2 * mul(R , uv));
float gaz_trsp = pow((1. - gaz * dens) , 2.);

// stars 
// float a = SPEED * t , co = cos ( a ) , si = sin ( a ) ; 
// float2x2 M = float2x2 ( co , - si , si , co ) ; 
// adapt stars size to display resolution 
float ratio = .8 * _ScreenParams.y / _ScreenParams.y;
float stars1 = SAMPLE_TEXTURE2D_LOD(_Channel1 , sampler_Channel1 , ratio * uv + .5 , 0.).r , // M * uv 
      stars2 = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , ratio * uv + .5 , 0.).r ,
       stars = pow(1. - (1. - stars1) * (1. - stars2) , 5.);

// stars = pow ( stars , 5. ) ; 

// keybord controls ( numbers ) 
//if (keyToggle(49)) gaz_trsp = 1. / 1.7;
//if (keyToggle(50)) stars = 0.;
//if (keyToggle(51)) bulb = 0.;
//if (keyToggle(52)) dens = .3 * spires;
gaz_trsp = 1. / 1.7;
dens = .3 * spires;

// lerp all 
col = lerp(SKY_COL ,
            gaz_trsp * (1.7 * GALAXY_COL) + 1.2 * stars ,
            dens);
col = lerp(col , 1.2 * BULB_COL , bulb);

fragColor = float4 (col , 1.);
fragColor.xyz *= 0.85;
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