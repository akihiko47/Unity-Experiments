Shader "RayMarching/RayMarchOperations" {

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

            uniform float3 _CameraWorldPos;
            uniform float4x4 _FrustumCornersMatrix;
            uniform float4x4 _CameraToWorldMatrix;


            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvOriginal :TEXCOORD01;
                float3 ray: TEXCOORD2;
            };

            float sdTorus(float3 p, float2 t) {
                float2 q = float2(length(p.xz) - t.x, p.y);
                return length(q) - t.y;
            }

            float GetDist(float3 pnt) {
                float4 sphere = float4(1.0, 1.0, 1.0, 0.5);
                float dS = length(pnt - sphere.xyz) - sphere.w;
                float dP = pnt.y;

                float d = min(dS, dP);
                return d;
            }

            float3 GetNormal(float3 pnt) {
                float d = GetDist(pnt);
                float2 e = float2(0.001, 0.0);

                float3 n = d - float3(GetDist(pnt - e.xyy),
                                      GetDist(pnt - e.yxy),
                                      GetDist(pnt - e.yyx));

                return normalize(n);
            }

            float RayMarch(float3 ro, float3 rd) {
                float dO = 0.0;

                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * dO;
                    float dS = GetDist(p);
                    dO += dS;
                    if (dS < SURF_DIST || dO > MAX_DIST) {
                        break;
                    }
                }

                return dO;
            }

            v2f vert (appdata v) {
                v2f o;

                half index = v.vertex.z;
                v.vertex.z = 0.1;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uvOriginal = v.uv;
                o.uv = v.uv.xy * 2 - 1;

                o.ray = _FrustumCornersMatrix[(int)index].xyz;
                o.ray = mul(_CameraToWorldMatrix, o.ray);
                return o;
            }

            float4 frag(v2f i) : SV_Target{

                // MARCHING
                float3 ro = _CameraWorldPos;
                float3 rd = normalize(i.ray);

                float dist = RayMarch(ro, rd);

                float3 color = float3(0.43, 0.83, 1.0);
                if (dist < MAX_DIST) {
                    float3 p = ro + rd * dist;

                    float3 N = GetNormal(p);
                    float3 L = normalize(float3(1, 1, 1));
                    float3 V = normalize(ro - p);
                    float3 H = normalize(L + V);

                    // LIGHTING
                    float3 albedo = float3(1.0, 1.0, 1.0);
                    float diff = saturate(dot(N, L));
                    float3 spec = pow(saturate(dot(N, H)), 70.0) * (diff > 0);

                    color.rgb = albedo * diff + spec;

                    // SHADOWS
                    float rayToLightLength = RayMarch(p + N * SURF_DIST * 8.0, L);
                    color *= !(rayToLightLength < MAX_DIST);

                    // AMBIENT
                    float3 ambient = float3(0, 0.02, 0.05);
                    color += ambient;

                    // FOG
                    float3 fogColor = float3(0.43, 0.83, 1.0);
                    float density = 0.02;
                    float fog = pow(2, -pow((dist * density), 2));
                    color = lerp(fogColor, color, fog);

                }

                return float4(color, 1.0);
              
            }

            ENDCG
        }
    }
}
