Shader "Effects/Shield" {
    Properties{
        _Color("Shield Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _FresnelInt("Fresnel Intensity", Range(0.0, 1.0)) = 0.5
        _FresnelColor("Fresnel Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _LinesNum("Number of lines", float) = 10.0
        _LinesSpeed("Speed of lines", float) = 5.0
        _LinesColor("Color of lines", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader{
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}

        Pass {
            Cull Off
            ZWrite Off
            Blend One One

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            float4 _Color;
            float4 _FresnelColor;
            float4 _LinesColor;
            float _FresnelInt;
            float _LinesNum, _LinesSpeed;

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target{
                i.normal = normalize(i.normal);

                float3 lookDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                // FRESNEL EFFECT
                float fresnelDot = dot(i.normal, lookDir);
                float fresnel = pow(1 - saturate(fresnelDot), 4.0) * _FresnelInt * (fresnelDot >= 0.0);
                float3 fresnelColor = fresnel * lerp(_FresnelColor.rgb, fixed3(1.0, 1.0, 1.0), pow(fresnel, 2.0));  // make color


                // WAVES
                float wavesMask = (sin(i.uv.y * 6.28 * _LinesNum - _Time.y * _LinesSpeed) * 0.5 + 0.5);
                float3 waves = _LinesColor * wavesMask;

                // MAIN COLOR
                float3 color = _Color.rgb * pow(i.uv.y, 8.0) * (1 - wavesMask);
                return float4(fresnelColor + waves + color, 1.0);
            }

            ENDCG
        }
    }
}
