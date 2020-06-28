Shader "UmutBebek/URP/ShaderToy/Gate ttjXzd"
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

             #define PI 3.14159265358979323846 

float2 rotate(float2 _st , float _angle) {
    _st = mul (float2x2 (cos(_angle) , -sin(_angle) ,
                sin(_angle) , cos(_angle)) , _st);
    return _st;
 }

float sdCircle(in float2 _st , in float _radius)
 {
    return length(_st) - _radius;
 }

float boxDist(float2 p , float2 size , float radius)
 {
       float2 d = abs(p) - size - radius;
       return min(max(d.x , d.y) , 0.0) + length(max(d , 0.0)) - radius;
 }


// by IQ 
// http: // www.iquilezles.org / www / articles / distfunctions2d / distfunctions2d.htm 
float sdTrapezoid(in float2 p , in float r1 , float r2 , float he)
 {
    float2 k1 = float2 (r2 , he);
    float2 k2 = float2 (r2 - r1 , 2.0 * he);

     p.x = abs(p.x);
    float2 ca = float2 (max(0.0 , p.x - ((p.y < 0.0) ? r1 : r2)) , abs(p.y) - he);
    float2 cb = p - k1 + k2 * clamp(dot(k1 - p , k2) / dot(k2 , k2) , 0.0 , 1.0);

    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;

    return s * sqrt(min(dot(ca , ca) , dot(cb , cb)));
 }

// 2D Random 
float random(in float2 st) { return frac(sin(dot(st.xy , float2 (12.9898 , 78.233))) * 43758.5453123); }

// https: // thebookofshaders.com / edit.php#12 / vorono - 01.frag 
float voroni(in float2 _st , in float _offset)
 {
    float2 i_st = floor(_st);
    float2 f_st = frac(_st);

    float m_dist = 150.; // minimun distance 
    float2 m_point; // minimum point 

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 neighbor = float2 (float(i) , float(j));
            float2 point1 = float2 (random(i_st + neighbor) , random(i_st + neighbor));
            point1 = 0.5 + 0.5 * sin(_offset + 6.2831 * point1);
            float2 diff = neighbor + point1 - f_st;
            float dist = length(diff);

            if (dist < m_dist) {
                m_dist = dist;
                m_point = point1;
             }
         }
     }

    return m_dist;
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
half4 fragColor = half4 (1 , 1 , 1 , 1);
float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
    float2 st = 4.0 * fragCoord.xy / _ScreenParams.x - float2 (2.0 , 1.0);


    float3 col1 = float3 (1.0 , 1.0 , 0.416);
    float3 col2 = float3 (0.0 , 0.0 , 0.0);
    float3 col3 = float3 (0.0 , 0.0 , 0.65);

    float3 color = float3 (0.0 , 0.0 , 0.0);


    float ripples;
    float gateDF;
    float3 gradient;



    // * * * * * * * * * * * * * * 
   if (st.y >= -0.2)
    {
       color = lerp(col1 , col3 , st.y * 2.0 + 0.5);
        color = lerp(color , col2 , st.y * 0.8 + 0.0);

        // // * * * * * * * * * * * * * * 
       float starsDF = 1.0 - smoothstep(voroni(-st * 40.0 , 0.0) , 0.0 , 0.018);
       starsDF += 1.0 - smoothstep(voroni(st * float2 (-2.0 , 2.0) - float2 (_Time.y * 0.38 , 0.0) + st.x * 2.0 , 0.0) , 0.0 , 0.015);
       color = lerp(color , float3 (1.0 , 1.0 , 1.0) , starsDF * 0.75);

       gateDF = boxDist(st - float2 (0.0 , -0.25) , float2 (0.225 , 1.1) , 0.0);
        gradient = lerp(col3 , col1 , st.y + 0.45 - (st.x * 0.3));
        gradient = lerp(gradient , float3 (1.0 , 1.0 , 1.0) , 0.15);
        color = lerp(color , gradient , clamp(1.0 - sign(gateDF) , 0.0 , 1.0));
       color = lerp(color , float3 (0.678 , 0.847 , 0.902) , 1.0 - smoothstep(0.0 , 0.015 , abs(gateDF)));
    }
   else
    {

       float2 xy = st;
       // xy.y = ceil ( xy.y * 12.0 - sin ( _Time.y - xy.y * 3.0 ) ) ; 

       // xy.y = ceil ( xy.y * 3.0 + 3.0 + sin ( _Time.y - xy.y ) ) ; 
       // float timeOffset = ceil ( xy.y * 3.0 + 3.0 + sin ( _Time.y - xy.y ) ) ; 


       // color = lerp ( col1 , col3 , xy.y * - 3.0 - 0.8 + timeOffset ) ; 
        // color = lerp ( color , col2 , xy.y - 0.2 + timeOffset ) ; 

// float dx = 1.0 + _Time.y / 25.0 - abs ( distance ( xy.y , floor ( xy.x ) ) ) ; 
// float dx2 = 1.0 + 0.25 / 10.0 - abs ( distance ( xy.y , 0.5 ) ) ; 
// float dy = ( 1.0 - abs ( distance ( xy.y , mod ( 0.0 + _Time.y , 1.0 ) ) ) ) ; 
// dy = ( dy > 0.5 ) ? 2.0 * dy : 2.0 * ( 1.0 - dy ) ; 

// if ( dx2 > 1.0 - 0.25 / 10.0 ) { 
 // float rX2 = ( dy * random ( float2 ( dy , dx ) ) + dx2 ) / 4.0 ; 
 // xy.y += 0.5 + rX2 / 12.5 ; 
// } 

// xy.y = mod ( xy.y , 1.0 ) ; 

       color = lerp(col1 , col3 , xy.y * -3.5 - 0.8);
        color = lerp(color , col2 , xy.y - 0.0);

       gateDF = boxDist(xy - float2 (0.0 , -0.25) , float2 (0.225 , 1.1) , 0.0);
        gradient = lerp(col3 , col1 , xy.y + 0.45 - (xy.x * 0.3));
        gradient = lerp(gradient , float3 (1.0 , 1.0 , 1.0) , 0.15);
       color = lerp(color , gradient , clamp(1.0 - sign(gateDF) , 0.0 , 1.0));
       color = lerp(color , float3 (0.678 , 0.847 , 0.902) , 1.0 - smoothstep(0.0 , 0.015 , abs(gateDF)));
    }


   // * * * * * * * * * * * * * 
   if (st.y < -0.2)
   {
       // // * * * * * * * * * * * * * * 
      float2 xy = 2.0 * fragCoord.xy / _ScreenParams.xy - float2 (1.0 , 0.25);
      xy.x += abs(mul(sin(st.y + 0.5) , 8.0)) - 1.3;
      float road = sdTrapezoid(xy - float2 (0.05 , 0.0) , 4.0 , 0.2 , 0.325);

      gradient = lerp(float3 (1.0 , 1.0 , 1.0) , float3 (0.0 , 0.0 , 0.125) , st.y * -0.75 + 0.45);
      gradient = lerp(float3 (1.0 , 1.0 , 1.0) , float3 (0.0 , 0.0 , 0.235) , -road + 1.05);

      color = lerp(color , gradient , 1.0 - smoothstep(0.0 , 0.0175 - st.y / 32.0 , road));
   }

   // * * * * * * * * * * * * * 
  if (st.x < -1.0 || st.x > 1.0)
   {
      color = float3 (0.0 , 0.0 , 0.0);
   }

      fragColor = float4 (
          (float3 (color )).x , 
          (float3 (color )).y , (float3 (color )).z , 1.0);

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