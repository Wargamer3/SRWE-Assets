float4x4 WorldMatrix;
float4x4 ViewMatrix;
float4x4 ProjectionMatrix;

float4 AmbienceColor = float4(0.1f, 0.1f, 0.1f, 1.0f);
float ShowAlpha;

// For Diffuse Lightning
float4x4 WorldInverseTransposeMatrix;
float3 DiffuseLightDirection = float3(-1.0f, 0.0f, 0.0f);
float4 DiffuseColor = float4(1.0f, 1.0f, 1.0f, 1.0f);

// For Texture
texture ModelTexture;
sampler2D TextureSampler = sampler_state {
    Texture = (ModelTexture);
    MagFilter = Linear;
    MinFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VertexShaderInput
{
    float4 Position : POSITION0;
    // For Diffuse Lightning
    float4 NormalVector : NORMAL0;
    // For Texture
    float2 TextureCoordinate : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    // For Diffuse Lightning
    float4 VertexColor : COLOR0;
    // For Texture    
    float2 TextureCoordinate : TEXCOORD0;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;

    float4 worldPosition = mul(input.Position, WorldMatrix);
    float4 viewPosition = mul(worldPosition, ViewMatrix);
    output.Position = mul(viewPosition, ProjectionMatrix);

    // For Diffuse Lightning
    float4 normal = normalize(mul(input.NormalVector, WorldInverseTransposeMatrix));
    float lightIntensity = dot(normal, DiffuseLightDirection);
    output.VertexColor = saturate(DiffuseColor * lightIntensity);

    // For Texture
    output.TextureCoordinate = input.TextureCoordinate;

    return output;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
    // For Texture
    float4 TextureColor = tex2D(TextureSampler, input.TextureCoordinate);

    float IsTransparent = (TextureColor.a < 0.95f) ? 1 : 0;
    float IsSolid = (TextureColor.a >= 0.95f) ? 1 : 0;
    float HideTransparent = (TextureColor.a <= 0.01 ? -10 : 0);

    TextureColor.a = saturate(TextureColor.a
        + (-10 * IsTransparent * (1 - ShowAlpha))
        + (-10 * (IsSolid * (ShowAlpha))));

    clip((TextureColor.a <= 0.01 ? -1 : 1) + HideTransparent);

    float4 FinalColor = ((TextureColor * input.VertexColor + AmbienceColor) * (IsSolid * (1 - ShowAlpha)))
         + TextureColor * IsTransparent * (ShowAlpha);

    return saturate(FinalColor);
}

technique Texture
{
    pass Pass1
    {
        AlphaBlendEnable = TRUE;
        DestBlend = INVSRCALPHA;
        SrcBlend = SRCALPHA;
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}