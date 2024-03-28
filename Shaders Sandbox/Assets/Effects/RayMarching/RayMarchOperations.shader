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
            #define SURF_DIST 0.001

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

            float2x2 Rot(float a) {
                float s = sin(a);
                float c = cos(a);
                return float2x2(c, -s, s, c);
            }

            float sdBox(float3 p, float3 b) {
                float3 q = abs(p) - b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            float sdTorus(float3 p, float R, float r) {
                float x = length(p.xz) - R;
                float y = p.y;
                float d = length(float2(x, y)) - r;
                return d;
            }

            float sdCapsule(float3 p, float3 a, float3 b, float3 r) {
                float3 ap = p - a;
                float3 ab = b - a;

                float t = dot(ap, ab) / dot(ab, ab);
                t = saturate(t);

                float3 c = a + t * (b - a);
                float d = length(p - c) - r;

                return d;
            }

            float GetDist(float3 p) {
                //float4 sphere = float4(1.0, 1.0, 1.0, 0.5);
                //float dS = length(p - sphere.xyz) - sphere.w;

                float3 bP = p - float3(0, 1, 0);  // Translate
                bP.xz = mul(Rot(_Time.y), bP.xz);  // Rotate around axis
                float dBox = sdBox(bP, float3(0.5, 0.5, 0.5));

                float3 sp = p - float3(3, 1, 0);
                sp *= float3(1.0, 4.0, 1.0);  // Scale
                float dS = length(sp) - 1.0;
                dS = dS / 4.0;  // ! Scale compensation !

                float3 bp = p - float3(6.0, 1.0, 0.0);  // main object point
                float3 ap = bp - float3(sin(_Time.y) * 0.5, 0.0, 0.0);  // sub object point
                float dB = sdBox(bp, float3(0.5, 0.5, 0.5)); // Object B (main)
                float dA = length(ap) - 0.6;  // Object A (sub)
                float dSub = max(-dA, dB);  // Subtraction

                float3 cp = p - float3(8.0, 1.0, 0.0);  // main object point
                float3 dp = cp - float3(sin(_Time.y) * 0.5, 0.0, 0.0);  // add object point
                float dC = sdBox(cp, float3(0.5, 0.5, 0.5)); // Object B (main)
                float dD = length(dp) - 0.6;  // Object A (add)
                float dAdd = max(dC, dD);  // Intersection

                float3 ep = p - float3(10.0, 1.0, 0.0);  // obj1 object point
                float3 fp = ep;  // obj2 object point
                float dE = sdBox(ep, float3(0.5, 0.5, 0.5)); // Object E
                float dF = sdCapsule(fp, float3(0, -0.5, 0), float3(0, 0.5, 0), 0.5);  // Object F
                float dLerp = lerp(dE, dF, sin(_Time.y) * 0.5 + 0.5);  // Lerping

                float dP = p.y;

                float d = min(dBox, dP);
                d = min(d, dS);
                d = min(d, dSub);
                d = min(d, dAdd);
                d = min(d, dLerp);
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

                float3 color = float3(0.18, 0.49, 1.0);
                if (dist < MAX_DIST) {
                    float3 p = ro + rd * dist;

                    float3 N = GetNormal(p);
                    float3 L = normalize(float3(3, 5, 1));
                    float3 V = normalize(ro - p);
                    float3 H = normalize(L + V);

                    // SHADOWS
                    float rayToLightLength = RayMarch(p + N * SURF_DIST * 2.0, L);
                    float attenuation = !(rayToLightLength < MAX_DIST);

                    // LIGHTING
                    float3 albedo = float3(0.3, 0.3, 0.3);
                    float3 ambient = float3(0.01, 0.02, 0.05);

                    float3 diff = saturate(dot(N, L)) * attenuation;
                    diff += ambient;

                    float3 spec = pow(saturate(dot(N, H)), 70.0) * (diff > 0) * attenuation;

                    color.rgb = albedo * diff + spec;

                    // FOG
                    float3 fogColor = float3(0.18, 0.49, 1.0);
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
