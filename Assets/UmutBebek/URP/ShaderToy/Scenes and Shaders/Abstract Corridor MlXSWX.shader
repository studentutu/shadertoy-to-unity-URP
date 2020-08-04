Shader "UmutBebek/URP/ShaderToy/Abstract Corridor MlXSWX"
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
               float darken = 0.05;
               item.x = max(item.x - darken, 0);
               item.y = max(item.y - darken, 0);
               item.z = max(item.z - darken, 0);
               return item;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           /*
Abstract Corridor
 -- -- -- -- -- -- -- -- -- -

Using Shadertoy user Nimitz's triangle noise idea and his curvature function to fake an abstract ,
 flat - shaded , pointExtended - lit , mesh look.

 It's a slightly trimmed back , and hopefully , much quicker version my previous tunnel example...
 which is not interesting enough to link to. : )

*/

#define PI 3.1415926535898 
#define FH 1.0 // Floor height. Set it to 2.0 to get rid of the floor. 

// Grey scale. 
float getGrey(float3 p) { return p.x * 0.299 + p.y * 0.587 + p.z * 0.114; }

// Non - standard float3 - to - float3 hash function. 
float3 hash33(float3 p) {

    float n = sin(dot(p , float3 (7 , 157 , 113)));
    return frac(float3 (2097152 , 262144 , 32768) * n);
 }

// 2x2 matrix rotation. 
float2x2 rot2(float a) {

    float c = cos(a); float s = sin(a);
     return float2x2 (c , s , -s , c);
 }

// Tri - Planar blending function. Based on an old Nvidia tutorial. 
float3 tex3D(Texture2D tex, SamplerState samp, in float3 p , in float3 n) {

    n = max((abs(n) - 0.2) * 7. , 0.001); // max ( abs ( n ) , 0.001 ) , etc. 
    n /= (n.x + n.y + n.z);

     return (SAMPLE_TEXTURE2D(tex , samp, p.yz) * n.x + 
         SAMPLE_TEXTURE2D(tex , samp, p.zx) * n.y + 
         SAMPLE_TEXTURE2D(tex , samp, p.xy) * n.z).xyz;
 }

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations. 
// See Xyptonjtroz - Very cool. Anyway , it's not really being used to its full potential here. 
float3 tri(in float3 x) { return abs(x - floor(x) - .5); } // Triangle function. 

 // The function used to perturb the walls of the cavern: There are infinite possibities , but this one is 
 // just a cheap...ish routine - based on the triangle function - to give a subtle jaggedness. Not very fancy , 
 // but it does a surprizingly good job at laying the foundations for a sharpish rock face. Obviously , more 
 // layers would be more convincing. However , this is a GPU - draining distance function , so the finer details 
 // are bump mapped. 
float surfFunc(in float3 p) {

     return dot(tri(p * 0.5 + tri(p * 0.25).yzx) , float3 (0.666 , 0.666 , 0.666));
 }


// The path is a 2D sinusoid that varies over time , depending upon the frequencies , and amplitudes. 
float2 path(in float z) { float s = sin(z / 24.) * cos(z / 12.); return float2 (s * 12. , 0.); }

// Standard tunnel distance function with some perturbation thrown into the mix. A floor has been 
// worked in also. A tunnel is just a tube with a smoothly shifting center as you traverse lengthwise. 
// The walls of the tube are perturbed by a pretty cheap 3D surface function. 
float map(float3 p) {

    float sf = surfFunc(p - float3 (0 , cos(p.z / 3.) * .15 , 0));
    // Square tunnel. 
    // For a square tunnel , use the Chebyshev ( ? ) distance: max ( abs ( tun.x ) , abs ( tun.y ) ) 
   float2 tun = abs(p.xy - path(p.z)) * float2 (0.5 , 0.7071);
   float n = 1. - max(tun.x , tun.y) + (0.5 - sf);
   return min(n , p.y + FH);

   /*
       // Round tunnel.
       // For a round tunnel , use the Euclidean distance: length ( tun.y )
      float2 tun = ( p.xy - path ( p.z ) ) * float2 ( 0.5 , 0.7071 ) ;
      float n = 1. - length ( tun ) + ( 0.5 - sf ) ;
      return min ( n , p.y + FH ) ;
   */

   /*
       // Rounded square tunnel using Minkowski distance: pow ( pow ( abs ( tun.x ) , n ) , pow ( abs ( tun.y ) , n ) , 1 / n )
      float2 tun = abs ( p.xy - path ( p.z ) ) * float2 ( 0.5 , 0.7071 ) ;
      tun = pow ( tun , float2 ( 4. ) ) ;
      float n = 1. - pow ( tun.x + tun.y , 1.0 / 4. ) + ( 0.5 - sf ) ;
      return min ( n , p.y + FH ) ;
   */

   }

