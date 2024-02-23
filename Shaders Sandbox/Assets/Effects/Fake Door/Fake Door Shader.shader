Shader "Effects/Fake Door" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            v2f vert (MeshData v) {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.position);
                return o;
            }

            float4 frag(v2f i) : SV_Target{
                float2 screenPos = i.screenPos.xy / i.screenPos.w;

                float4 col = float4(frac(screenPos.xy * 2.0), 0.0, 1.0);
                return col;
            }

            ENDCG
        }
    }
}
