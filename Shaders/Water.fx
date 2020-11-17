float4x4 View;
float4x4 Projection;
float4x4 World;
float4x4 WorldInverseTranspose;
float4 CameraPosition;
float Time;

float2    FloodLevel; // HM, VC
float     WaterLevel;
float     MinWaterLevel;
float     MaxPuddleDepth;
float     WetLevel;
float     RainIntensity;

float3    LightPosition;
float3    LightDirection;
float     LightIntensity;

float3 FogColor;
float MinimumFog;
float MinimumMultiplier;
float DesaturationValue;

float3 Normal = float3(0.0f, 0.0f, 1.0f);
float3 Tangent = float3(1.0f, 0.0f, 0.0f);
float3 Binormal = float3(0.0f, -1.0f, 0.0f);

float BumpConstant = 1;

texture t0;
sampler2D textureSampler = sampler_state {
    Texture = (t0);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

texture NormalMap;
sampler2D NormalMapSampler = sampler_state {
    Texture = (NormalMap);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

texture HeightMap;
sampler2D HeightSampler = sampler_state {
    Texture = (HeightMap);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

texture RippleTexture;
sampler2D RippleSampler = sampler_state {
    Texture = (RippleTexture);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

texture DropletsTexture;
sampler2D DropletsSampler = sampler_state {
    Texture = (DropletsTexture);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

texture ReflectionCubeMap;
samplerCUBE ReflectionCubeMapSampler = sampler_state
{
    texture = <ReflectionCubeMap>;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 TextureCoordinate : TEXCOORD0;
    float4 Color:     COLOR0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TextureCoordinate : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float3 Tangent : TEXCOORD2;
    float3 Binormal : TEXCOORD3;
    float4 Color:       TEXCOORD4;
    float3 ViewDir:     TEXCOORD5;
    float4 Pos:         TEXCOORD6;
};

float3 SampleEnvmap(float3 SkyReflection, float Gloss)
{
    // Use SkyLDR envmap from default cubemapgen package
    // Cubemap pre-filtered with ModifiedCubemapgen
    // http://seblagarde.wordpress.com/2012/06/10/amd-cubemapgen-for-physically-based-rendering/
    // CosinePower filter with mipmap filtering: NumMipmap 9, ExcludeBase enable, Gloss Scale 11, Gloss Bias 0 

    // Think to put trilinear filtering in RM cubemap setting   
    // LDR cubemap, should be HDR, small boost of 1.4 and pow to better see the result.
    return pow(1.4 * texCUBElod(ReflectionCubeMapSampler, float4(float3(SkyReflection.x, SkyReflection.z, -SkyReflection.y), (1.0 - Gloss) * 8.0)), 2.2);
}

void DoWetProcess(inout float3 Diffuse, inout float Gloss, float WetLevel)
{
    // Water influence on material BRDF
    Diffuse *= lerp(1.0, 0.3, WetLevel);                   // Attenuate diffuse
    Gloss = min(Gloss * lerp(1.0, 2.5, WetLevel), 1.0); // Boost gloss
}

float4 VertexToScreen(float4 VertexPosition)
{
    float Scale = -1.0;
    float4 ScreenPosition = VertexPosition * 0.5f;
    ScreenPosition.xy = float2(ScreenPosition.x, ScreenPosition.y * Scale) + ScreenPosition.w;
    ScreenPosition.zw = VertexPosition.zw;
    return ScreenPosition;
}

float CalcLuminance(float3 ActiveColor)
{
    return dot(ActiveColor, float3(0.299f, 0.587f, 0.114f));
}

float3 vertexFog(float MaxWeight)
{
    float Weight = lerp(0, MaxWeight, DesaturationValue);
    float3 RainFogColor = lerp(FogColor, FogColor * CalcLuminance(FogColor), Weight);

    return RainFogColor;
}

float4 ComputeFoggedColor(float3 cFinalColor, // Pixel color 
    float glow,  // Glow amount 
    float MaximumFogValue) // Vertex shader computed fog
{
    float4 cOut;
    float3 FinalFogColor = vertexFog(1);
    // Foggy factor
    float fogFactor = MaximumFogValue * (1 - (CalcLuminance(cFinalColor) / 10));
    fogFactor = min(fogFactor, MinimumFog);
    // First figure out color
    cOut.rgb = lerp(cFinalColor, FinalFogColor, fogFactor);
    // Then alpha (which is the glow)
    cOut.a = lerp(glow, fogFactor * MinimumMultiplier + glow, fogFactor);
    return cOut;
}

VertexShaderOutput VertexShaderFunction(VertexShaderInput Input)
{
    VertexShaderOutput Output;

    float4 WorldPos = mul(float4(Input.Position, 1), World);
    Output.Position = mul(mul(WorldPos, View), Projection);
    Output.TextureCoordinate = Input.TextureCoordinate;

    Output.Normal = normalize(mul(Normal, WorldInverseTranspose));
    Output.Tangent = normalize(mul(Tangent, WorldInverseTranspose));
    Output.Binormal = normalize(mul(Binormal, WorldInverseTranspose));

    Output.Color = Input.Color;
    Output.ViewDir = normalize(CameraPosition - WorldPos);
    Output.Pos = WorldPos;
    Output.Pos = VertexToScreen(Output.Position);

    return Output;
}

float4 PixelShaderFunction(VertexShaderOutput Input) : COLOR0
{   
    float BumpConstant = 1;

   float2 UV = Input.TextureCoordinate;
   float3 Heightmap = tex2D(HeightSampler, UV);
   float  TextureHeight = Heightmap.r;
   float  HorizontalWallInclination = Heightmap.g;
   float  VerticalWallInclination = Heightmap.b;

   float3x3 WorldToTangentSpace = float3x3(Input.Tangent, Input.Binormal, Input.Normal);

   // BumpOffset
   float BumpStrenght = 0.0003; // Magic value for this scene
   //UV = UV + CameraPosition.xy * (Heightmap - 0) * BumpStrenght;

   // Gather material BRDF Parameter
   // Convert to linear lighting
   float4 Texture = tex2D(textureSampler, UV);
   float3 BaseDiffuse = pow(Texture.rgb, 2.2);
   float BaseDiffuseAlpha = Texture.a;

   float3 bump = BumpConstant * (tex2D(NormalMapSampler, UV) - (0.5, 0.5, 0.5));
   bump = bump + VerticalWallInclination * float3(1, 0, 0);
   float3 bumpNormal = Input.Normal + (bump.x * Input.Tangent + bump.y * Input.Binormal);
   bumpNormal = normalize(bumpNormal);

   float3 SimulatedNormal = bumpNormal * 2.0 - 1.0;
   // TS to LS by inverse matrix - note LS is WS in this app
   SimulatedNormal = mul(WorldToTangentSpace, SimulatedNormal);

   // Glossiness store in alpha channel of the normal map
   float  Gloss = /*tex2D(NormalMapSampler, UV).a*/0.01;
   float3 Specular = 0.04; // Default specular value for dieletric

   /////////////////////////////
   // Rain effets - Specific code

   float  ScaleHeight = 1.0f;
   float  BiasHeight = 0.0f;
   TextureHeight = TextureHeight * ScaleHeight + BiasHeight;
   float TextureDepth = 1.0 - TextureHeight;

   float FinalWaterLevel = /*max(0, WaterLevel - TextureHeight)*/min(WaterLevel, TextureDepth);
   FinalWaterLevel = max(MinWaterLevel, FinalWaterLevel);

   // Get the size of the accumlated water in puddle taking into account the 
   // marging (0.4 constant here)
   float PuddleDepth = saturate((MaxPuddleDepth - Input.Color.g) / 0.4);

   float FinalWaterDepth = max(FinalWaterLevel, PuddleDepth);

   float FinalWetLevel = saturate(WetLevel + FinalWaterDepth);

   // Ripple part
   float3 RippleNormal = tex2D(RippleSampler, Input.Pos.xy * 6) * 2 - 1;
   RippleNormal = mul(WorldToTangentSpace, RippleNormal);
   // saturate(RainIntensity * 100.0) to be 1 when RainIntensity is > 0 and 0 else
   float3 WaterNormal = lerp(float3(0, 0, 1), RippleNormal, saturate(RainIntensity * 100.0)); // World space

   // Water influence on material BRDF (no modification of the specular term for now)
   // Type 2 : Wet region
   DoWetProcess(BaseDiffuse, Gloss, FinalWetLevel);

   // Apply accumulated water effect
   // When FinalWaterDepth is 1.0 we are in Type 4
   // so full water properties, in between we are in Type 3
   // Water is smooth
   Gloss = lerp(Gloss, 1.0, FinalWaterDepth);
   // Water F0 specular is 0.02 (based on IOR of 1.33)
   Specular = lerp(Specular, 0.02, FinalWaterDepth);
   SimulatedNormal = lerp(SimulatedNormal, WaterNormal, FinalWaterDepth);

   SimulatedNormal = lerp(SimulatedNormal, WaterNormal, FinalWaterDepth * abs(VerticalWallInclination) * 2);

   // End Rain effect specific code
   ////////////////////////

   // Precalc many values for lighting equation
   float3 ViewDir = Input.ViewDir;
   float3 LightDir = normalize(LightPosition - Input.Pos);
   float3 SpecularDir = normalize(LightDir + ViewDir);

   float  SpecularReflection = saturate(dot(ViewDir, SpecularDir));
   float  SpecularDiffuse = saturate(dot(SimulatedNormal, SpecularDir));
   float  LightDiffuse = saturate(dot(SimulatedNormal, LightDir));
   float  ViewDiffuse = saturate(dot(SimulatedNormal, ViewDir));

   float3 SkyReflection = reflect(ViewDir, SimulatedNormal);
   float3 ReflColor = SampleEnvmap(SkyReflection, Gloss);

   float RaindropAngle = tex2D(DropletsSampler, (Input.Pos.xy * 13 - float2(0, Time * 0.21))).r;
   float3 Reflect = normalize(2 * LightDiffuse * normalize(SimulatedNormal + float3(1, 0, 0) * RaindropAngle - LightDir));
   float3 ReflectColor = texCUBE(ReflectionCubeMapSampler, Reflect) * VerticalWallInclination * 0.2f * RaindropAngle;

   // Fresnel for cubemap and Fresnel for direct lighting
   float3 LightSpecular = Specular + (1.0 - Specular) * pow(1.0 - SpecularReflection, 5.0);
   // Use fresnel attenuation from Call of duty siggraph 2011 talk
   float3 ViewSpecular = Specular + (1.0 - Specular) * pow(1.0 - ViewDiffuse, 5.0) / (4.0 - 3.0 * Gloss);

   // Convert Gloss [0..1] to SpecularPower [0..2048]
   float  SpecPower = exp2(Gloss * 11);

   // Lighting
   float3 DiffuseLighting = LightDiffuse * BaseDiffuse;
   // Normalized specular lighting
   float3 SpecularLighting = LightSpecular * ((SpecPower + 2.0) / 8.0) * pow(SpecularDiffuse, SpecPower) * LightDiffuse;
   float3 AmbientSpecLighting = ReflColor * ViewSpecular;

   float3 FinalColor = LightIntensity * (DiffuseLighting + SpecularLighting) + AmbientSpecLighting + ReflectColor;
   FinalColor = pow(FinalColor, 1.0 / 2.2);

   float MaxWeight = 1;

   float4 FinalRainFogColor = ComputeFoggedColor(FinalColor, 1, 1);

   FinalColor = FinalRainFogColor.a * FinalColor + (1.0 - FinalRainFogColor.a) * FinalRainFogColor.rgb;

   return float4(FinalRainFogColor.rgb * FinalRainFogColor.a, BaseDiffuseAlpha);
}

technique BumpMapped
{
    pass Pass1
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
    }
}