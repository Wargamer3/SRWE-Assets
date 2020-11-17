#include "Macros.fxh"

float4x4 View;
float4x4 Projection;
float4x4 World;
float2 ViewportScale;

float AnimationSpeed;
float CurrentTime;
float NumberOfImages;
float2 Size;
float4 OutlineColor;
bool Greyscale;

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
    float2 UVCoordinateCenter			: TEXCOORD0;
    float2 UVCoordinateNeighborUp		: TEXCOORD1;
    float2 UVCoordinateNeighborDown		: TEXCOORD2;
    float2 UVCoordinateNeighborLeft		: TEXCOORD3;
    float2 UVCoordinateNeighborRight	: TEXCOORD4;
	float4 Color						: COLOR0;
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
    
    float4 WorldPos = mul(float4(Input.Position, 1), World);
    Output.Position = mul(mul(WorldPos, View), Projection);
    float2 size = ComputeParticleSize();
    float2x2 rotation = ComputeParticleRotation();
	float2 UVPosition = float2((Input.UV.x * 2 - 1) * 0.5, (Input.UV.y * 2 - 1) * 0.5);
    Output.Position.xy += mul(UVPosition, rotation) * size * ViewportScale;

    Output.Color = float4(1, 1, 1, 1);
	
    Output.UVCoordinateCenter = float2(Input.UV.x / NumberOfImages + CurrentImage / NumberOfImages, Input.UV.y);

	float2 TextureSize = Size / 2.f;

    Output.UVCoordinateNeighborUp		= Output.UVCoordinateCenter - float2(0, 1.f / TextureSize.y);
    Output.UVCoordinateNeighborDown		= Output.UVCoordinateCenter + float2(0, 1.f / TextureSize.y);
    Output.UVCoordinateNeighborLeft		= Output.UVCoordinateCenter - float2(1.f / TextureSize.x, 0);
    Output.UVCoordinateNeighborRight	= Output.UVCoordinateCenter + float2(1.f / TextureSize.x, 0);
    
    return Output;
}

float4 ParticlePixelShader(PixelInfo Input) : SV_Target
{
    float4 Pixel = SAMPLE_TEXTURE(Sampler, Input.UVCoordinateCenter) * Input.Color;
	
	if (Input.UVCoordinateNeighborRight.x < 0 || Input.UVCoordinateNeighborLeft.x > 1 || Input.UVCoordinateNeighborDown.y < 0 || Input.UVCoordinateNeighborUp.y > 1)
		return float4(0, 0, 0, 0);

    if (Greyscale)
    {
        Pixel.rgb = (Pixel.r + Pixel.b + Pixel.g) / 3;
        return Pixel;
    }

	float4 PixelUp		= SAMPLE_TEXTURE(Sampler, Input.UVCoordinateNeighborUp);
	float4 PixelDown	= SAMPLE_TEXTURE(Sampler, Input.UVCoordinateNeighborDown);
	float4 PixelLeft	= SAMPLE_TEXTURE(Sampler, Input.UVCoordinateNeighborLeft);
	float4 PixelRight	= SAMPLE_TEXTURE(Sampler, Input.UVCoordinateNeighborRight);
	
	clip((Pixel.a < 0.9f && PixelUp.a < 0.9f && PixelDown.a < 0.9f && PixelLeft.a < 0.9f && PixelRight.a < 0.9f) ? -1 : 1);
	if (Pixel.a > 0.9f)
	{
		return Pixel;
	}
	else if (PixelUp.a > 0.9f || PixelDown.a > 0.9f || PixelLeft.a > 0.9f || PixelRight.a > 0.9f)
	{
		return OutlineColor;
	}
	else
	{
		return float4(0, 0, 0, 0);
	}
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);