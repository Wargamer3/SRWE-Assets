#include "Macros.fxh"

float4x4 View;
float4x4 Projection;
float2 ViewportScale;

float AnimationSpeed;
float CurrentTime;
float NumberOfImages;
float2 Size;

texture t0;

sampler Sampler = sampler_state
{
    Texture = (t0);
    
    MinFilter = Point;
    MagFilter = Point;
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

struct PixelInfo
{
    float4 Position						: POSITION0;
    float2 UV                           : TEXCOORD0;
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

PixelInfo ParticleVertexShader(VertexShaderInput Input)
{
	PixelInfo Output;
    
    float EllapsedTime = CurrentTime - Input.Time;
    float normalizedAge = EllapsedTime * AnimationSpeed;
	float CurrentImage = floor(normalizedAge * NumberOfImages) % NumberOfImages;

    Output.Position = mul(mul(float4(Input.Position, 1), View), Projection);
    float2 size = ComputeParticleSize();
    float2x2 rotation = ComputeParticleRotation();
	float2 UVPosition = float2((Input.UV.x * 2 - 1) * 0.5, (Input.UV.y * 2 - 1) * 0.5);
    Output.Position.xy += mul(UVPosition, rotation) * size * ViewportScale;

    Output.UV = float2(Input.UV.x / NumberOfImages + CurrentImage / NumberOfImages, Input.UV.y);

	float2 TextureSize = Size / 2.f;

    return Output;
}

float4 ParticlePixelShader(PixelInfo Input) : SV_Target
{
    float4 Pixel = SAMPLE_TEXTURE(Sampler, Input.UV);
	
	clip((Pixel.a < 0.9f) ? -1 : 1);
	if (Pixel.a > 0.9f)
	{
		return Pixel;
	}
	else
	{
		return float4(0, 0, 0, 0);
	}
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);