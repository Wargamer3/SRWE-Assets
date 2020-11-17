sampler s0;

float4 psRenderOutline(float2 UVCoordinate : TEXCOORD0) : COLOR0
{
    float4 Pixel = tex2D(s0, UVCoordinate);
    Pixel = float4(UVCoordinate.x, UVCoordinate.y, 0, Pixel.a);
    return Pixel;
}

technique Technique1
{
    pass Pass1
    {
        PixelShader = compile ps_2_0 psRenderOutline();
    }
}
