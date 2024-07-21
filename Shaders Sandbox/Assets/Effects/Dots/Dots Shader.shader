Shader "Effects/Dots" {

    Properties {
        _MainTex ("Noise Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Threshold ("Threshold", Range(0, 1)) = 0.5

    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {

            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST, _Color;
            float _Threshold;

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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float noise = tex2D(_MainTex, i.uv).x;

                clip(_Threshold - noise);
                
                return _Color;
            }

            ENDCG
        }
    }
}
