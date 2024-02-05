Shader "Effects/First Light" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_Albedo("Albedo", 2D) = "white" {}
		_DetailTex("Detail texture for albedo", 2D) = "gray" {}
		[NoScaleOffset] _NormalMap("Normal Map", 2D) = "bump" {}
		_BumpScale("BumpScale", float) = 1.0
		[NoScaleOffset] _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailBumpScale("BumpScale", float) = 1.0
		_Gloss("Glossiness", Range(0.0, 1.0)) = 0.5
		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
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

			#pragma multi_compile _ VERTEXLIGHT_ON
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

			#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT  // #pragma multi_compile_fwdadd

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "MyLighting.cginc"

			ENDCG
		}
	}
}