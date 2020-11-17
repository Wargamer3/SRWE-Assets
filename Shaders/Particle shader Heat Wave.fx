#include "Macros.fxh"

float4x4 ViewProjection;

float Duration;
float CurrentTime;
float SpeedMultiplier;
float2 Gravity;
float2 Size;
float2 Camera;
float StartingAlpha;
float EndAlpha;

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
};

float4 VertexToScreen(float4 VertexPosition)
{
    float Scale = -1.0;
    float4 ScreenPosition = VertexPosition * 0.5f;
    ScreenPosition.xy = float2(ScreenPosition.x, ScreenPosition.y * Scale) + ScreenPosition.w;
    ScreenPosition.zw = VertexPosition.zw;
    return ScreenPosition;
}

VertexShaderOutput ParticleVertexShader(VertexShaderInput input)
{
    VertexShaderOutput output;
    
    float age = CurrentTime - input.Time;
	
    float normalizedAge = saturate(age / Duration);
    float NormalizedTimeAlive = normalizedAge * Duration * SpeedMultiplier;
	float2 ScaleValue = (1 - input.MinScale);
	float2 FinalSize = Size - (ScaleValue * Size) * normalizedAge;

	float2 tempPos = input.Position - Camera + (input.UV * 2 - 1) * FinalSize + input.Speed * NormalizedTimeAlive + Gravity * NormalizedTimeAlive;
	
    output.Position = mul(float4(tempPos, 0, 1), ViewProjection);
    output.UV = VertexToScreen(output.Position);

    float FinalAlpha = StartingAlpha + (EndAlpha - StartingAlpha) * normalizedAge;
    return output;
}

float4 ParticlePixelShader(VertexShaderOutput input) : SV_Target
{
    return SAMPLE_TEXTURE(Sampler, input.UV);
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);