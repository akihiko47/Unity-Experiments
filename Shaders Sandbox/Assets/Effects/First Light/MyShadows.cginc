#if !defined(MY_SHADOWS_INCLUDED)

#define MY_SHADOWS_INCLUDED

#include "UnityCG.cginc"

struct MeshData {
	float4 position : POSITION;
	float3 normal : NORMAL;
};

float4 vert(MeshData v) : SV_POSITION{
	float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
	return UnityApplyLinearShadowBias(position);
}

float4 frag() : SV_TARGET{
	return 0;
}

#endif