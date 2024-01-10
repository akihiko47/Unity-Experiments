Shader "Effects/First Light" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_Albedo("Albedo", 2D) = "white" {}
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecularTint("Specular", Color) = (0.5, 0.5, 0.5)
	}

	SubShader{

		Pass {

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityStandardBRDF.cginc"

			float4 _Tint;
			sampler2D _Albedo;
			float4 _Albedo_ST;
			float _Smoothness;
			float4 _SpecularTint;

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			Interpolators vert(VertexData v) {
				Interpolators i;
				i.uv = v.uv * _Albedo_ST.xy + _Albedo_ST.zw;
				i.position = UnityObjectToClipPos(v.position);
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				i.normal = UnityObjectToWorldNormal(v.normal);
				return i;
			};

			float4 frag(Interpolators i) : SV_TARGET {
				i.normal = normalize(i.normal);

				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfVector = normalize(lightDir + viewDir);
				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_Albedo, i.uv) * _Tint;

				float3 specular = _SpecularTint.rgb * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100.0);
				float3 diffuse = saturate(dot(lightDir, i.normal)) * lightColor * albedo;
				return float4(diffuse + specular, 1.0);
			}

			ENDCG
		}
	}
}