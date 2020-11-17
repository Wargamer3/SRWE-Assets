
// The world transformation
float4x4 World;
 
// The view transformation
float4x4 View;
 
// The projection transformation
float4x4 Projection;

float2 TextureOffset;
sampler s0;

float2 TextureScale;
float2 OffsetScale;

struct VertexInfo
{
    float4 Position : POSITION0;            // The position of the vertex
    float2 TextureCoordinate : TEXCOORD0;    // The texture coordinate of the vertex
	float4 Color     : COLOR0;
};

struct PixelInfo
{
    float4 Position : POSITION0;
    float2 UVCoordinateCenter			: TEXCOORD0;
    float2 UVCoordinateNeighborUp		: TEXCOORD1;
    float2 UVCoordinateNeighborDown		: TEXCOORD2;
    float2 UVCoordinateNeighborLeft		: TEXCOORD3;
    float2 UVCoordinateNeighborRight	: TEXCOORD4;
	float4 Color     : COLOR0;
};

PixelInfo vsGetNeighbor(VertexInfo Input)
{
	PixelInfo Output;

    //Get pixel postion.
    float4 WorldPosition = mul(Input.Position, World);
    float4 ViewPosition = mul(WorldPosition, View);
	//Project to Viewport.
    Output.Position = mul(ViewPosition, Projection);

	float2 RealPosition = Input.TextureCoordinate * TextureScale - TextureOffset * OffsetScale;

    // Copy over the texture coordinate
    Output.UVCoordinateCenter			= RealPosition;

    Output.UVCoordinateNeighborUp		= RealPosition - float2(0, OffsetScale.y);
    Output.UVCoordinateNeighborDown		= RealPosition + float2(0, OffsetScale.y);
    Output.UVCoordinateNeighborLeft		= RealPosition - float2(OffsetScale.x, 0);
    Output.UVCoordinateNeighborRight	= RealPosition + float2(OffsetScale.x, 0);
    // Copy over the vertex color.
	Output.Color = Input.Color;
	
	return Output;
}

float4 psRenderOutline(PixelInfo Input) : COLOR0
{
	if (Input.UVCoordinateNeighborRight.x < 0 || Input.UVCoordinateNeighborLeft.x > 1 || Input.UVCoordinateNeighborDown.y < 0 || Input.UVCoordinateNeighborUp.y > 1)
		return float4(0, 0, 0, 0);

	float4 Pixel		= tex2D(s0, Input.UVCoordinateCenter);
	float4 PixelUp		= tex2D(s0, Input.UVCoordinateNeighborUp);
	float4 PixelDown	= tex2D(s0, Input.UVCoordinateNeighborDown);
	float4 PixelLeft	= tex2D(s0, Input.UVCoordinateNeighborLeft);
	float4 PixelRight	= tex2D(s0, Input.UVCoordinateNeighborRight);

	if (Pixel.a == 1 || PixelUp.a == 1 || PixelDown.a == 1 || PixelLeft.a == 1 || PixelRight.a == 1)
		return Input.Color;

	return float4(0, 0, 0, 0);
}

technique Technique1
{
    pass Pass1
    {
        VertexShader = compile vs_2_0 vsGetNeighbor();
        PixelShader = compile ps_2_0 psRenderOutline();
    }
}