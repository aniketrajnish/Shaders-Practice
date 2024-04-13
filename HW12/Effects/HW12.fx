// Resources:
#define FLIP_TEXTURE_Y 1
// Globals (user-defined):
matrix World, View, Projection;
// Utility Functions:
float2 GetUV(float2 uv)
{
    return float2(uv.x, uv.y * (1 - FLIP_TEXTURE_Y) + (FLIP_TEXTURE_Y) * (1 - uv.y)); // avoiding bools for better performance
}
float3 GetVectorColorContribution(float4 light, float3 color)
{
    return light.rgb * light.a * color;
}
float3 GetScalarColorContribution(float4 light, float color)
{
    return light.rgb * light.a * color;
}
// Render States:
RasterizerState DisableCulling
{
    CullMode = None;
};
// Texture Mapping:
Texture2D ColTex;
SamplerState ColSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
};
// Constants (per frame):
cbuffer CBufferPerFrame
{
    float4 AmbientCol;
    float4 LightCol;
    float3 LightPos;
    float3 LightLookAt;
    float3 CameraPos;
    float LightRad;
    float SpotInnerAngle;
    float SpotOuterAngle;
}
// Constants (per object):
cbuffer CBufferPerObject
{
    float4 SpecCol;
    float SpecPow;
}
// Data Structures:
struct VS_IN
{
    float4 ObjectPos : POSITION;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL;
};
struct VS_OUT
{
    float4 Pos : SV_POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float3 LightDir : TEXCOORD1;
    float3 WorldPos : TEXCOORD2;
    float3 ViewDir : TEXCOORD3;
    float Attenuation : TEXCOORD4;
    float LightLookAt : TEXCOORD5;
};
// Vertex Shader:
VS_OUT VSPoint(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
    matrix WorldViewProj = mul(mul(World, View), Projection);

    Out.Pos = mul(In.ObjectPos, WorldViewProj);
    Out.TexCoord = GetUV(In.TexCoord);
    Out.Normal = normalize(mul(In.Normal, World)).xyz;
    Out.WorldPos = mul(In.ObjectPos, World).xyz;
    
    float3 LightDir = normalize(LightPos - Out.WorldPos);
    Out.Attenuation = saturate(1 - length(Out.WorldPos - LightDir) / LightRad);
    Out.LightDir = LightDir;

    return Out;
}
VS_OUT VSSpot(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
    matrix WorldViewProj = mul(mul(World, View), Projection);

    Out.Pos = mul(In.ObjectPos, WorldViewProj);
    Out.TexCoord = GetUV(In.TexCoord);
    Out.Normal = normalize(mul(In.Normal, World)).xyz;
    Out.WorldPos = mul(In.ObjectPos, World).xyz;
    
    float3 LightDir = normalize(LightPos - Out.WorldPos);
    Out.Attenuation = saturate(1 - length(Out.WorldPos - LightDir) / LightRad);
    Out.LightLookAt = -LightLookAt;

    return Out;
}
// Pixel Shader:
float4 PSPoint(VS_OUT In) : SV_TARGET
{
    float4 OUT = (float4)0;

    float3 LightDir = normalize(LightPos - In.WorldPos);
    float3 ViewDir = normalize(CameraPos - In.WorldPos);

    float3 Normal = normalize(In.Normal);
    float n_dot_h = dot(lightDir, normal);

    float3 HalfDir = normalize(LightDir + ViewDir);
    float3 n_dot_h = dot(Normal, HalfDir);

    float4 Col = ColTex.Sample(ColSampler, In.TexCoord);
    float4 LightCoefficients = lit(n_dot_l, n_dot_h, SpecPow);

    float3 Ambient = GetVectorColorContribution(AmbientCol, Col.rgb);
    float3 Diffuse = In.Attenuation * GetVectorColorContribution(LightCol, LightCoefficients.y * Col.rgb);
    float3 Specular = In.Attenuation * GetScalarColorContribution(SpecCol, min(LightCoefficients.z, Col.w));

    Out.rgb = Ambient + Diffuse + Specular;
    Out.a = Col.a;

    return OUT;
}
float4 PSSpot(VS_OUT In) : SV_TARGET
{
    float4 OUT = (float4)0;

    float3 LightDir = normalize(LightPos - In.WorldPos);
    float3 ViewDir = normalize(CameraPos - In.WorldPos);

    float3 Normal = normalize(In.Normal);
    float n_dot_h = dot(lightDir, normal);

    float3 HalfDir = normalize(LightDir + ViewDir);
    float3 n_dot_h = dot(Normal, HalfDir);

    float4 Col = ColTex.Sample(ColSampler, In.TexCoord);
    float4 LightCoefficients = lit(n_dot_l, n_dot_h, SpecPow);

    float3 Ambient = GetVectorColorContribution(AmbientCol, Col.rgb);
    float3 Diffuse = In.Attenuation * GetVectorColorContribution(LightCol, LightCoefficients.y * Col.rgb);
    float3 Specular = In.Attenuation * GetScalarColorContribution(SpecCol, min(LightCoefficients.z, Col.w));

    float3 LightLookAt = normalize(In.LightLookAt);
    float SpotFactor = smoothstep(SpotOuterAngle, SpotInnerAngle, max(0, dot(LightDir, LightLookAt)));

    Out.rgb = Ambient + SpotFactor*(Diffuse + Specular);
    Out.a = Col.a;

    return OUT;
}
// Techniques:
technique11 PointLightTechnique
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_5_0, VSPoint()));
        SetPixelShader(CompileShader(ps_5_0, PSPoint()));
        SetRasterizerState(DisableCulling);
    }
}
technique11 SpotLightTechnique
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_5_0, VSSpot()));
        SetPixelShader(CompileShader(ps_5_0, PSSpot()));
        SetRasterizerState(DisableCulling);
    }
}


