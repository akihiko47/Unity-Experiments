Shader "Custom/CatLikeCoding" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_Albedo("Albedo", 2D) = "white" {}
		_DetailTex("Detail Albedo", 2D) = "gray" {}

		[NoScaleOffset] _NormalMap("Normal Map", 2D) = "bump" {}
		_BumpScale("BumpScale", float) = 1.0
		[NoScaleOffset] _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailBumpScale("BumpScale", float) = 1.0

		_Gloss("Glossiness", Range(0.0, 1.0)) = 0.5
		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		[NoScaleOffset] _MetallicMap("Metallic Map", 2D) = "white" {}

		[NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[NoScaleOffset] _DetailMask("Detail Mask", 2D) = "white" {}

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "black" {}
		_Emission("Emission", Color) = (0, 0, 0)

		_Fresnel("Fresnel Effect", Range(0.0, 1.0)) = 0.0
	}

	CGINCLUDE
		#define BINORMAL_PER_FRAGMENT
	ENDCG

	SubShader{

		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
			#define FORWARD_BASE_PASS

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "MyLighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma multi_compile_fwdadd_fullshadows //#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT + Multiple shadows
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "MyLighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma multi_compile_shadowcaster

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "MyShadows.cginc"

			ENDCG
		}
	}

	CustomEditor "MyLightingShaderGUI"
}