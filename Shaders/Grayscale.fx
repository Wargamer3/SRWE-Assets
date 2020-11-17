sampler s0;

float4 psRenderOutline(float2 UVCoordinate : TEXCOORD0) : COLOR0
{
	float4 Pixel		= tex2D(s0, UVCoordinate);
	Pixel.rgb = (Pixel.r + Pixel.b + Pixel.g) / 3;
	return Pixel;
}

technique Technique1
{
    pass Pass1
    {
        PixelShader = compile ps_2_0 psRenderOutline();
    }
}