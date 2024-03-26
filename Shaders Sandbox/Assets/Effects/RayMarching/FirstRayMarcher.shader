Shader "RayMarching/FirstRayMarcher" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Cull Off ZWrite Off ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define MAX_STEPS 100
            #define MAX_DIST 100.0
            #define SURF_DIST 0.01

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

            float GetDist(float3 pnt) {
                float4 sphere = float4(0.0, 1.0, 6.0, 1.0);
                float dS = length(pnt - sphere.xyz) - sphere.w;

                float dP = pnt.y;

                float d = min(dS, dP);
                return d;
            }

            float RayMarch(float3 rayOrigin, float3 rayDir) {

                float OriginDistance = 0.0;

                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 pnt = rayOrigin + rayDir * OriginDistance;
                    float deltaDistance = GetDist(pnt);
                    OriginDistance += deltaDistance;
                    if (OriginDistance < SURF_DIST || OriginDistance > MAX_DIST) break;
                }

                return OriginDistance;
            }

            float3 GetNormal(float3 pnt) {
                float d = GetDist(pnt);
                float2 e = float2(0.01, 0.0);

                float3 n = d - float3(GetDist(pnt - e.xyy),
                                      GetDist(pnt - e.yxy),
                                      GetDist(pnt - e.yyx));

                return normalize(n);
            }

            float GetLight(float3 pnt) {
                float3 lightPos = float3(0.0, 5.0, 6.0);

                lightPos.xz += float2(sin(_Time.y), cos(_Time.y));

                float3 L = normalize(lightPos - pnt);
                float3 N = GetNormal(pnt);

                return saturate(dot(L, N));
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * 2 - 1;
                return o;
            }

            float4 frag(v2f i) : SV_Target{

                float3 rayOrigin = float3(0.0, 1.0, 0.0);
                float3 rayDir = normalize(float3(i.uv.x, i.uv.y, 1.0));

                float dist = RayMarch(rayOrigin, rayDir);

                float light = GetLight(rayOrigin + rayDir * dist);

                return float4(light.xxx, 1.0);
            }
            ENDCG
        }
    }
}
