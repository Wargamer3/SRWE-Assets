#include "Macros.fxh"

float4x4 ViewProjection;

float4 Color;

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
    float2 UV       : TEXCOORD0;
    float3 Normal   : NORMAL0;
};

struct VertexShaderOutput
{
    float4 Position         : SV_POSITION;
    float2 UV               : TEXCOORD0;
};

VertexShaderOutput ParticleVertexShader(VertexShaderInput Input)
{
    VertexShaderOutput Output;

    Output.Position = mul(float4(Input.Position, 1), ViewProjection);

    Output.UV = Input.UV;

    return Output;
}

float4 ParticlePixelShader(VertexShaderOutput Input) : SV_Target0
{
    float4 TextureColor = SAMPLE_TEXTURE(Sampler, Input.UV);
    clip(TextureColor.a < 0.9f ? -1 : 1);

    TextureColor *= Color;

    return TextureColor;
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);
