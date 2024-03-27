Shader "Custom/CubeRayMarcher" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 0.01

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            float GetDist(float3 p) {
                float d = length(float2(length(p.xz) - 0.5, p.y)) - 0.1;

                return d;
            }

            float3 GetNormal(float3 pnt) {
                float d = GetDist(pnt);
                float2 e = float2(0.01, 0.0);

                float3 n = d - float3(GetDist(pnt - e.xyy),
                                      GetDist(pnt - e.yxy),
                                      GetDist(pnt - e.yyx));

                return normalize(n);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * 2.0 - 1.0;

                o.hitPos = v.vertex;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                // RAYMARCH
                float dO = 0.0;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * dO;
                    float dS = GetDist(p);
                    dO += dS;
                    if (dS < SURF_DIST || dO > MAX_DIST) {
                        break;
                    }
                }
                float d = dO;

                float3 col = 0.0;
                if (d < MAX_DIST) {
                    float3 p = ro + rd * d;
                    float3 N = GetNormal(p);
                    col = N;
                }

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
