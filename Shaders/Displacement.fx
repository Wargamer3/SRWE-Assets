#include "Macros.fxh"

float4x4 World;
float4x4 View;
float4x4 Projection;

float2 TextureSize;

sampler RenderedMap : register(s0);
sampler Distortion : register(s1);

struct VertexInfo
{
    float4 Position : POSITION0;
    float2 UV       : TEXCOORD0;
	float4 Color     : COLOR0;
};

struct PixelInfo
{
    float4 Position : POSITION0;
    float2 UV       : TEXCOORD0;
	float4 Color     : COLOR0;
};

PixelInfo vsGetNeighbor(VertexInfo Input)
{
	PixelInfo Output;

    float4 WorldPosition = mul(Input.Position, World);
    float4 ViewPosition = mul(WorldPosition, View);
    Output.Position = mul(ViewPosition, Projection);

    Output.UV = Input.UV;
	Output.Color = Input.Color;
	
	return Output;
}

float4 psApplyDisplacament(PixelInfo Input) : COLOR0
{
    float4 DistortionPixel = tex2D(Distortion, Input.UV);
    float4 Pixel = tex2D(RenderedMap, Input.UV + float2((DistortionPixel.x - 0.5f) * TextureSize.x * 4, (DistortionPixel.y - 0.5f) * TextureSize.y * 4));

    if (DistortionPixel.a > 0.1f)
    {
        return Pixel;
    }
    else
    {
        return tex2D(RenderedMap, Input.UV);
    }
}

technique Technique1
{
    pass Pass1
    {
        VertexShader = compile vs_2_0 vsGetNeighbor();
        PixelShader = compile ps_2_0 psApplyDisplacament();
    }
}