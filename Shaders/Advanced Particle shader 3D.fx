#include "Macros.fxh"
#define NumberOfSeeds 200
#define NumberOfValuesOverTime 20

float4x4 View;
float4x4 Projection;
float2 ViewportScale;
float CurrentTime;
float NumberOfImages;
float2 Size;
float2 ScaleValuesOverTime[NumberOfSeeds * NumberOfValuesOverTime];
texture2D t0;

sampler Sampler : register(s0) = sampler_state
{
    Texture = (t0);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VertexShaderInput
{
    float3 Position : SV_POSITION;
    float2 UV : TEXCOORD0;
    float CreationTime : TEXCOORD1;
    float EndTime : TEXCOORD2;
    uint Seed : TEXCOORD3;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
    float2 UV : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

VertexShaderOutput ParticleVertexShader(VertexShaderInput input)
{
    VertexShaderOutput output;
    float Age = CurrentTime - input.CreationTime;
    float Duration = input.CreationTime - input.EndTime;
    float normalizedAge = saturate(Age / Duration);
    float CurrentImage = floor(normalizedAge * NumberOfImages) % NumberOfImages;

	float3 tempPos = input.Position + float3(0, -10, 0) * Age;
    float2 UVPosition = (input.UV * 2 - 1);
    float2 ScaleData = ScaleValuesOverTime[input.Seed * NumberOfValuesOverTime];

    float2 Scale = Size;

    tempPos.xy += UVPosition * Scale;
    output.Position = mul(mul(float4(tempPos, 1), View), Projection);
    output.UV = float2(input.UV.x / NumberOfImages + CurrentImage / NumberOfImages, 1 - input.UV.y);

    output.Color = float4(1, 1, 1, 1);
    
    return output;
}

float4 ParticlePixelShader(VertexShaderOutput input) : SV_TARGET
{
    float4 test = tex2Dlod(Sampler, float4(0, 0, 0, 0));
    float4 Color = tex2D(Sampler, input.UV) * input.Color;
    clip(Color.a < 0.9f ? -1 : 1);
    return Color;
}

technique Particles
{
    pass
    {
        VertexShader = compile vs_2_0 ParticleVertexShader ();
        PixelShader = compile ps_2_0 ParticlePixelShader();
    }
}