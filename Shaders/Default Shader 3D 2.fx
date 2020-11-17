#include "Macros.fxh"

float4x4 World;
float4x4 WorldInverseTranspose;
float4x4 WorldViewProj;
float TextureAlpha;

float3 CameraPosition;

float3 DirLight0Direction;
float3 DirLight0DiffuseColor;
float3 DirLight0SpecularColor;

float3 DirLight1Direction;
float3 DirLight1DiffuseColor;
float3 DirLight1SpecularColor;

float3 DirLight2Direction;
float3 DirLight2DiffuseColor;
float3 DirLight2SpecularColor;

float4 DiffuseColor;

float3 EmissiveColor;

float3 SpecularColor;
float  SpecularPower;

float3 FogColor;
float2 FogLimits;

texture t0;

sampler Sampler = sampler_state
{
    Texture = (t0);
    
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = Point;
    
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VertexShaderInput
{
    float3 Position : SV_POSITION;
    float2 UV       : TEXCOORD0;
    float3 Normal   : NORMAL0;
};

struct VertexShaderOutput
{
    float4 Position         : SV_POSITION;
    float2 UV               : TEXCOORD0;
    float3 Normal           : TEXCOORD1;
    float4 PositionWorld    : TEXCOORD2;
    float4 Diffuse          : TEXCOORD3;
};

struct ColorPair
{
    float3 Diffuse;
    float3 Specular;
};

ColorPair ComputeLights(float3 eyeVector, float3 worldNormal, uniform int numLights)
{
    float3x3 lightDirections = 0;
    float3x3 lightDiffuse = 0;
    float3x3 lightSpecular = 0;
    float3x3 halfVectors = 0;

    [unroll]
    for (int i = 0; i < numLights; i++)
    {
        lightDirections[i] = float3x3(DirLight0Direction, DirLight1Direction, DirLight2Direction)[i];
        lightDiffuse[i] = float3x3(DirLight0DiffuseColor, DirLight1DiffuseColor, DirLight2DiffuseColor)[i];
        lightSpecular[i] = float3x3(DirLight0SpecularColor, DirLight1SpecularColor, DirLight2SpecularColor)[i];

        halfVectors[i] = normalize(eyeVector - lightDirections[i]);
    }

    float3 dotL = mul(-lightDirections, worldNormal);
    float3 dotH = mul(halfVectors, worldNormal);

    float3 zeroL = step(0, dotL);

    float3 diffuse = zeroL * dotL;
    float3 specular = pow(max(dotH, 0) * zeroL, SpecularPower);

    ColorPair result;

    result.Diffuse = mul(diffuse, lightDiffuse) * DiffuseColor.rgb + EmissiveColor;
    result.Specular = mul(specular, lightSpecular) * SpecularColor;

    return result;
}

//VSBasicPixelLightingTx
VertexShaderOutput ParticleVertexShader(VertexShaderInput Input)
{
    VertexShaderOutput Output;
    float FogStart = FogLimits.x;
    float FogEnd = FogLimits.y;

    float DistanceToCamera = length(CameraPosition - Input.Position);
    float RealFogFactor = clamp((DistanceToCamera - FogStart) / (FogEnd - FogStart), 0, 1);

    Output.Position = mul(float4(Input.Position, 1), WorldViewProj);
    Output.PositionWorld = float4(mul(float4(Input.Position, 1), World).xyz, RealFogFactor);
    Output.Normal = normalize(mul(Input.Normal, (float3x3)WorldInverseTranspose));

    //Output.Diffuse.rgb = Input.Color.rgb;
    //Output.Diffuse.a = Input.Color.a * DiffuseColor.a;
    Output.Diffuse = float4(1, 1, 1 ,1);
    Output.UV = Input.UV;

    return Output;
}

float4 ParticlePixelShader(VertexShaderOutput Input) : SV_Target0
{
    float4 TextureColor = SAMPLE_TEXTURE(Sampler, Input.UV) * Input.Diffuse;
    clip(TextureColor.a < 0.9f ? -1 : 1);

    float3 eyeVector = normalize(CameraPosition - Input.PositionWorld.xyz);
    float3 worldNormal = normalize(Input.PositionWorld);

    ColorPair lightResult = ComputeLights(eyeVector, worldNormal, 3);

    TextureColor.rgb *= lightResult.Diffuse;

    //TextureColor.rgb += lightResult.Specular * TextureColor.a;
    TextureColor.rgb = lerp(TextureColor.rgb, FogColor * TextureColor.a, Input.PositionWorld.w);
    TextureColor.a = TextureAlpha;

    return TextureColor;
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);
