Shader "UmutBebek/URP/ShaderToy/Physically Based Shading 4sSfzK MainImage"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", Cube) = "" {}
        _Channel2("Channel2 (RGB)", Cube) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)

        MATH_PI("MATH_PI", float) = 3.14159
MENU_SURFACE("MENU_SURFACE", float) = 0.
MENU_METAL("MENU_METAL", float) = 1.
MENU_DIELECTRIC("MENU_DIELECTRIC", float) = 2.
MENU_ROUGHNESS("MENU_ROUGHNESS", float) = 3.
MENU_BASE_COLOR("MENU_BASE_COLOR", float) = 4.
MENU_LIGHTING("MENU_LIGHTING", float) = 5.
MENU_DIFFUSE("MENU_DIFFUSE", float) = 6.
MENU_SPECULAR("MENU_SPECULAR", float) = 7.
MENU_DISTR("MENU_DISTR", float) = 8.
MENU_FRESNEL("MENU_FRESNEL", float) = 9.
MENU_GEOMETRY("MENU_GEOMETRY", float) = 10.

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
    
    TEXTURECUBE(_Channel1);
    SAMPLER(sampler_Channel1);

    TEXTURECUBE(_Channel2);
    SAMPLER(sampler_Channel2);

    float4 _Channel3_ST;
    TEXTURE2D(_Channel3);       SAMPLER(sampler_Channel3);

    float4 iMouse;
    float MATH_PI;
float MENU_SURFACE;
float MENU_METAL;
float MENU_DIELECTRIC;
float MENU_ROUGHNESS;
float MENU_BASE_COLOR;
float MENU_LIGHTING;
float MENU_DIFFUSE;
float MENU_SPECULAR;
float MENU_DISTR;
float MENU_FRESNEL;
float MENU_GEOMETRY;


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










                   const float3 BASE_COLORS[6] = 
                   {
                       float3(0.74, 0.74, 0.74),
                       float3(0.51, 0.72, 0.81),
                       float3(0.66, .85, .42),
                       float3(0.87, 0.53, 0.66),
                       float3(0.51, 0.46, 0.74),
                       float3(0.78, 0.71, 0.45)
                   };



struct AppState
 {
     float menuId;
     float metal;
     float roughness;
     float baseColor;
     float focus;
     float focusObjRot;
     float objRot;
 };

float4 LoadValue(int x , int y)
 {
     return pointSampleTex2D(_Channel0 , sampler_Channel0 , int2 (x , y) );
 }

void LoadState(out AppState s)
 {
     float4 data;

     data = LoadValue(0 , 0);
     s.menuId = data.x;
     s.metal = data.y;
     s.roughness = data.z;
     s.baseColor = data.w;

     data = LoadValue(1 , 0);
     s.focus = data.x;
     s.focusObjRot = data.y;
     s.objRot = data.z;
 }