// Texture bump mapping. Four tri - planar lookups , or 12 SAMPLE_TEXTURE2D lookups in total. 
float3 doBumpMap(Texture2D tex, SamplerState samp, in float3 p , in float3 nor , float bumpfactor) {

    static const float eps = 0.001;
    float ref = getGrey(tex3D(tex , samp, p , nor));
    float3 grad = float3 (getGrey(tex3D(tex ,samp, float3 (p.x - eps , p.y , p.z) , nor)) - ref ,
                      getGrey(tex3D(tex ,samp, float3 (p.x , p.y - eps , p.z) , nor)) - ref ,
                      getGrey(tex3D(tex ,samp, float3 (p.x , p.y , p.z - eps) , nor)) - ref) / eps;

    grad -= nor * dot(nor , grad);

    return normalize(nor + grad * bumpfactor);

 }

// Surface normal. 
float3 getNormal(in float3 p) {

     static const float eps = 0.001;
     return normalize(float3 (
          map(float3 (p.x + eps , p.y , p.z)) - map(float3 (p.x - eps , p.y , p.z)) ,
          map(float3 (p.x , p.y + eps , p.z)) - map(float3 (p.x , p.y - eps , p.z)) ,
          map(float3 (p.x , p.y , p.z + eps)) - map(float3 (p.x , p.y , p.z - eps))
      ));

 }

// Based on original by IQ. 
float calculateAO(float3 p , float3 n) {

    static const float AO_SAMPLES = 5.0;
    float r = 0.0 , w = 1.0 , d;

    for (float i = 1.0; i < AO_SAMPLES + 1.1; i++) {
        d = i / AO_SAMPLES;
        r += w * (d - map(p + n * d));
        w *= 0.5;
     }

    return 1.0 - clamp(r , 0.0 , 1.0);
 }

// Cool curve function , by Shadertoy user , Nimitz. 
// 
// I wonder if it relates to the discrete finite difference approximation to the 
// continuous Laplace differential operator? Either way , it gives you a scalar 
// curvature value for an object's signed distance function , which is pretty handy. 
// 
// From an intuitive sense , the function returns a weighted difference between a surface 
// value and some surrounding values. Almost common sense... almost. : ) If anyone 
// could provide links to some useful articles on the function , I'd be greatful. 
// 
// Original usage ( I think? ) - Cheap curvature: https: // www.shadertoy.com / view / Xts3WM 
// Other usage: Xyptonjtroz: https: // www.shadertoy.com / view / 4ts3z2 
float curve(in float3 p , in float w) {

    float2 e = float2 (-1. , 1.) * w;

    float t1 = map(p + e.yxx) , t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx) , t4 = map(p + e.yyy);

    return 0.125 / (w * w) * (t1 + t2 + t3 + t4 - 4. * map(p));
 }

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

 // Screen coordinates. 
float2 uv = (fragCoord - _ScreenParams.xy * 0.5) / _ScreenParams.y;

// Camera Setup. 
float3 camPos = float3 (0.0 , 0.0 , _Time.y * 5.); // Camera position , doubling as the ray origin. 
float3 lookAt = camPos + float3 (0.0 , 0.1 , 0.5); // "Look At" position. 

// Light positioning. One is a little behind the camera , and the other is further down the tunnel. 
 float3 light_pos = camPos + float3 (0.0 , 0.125 , -0.125); // Put it a bit in front of the camera. 
float3 light_pos2 = camPos + float3 (0.0 , 0.0 , 6.0); // Put it a bit in front of the camera. 

 // Using the Z - value to perturb the XY - plane. 
 // Sending the camera , "look at , " and two light vectors down the tunnel. The "path" function is 
 // synchronized with the distance function. 
lookAt.xy += path(lookAt.z);
camPos.xy += path(camPos.z);
light_pos.xy += path(light_pos.z);
light_pos2.xy += path(light_pos2.z);

// Using the above to produce the unit ray - direction vector. 
float FOV = PI / 3.; // FOV - Field of view. 
float3 forward = normalize(lookAt - camPos);
float3 right = normalize(float3 (forward.z , 0. , -forward.x));
float3 up = cross(forward , right);

// rd - Ray direction. 
float3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);

// Swiveling the camera from left to right when turning corners. 
rd.xy = mul(rot2(path(lookAt.z).x / 32.) , rd.xy);

// Standard ray marching routine. I find that some system setups don't like anything other than 
// a "break" statement ( by itself ) to exit. 
float t = 0.0 , dt;
for (int i = 0; i < 128; i++) {
     dt = map(camPos + rd * t);
     if (dt < 0.005 || t > 150.) { break; }
     t += dt * 0.75;
 }

// The final scene color. Initated to black. 
float3 sceneCol = float3 (0. , 0. , 0.);

