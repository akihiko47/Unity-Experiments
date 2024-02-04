#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _Albedo, _NormalMap, _DetailNormalMap;
sampler2D _DetailTex;
float4 _Albedo_ST, _DetailTex_ST;
float _Gloss, _Fresnel, _Metallic, _BumpScale, _DetailBumpScale;

struct Interpolators {
	float4 position : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;

	#ifdef VERTEXLIGHT_ON
		float3 vertexLightColor : TEXCOORD3;
	#endif
};

struct VertexData {
	float4 position : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
};

void InitializeFragmentNormal(inout Interpolators i) {
	float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
	i.normal = BlendNormals(mainNormal, detailNormal);
	i.normal = i.normal.xzy;
	i.normal = normalize(i.normal);
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

UnityIndirect CreateIndirectLight(Interpolators i) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#ifdef VERTEXLIGHT_ON
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#ifdef FORWARD_BASE_PASS
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1.0)));
	#endif

	return indirectLight;
}

Interpolators vert(VertexData v) {
	Interpolators i;
	i.uv.xy = v.uv * _Albedo_ST.xy + _Albedo_ST.zw;
	i.uv.zw = v.uv * _DetailTex_ST.xy + _DetailTex_ST.zw;
	i.position = UnityObjectToClipPos(v.position);
	i.worldPos = mul(unity_ObjectToWorld, v.position);
	i.normal = UnityObjectToWorldNormal(v.normal);
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
		albedo, _Metallic, specularTint, oneMinusReflectivity
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
	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	light.color = lightColor * attenuation;
	light.ndotl = DotClamped(i.normal, lightDir);

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Gloss,
		i.normal, viewDir,
		light, CreateIndirectLight(i)
	);
}