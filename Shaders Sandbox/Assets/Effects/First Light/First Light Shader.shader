Shader "Effects/First Light" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_Albedo("Albedo", 2D) = "white" {}
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

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
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
				i.normal = UnityObjectToWorldNormal(v.normal);
				return i;
			};

			float4 frag(Interpolators i) : SV_TARGET {
				i.normal = normalize(i.normal);

				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_Albedo, i.uv) * _Tint;
				float3 diffuse = saturate(dot(lightDir, i.normal)) * lightColor * albedo;
				return float4(diffuse, 1.0);
			}

			ENDCG
		}
	}
}