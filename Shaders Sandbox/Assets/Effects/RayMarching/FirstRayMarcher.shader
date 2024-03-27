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

            float mod(float x, float y) {
                return x - y * floor(x / y);
            }

            float sdTorus(float3 p, float2 t) {
                float2 q = float2(length(p.xz) - t.x, p.y);
                return length(q) - t.y;
            }

            float GetDist(float3 pnt) {
                float4 sphere = float4(0.0, 1.0, 6.0, 1.0);
                float dS = length(pnt - sphere.xyz) - sphere.w;
                float dT = sdTorus(pnt, float2(1, 0.2));


                float d = min(dS, dT);
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

            float GetLightAttenuation(float3 pnt) {
                float3 lightPos = float3(0.0, 5.0, 6.0);

                lightPos.xz += float2(sin(_Time.y), cos(_Time.y));

                float3 L = normalize(lightPos - pnt);
                float3 N = GetNormal(pnt);

                float diffuse = saturate(dot(L, N));
                float light = diffuse;

                float lightDistance = length(lightPos - pnt);
                float rayToLightLength = RayMarch(pnt + N * SURF_DIST * 2.0, L);
                light *= !(rayToLightLength < lightDistance);

                return light;
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

                float3 rayOrigin = _CameraWorldPos;
                float3 rayDir = i.ray;

                float dist = RayMarch(rayOrigin, rayDir);
                float3 pnt = rayOrigin + rayDir * dist;

                float attenuation = GetLightAttenuation(pnt);

                float4 color = (dist > SURF_DIST) && (dist < MAX_DIST);

                float4 originalColor = tex2D(_MainTex, i.uvOriginal);
                return float4(originalColor * (1.0 - color.w) + color.xyz * color.w, 1.0);
            }

            ENDCG
        }
    }
}
