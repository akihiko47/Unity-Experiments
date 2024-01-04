Shader "Effects/First"
{
    Properties{
        _ColorA("Color A", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorB("Color B", Color) = (1.0, 1.0, 1.0, 1.0)
        _NLines("Number Of Lines", float) = 5.0
        _LinesSpeed("Speed Of Lines", float) = 1.0
    }
    SubShader {
        Tags { "RenderType" = "Transparent"
               "Queue" = "Transparent"
        }

        Pass {

            Cull Off
            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment DUMMY

            #include "UnityCG.cginc"

            float4 _ColorA;
            float4 _ColorB;
            float _NLines;
            float _LinesSpeed;

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
            };

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target {

                float offsetX = cos(i.uv.x * 6.28 * 5.0) * (cos(_Time.y) * 0.05);
                float timeOffset = (-_Time.y * _LinesSpeed * 0.1);
                float4 lines = cos((i.uv.y + timeOffset + offsetX) * 6.28 * _NLines) * 0.5 + 0.5;

                float4 fade = 1 - i.uv.y;

                float4 colorGradient = lerp(_ColorA, _ColorB, i.uv.y);

                float4 outColor = lines * colorGradient * fade;

                return outColor * (abs(i.normal.y) < 0.99);
            }

            ENDCG
        }
    }
}
