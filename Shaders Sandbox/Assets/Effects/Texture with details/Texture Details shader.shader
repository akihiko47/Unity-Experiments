Shader "Effects/Textured With Detail" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Texture", 2D) = "white" {}
		_DetailTex("Detail Texture", 2D) = "gray" {}
	}

	SubShader{

		Pass {

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4 _Tint;
			sampler2D _MainTex, _DetailTex;
			float4 _MainTex_ST, _DetailTex_ST;

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvDetail : TEXCOORD1;
			};

			struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			Interpolators vert(VertexData v) {
				Interpolators i;
				i.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				i.uvDetail = v.uv * _DetailTex_ST.xy + _DetailTex_ST.zw;
				i.position = UnityObjectToClipPos(v.position);
				return i;
			};

			float4 frag(Interpolators i) : SV_TARGET{
				float4 color = tex2D(_MainTex, i.uv) * _Tint;
				color *= tex2D(_DetailTex, i.uvDetail) * unity_ColorSpaceDouble;
				return color;
			}

			ENDCG
		}
	}
}