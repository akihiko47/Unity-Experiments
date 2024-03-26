Shader "Hidden/CustomScreenShader" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Cull Off ZWrite Off ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target{

                float2 newUV = i.uv;
                newUV.y += sin(newUV.x * 20 + _Time.y * 2.0) * 0.01;

                float3 texCol = tex2D(_MainTex, newUV).rgb;

                return float4(texCol, 1.0);
            }

            ENDCG
        }
    }
}
