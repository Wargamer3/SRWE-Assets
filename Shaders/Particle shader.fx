#include "Macros.fxh"

float4x4 ViewProjection;

float Duration;
float CurrentTime;
float SpeedMultiplier;
float2 Gravity;
float NumberOfImages;
float2 Size;
float2 Camera;
float StartingAlpha;
float EndAlpha;

// Particle texture and sampler.
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
	float2 Position : SV_POSITION;
	float2 UV : TEXCOORD0;
	float Time : TEXCOORD1;
	float2 Speed : TEXCOORD2;
	float2 MinScale : TEXCOORD3;
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
    
    float age = CurrentTime - input.Time;
	
    float normalizedAge = saturate(age / Duration);
    float NormalizedTimeAlive = normalizedAge * Duration * SpeedMultiplier;
	float2 ScaleValue = (1 - input.MinScale);
	float2 FinalSize = Size - (ScaleValue * Size) * normalizedAge;
	float CurrentImage = floor(normalizedAge * NumberOfImages);

	float2 tempPos = input.Position - Camera + (input.UV * 2 - 1) * FinalSize + input.Speed * NormalizedTimeAlive + Gravity * NormalizedTimeAlive;
	
    output.Position = mul(float4(tempPos, 0, 1), ViewProjection);
    output.UV = float2(input.UV.x / NumberOfImages + CurrentImage / NumberOfImages, input.UV.y);

    float FinalAlpha = StartingAlpha + (EndAlpha - StartingAlpha) * normalizedAge;
    output.Color = float4(1, 1, 1, FinalAlpha);
    return output;
}

float4 ParticlePixelShader(VertexShaderOutput input) : SV_Target
{
    return SAMPLE_TEXTURE(Sampler, input.UV) * input.Color;
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);