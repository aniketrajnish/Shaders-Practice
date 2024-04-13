 // Resources:
 #define FLIP_TEXTURE_Y 1
// Utility Functions:
 float2 GetUV(float2 uv)
 {
    return float2(uv.x, uv.y * (1 - FLIP_TEXTURE_Y) + (FLIP_TEXTURE_Y) * (1 - uv.y)); // avoiding bools for better performance
 }
// Render States:
RasterizerState DisableCulling
{
    CullMode = None;
};
// Texture Mapping:
float4 BaseCol;
Texture2D Tex; // Texture Object
SamplerState TexSampler // Texture Sampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = CLAMP;
};
// Data Structures:
struct VS_IN
{
    float4 ObjectPos : POSITION;
    float2 TexCoord : TEXCOORD0;
};
struct VS_OUT
{
    float4 Pos : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};
// Vertex Shader:
VS_OUT VS_Q6(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
    Out.Pos = In.ObjectPos;
    Out.TexCoord = GetUV(In.TexCoord);
    return Out;
}
VS_OUT VS_Q7(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
    Out.Pos = In.ObjectPos;
    Out.TexCoord = GetUV(In.TexCoord) * 4;
    return Out;
}
// Pixel Shader:
float4 PS_Q6(VS_OUT In) : SV_TARGET
{
    float density = 50;
    return float4(cos(In.TexCoord.x * density), cos(In.TexCoord.y * density), 0, 1);
}
float4 PS_Q7(VS_OUT In) : SV_TARGET
{
    float4 col = Tex.Sample(TexSampler, In.TexCoord) + BaseCol;
    float xBar = (uint)((1+ In.TexCoord.x - .1) * 4 % 4  -1) / 2; // I spent 80% of my time on the next two lines, trying to remove the red bars on the texture
    float yBar = (uint)((1+ In.TexCoord.y - .1) * 4 % 4  -1) / 2; // So that it matches the texture you gave exactly ;) using uint for performance
    return float4(col.x + max(xBar, yBar), col.y + max(xBar, yBar), col.z + max(xBar, yBar), 1);
}
// Techniques:
technique11 TexTechnique_Q6
{
    pass P0
    {
        SetVertexShader( CompileShader( vs_5_0, VS_Q6() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_5_0, PS_Q6() ) );
        SetRasterizerState( DisableCulling );
    }
}
technique11 TexTechnique_Q7
{
    pass P0
    {
        SetVertexShader( CompileShader( vs_5_0, VS_Q7() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_5_0, PS_Q7() ) );
        SetRasterizerState( DisableCulling );
    }
}
