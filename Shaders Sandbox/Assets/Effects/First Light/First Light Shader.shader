Shader "Effects/First Light" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_Albedo("Albedo", 2D) = "white" {}
		_Gloss("Glossiness", float) = 1.0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Fresnel("Fresnel Effect", Range(0.0, 1.0)) = 0.0
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
			float _Gloss, _Fresnel, _Metallic;

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

				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_Albedo, i.uv) * _Tint;

				// energy conservation
				float3 specularTint = albedo * _Metallic;
				albedo = albedo * (1 - _Metallic);

				// diffuse light
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 lambert = saturate(dot(lightDir, i.normal));
				float3 diffuse = lambert * lightColor * albedo;

				// specular light - PHONG
				/*float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 reflectDir = reflect(-lightDir, i.normal);

				float specular = saturate(dot(viewDir, reflectDir));
				specular = pow(specular, _Gloss);*/

				// specular light - BLINN-PHONG
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfVector = normalize(lightDir + viewDir);

				float3 specular = dot(i.normal, halfVector);	
				specular = specular * (lambert > 0.0);  // cutting of bugs when looking from behind
				specular = pow(specular, _Gloss);
				specular = specular * lightColor * specularTint;


				float3 fresnel = pow(1 - saturate(dot(i.normal, viewDir)), 5.0) * _Fresnel;

				return float4(specular + diffuse + fresnel, 1.0);
			}

			ENDCG
		}
	}
}