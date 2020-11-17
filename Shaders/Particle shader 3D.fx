#include "Macros.fxh"

float4x4 ViewProjection;
float4x4 World;
float4x4 InverseWorld;

float Duration;
float CurrentTime;
float SpeedMultiplier;
float3 Gravity;
float3 Size;
float3 Camera;
float StartingAlpha;
float EndAlpha;
float3 RotationSpeed;

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
	float3 VectorOffset : TEXCOORD0;
	float Time : TEXCOORD1;
	float3 Speed : TEXCOORD2;
	float3 MinScale : TEXCOORD3;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
	float3 Normal : TEXCOORD0;
    float4 UV : TEXCOORD1;
};

float3 Unity_RotateAboutAxis_Radians_float(float3 In, float3 Axis, float Rotation)
{
    float s = sin(Rotation);
    float c = cos(Rotation);
    float one_minus_c = 1.0 - c;

    Axis = normalize(Axis);
    float3x3 rot_mat =
    {
        one_minus_c * Axis.x * Axis.x + c,              one_minus_c * Axis.x * Axis.y - Axis.z * s,         one_minus_c * Axis.z * Axis.x + Axis.y * s,
        one_minus_c * Axis.x * Axis.y + Axis.z * s,     one_minus_c * Axis.y * Axis.y + c,                  one_minus_c * Axis.y * Axis.z - Axis.x * s,
        one_minus_c * Axis.z * Axis.x - Axis.y * s,     one_minus_c * Axis.y * Axis.z + Axis.x * s,         one_minus_c * Axis.z * Axis.z + c
    };
    return mul(rot_mat, In);
}

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
	float3 ScaleValue = (1 - input.MinScale);
	float3 FinalSize = Size - (ScaleValue * Size) * normalizedAge;

    float3 ProjectedVertex = (input.VectorOffset * 2 - 1) * FinalSize;
    float3 Normal = float3(0, 1, 0);

    ProjectedVertex = Unity_RotateAboutAxis_Radians_float(ProjectedVertex, RotationSpeed, NormalizedTimeAlive / 6.1416);
    Normal = Unity_RotateAboutAxis_Radians_float(Normal, RotationSpeed, NormalizedTimeAlive / 6.1416);

	float3 FinalPosition = input.Position - Camera + ProjectedVertex + input.Speed * NormalizedTimeAlive + Gravity * NormalizedTimeAlive;

    output.Position = mul(float4(FinalPosition.xy, 0, 1), ViewProjection);
    output.UV = VertexToScreen(output.Position);
    output.Normal = normalize(mul(Normal, (float3x3)InverseWorld));

    float FinalAlpha = StartingAlpha + (EndAlpha - StartingAlpha) * normalizedAge;
    return output;
}

float4 ParticlePixelShader(VertexShaderOutput input) : SV_Target
{
    float3 r  = input.Normal * 0.5 + 0.5;

    //return float4(1, 0, 0, 1);
    return tex2Dproj(Sampler, input.UV + r.r);
}

TECHNIQUE(Particles, ParticleVertexShader, ParticlePixelShader);