void StoreValue(float2 re , float4 va , inout float4 fragColor , float2 fragCoord)
 {
     fragCoord = floor(fragCoord);
     fragColor = (fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor;
 }

float saturate(float x)
 {
     return clamp(x , 0. , 1.);
 }

float3 saturate(float3 x)
 {
     return clamp(x , float3 (0. , 0. , 0.) , float3 (1. , 1. , 1.));
 }

float Smooth(float x)
 {
     return smoothstep(0. , 1. , saturate(x));
 }

void Repeat(inout float p , float w)
 {
     p = mod(p , w) - 0.5f * w;
 }

float Circle(float2 p , float r)
 {
     return (length(p / r) - 1.) * r;
 }

float Rectangle(float2 p , float2 b)
 {
     float2 d = abs(p) - b;
     return min(max(d.x , d.y) , 0.) + length(max(d , 0.));
 }

void Rotate(inout float2 p , float a)
 {
     p = cos(a) * p + sin(a) * float2 (p.y , -p.x);
 }

float Capsule(float2 p , float r , float c)
 {
     return lerp(length(p.x) - r , length(float2 (p.x , abs(p.y) - c)) - r , step(c , abs(p.y)));
 }

float Arrow(float2 p , float a , float l , float w)
 {
     Rotate(p , a);
     p.y += l;

     float body = Capsule(p , w , l);
     p.y -= w;

     float tip = p.y + l;

     p.y += l + w;
     Rotate(p , +2.);
     tip = max(tip , p.y - 2. * w);
     Rotate(p , -4.);
     tip = max(tip , p.y - 2. * w);

     return min(body , tip);
 }

float TextSDF(float2 p , float glyph)
 {
     p = abs(p.x - .5) > .5 || abs(p.y - .5) > .5 ? float2 (0. , 0.) : p;
     return 2. * (SAMPLE_TEXTURE2D(_Channel3 , sampler_Channel3 , p / 16. + frac(float2 (glyph , 15. - floor(glyph / 16.)) / 16.)).w - 127. / 255.);
 }

void Diagram(inout float3 color , float2 p , in AppState s)
 {
     float3 surfColor = float3 (0.9 , 0.84 , 0.8);
     float3 lightColor = float3 (0.88 , 0.65 , 0.2);
     float3 baseColor = BASE_COLORS[int(s.baseColor)];
     float3 diffuseColor = s.metal == 1. ? float3 (0. , 0. , 0.) : baseColor;
     float3 specularColor = s.metal == 1. ? baseColor : float3 (0.7 , 0.7 , 0.7);

     p -= float2 (84. , 44.);

     float2 t = p - float2 (18. , 4.);
     float r = Rectangle(t , float2 (52. , 12.));
     color = lerp(color , surfColor , Smooth(-r * 2.));

     t.y += s.roughness * sin(t.x);
     r = Rectangle(t - float2 (0. , 11.) , float2 (52. , 1.2));
     color = lerp(color , surfColor * 0.6 , Smooth(-r * 2.));


     // refraction 
    r = 1e4;
    t = p - float2 (18. , 15.);
    for (int i = 0; i < 3; ++i)
     {
         r = min(r , Arrow(t - float2 (-15. + float(i) * 15. , 0.) , -0.4 , 7. , .7));
     }
    r = min(r , Arrow(t - float2 (9. , -15.) , 2. , 4. , .7));
    r = min(r , Arrow(t - float2 (17. , -10.) , 3.8 , 18. , .7));
    r = min(r , Arrow(t - float2 (-6. , -14.) , 0.9 , 3. , .7));
    r = min(r , Arrow(t - float2 (1. , -19.) , 2.9 , 18. , .7));
    r = min(r , Arrow(t - float2 (-22. , -15.) , 4.5 , 2. , .7));
    r = min(r , Arrow(t - float2 (-28. , -14.) , 2.6 , 14. , .7));
    if (s.metal != 1. && s.menuId < MENU_SPECULAR)
     {
         color = lerp(color , diffuseColor , Smooth(-r * 2.));
     }

    // reflection 
   r = 1e4;
   t = p - float2 (18. , 15.);
   for (int i = 0; i < 3; ++i)
    {
        float off = s.roughness * (1.5 - float(i)) * .45;
        r = min(r , Arrow(t - float2 (-15. + float(i) * 15. , 2.) , -0.5 * MATH_PI - 0.9 + off , 12. , 1.));
    }
   if (s.menuId != MENU_DIFFUSE)
    {
        color = lerp(color , specularColor , Smooth(-r * 2.));
    }

   // light in 
  r = 1e4;
  t = p - float2 (18. , 15.);
  for (int i = 0; i < 3; ++i)
   {
       r = min(r , Arrow(t - float2 (12. + float(i) * 15. , 22.) , -0.9 , 15. , 1.));
   }
  color = lerp(color , lightColor , Smooth(-r * 2.));
}

float RaySphere(float3 rayOrigin , float3 rayDir , float3 spherePos , float sphereRadius)
 {
     float3 oc = rayOrigin - spherePos;

     float b = dot(oc , rayDir);
     float c = dot(oc , oc) - sphereRadius * sphereRadius;
     float h = b * b - c;

     float t;
     if (h < 0.0)
      {
          t = -1.0;
      }
     else
      {
          t = (-b - sqrt(h));
      }
     return t;
 }

float VisibilityTerm(float roughness , float ndotv , float ndotl)
 {
     float r2 = roughness * roughness;
     float gv = ndotl * sqrt(ndotv * (ndotv - ndotv * r2) + r2);
     float gl = ndotv * sqrt(ndotl * (ndotl - ndotl * r2) + r2);
     return 0.5 / max(gv + gl , 0.00001);
 }

float DistributionTerm(float roughness , float ndoth)
 {
     float r2 = roughness * roughness;
     float d = (ndoth * r2 - ndoth) * ndoth + 1.0;
     return r2 / (d * d * MATH_PI);
 }

float3 FresnelTerm(float3 specularColor , float vdoth)
 {
     float3 fresnel = specularColor + (1. - specularColor) * pow((1. - vdoth) , 5.);
     return fresnel;
 }

float Cylinder(float3 p , float r , float height)
 {
     float d = length(p.xz) - r;
     d = max(d , abs(p.y) - height);
     return d;
 }

float Substract(float a , float b)
 {
     return max(a , -b);
 }

float SubstractRound(float a , float b , float r)
 {
     float2 u = max(float2 (r + a , r - b) , float2 (0.0 , 0.0));
     return min(-r , max(a , -b)) + length(u);
 }

float Union(float a , float b)
 {
     return min(a , b);
 }

float Box(float3 p , float3 b)
 {
     float3 d = abs(p) - b;
     return min(max(d.x , max(d.y , d.z)) , 0.0) + length(max(d , 0.0));
 }

float Sphere(float3 p , float s)
 {
     return length(p) - s;
 }

float Torus(float3 p , float sr , float lr)
 {
     return length(float2 (length(p.xz) - lr , p.y)) - sr;
 }

float Disc(float3 p , float r , float t)
 {
     float l = length(p.xz) - r;
     return l < 0. ? abs(p.y) - t : length(float2 (p.y , l)) - t;
 }

float UnionRound(float a , float b , float k)
 {
     float h = clamp(0.5 + 0.5 * (b - a) / k , 0.0 , 1.0);
     return lerp(b , a , h) - k * h * (1.0 - h);
 }

float Scene(float3 p , float3x3 localToWorld)
 {
     p = mul(p , localToWorld);

     // ring 
    float3 t = p;
    t.y -= -.7;
    float r = Substract(Disc(t , 0.9 , .1) , Cylinder(t , .7 , 2.));
    float3 t2 = t - float3 (0. , 0. , 1.0);
    Rotate(t2.xz , 0.25 * MATH_PI);
    r = Substract(r , Box(t2 , float3 (.5 , .5 , .5)));
    r = Union(r , Disc(t + float3 (0. , 0.05 , 0.) , 0.85 , .05));

    t = p;
    Rotate(t.yz , -.3);

    // body 
   float b = Sphere(t , .8);
   b = Substract(b , Sphere(t - float3 (0. , 0. , .5) , .5));
   b = Substract(b , Sphere(t - float3 (0. , 0. , -.7) , .3));
   b = Substract(b , Box(t , float3 (2. , .03 , 2.)));
   b = Union(b , Sphere(t , .7));

   float ret = Union(r , b);
   return ret;
}

float CastRay(in float3 ro , in float3 rd , float3x3 localToWorld)
 {
     const float maxd = 5.0;

     float h = 0.5;
     float t = 0.0;

     for (int i = 0; i < 50; ++i)
      {
          if (h < 0.001 || t > maxd)
           {
               break;
           }

          h = Scene(ro + rd * t , localToWorld);
          t += h;
      }

     if (t > maxd)
      {
          t = -1.0;
      }

     return t;
 }

float3 SceneNormal(in float3 pos , float3x3 localToWorld)
 {
     float3 eps = float3 (0.001 , 0.0 , 0.0);
     float3 nor = float3 (
          Scene(pos + eps.xyy , localToWorld) - Scene(pos - eps.xyy , localToWorld) ,
          Scene(pos + eps.yxy , localToWorld) - Scene(pos - eps.yxy , localToWorld) ,
          Scene(pos + eps.yyx , localToWorld) - Scene(pos - eps.yyx , localToWorld));
     return normalize(nor);
 }

float SceneAO(float3 p , float3 n , float3x3 localToWorld)
 {
     float ao = 0.0;
     float s = 1.0;
     for (int i = 0; i < 6; ++i)
      {
          float off = 0.001 + 0.2 * float(i) / 5.;
          float t = Scene(n * off + p , localToWorld);
          ao += (off - t) * s;
          s *= 0.4;
      }

     return Smooth(1.0 - 12.0 * ao);
 }

// St. Peter's Basilica SH 
// https: // www.shadertoy.com / view / lt2GRD 
struct SHCoefficients
 {
     float3 l00 , l1m1 , l10 , l11 , l2m2 , l2m1 , l20 , l21 , l22;
 };

SHCoefficients SH_STPETER;

float3 SHIrradiance(float3 nrm)
 {
     const SHCoefficients c = SH_STPETER;
     const float c1 = 0.429043;
     const float c2 = 0.511664;
     const float c3 = 0.743125;
     const float c4 = 0.886227;
     const float c5 = 0.247708;
     return (
          c1 * c.l22 * (nrm.x * nrm.x - nrm.y * nrm.y) +
          c3 * c.l20 * nrm.z * nrm.z +
          c4 * c.l00 -
          c5 * c.l20 +
          2.0 * c1 * c.l2m2 * nrm.x * nrm.y +
          2.0 * c1 * c.l21 * nrm.x * nrm.z +
          2.0 * c1 * c.l2m1 * nrm.y * nrm.z +
          2.0 * c2 * c.l11 * nrm.x +
          2.0 * c2 * c.l1m1 * nrm.y +
          2.0 * c2 * c.l10 * nrm.z
           );
 }

// https: // www.unrealengine.com / en - US / blog / physically - based - shading - on - mobile 
float3 EnvBRDFApprox(float3 specularColor , float roughness , float ndotv)
 {
     const float4 c0 = float4 (-1 , -0.0275 , -0.572 , 0.022);
     const float4 c1 = float4 (1 , 0.0425 , 1.04 , -0.04);
     float4 r = roughness * c0 + c1;
     float a004 = min(r.x * r.x , exp2(-9.28 * ndotv)) * r.x + r.y;
     float2 AB = float2 (-1.04 , 1.04) * a004 + r.zw;
     return specularColor * AB.x + AB.y;
 }

float3 EnvRemap(float3 c)
 {
     return pow(2. * c , float3 (2.2, 2.2, 2.2));
 }

void DrawScene(inout float3 color , float2 p , in AppState s)
 {
     float3 lightColor = float3 (2., 2., 2.);
     float3 lightDir = normalize(float3 (.7 , .9 , -.2));

     float3 baseColor = pow(BASE_COLORS[int(s.baseColor)] , float3 (2.2, 2.2, 2.2));
     float3 diffuseColor = s.metal == 1. ? float3 (0. , 0. , 0.) : baseColor;
     float3 specularColor = s.metal == 1. ? baseColor : float3 (0.02 , 0.02 , 0.02);
     float roughnessE = s.roughness * s.roughness;
     float roughnessL = max(.01 , roughnessE);

     float a = -_Time.y * .5;
     float3x3 rot = float3x3 (
          float3 (cos(a) , 0. , -sin(a)) ,
          float3 (0. , 1. , 0.) ,
          float3 (sin(a) , 0. , cos(a))
      );

     p -= float2 (-20. , 10.);
     p *= .011;

     float yaw = 2.7 - s.objRot;
     float3x3 rotZ = float3x3 (
          float3 (cos(yaw) , 0.0 , -sin(yaw)) ,
          float3 (0.0 , 1.0 , 0.0) ,
          float3 (sin(yaw) , 0.0 , cos(yaw))
      );

     float phi = -0.1;
     float3x3 rotY = float3x3 (
          float3 (1.0 , 0.0 , 0.0) ,
          float3 (0.0 , cos(phi) , sin(phi)) ,
          float3 (0.0 , -sin(phi) , cos(phi))
      );

     float3x3 localToWorld = rotY * rotZ;

     float3 rayOrigin = float3 (0.0 , .5 , -3.5);
     float3 rayDir = normalize(float3 (p.x , p.y , 2.0));
     float t = CastRay(rayOrigin , rayDir , localToWorld);
     if (t > 0.0)
      {
          float3 pos = rayOrigin + t * rayDir;
          float3 normal = SceneNormal(pos , localToWorld);
          float3 viewDir = -rayDir;
          float3 refl = reflect(rayDir , normal);

          float3 diffuse = float3 (0. , 0. , 0.);
          float3 specular = float3 (0. , 0. , 0.);

          float3 halfVec = normalize(viewDir + lightDir);
          float vdoth = saturate(dot(viewDir , halfVec));
          float ndoth = saturate(dot(normal , halfVec));
          float ndotv = saturate(dot(normal , viewDir));
          float ndotl = saturate(dot(normal , lightDir));
          float3 envSpecularColor = EnvBRDFApprox(specularColor , roughnessE , ndotv);

          float3 env1 = EnvRemap(SAMPLE_TEXTURE2D(_Channel2 , sampler_Channel2 , refl).xyz);
          float3 env2 = EnvRemap(SAMPLE_TEXTURE2D(_Channel1 , sampler_Channel1 , refl).xyz);
          float3 env3 = EnvRemap(SHIrradiance(refl));
          float3 env = lerp(env1 , env2 , saturate(roughnessE * 4.));
          env = lerp(env , env3 , saturate((roughnessE - 0.25) / 0.75));

          diffuse += diffuseColor * EnvRemap(SHIrradiance(normal));
          specular += envSpecularColor * env;

          diffuse += diffuseColor * lightColor * saturate(dot(normal , lightDir));

          float3 lightF = FresnelTerm(specularColor , vdoth);
          float lightD = DistributionTerm(roughnessL , ndoth);
          float lightV = VisibilityTerm(roughnessL , ndotv , ndotl);
          specular += lightColor * lightF * (lightD * lightV * MATH_PI * ndotl);

          float ao = SceneAO(pos , normal , localToWorld);
          diffuse *= ao;
          specular *= saturate(pow(ndotv + ao , roughnessE) - 1. + ao);

          color = diffuse + specular;
          if (s.menuId == MENU_DIFFUSE)
           {
               color = diffuse;
           }
          if (s.menuId == MENU_SPECULAR)
           {
               color = specular;
           }
          if (s.menuId == MENU_DISTR)
           {
               color = float3 (lightD, lightD, lightD);
           }
          if (s.menuId == MENU_FRESNEL)
           {
               color = envSpecularColor;
           }
          if (s.menuId == MENU_GEOMETRY)
           {
               color = float3 (lightV, lightV, lightV) * (4.0f * ndotv * ndotl);
           }
          color = pow(color * .4 , float3 (1. / 2.2, 1. / 2.2, 1. / 2.2));
      }
     else
      {
         // shadow 
        float planeT = -(rayOrigin.y + 1.2) / rayDir.y;
        if (planeT > 0.0)
         {
             float3 p = rayOrigin + planeT * rayDir;

             float radius = .7;
             color *= 0.7 + 0.3 * smoothstep(0.0 , 1.0 , saturate(length(p + float3 (0.0 , 1.0 , -0.5)) - radius));
         }
    }
}

void InfoText(inout float3 color , float2 p , in AppState s)
 {
     p -= float2 (52 , 12);
     float2 q = p;
     if (s.menuId == MENU_METAL || s.menuId == MENU_BASE_COLOR || s.menuId == MENU_DISTR)
      {
          p.y -= 6.;
      }
     if (s.menuId == MENU_DIELECTRIC || s.menuId == MENU_FRESNEL)
      {
          p.y += 6.;
      }
     if (s.menuId == MENU_SPECULAR)
      {
          p.y += 6. * 6.;

          if (p.x < 21. && p.y >= 27. && p.y < 30.)
           {
               p.y = 0.;
           }
          else if (s.menuId == MENU_SPECULAR && p.y > 20. && p.y < 28. && p.x < 21.)
           {
               p.y += 3.;
           }
      }

     float2 scale = float2 (3. , 6.);
     float2 t = floor(p / scale);

     uint v = 0u;
     if (s.menuId == MENU_SURFACE)
      {
          v = t.y == 2. ? (t.x < 4. ? 1702127169u : (t.x < 8. ? 1768431730u : (t.x < 12. ? 1852404852u : (t.x < 16. ? 1752440935u : (t.x < 20. ? 1970479205u : (t.x < 24. ? 1667327602u : (t.x < 28. ? 1768693861u : 7628903u))))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1937334642u : (t.x < 8. ? 1717924384u : (t.x < 12. ? 1952671084u : (t.x < 16. ? 1684955424u : (t.x < 20. ? 1717924384u : (t.x < 24. ? 1952670066u : (t.x < 28. ? 32u : 0u))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1868784481u : (t.x < 8. ? 1852400754u : (t.x < 12. ? 1869881447u : (t.x < 16. ? 1701729056u : (t.x < 20. ? 1931963500u : (t.x < 24. ? 2002873376u : 0u)))))) : v;
          v = t.x >= 0. && t.x < 32. ? v : 0u;
      }
     if (s.menuId == MENU_METAL)
      {
          v = t.y == 1. ? (t.x < 4. ? 1635018061u : (t.x < 8. ? 1852776556u : (t.x < 12. ? 1914730860u : (t.x < 16. ? 1701602917u : (t.x < 20. ? 544437347u : (t.x < 24. ? 1751607660u : (t.x < 28. ? 1914729332u : (t.x < 32. ? 544438625u : 45u)))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 544432488u : (t.x < 8. ? 2037149295u : (t.x < 12. ? 1701868320u : (t.x < 16. ? 1634497891u : (t.x < 20. ? 114u : 0u))))) : v;
          v = t.x >= 0. && t.x < 36. ? v : 0u;
      }
     if (s.menuId == MENU_DIELECTRIC)
      {
          v = t.y == 3. ? (t.x < 4. ? 1818585412u : (t.x < 8. ? 1920230245u : (t.x < 12. ? 1914725225u : (t.x < 16. ? 1701602917u : (t.x < 20. ? 544437347u : (t.x < 24. ? 1701868328u : (t.x < 28. ? 1634497891u : (t.x < 32. ? 2107762u : 0u)))))))) : v;
          v = t.y == 2. ? (t.x < 4. ? 543452769u : (t.x < 8. ? 1935832435u : (t.x < 12. ? 1634103925u : (t.x < 16. ? 1931502947u : (t.x < 20. ? 1953784163u : (t.x < 24. ? 544436837u : (t.x < 28. ? 1718182952u : (t.x < 32. ? 1702065510u : 41u)))))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1751607660u : (t.x < 8. ? 1634869364u : (t.x < 12. ? 539915129u : (t.x < 16. ? 1667592275u : (t.x < 20. ? 1918987381u : (t.x < 24. ? 544434464u : (t.x < 28. ? 1936617315u : (t.x < 32. ? 1953390964u : 0u)))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 808333438u : (t.x < 8. ? 774909234u : (t.x < 12. ? 13360u : 0u))) : v;
          v = t.x >= 0. && t.x < 36. ? v : 0u;
      }
     if (s.menuId == MENU_ROUGHNESS)
      {
          v = t.y == 2. ? (t.x < 4. ? 1735749458u : (t.x < 8. ? 544367976u : (t.x < 12. ? 1718777203u : (t.x < 16. ? 1936024417u : (t.x < 20. ? 1830825248u : (t.x < 24. ? 543519343u : (t.x < 28. ? 1952539507u : (t.x < 32. ? 1701995892u : 100u)))))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1818649970u : (t.x < 8. ? 1702126437u : (t.x < 12. ? 1768693860u : (t.x < 16. ? 544499815u : (t.x < 20. ? 1937334642u : (t.x < 24. ? 1851858988u : (t.x < 28. ? 1752440932u : (t.x < 32. ? 2126709u : 0u)))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1920298082u : (t.x < 8. ? 1919248754u : (t.x < 12. ? 1717924384u : (t.x < 16. ? 1952671084u : (t.x < 20. ? 1936617321u : 0u))))) : v;
          v = t.x >= 0. && t.x < 36. ? v : 0u;
      }
     if (s.menuId == MENU_BASE_COLOR)
      {
          v = t.y == 1. ? (t.x < 4. ? 544370502u : (t.x < 8. ? 1635018093u : (t.x < 12. ? 1679848300u : (t.x < 16. ? 1852401253u : (t.x < 20. ? 1931506533u : (t.x < 24. ? 1969448304u : (t.x < 28. ? 544366956u : (t.x < 32. ? 1869377379u : 114u)))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 544370502u : (t.x < 8. ? 1818585444u : (t.x < 12. ? 1920230245u : (t.x < 16. ? 544433001u : (t.x < 20. ? 1768169517u : (t.x < 24. ? 1937073766u : (t.x < 28. ? 1868767333u : (t.x < 32. ? 7499628u : 0u)))))))) : v;
          v = t.x >= 0. && t.x < 36. ? v : 0u;
      }
     if (s.menuId == MENU_LIGHTING)
      {
          v = t.y == 2. ? (t.x < 4. ? 1751607628u : (t.x < 8. ? 1735289204u : (t.x < 12. ? 544434464u : (t.x < 16. ? 1869770849u : (t.x < 20. ? 1634560376u : (t.x < 24. ? 543450484u : 2128226u)))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1634755955u : (t.x < 8. ? 1769234802u : (t.x < 12. ? 1679845230u : (t.x < 16. ? 1969645161u : (t.x < 20. ? 1629513075u : (t.x < 24. ? 2122862u : 0u)))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1667592307u : (t.x < 8. ? 1918987381u : (t.x < 12. ? 1836016416u : (t.x < 16. ? 1701736304u : (t.x < 20. ? 544437358u : 0u))))) : v;
          v = t.x >= 0. && t.x < 28. ? v : 0u;
      }
     if (s.menuId == MENU_DIFFUSE)
      {
          v = t.y == 2. ? (t.x < 4. ? 1818324307u : (t.x < 8. ? 1668489324u : (t.x < 12. ? 543517793u : (t.x < 16. ? 1935832435u : (t.x < 20. ? 1634103925u : (t.x < 24. ? 1931502947u : (t.x < 28. ? 1953784163u : (t.x < 32. ? 1852404325u : 8295u)))))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1635087189u : (t.x < 8. ? 981036140u : (t.x < 12. ? 1835093024u : (t.x < 16. ? 1953654114u : (t.x < 20. ? 1146241568u : (t.x < 24. ? 1713388102u : (t.x < 28. ? 824196384u : (t.x < 32. ? 543780911u : 0u)))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1702257960u : (t.x < 8. ? 1914730866u : (t.x < 12. ? 1696627041u : (t.x < 16. ? 1937009016u : (t.x < 20. ? 544106784u : (t.x < 24. ? 1634869345u : (t.x < 28. ? 1679844462u : (t.x < 32. ? 2716265u : 0u)))))))) : v;
          v = t.x >= 0. && t.x < 36. ? v : 0u;
      }
     if (s.menuId == MENU_SPECULAR)
      {
          v = t.y == 8. ? (t.x < 4. ? 1818649938u : (t.x < 8. ? 1702126437u : (t.x < 12. ? 1768693860u : (t.x < 16. ? 779380839u : (t.x < 20. ? 1970492704u : (t.x < 24. ? 2037148769u : 8250u)))))) : v;
          v = t.y == 7. ? (t.x < 4. ? 1802465091u : (t.x < 8. ? 1919898669u : (t.x < 12. ? 1668178290u : (t.x < 16. ? 1998597221u : (t.x < 20. ? 1751345512u : (t.x < 24. ? 1685024032u : 7564389u)))))) : v;
          v = t.y == 6. ? (t.x < 4. ? 1919117677u : (t.x < 8. ? 1667327599u : (t.x < 12. ? 544437349u : (t.x < 16. ? 1919250472u : (t.x < 20. ? 1952671078u : (t.x < 24. ? 1919511840u : 544370546u)))))) : v;
          v = t.y == 5. ? (t.x < 4. ? 1734960488u : (t.x < 8. ? 1634563176u : (t.x < 12. ? 3811696u : 0u))) : v;
          v = t.y == 4. ? (t.x < 4. ? 745285734u : (t.x < 8. ? 1178413430u : (t.x < 12. ? 1747744296u : (t.x < 16. ? 1814578985u : (t.x < 20. ? 1747744300u : (t.x < 24. ? 1747469353u : 41u)))))) : v;
          v = t.y == 3. ? (t.x < 4. ? 538976288u : (t.x < 8. ? 538976288u : (t.x < 12. ? 1848128544u : (t.x < 16. ? 673803447u : (t.x < 20. ? 695646062u : 0u))))) : v;
          v = t.y == 2. ? (t.x < 4. ? 539828294u : (t.x < 8. ? 1936028230u : (t.x < 12. ? 7103854u : 0u))) : v;
          v = t.y == 1. ? (t.x < 4. ? 539828295u : (t.x < 8. ? 1836016967u : (t.x < 12. ? 2037544037u : 0u))) : v;
          v = t.y == 0. ? (t.x < 4. ? 539828292u : (t.x < 8. ? 1953720644u : (t.x < 12. ? 1969383794u : (t.x < 16. ? 1852795252u : 0u)))) : v;
          v = t.x >= 0. && t.x < 28. ? v : 0u;
      }
     if (s.menuId == MENU_DISTR)
      {
          v = t.y == 1. ? (t.x < 4. ? 1702109252u : (t.x < 8. ? 1679846770u : (t.x < 12. ? 1852401253u : (t.x < 16. ? 622883685u : (t.x < 20. ? 543584032u : (t.x < 24. ? 1919117677u : (t.x < 28. ? 1667327599u : 544437349u))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1818649970u : (t.x < 8. ? 1769235301u : (t.x < 12. ? 1814062958u : (t.x < 16. ? 1952999273u : (t.x < 20. ? 1919903264u : (t.x < 24. ? 1730175264u : (t.x < 28. ? 1852143209u : 1919509536u))))))) : v;
          v = t.x >= 0. && t.x < 32. ? v : 0u;
      }
     if (s.menuId == MENU_FRESNEL)
      {
          v = t.y == 3. ? (t.x < 4. ? 1702109254u : (t.x < 8. ? 1679846770u : (t.x < 12. ? 1852401253u : (t.x < 16. ? 1629516645u : (t.x < 20. ? 1853189997u : (t.x < 24. ? 1718558836u : 32u)))))) : v;
          v = t.y == 2. ? (t.x < 4. ? 1818649970u : (t.x < 8. ? 1702126437u : (t.x < 12. ? 1768693860u : (t.x < 16. ? 544499815u : (t.x < 20. ? 544370534u : (t.x < 24. ? 1768366177u : 544105846u)))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1935832435u : (t.x < 8. ? 1851880052u : (t.x < 12. ? 539911523u : (t.x < 16. ? 1629516873u : (t.x < 20. ? 1869770864u : (t.x < 24. ? 1701340001u : 3219571u)))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 544370534u : (t.x < 8. ? 2053206631u : (t.x < 12. ? 543649385u : (t.x < 16. ? 1818717793u : (t.x < 20. ? 29541u : 0u))))) : v;
          v = t.x >= 0. && t.x < 28. ? v : 0u;
      }
     if (s.menuId == MENU_GEOMETRY)
      {
          v = t.y == 2. ? (t.x < 4. ? 1702109255u : (t.x < 8. ? 1679846770u : (t.x < 12. ? 1852401253u : (t.x < 16. ? 1931506533u : (t.x < 20. ? 1868849512u : (t.x < 24. ? 1735289207u : (t.x < 28. ? 543584032u : 0u))))))) : v;
          v = t.y == 1. ? (t.x < 4. ? 1919117677u : (t.x < 8. ? 1667327599u : (t.x < 12. ? 544437349u : (t.x < 16. ? 1701864804u : (t.x < 20. ? 1852400750u : (t.x < 24. ? 1852776551u : (t.x < 28. ? 1701344288u : 2126441u))))))) : v;
          v = t.y == 0. ? (t.x < 4. ? 1634890337u : (t.x < 8. ? 1835362158u : (t.x < 12. ? 7630437u : 0u))) : v;
          v = t.x >= 0. && t.x < 32. ? v : 0u;
      }

     float c = float((v >> uint (8. * t.x)) & 255u);

     float3 textColor = float3 (.3 , .3 , .3);

     p = (p - t * scale) / scale;
     p.x = (p.x - .5) * .45 + .5;
     float sdf = TextSDF(p , c);
     if (c != 0.)
      {
          color = lerp(textColor , color , smoothstep(-.05 , +.05 , sdf));
      }

     if (s.menuId == MENU_SPECULAR)
      {
          color = lerp(color , textColor , smoothstep(.05 , -.05 , Capsule(q.yx - float2 (-12.3 , 48.) , .3 , 26.)));
      }
 }

void MenuText(inout float3 color , float2 p , in AppState s)
 {
     p -= float2 (-160 , -1);

     float2 scale = float2 (4. , 8.);
     float2 t = floor(p / scale);

     float tab = 1.;
     if (t.y >= 6. && t.y < 10.)
      {
          p.x -= tab * scale.x;
          t.x -= tab;
      }
     if (t.y >= 0. && t.y < 5.)
      {
          p.x -= tab * scale.x;
          t.x -= tab;
      }
     if (t.y >= 0. && t.y < 3.)
      {
          p.x -= tab * scale.x;
          t.x -= tab;
      }

     uint v = 0u;
     v = t.y == 10. ? (t.x < 4. ? 1718777171u : (t.x < 8. ? 6644577u : 0u)) : v;
     v = t.y == 9. ? (t.x < 4. ? 1635018061u : (t.x < 8. ? 108u : 0u)) : v;
     v = t.y == 8. ? (t.x < 4. ? 1818585412u : (t.x < 8. ? 1920230245u : 25449u)) : v;
     v = t.y == 7. ? (t.x < 4. ? 1735749458u : (t.x < 8. ? 1936027240u : 115u)) : v;
     v = t.y == 6. ? (t.x < 4. ? 1702060354u : (t.x < 8. ? 1819231008u : 29295u)) : v;
     v = t.y == 5. ? (t.x < 4. ? 1751607628u : (t.x < 8. ? 1735289204u : 0u)) : v;
     v = t.y == 4. ? (t.x < 4. ? 1717987652u : (t.x < 8. ? 6648693u : 0u)) : v;
     v = t.y == 3. ? (t.x < 4. ? 1667592275u : (t.x < 8. ? 1918987381u : 0u)) : v;
     v = t.y == 2. ? (t.x < 4. ? 1953720644u : (t.x < 8. ? 1969383794u : 1852795252u)) : v;
     v = t.y == 1. ? (t.x < 4. ? 1936028230u : (t.x < 8. ? 7103854u : 0u)) : v;
     v = t.y == 0. ? (t.x < 4. ? 1836016967u : (t.x < 8. ? 2037544037u : 0u)) : v;
     v = t.x >= 0. && t.x < 12. ? v : 0u;

     float c = float((v >> uint (8. * t.x)) & 255u);

     float3 textColor = float3 (.3 , .3 , .3);
     if (t.y == 10. - s.menuId)
      {
          textColor = float3 (0.74 , 0.5 , 0.12);
      }

     p = (p - t * scale) / scale;
     p.x = (p.x - .5) * .45 + .5;
     float sdf = TextSDF(p , c);
     if (c != 0.)
      {
          color = lerp(textColor , color , smoothstep(-.05 , +.05 , sdf));
      }
 }

void DrawMenuControls(inout float3 color , float2 p , in AppState s)
 {
     p -= float2 (-110 , 74);

     // radial 
    float c2 = Capsule(p - float2 (0. , -3.5) , 3. , 4.);
    float c1 = Circle(p + float2 (0. , 7. - 7. * s.metal) , 2.5);

    // roughness slider 
   p.y += 15.;
   c1 = min(c1 , Capsule(p.yx - float2 (0. , 20.) , 1. , 20.));
   c1 = min(c1 , Circle(p - float2 (40. * s.roughness , 0.) , 2.5));

   p.y += 8.;
   c1 = min(c1 , Rectangle(p - float2 (19.5 , 0.) , float2 (21.4 , 4.)));
   color = lerp(color , float3 (0.9 , 0.9 , 0.9) , Smooth(-c2 * 2.));
   color = lerp(color , float3 (0.3 , 0.3 , 0.3) , Smooth(-c1 * 2.));

   for (int i = 0; i < 6; ++i)
    {
        float2 o = float2 (i == int(s.baseColor) ? 2.5 : 3.5, i == int(s.baseColor) ? 2.5 : 3.5);
        color = lerp(color , BASE_COLORS[i] , Smooth(-2. * Rectangle(p - float2 (2. + float(i) * 7. , 0.) , o)));
    }
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

SH_STPETER.l00 = float3 (0.3623915, 0.2624130, 0.2326261);
SH_STPETER.l1m1 = float3 (0.1759131, 0.1436266, 0.1260569);
SH_STPETER.l10 = float3 (-0.0247311, -0.0101254, -0.0010745);
SH_STPETER.l11 = float3 (0.0346500, 0.0223184, 0.0101350);
SH_STPETER.l2m2 = float3 (0.0198140, 0.0144073, 0.0043987);
SH_STPETER.l2m1 = float3 (-0.0469596, -0.0254485, -0.0117786);
SH_STPETER.l20 = float3 (-0.0898667, -0.0760911, -0.0740964);
SH_STPETER.l21 = float3 (0.0050194, 0.0038841, 0.0001374);
SH_STPETER.l22 = float3 (-0.0818750, -0.0321501, 0.0033399);


 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
      float2 uv = fragCoord.xy / _ScreenParams.xy;
      float2 q = fragCoord.xy / _ScreenParams.xy;
      float2 p = -1. + 2. * q;
      p.x *= _ScreenParams.x / _ScreenParams.y;
      p *= 100.;

      AppState s;
      LoadState(s);

      float3 color = float3 (1. , .98 , .94) * lerp(1.0 , 0.4 , Smooth(abs(.5 - uv.y)));
      float vignette = q.x * q.y * (1.0 - q.x) * (1.0 - q.y);
      vignette = saturate(pow(32.0 * vignette , 0.05));
      color *= vignette;

      DrawScene(color , p , s);
      Diagram(color , p , s);
      InfoText(color , p , s);
      MenuText(color , p , s);
      DrawMenuControls(color , p , s);

      fragColor = float4 (color , 1.);
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