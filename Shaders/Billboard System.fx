#include "Macros.fxh"

float4x4 View;
float4x4 Projection;
float2 ViewportScale;

float Duration;
float CurrentTime;
float NumberOfImages;
float2 Size;
float RotateTowardCamera;

texture t0;

sampler Sampler = sampler_state
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
    float Time : TEXCOORD1;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
    float2 UV : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

float2 ComputeParticleSize()
{
    // Project the size into screen coordinates.
    return Size * Projection._m11;
}

float2x2 ComputeParticleRotation()
{
    float rotation = 0;

    // Compute a 2x2 rotation matrix.
    float c = cos(rotation);
    float s = sin(rotation);

    return float2x2(c, -s, s, c);
}

VertexShaderOutput ParticleVertexShader(VertexShaderInput input)
{
    VertexShaderOutput output;

    float age = CurrentTime - input.Time;
    float normalizedAge = saturate(age / Duration);
    float CurrentImage = floor(normalizedAge * NumberOfImages) % NumberOfImages;

    output.Position = mul(mul(float4(input.Position, 1), View), Projection);
    if (RotateTowardCamera)
    {
        float2 size = ComputeParticleSize();
        float2x2 rotation = ComputeParticleRotation();
        float2 UVPosition = float2((input.UV.x * 2 - 1) * 0.5, input.UV.y - 1);
        output.Position.xy += mul(UVPosition, rotation) * size * ViewportScale;
    }

    output.Color = float4(1, 1, 1, 1);
    output.UV = float2(input.UV.x / NumberOfImages + CurrentImage / NumberOfImages, input.UV.y);

    return output;
}

float4 ParticlePixelShader(VertexShaderOutput input) : SV_Target
{
    float4 Color = SAMPLE_TEXTURE(Sampler, input.UV) * input.Color;
    clip(Color.a < 0.9f ? -1 : 1);
    return Color;
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);