// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'
#if !defined(MY_LIGHTS_INCLUDED)

#define MY_LIGHTS_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _Albedo, _NormalMap, _DetailNormalMap, _MetallicMap, _EmissionMap, _OcclusionMap, _DetailMask;
sampler2D _DetailTex;
float4 _Albedo_ST, _DetailTex_ST, _Emission;
float _Gloss, _Fresnel, _Metallic, _BumpScale, _DetailBumpScale, _OcclusionStrength, _AlphaCutoff;


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
	#ifdef _METALLIC_MAP
		return tex2D(_MetallicMap, i.uv.xy).r;
	#else
		return _Metallic;
	#endif
}

float GetGlossiness(Interpolators i) {
	float glossiness = 1;
	#if defined(_SMOOTHNESS_ALBEDO)
		glossiness = tex2D(_Albedo, i.uv.xy).a;
	#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
		glossiness = tex2D(_MetallicMap, i.uv.xy).a;
	#endif
	return glossiness * _Gloss;
}

float GetAlpha(Interpolators i) {
	float alpha = _Tint.a;
	#if !defined(_SMOOTHNESS_ALBEDO)
		alpha *= tex2D(_Albedo, i.uv.xy).a;
	#endif
	return alpha;
}

float3 GetEmission(Interpolators i) {
	#if defined(FORWARD_BASE_PASS)
		#if defined(_EMISSION_MAP)
			return tex2D(_EmissionMap, i.uv.xy) * _Emission;
		#else
			return _Emission;
		#endif
	#else
		return 0;
	#endif
}

float GetOcclusion(Interpolators i) {
	#ifdef _OCCLUSION_MAP
		return lerp(1.0, tex2D(_OcclusionMap, i.uv.xy).g, _OcclusionStrength);
	#else
		return 1.0;
	#endif
}

float GetDetailMask(Interpolators i) {
	#if defined (_DETAIL_MASK)
		return tex2D(_DetailMask, i.uv.xy).a;
	#else
		return 1;
	#endif
}

float3 GetTangentSpaceNormal(Interpolators i) {
	float3 normal = float3(0, 0, 1);
	#if defined(_NORMAL_MAP)
		normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	#endif
	#if defined(_DETAIL_NORMAL_MAP)
		float3 detailNormal =
			UnpackScaleNormal(
				tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale
			);
		detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(i));
		normal = BlendNormals(normal, detailNormal);
	#endif
	return normal;
}

float3 GetAlbedo(Interpolators i) {
	float3 albedo = tex2D(_Albedo, i.uv.xy).rgb * _Tint.rgb;
	#ifdef _DETAIL_ALBEDO_MAP
		float3 details = tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
		albedo = lerp(albedo, albedo * details, GetDetailMask(i));
	#endif
	return albedo;
}

void InitializeFragmentNormal(inout Interpolators i) {

	float3 tangentSpaceNormal = GetTangentSpaceNormal(i);

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
		envData.roughness = 1 - GetGlossiness(i);
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

		float occlusion = GetOcclusion(i);
		indirectLight.specular *= occlusion;
		indirectLight.diffuse *= occlusion;

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
	float alpha = GetAlpha(i);
	#ifdef _RENDERING_CUTOUT
		clip(alpha - _AlphaCutoff);
	#endif

	InitializeFragmentNormal(i);

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 lightDir = _WorldSpaceLightPos0.xyz;

	float3 fresnel = pow(1 - saturate(dot(i.normal, viewDir)), 5.0) * _Fresnel;

	float3 specularTint;
	float oneMinusReflectivity;
	float3 albedo = DiffuseAndSpecularFromMetallic(
		GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity
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

	light.color = _LightColor0 * attenuation;
	light.ndotl = DotClamped(i.normal, lightDir);

	float4 color = UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, GetGlossiness(i),
		i.normal, viewDir,
		light, CreateIndirectLight(i, viewDir)
	);
	color.rgb += GetEmission(i);
	return color;
}


#endif