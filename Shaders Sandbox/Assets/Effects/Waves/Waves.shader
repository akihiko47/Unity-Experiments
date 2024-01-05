Shader "Effects/Waves" {

    Properties {
        _TexLow("Low Texture", 2D) = "black"
        _TexHigh("High Texture", 2D) = "white"
    }

    SubShader {

        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _TexLow;
            sampler2D _TexHigh;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 localPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };


            v2f vert (MeshData v) {
                v2f o;

                v.vertex.y += sin(v.vertex.x * 1.0 + _Time.y);
                v.vertex.y += sin(v.vertex.z * 0.5 + _Time.y * 2.0) * 0.5;

                o.localPos = v.vertex;

                o.vertex = UnityObjectToClipPos(v.vertex);

               

                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float4 lowTex = tex2D(_TexLow, i.uv) * (1 - saturate(i.localPos.y));
                float4 highTex = tex2D(_TexHigh, i.uv) * saturate(i.localPos.y);
                return lowTex + highTex;
            }

            ENDCG
        }
    }
}
