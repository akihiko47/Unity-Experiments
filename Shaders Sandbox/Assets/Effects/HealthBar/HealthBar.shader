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
                float4 healthMask = (i.uv.x < _Health);
                float4 healthColor = lerp(_ColorLow, _ColorHigh, saturate(InvLerp(0.2, 0.8, _Health)));
                float4 pulsate = (sin(_Time.y * 5.0) * 0.5 + 0.5) * float4(1.0, 0.0, 0.0, 0.2) * (_Health < 0.2);
                float4 border = _BorderColor * (i.uv.x < _BorderSize) + (i.uv.x > 1 - _BorderSize) + (i.uv.y < _BorderSize) + (i.uv.y > 1 - _BorderSize);

                float4 outColor = (healthMask * tex2D(_MainTex, i.uv)) + pulsate + border;
                return outColor;
            }

            ENDCG
        }
    }
}