// The ray has effectively hit the surface , so light it up. 
if (dt < 0.005) {

    // Surface position and surface normal. 
   float3 sp = t * rd + camPos;
   float3 sn = getNormal(sp);

   // Texture scale factor. 
  static const float tSize0 = 1. / 1.;
  static const float tSize1 = 1. / 4.;

  // Texture - based bump mapping. 
 if (sp.y < -(FH - 0.005)) sn = doBumpMap(_Channel1 , sampler_Channel1 , sp * tSize1 , sn , 0.025); // Floor. 
 else sn = doBumpMap(_Channel0 , sampler_Channel0 , sp * tSize0 , sn , 0.025); // Walls. 

  // Ambient occlusion. 
 float ao = calculateAO(sp , sn);

 // Light direction vectors. 
float3 ld = light_pos - sp;
float3 ld2 = light_pos2 - sp;

// Distance from respective lights to the surface point. 
float distlpsp = max(length(ld) , 0.001);
float distlpsp2 = max(length(ld2) , 0.001);

// Normalize the light direction vectors. 
ld /= distlpsp;
ld2 /= distlpsp2;

// Light attenuation , based on the distances above. In case it isn't obvious , this 
// is a cheap fudge to save a few extra lines. Normally , the individual light 
// attenuations would be handled separately... No one will notice , nor care. : ) 
float atten = min(1. / (distlpsp)+1. / (distlpsp2) , 1.);

// Ambient light. 
float ambience = 0.25;

// Diffuse lighting. 
float diff = max(dot(sn , ld) , 0.0);
float diff2 = max(dot(sn , ld2) , 0.0);

// Specular lighting. 
float spec = pow(max(dot(reflect(-ld , sn) , -rd) , 0.0) , 8.);
float spec2 = pow(max(dot(reflect(-ld2 , sn) , -rd) , 0.0) , 8.);

// Curvature. 
float crv = clamp(curve(sp , 0.125) * 0.5 + 0.5 , .0 , 1.);

// Fresnel term. Good for giving a surface a bit of a reflective glow. 
float fre = pow(clamp(dot(sn , rd) + 1. , .0 , 1.) , 1.);

// Obtaining the texel color. If the surface pointExtended is above the floor 
// height use the wall SAMPLE_TEXTURE2D , otherwise use the floor texture. 
float3 texCol;
if (sp.y < -(FH - 0.005)) texCol = tex3D(_Channel1 , sampler_Channel1 , sp * tSize1 , sn); // Floor. 
  else texCol = tex3D(_Channel0 , sampler_Channel0 , sp * tSize0 , sn); // Walls. 

 // Shadertoy doesn't appear to have anisotropic filtering turned on... although , 
 // I could be wrong. Texture - bumped objects don't appear to look as crisp. Anyway , 
 // this is just a very lame , and not particularly well though out , way to sparkle 
 // up the blurry bits. It's not really that necessary. 
 // float3 aniso = ( 0.5 - hash33 ( sp ) ) * fre * 0.35 ; 
  // texCol = clamp ( texCol + aniso , 0. , 1. ) ; 

  // Darkening the crevices. Otherwise known as cheap , scientifically - incorrect shadowing. 
 float shading = crv * 0.5 + 0.5;

 // Combining the above terms to produce the final color. It was based more on acheiving a 
// certain aesthetic than science. 
// 
// Glow. 
sceneCol = getGrey(texCol) * ((diff + diff2) * 0.75 + ambience * 0.25) + (spec + spec2) * texCol * 2. + fre * crv * texCol.zyx * 2.;
// 
// Other combinations: 
// 
// Shiny. 
// sceneCol = texCol * ( ( diff + diff2 ) * float3 ( 1.0 , 0.95 , 0.9 ) + ambience + fre * fre * texCol ) + ( spec + spec2 ) ; 
// Abstract pen and ink? 
// float c = getGrey ( texCol ) * ( ( diff + diff2 ) * 1.75 + ambience + fre * fre ) + ( spec + spec2 ) * 0.75 ; 
// sceneCol = float3 ( c * c * c , c * c , c ) ; 


// Shading. 
sceneCol *= atten * shading * ao;

// Drawing the lines on the walls. Comment this out and change the first SAMPLE_TEXTURE2D to 
// granite for a granite corridor effect. 
sceneCol *= clamp(1. - abs(curve(sp , 0.0125)) , .0 , 1.);


}

// Edit: No gamma correction -- I can't remember whether it was a style choice , or whether I forgot at 
// the time , but you should always gamma correct. In this case , just think of it as rough gamma correction 
// on a postprocessed color: sceneCol = sqrt ( sceneCol * sceneCol ) ; :D 
fragColor = float4 (clamp(sceneCol , 0. , 1.) , 1.0);
fragColor.xyz = makeDarker(fragColor.xyz);
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