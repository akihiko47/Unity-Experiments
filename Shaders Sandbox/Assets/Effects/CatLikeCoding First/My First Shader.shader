Shader "Effects/CatLikeCodingFirst" {

	Properties{
		_Tint("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
	}

	SubShader{

		Pass {

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4 _Tint;

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			Interpolators vert(VertexData v) {
				Interpolators i;
				i.uv = v.uv;
				i.position = UnityObjectToClipPos(v.position);
				return i;
			};

			float4 frag(Interpolators i) : SV_TARGET {
				return float4(i.uv, 1.0, 1.0);
			}

			ENDCG
		}
	}
}