float4x4 View;
float4x4 Projection;
float4x4 World;

texture RippleTexture;
sampler2D RippleSampler = sampler_state {
    Texture = (RippleTexture);
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

float Time;
float TextureSize;

float RainIntensity;

#define PI 3.141592653

// Compute a ripple layer for the current time
float3 ComputeRipple(float2 UV, float CurrentTime, float Weight)
{
    float4 Ripple = tex2D(RippleSampler, UV);
    Ripple.yz = Ripple.yz * 2.0 - 1.0;

    float DropFrac = frac(Ripple.w + CurrentTime);
    float TimeFrac = DropFrac - 1.0 + Ripple.x;
    float DropFactor = saturate(0.2 + Weight * 0.8 - DropFrac);
    float FinalFactor = DropFactor * Ripple.x * sin(clamp(TimeFrac * 9.0, 0.0f, 3.0) * PI);

    return float3(Ripple.yz * FinalFactor * 0.35, 1.0);
}

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 TextureCoordinate : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TextureCoordinate : TEXCOORD0;
};

float4 PixelShaderFunction(VertexShaderOutput Input) : COLOR0
{
   // BEGIN CPU CODE
   float4 TimeMul = float4(1.0f, 0.85f, 0.93f, 1.13f);
   float4 TimeAdd = float4(0.0f, 0.2f, 0.45f, 0.7f);
   float GlobalMul = 1.6f;

   float4 Times = (Time * TimeMul + TimeAdd) * GlobalMul;

   Times = frac(Times);
   // END CPU CODE

   float2 UV = Input.TextureCoordinate;
   float2 UVRipple = UV;

   float4 Weights = RainIntensity - float4(0, 0.25, 0.5, 0.75);
   Weights = saturate(Weights * 4);

   float3 Ripple1 = ComputeRipple(UVRipple + float2(0.25f,0.0f), Times.x, Weights.x);
   float3 Ripple2 = ComputeRipple(UVRipple + float2(-0.55f,0.3f), Times.y, Weights.y);
   float3 Ripple3 = ComputeRipple(UVRipple + float2(0.6f, 0.85f), Times.z, Weights.z);
   float3 Ripple4 = ComputeRipple(UVRipple + float2(0.5f,-0.75f), Times.w, Weights.w);

   // Merge the 4 layers
   float4 Z = lerp(1, float4(Ripple1.z, Ripple2.z, Ripple3.z, Ripple4.z), Weights);
   float3 Normal = float3(Weights.x * Ripple1.xy +
                           Weights.y * Ripple2.xy +
                           Weights.z * Ripple3.xy +
                           Weights.w * Ripple4.xy,
                           Z.x * Z.y * Z.z * Z.w);

   float3 TextureNormal = normalize(Normal);

   // Compress
   return float4(TextureNormal.rgb * 0.5 + 0.5, 1);
}

VertexShaderOutput VertexShaderFunction(VertexShaderInput Input)
{
    VertexShaderOutput Output;

    float4 WorldPos = mul(float4(Input.Position, 1), World);
    Output.Position = mul(mul(WorldPos, View), Projection);

    Output.TextureCoordinate = float2(0.5 * (1 + Output.Position.x), 0.5 * (1 - Output.Position.y));
    return Output;
}

technique BumpMapped
{
    pass Pass1
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
    }
}