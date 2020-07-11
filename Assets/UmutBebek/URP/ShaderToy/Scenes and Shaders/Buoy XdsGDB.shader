Shader "UmutBebek/URP/ShaderToy/Buoy XdsGDB"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        tau("tau", float) = 6.28318530717958647692
        GAMMA("GAMMA", float) = 2.2
            // Gamma correction  

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
            float tau;
            float GAMMA;


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

           // License Creative Commons Attribution - NonCommercial - ShareAlike 3.0 Unported License. 




float3 ToLinear(in float3 col)
 {
    // simulate a monitor , converting colour values into light values 
   return pow(col , float3 (GAMMA, GAMMA, GAMMA));
}

float3 ToGamma(in float3 col)
 {
    // convert back into colour values , so the correct light will come out of the monitor 
   return pow(col , float3 (1.0 / GAMMA, 1.0 / GAMMA, 1.0 / GAMMA));
}

float3 localRay;

// Set up a camera looking at the scene. 
// origin - camera is positioned relative to , and looking at , this pointExtended 
// distance - how far camera is from origin 
// rotation - about x & y axes , by left - hand screw rule , relative to camera looking along + z 
// zoom - the relative length of the lens 
void CamPolar(out float3 pos , out float3 ray , in float3 origin , in float2 rotation , in float distance , in float zoom , in float2 fragCoord)
 {
    // get rotation coefficients 
   float2 c = float2 (cos(rotation.x) , cos(rotation.y));
   float4 s;
   s.xy = float2 (sin(rotation.x) , sin(rotation.y)); // worth testing if this is faster as sin or sqrt ( 1.0 - cos ) ; 
   s.zw = -s.xy;

   // ray in view space 
  ray.xy = fragCoord.xy - _ScreenParams.xy * .5;
  ray.z = _ScreenParams.y * zoom;
  ray = normalize(ray);
  localRay = ray;

  // rotate ray 
 ray.yz = ray.yz * c.xx + ray.zy * s.zx;
 ray.xz = ray.xz * c.yy + ray.zx * s.yw;

 // position camera 
pos = origin - distance * float3 (c.x * s.y , s.z , c.x * c.y);
}


// Noise functions , distinguished by variable types 

