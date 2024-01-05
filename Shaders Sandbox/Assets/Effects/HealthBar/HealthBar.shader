Shader "Effects/HealthBar" 
{
    Properties{
        _Health("Health", float) = 0.5
        _ColorLow("Color Low", Color) = (1.0, 0.0, 0.0, 1.0)
        _ColorHigh("Color Low", Color) = (0.0, 1.0, 0.0, 1.0)
    }

        SubShader{
            Tags { "RenderType" = "Opaque" }

            Pass {

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Health;
            float4 _ColorLow;
            float4 _ColorHigh;

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

                float4 outColor = healthMask * healthColor;
                return outColor;
            }

            ENDCG
        }
    }
}
