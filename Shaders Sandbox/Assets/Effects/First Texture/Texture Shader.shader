// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Effects/Texture"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _MyTex ("Texture", 2D) = "white" {}
    }

    SubShader {
        Tags { "RenderType" = "Opaque" }

        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _MyTex;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

            };

            v2f vert (MeshData v) {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.screenPos = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float4 pattern = tex2D(_MyTex, i.uv);
                pattern = sin(pattern * 6.28 + _Time.y * 0.5) * 0.5 + 0.5;

                float4 col = tex2D(_MainTex, i.uv.xy) * (sin(length(i.screenPos.xy) + _Time.y * 0.5) * 0.5 + 0.5);

                return col;
            }

            ENDCG
        }
    }
}
