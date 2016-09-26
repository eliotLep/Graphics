// GENERATED BY SHADER GRAPH
// No guard header!

#define UNITY_MATERIAL_DISNEYGXX // Need to be define before including Material.hlsl
#include "Lighting/Lighting.hlsl" // This include Material.hlsl
#include "ShaderVariables.hlsl"

// This files is generated by the ShaderGraph or written by hand

// Note for ShaderGraph:
// ShaderGraph should generate the vertex shader output to add the variable that may be required
// For example if we require view vector in shader graph, the output must contain positionWS and we calcualte the view vector with it.
// Still some input are mandatory depends on the type of loop. positionWS is mandatory in this current framework. So the ShaderGraph should always generate it.

//-------------------------------------------------------------------------------------
// variable declaration
//-------------------------------------------------------------------------------------

// Set of users variables
float4 _DiffuseColor;
float4 _SpecColor;
float _Smoothness;
sampler2D _DiffuseMap;
sampler2D _NormalMap;
// ... Others

//-------------------------------------------------------------------------------------
// Lighting architecture
//-------------------------------------------------------------------------------------

// TODO: Check if we will have different Varyings based on different pass, not sure about that...
#if UNITY_SHADERRENDERPASS == UNITY_SHADERRENDERPASS_DEFERRED || UNITY_SHADERRENDERPASS == UNITY_SHADERRENDERPASS_FORWARD

// Forward
struct Attributes
{
	float3 positionOS	: POSITION;
	float3 normalOS		: NORMAL;
	float2 uv0			: TEXCOORD0;
	float4 tangentOS		: TANGENT;
};

struct Varyings
{
	float4 positionHS;
	float3 positionWS;
	float2 texCoord0;
	float4 tangentToWorld[3]; // [3x3:tangentToWorld | 1x3:viewDirForParallax]
};

struct PackedVaryings
{
	float4 positionHS : SV_Position;
	float4 interpolators[5] : TEXCOORD0;
};

// Function to pack data to use as few interpolator as possible, the ShaderGraph should generate these functions
PackedVaryings PackVaryings(Varyings input)
{
	PackedVaryings output;
	output.positionHS = input.positionHS;
	output.interpolators[0].xyz = input.positionWS.xyz;
	output.interpolators[0].w = input.texCoord0.x;
	output.interpolators[1] = input.tangentToWorld[0];
	output.interpolators[2] = input.tangentToWorld[1];
	output.interpolators[3] = input.tangentToWorld[2];
	output.interpolators[4].x = input.texCoord0.y;
	output.interpolators[4].yzw = float3(0.0, 0.0, 0.0);

	return output;
}

Varyings UnpackVaryings(PackedVaryings input)
{
	Varyings output;
	output.positionHS = input.positionHS;
	output.positionWS.xyz = input.interpolators[0].xyz;
	output.texCoord0.x = input.interpolators[0].w;
	output.texCoord0.y = input.interpolators[4].x;
	output.tangentToWorld[0] = input.interpolators[1];
	output.tangentToWorld[1] = input.interpolators[2];
	output.tangentToWorld[2] = input.interpolators[3];

	return output;
}

// TODO: Here we will also have all the vertex deformation (GPU skinning, vertex animation, morph target...) or we will need to generate a compute shaders instead (better! but require work to deal with unpacking like fp16)
PackedVaryings VertDefault(Attributes input)
{
	Varyings output;

	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	// TODO deal with camera center rendering and instancing (This is the reason why we always perform tow steps transform to clip space + instancing matrix)
	output.positionHS = TransformWorldToHClip(output.positionWS);

	float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

	output.texCoord0 = input.uv0;

	float4 tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);

	float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	output.tangentToWorld[0].xyz = tangentToWorld[0];
	output.tangentToWorld[1].xyz = tangentToWorld[1];
	output.tangentToWorld[2].xyz = tangentToWorld[2];

	output.tangentToWorld[0].w = 0;
	output.tangentToWorld[1].w = 0;
	output.tangentToWorld[2].w = 0;

	return PackVaryings(output);
}

#endif

//-------------------------------------------------------------------------------------
// Fill SurfaceData function
//-------------------------------------------------------------------------------------

SurfaceData GetSurfaceData(Varyings input)
{
	SurfaceData data;

	data.diffuseColor = tex2D(_DiffuseMap, input.texCoord0) * _DiffuseColor;
	data.occlusion = 1.0;

	data.specularColor = _SpecColor;
	data.smoothness = _Smoothness;

	data.normal = input.tangentToWorld[2].xyz;//UnpackNormalDXT5nm(tex2D(_NormalMap, input.texCoord0));

	return data;
}