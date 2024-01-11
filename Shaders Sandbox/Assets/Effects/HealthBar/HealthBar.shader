Shader "Effects/HealthBar" 
{
    Properties{
        _Health("Health", Range(0.0, 1.0)) = 0.5
        _ColorLow("Color Low", Color) = (1.0, 0.0, 0.0, 1.0)
        _ColorHigh("Color Low", Color) = (0.0, 1.0, 0.0, 1.0)
        _BorderColor("Border Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _BorderSize("Border Size", Range(0.0, 0.1)) = 0.01
        _MainTex("Health Texture", 2D) = "white" {}
    }

    SubShader{
        Tags { "RenderType" = "Transparent"
                "Queue" = "Transparent"}

        Pass {

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Health;
            float _BorderSize;
            float4 _ColorLow;
            float4 _ColorHigh;
            float4 _BorderColor;
            sampler2D _MainTex;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float InvLerp(float a, float b, float v) {
                return (v - a) / (b - a);
            }

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float healthMask = (i.uv.x < _Health);
                //float3 healthColor = lerp(_ColorLow, _ColorHigh, saturate(InvLerp(0.2, 0.8, _Health)));
                float pulsate = (sin(_Time.y * 5.0) * 0.3) * (_Health < 0.2) + 1.0;
                float3 healthTexture = tex2D(_MainTex, float2(_Health, i.uv.y)).rgb;

                float4 outColor = float4(healthTexture * pulsate, healthMask);
                return outColor;
            }

            ENDCG
        }
    }
}
