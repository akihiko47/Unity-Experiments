// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _Albedo, _NormalMap, _DetailNormalMap, _MetallicMap;
sampler2D _DetailTex;
float4 _Albedo_ST, _DetailTex_ST;
float _Gloss, _Fresnel, _Metallic, _BumpScale, _DetailBumpScale;


struct Interpolators {
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;

	#ifdef BINORMAL_PER_FRAGMENT 
		float4 tangent : TEXCOORD2;
	#else
		float3 tangent : TEXCOORD2;
		float3 binormal : TEXCOORD3;
	#endif

	float3 worldPos : TEXCOORD4;

	#ifdef VERTEXLIGHT_ON
		float3 vertexLightColor : TEXCOORD5;
	#endif

	SHADOW_COORDS(5)
};

struct VertexData {
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};


float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

float GetMetallic(Interpolators i) {
	return tex2D(_MetallicMap, i.uv.xy).r * _Metallic;
}


void InitializeFragmentNormal(inout Interpolators i) {
	float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
	float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	#else
		float3 binormal = i.binormal;
	#endif

	i.normal = normalize(
		tangentSpaceNormal.x * i.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * i.normal
	);
}


void ComputeVertexLightColor(inout Interpolators i) {
	#ifdef VERTEXLIGHT_ON 
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
	#endif
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) {
	UNITY_BRANCH
	if (cubemapPosition.w > 0) {
		float3 factors =
			((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition);
	}
	return direction;
}


UnityIndirect CreateIndirectLight(Interpolators i, float3 viewDir) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#ifdef VERTEXLIGHT_ON
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#ifdef FORWARD_BASE_PASS
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1.0)));

		float3 sampleVec = reflect(-viewDir, i.normal);
		// float4 skyboxSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, sampleVec, (1- _Gloss) * 6.0);
		// indirectLight.specular = DecodeHDR(skyboxSample, unity_SpecCube0_HDR);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - _Gloss;
		envData.reflUVW = BoxProjection(
			sampleVec,
			i.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin,
			unity_SpecCube0_BoxMax
		);
		float3 probe0 = Unity_GlossyEnvironment( UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData );

		envData.roughness = 1 - _Gloss;
		envData.reflUVW = BoxProjection(
			sampleVec,
			i.worldPos,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin,
			unity_SpecCube1_BoxMax
		);

		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
				indirectLight.specular = lerp(probe1, probe0, interpolator);
			} else {
				indirectLight.specular = probe0;
			}
		#else
			indirectLight.specular = probe0;
		#endif

	#endif

	return indirectLight;
}

Interpolators vert(VertexData v) {
	Interpolators i;
	i.uv.xy = v.uv * _Albedo_ST.xy + _Albedo_ST.zw;
	i.uv.zw = v.uv * _DetailTex_ST.xy + _DetailTex_ST.zw;
	i.pos = UnityObjectToClipPos(v.vertex);
	i.worldPos = mul(unity_ObjectToWorld, v.vertex);
	i.normal = UnityObjectToWorldNormal(v.normal);

	#if defined(BINORMAL_PER_FRAGMENT)
		i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
	#endif

	TRANSFER_SHADOW(i);

	ComputeVertexLightColor(i);
	return i;
};

float4 frag(Interpolators i) : SV_TARGET{
	InitializeFragmentNormal(i);

	float3 lightColor = _LightColor0.rgb;
	float3 albedo = tex2D(_Albedo, i.uv.xy) * _Tint;
	albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 lightDir = _WorldSpaceLightPos0.xyz;

	float3 fresnel = pow(1 - saturate(dot(i.normal, viewDir)), 5.0) * _Fresnel;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, GetMetallic(i), specularTint, oneMinusReflectivity
	);

	// ===== BLING PHONG LIGHT MODEL =====

	//   energy conservation
	//float3 specularTint = albedo * _Metallic;
	//albedo = albedo * (1 - _Metallic);

	//   diffuse light
	//float3 lambert = saturate(dot(lightDir, i.normal));
	//float3 diffuse = lambert * lightColor * albedo;

	//   specular light - PHONG
	//float3 reflectDir = reflect(-lightDir, i.normal);

	//float specular = saturate(dot(viewDir, reflectDir));
	//specular = pow(specular, _Gloss);

	//   specular light - BLINN-PHONG
	
	//float3 halfVector = normalize(lightDir + viewDir);
	//float3 specular = dot(i.normal, halfVector);
	//specular = specular * (lambert > 0.0);  // cutting of bugs when looking from behind
	//specular = pow(specular, _Gloss);
	//specular = specular * lightColor * specularTint;

	//return float4(specular + diffuse + fresnel, 1.0);  // BLINN-PHONG lighting model (with fresnel)

	// ===== BLING PHONG LIGHT MODEL =====



	// ===== UNITY PBS LIGHT MODEL =====

	UnityLight light;
	#if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else 
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif

	#ifdef SHADOWS_SCREEN
		float attenuation = SHADOW_ATTENUATION(i);
	#else
		UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	#endif

	light.color = lightColor * attenuation;
	light.ndotl = DotClamped(i.normal, lightDir);

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Gloss,
		i.normal, viewDir,
		light, CreateIndirectLight(i, viewDir)
	);
}