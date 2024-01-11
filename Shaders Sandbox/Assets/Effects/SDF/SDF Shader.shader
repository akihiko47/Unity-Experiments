Shader "Effects/SDF" {
    Properties
    {
        _Color1("Color 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _Color2("Color 2", Color) = (0.0, 0.0, 0.0, 0.0)
    }

    SubShader{
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}

        Pass {

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Color1;
            float4 _Color2;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target{

                float waveT = sin(i.uv.y * 6.28 * 10.0 + (-_Time.y * 3.0)) * 0.5 + 0.5;

                float3 wave = lerp(_Color1, _Color2, waveT);

                i.uv = i.uv * 2.0 - 1.0;
                i.uv.x += sin(i.uv.y * 15.0 + _Time.y) * 0.05;
                float dist_mask = abs(length(i.uv) - 0.5) < ((sin(_Time.y) * 0.2 + 1.0) * 0.1);

                float4 col = float4(wave * dist_mask, dist_mask);
                return col;
            }

            ENDCG
        }
    }
}