float2 Noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);
     // float3 f2 = f * f ; f = f * f2 * ( 10.0 - 15.0 * f + 6.0 * f2 ) ; 

         float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z);

         float4 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + f.xy + 0.5) / 256.0 , 0.0);

         return lerp(rg.yw , rg.xz , f.z);
     }

    float2 NoisePrecise(in float3 x)
     {
        float3 p = floor(x);
        float3 f = frac(x);
         f = f * f * (3.0 - 2.0 * f);
         // float3 f2 = f * f ; f = f * f2 * ( 10.0 - 15.0 * f + 6.0 * f2 ) ; 

             float2 uv = (p.xy + float2 (37.0 , 17.0) * p.z);

             float4 rg = lerp(lerp(
                            SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0) ,
                            SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (1 , 0) + 0.5) / 256.0 , 0.0) ,
                            f.x) ,
                              lerp(
                            SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + float2 (0 , 1) + 0.5) / 256.0 , 0.0) ,
                            SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 1.5) / 256.0 , 0.0) ,
                            f.x) ,
                            f.y);


             return lerp(rg.yw , rg.xz , f.z);
         }

        float4 Noise(in float2 x)
         {
            float2 p = floor(x.xy);
            float2 f = frac(x.xy);
             f = f * f * (3.0 - 2.0 * f);
             // float3 f2 = f * f ; f = f * f2 * ( 10.0 - 15.0 * f + 6.0 * f2 ) ; 

                 float2 uv = p.xy + f.xy;
                 return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0);
             }

            float4 Noise(in int2 x)
             {
                 return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (float2 (x)+0.5) / 256.0 , 0.0);
             }

            float2 Noise(in int3 x)
             {
                 float2 uv = float2 (x.xy) + float2 (37.0 , 17.0) * float(x.z);
                 return SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).xz;
             }


            float Waves(float3 pos)
             {
                 pos *= .2 * float3 (1 , 1 , 1);

                 const int octaves = 5;
                 float f = 0.0;

                 // need to do the octaves from large to small , otherwise things don't line up 
                 // ( because I rotate by 45 degrees on each octave ) 
                     pos += _Time.y * float3 (0 , .1 , .1);
                for (int i = 0; i < octaves; i++)
                 {
                     pos = (pos.yzx + pos.zyx * float3 (1 , -1 , 1)) / sqrt(2.0);
                     f = f * 2.0 + abs(Noise(pos).x - .5) * 2.0;
                     pos *= 2.0;
                 }
                f /= exp2(float(octaves));

                return (.5 - f) * 1.0;
            }

           float WavesDetail(float3 pos)
            {
                pos *= .2 * float3 (1 , 1 , 1);

                const int octaves = 8;
                float f = 0.0;

                // need to do the octaves from large to small , otherwise things don't line up 
                // ( because I rotate by 45 degrees on each octave ) 
                    pos += _Time.y * float3 (0 , .1 , .1);
               for (int i = 0; i < octaves; i++)
                {
                    pos = (pos.yzx + pos.zyx * float3 (1 , -1 , 1)) / sqrt(2.0);
                    f = f * 2.0 + abs(NoisePrecise(pos).x - .5) * 2.0;
                    pos *= 2.0;
                }
               f /= exp2(float(octaves));

               return (.5 - f) * 1.0;
           }

          float WavesSmooth(float3 pos)
           {
               pos *= .2 * float3 (1 , 1 , 1);

               const int octaves = 2;
               float f = 0.0;

               // need to do the octaves from large to small , otherwise things don't line up 
               // ( because I rotate by 45 degrees on each octave ) 
                   pos += _Time.y * float3 (0 , .1 , .1);
              for (int i = 0; i < octaves; i++)
               {
                   pos = (pos.yzx + pos.zyx * float3 (1 , -1 , 1)) / sqrt(2.0);
                   // f = f * 2.0 + abs ( Noise ( pos ) .x - .5 ) * 2.0 ; 
                  f = f * 2.0 + sqrt(pow(NoisePrecise(pos).x - .5 , 2.0) + .01) * 2.0;
                  pos *= 2.0;
              }
             f /= exp2(float(octaves));

             return (.5 - f) * 1.0;
         }

        float WaveCrests(float3 ipos , in float2 fragCoord)
         {
             float3 pos = ipos;
             pos *= .2 * float3 (1 , 1 , 1);

             const int octaves1 = 6;
             const int octaves2 = 16;
             float f = 0.0;

             // need to do the octaves from large to small , otherwise things don't line up 
             // ( because I rotate by 45 degrees on each octave ) 
            pos += _Time.y * float3 (0 , .1 , .1);
            float3 pos2 = pos;
            for (int i = 0; i < octaves1; i++)
             {
                 pos = (pos.yzx + pos.zyx * float3 (1 , -1 , 1)) / sqrt(2.0);
                 f = f * 1.5 + abs(Noise(pos).x - .5) * 2.0;
                 pos *= 2.0;
             }
            pos = pos2 * exp2(float(octaves1));
            pos.y = -.05 * _Time.y;
            for (int i = octaves1; i < octaves2; i++)
             {
                 pos = (pos.yzx + pos.zyx * float3 (1 , -1 , 1)) / sqrt(2.0);
                 f = f * 1.5 + pow(abs(Noise(pos).x - .5) * 2.0 , 1.0);
                 pos *= 2.0;
             }
            f /= 1500.0;

            f -= Noise(int2 (fragCoord.xy)).x * .01;

            return pow(smoothstep(.4 , -.1 , f) , 6.0);
        }


       float3 Sky(float3 ray)
        {
            return float3 (.4 , .45 , .5);
        }


       float3 boatRight , boatUp , boatForward;
       float3 boatPosition;

       void ComputeBoatTransform(void)
        {
            float3 samples[5];

            samples[0] = float3 (0 , 0 , 0);
            samples[1] = float3 (0 , 0 , .5);
            samples[2] = float3 (0 , 0 , -.5);
            samples[3] = float3 (.5 , 0 , 0);
            samples[4] = float3 (-.5 , 0 , 0);

            samples[0].y = WavesSmooth(samples[0]);
            samples[1].y = WavesSmooth(samples[1]);
            samples[2].y = WavesSmooth(samples[2]);
            samples[3].y = WavesSmooth(samples[3]);
            samples[4].y = WavesSmooth(samples[4]);

            boatPosition = (samples[0] + samples[1] + samples[2] + samples[3] + samples[4]) / 5.0;

            boatRight = samples[3] - samples[4];
            boatForward = samples[1] - samples[2];
            boatUp = normalize(cross(boatForward , boatRight));
            boatRight = normalize(cross(boatUp , boatForward));
            boatForward = normalize(boatForward);

            boatPosition += .0 * boatUp;
        }

       float3 BoatToWorld(float3 dir)
        {
            return dir.x * boatRight + dir.x * boatUp + dir.x * boatForward;
        }

       float3 WorldToBoat(float3 dir)
        {
            return float3 (dot(dir , boatRight) , dot(dir , boatUp) , dot(dir , boatForward));
        }

       float TraceBoat(float3 pos , float3 ray)
        {
            float3 c = boatPosition;
            float r = 1.0;

            c -= pos;

            float t = dot(c , ray);

            float p = length(c - t * ray);
            if (p > r)
                 return 0.0;

            return t - sqrt(r * r - p * p);
        }


       float3 ShadeBoat(float3 pos , float3 ray)
        {
            pos -= boatPosition;
            float3 norm = normalize(pos);
            pos = WorldToBoat(pos);

            float3 lightDir = normalize(float3 (-2 , 3 , 1));
            float ndotl = dot(norm , lightDir);

            // allow some light bleed , as if it's subsurface scattering through plastic 
           float3 light = smoothstep(-.1 , 1.0 , ndotl) * float3 (1.0 , .9 , .8) + float3 (.06 , .1 , .1);

           // anti - alias the albedo 
          float aa = 4.0 / _ScreenParams.x;

          // float3 albedo = ( ( frac ( pos.x ) - .5 ) * ( frac ( pos.y ) - .5 ) * ( frac ( pos.z ) - .5 ) < 0.0 ) ? float3 ( 0 , 0 , 0 ) : float3 ( 1 , 1 , 1 ) ; 
         float3 albedo = float3 (1 , .01 , 0);
         albedo = lerp(float3 (.04 , .04 , .04) , albedo , smoothstep(.25 - aa , .25 , abs(pos.y)));
         albedo = lerp(lerp(float3 (1 , 1 , 1) , float3 (.04 , .04 , .04) , smoothstep(-aa * 4.0 , aa * 4.0 , cos(atan2(pos.x , pos.z) * 6.0))) , albedo , smoothstep(.2 - aa * 1.5 , .2 , abs(pos.y)));
         albedo = lerp(float3 (.04 , .04 , .04) , albedo , smoothstep(.05 - aa * 1.0 , .05 , abs(abs(pos.y) - .6)));
         albedo = lerp(float3 (1 , .8 , .08) , albedo , smoothstep(.05 - aa * 1.0 , .05 , abs(abs(pos.y) - .65)));

         float3 col = albedo * light;

         // specular 
        float3 h = normalize(lightDir - ray);
        float s = pow(max(0.0 , dot(norm , h)) , 100.0) * 100.0 / 32.0;

        float3 specular = s * float3 (1 , 1 , 1);

        float3 rr = reflect(ray , norm);
        specular += lerp(float3 (0 , .04 , .04) , Sky(rr) , smoothstep(-.1 , .1 , rr.y));

        float ndotr = dot(norm , ray);
        float fresnel = pow(1.0 - abs(ndotr) , 5.0);
        fresnel = lerp(.001 , 1.0 , fresnel);

        col = lerp(col , specular , fresnel);

        return col;
    }


   float OceanDistanceField(float3 pos)
    {
        return pos.y - Waves(pos);
    }

   float OceanDistanceFieldDetail(float3 pos)
    {
        return pos.y - WavesDetail(pos);
    }

   float3 OceanNormal(float3 pos)
    {
        float3 norm;
        float2 d = float2 (.01 * length(pos) , 0);

        norm.x = OceanDistanceFieldDetail(pos + d.xyy) - OceanDistanceFieldDetail(pos - d.xyy);
        norm.y = OceanDistanceFieldDetail(pos + d.yxy) - OceanDistanceFieldDetail(pos - d.yxy);
        norm.z = OceanDistanceFieldDetail(pos + d.yyx) - OceanDistanceFieldDetail(pos - d.yyx);

        return normalize(norm);
    }

   float TraceOcean(float3 pos , float3 ray)
    {
        float h = 1.0;
        float t = 0.0;
        for (int i = 0; i < 100; i++)
         {
             if (h < .01 || t > 100.0)
                  break;
             h = OceanDistanceField(pos + t * ray);
             t += h;
         }

        if (h > .1)
             return 0.0;

        return t;
    }


   float3 ShadeOcean(float3 pos , float3 ray , in float2 fragCoord)
    {
        float3 norm = OceanNormal(pos);
        float ndotr = dot(ray , norm);

        float fresnel = pow(1.0 - abs(ndotr) , 5.0);

        float3 reflectedRay = ray - 2.0 * norm * ndotr;
        float3 refractedRay = ray + (-cos(1.33 * acos(-ndotr)) - ndotr) * norm;
        refractedRay = normalize(refractedRay);

        const float crackFudge = .0;

        // reflection 
       float3 reflection = Sky(reflectedRay);
       float t = TraceBoat(pos - crackFudge * reflectedRay , reflectedRay);

       if (t > 0.0)
        {
            reflection = ShadeBoat(pos + (t - crackFudge) * reflectedRay , reflectedRay);
        }


       // refraction 
      t = TraceBoat(pos - crackFudge * refractedRay , refractedRay);

      float3 col = float3 (0 , .04 , .04); // under - sea colour 
      if (t > 0.0)
       {
           col = lerp(col , ShadeBoat(pos + (t - crackFudge) * refractedRay , refractedRay) , exp(-t));
       }

      col = lerp(col , reflection , fresnel);

      // foam 
     col = lerp(col , float3 (1 , 1 , 1) , WaveCrests(pos , fragCoord));

     return col;
 }


half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      ComputeBoatTransform();

      float2 camRot = float2 (.5 , .5) + float2 (-.35 , 4.5) * (iMouse.yx / _ScreenParams.yx);
      float3 pos , ray;
      CamPolar(pos , ray , float3 (0 , 0 , 0) , camRot , 3.0 , 1.0 , fragCoord);

      float to = TraceOcean(pos , ray);
      float tb = TraceBoat(pos , ray);

      float3 result;
      if (to > 0.0 && (to < tb || tb == 0.0))
           result = ShadeOcean(pos + ray * to , ray , fragCoord);
      else if (tb > 0.0)
           result = ShadeBoat(pos + ray * tb , ray);
      else
           result = Sky(ray);

      // vignette effect 
     result *= 1.1 * smoothstep(.35 , 1.0 , localRay.z);

     fragColor = float4 (ToGamma(result) , 1.0);
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