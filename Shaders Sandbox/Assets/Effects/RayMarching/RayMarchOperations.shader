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
            #define MAX_DIST 500.0
            #define SURF_DIST 0.001

            #define POWER 8.0

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

            // Noise 2 input, 1 output
            float N21(float2 p) {
                return frac(sin(p.x * 125.0 + p.y * 412.0) * 6745.0);
            }

            float SmoothNoise(float2 uv) {
                float2 lv = frac(uv);
                float2 id = floor(uv);

                lv = lv * lv * (3.0 - 2.0 * lv);  // Iterpolation (smoothstep)

                float bl = N21(id);
                float br = N21(id + float2(1.0, 0.0));
                float b = lerp(bl, br, lv.x);

                float tl = N21(id + float2(0.0, 1.0));
                float tr = N21(id + float2(1.0, 1.0));
                float t = lerp(tl, tr, lv.x);

                return lerp(b, t, lv.y);
            }

            float SmoothNoise2(float2 uv) {
                float c = SmoothNoise(uv.xy * 4.0);
                c += SmoothNoise(uv.xy * 8.0) * 0.5;
                c += SmoothNoise(uv.xy * 16.0) * 0.25;
                c += SmoothNoise(uv.xy * 32.0) * 0.125;
                c += SmoothNoise(uv.xy * 64.0) * 0.0625;

                return c *= 0.5;
            }

            float sdFractal(float3 pos) {
                float3 z = pos;
                float dr = 1.0;
                float r = 0.0;
                for (int i = 0; i < 16; i++)
                {
                    r = length(z);
                    if (r > 1.5) break;

                    // convert to polar coordinates
                    float theta = acos(z.z / r);
                    float phi = atan(float2(z.y, z.x));

                    dr = pow(r, POWER - 1.0) * POWER * dr + 1.0;

                    // scale and rotate the point
                    float zr = pow(r, POWER);
                    theta = theta * POWER;
                    phi = phi * POWER;

                    // convert back to cartesian coordinates
                    z = pos + zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
                }
                return 0.5 * log(r) * r / dr;
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

                float3 cutBoxP = p - float3(12.0, 1.0, 0.0);
                float cutBoxD = sdBox(cutBoxP, float3(0.5, 0.5, 0.5));
                cutBoxD = abs(cutBoxD) - 0.05;  // Shell
                float cutPlaneD = dot(cutBoxP, normalize(float3(-1.0, 1.0, -1.0)));  // Rotating and moving plane
                float shellBoxD = max(cutPlaneD, cutBoxD);  // Cutting with plane

                float3 disBoxP = p - float3(14.0, 1.0, 0.0);
                float disBoxD = sdBox(disBoxP, float3(0.5, 0.5, 0.5));
                disBoxD -= sin(p.x * 10.0 + _Time.y * 4.0) * 0.02;  // Displacement
                disBoxD -= sin(p.y * 10.0 + _Time.y * 4.0) * 0.02;  // Displacement
                disBoxD -= sin(p.z * 10.0 + _Time.y * 4.0) * 0.02;  // Displacement

                
                float3 scBoxP = p - float3(16.0, 1.0, 0.0);
                scBoxP.x = abs(scBoxP.x);  // Mirroring
                float scale = lerp(1.0, 3.0, smoothstep(-0.5, 0.5, scBoxP.y));  // Controlled scaling
                scBoxP.xz *= scale;
                scBoxP.xz = mul(Rot(scBoxP.y * 2.0 + _Time.y), scBoxP.xz);  // Twisting
                float scBoxD = sdBox(scBoxP, float3(0.5, 0.5, 0.5)) / scale;

                float3 mBoxP = p - float3(18.0, 1.0, 0.0);
                float3 n = normalize(float3(-1.0, 1.0, -1.0));  // Folding around needed plane
                mBoxP -= 2.0 * n * min(dot(mBoxP, n), 0.0);  // Folding around needed plane
                mBoxP.xz *= 4.0;
                float mBoxD = sdBox(mBoxP, float3(0.5, 0.5, 0.5)) / 4.0;


                float3 fractalP = p - float3(20.0, 1.0, 0.0);
                fractalP;
                float fractalD = sdFractal(fractalP);


                float dP = p.y;
                //float c = SmoothNoise2(p.xz * 0.001);
                //float c2 = SmoothNoise2(p.xz * 0.1);
                //float c3 = SmoothNoise2(p.xz * 1);
                //dP -= c * 100;
                //dP -= c2 * 1;
                //dP -= c3 * 0.1;

                float d = min(dBox, dP);
                d = min(d, dS);
                d = min(d, dSub);
                d = min(d, dAdd);
                d = min(d, dLerp);
                d = min(d, shellBoxD);
                d = min(d, disBoxD);
                d = min(d, scBoxD);
                d = min(d, mBoxD);
                d = min(d, fractalD);

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

            float RayMarch(float3 ro, float3 rd, out float steps) {
                float dO = 0.0;
                steps = 0.0;

                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * dO;
                    float dS = GetDist(p);
                    dO += dS;
                    steps += 1;
                    if (abs(dS) < SURF_DIST || dO > MAX_DIST) {
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
                float steps = 0.0;

                float dist = RayMarch(ro, rd, steps);

                float3 color = float3(0.18, 0.49, 1.0);
                if (dist < MAX_DIST) {
                    float3 p = ro + rd * dist;

                    float3 lightPos = float3(540.0, 785.0, -1120.0);

                    float3 N = GetNormal(p);
                    float3 L = normalize(lightPos - p);
                    float3 V = normalize(ro - p);
                    float3 H = normalize(L + V);

                    // SHADOWS
                    float s;
                    float rayToLightLength = RayMarch(p + N * SURF_DIST * 2.0, L, s);
                    float attenuation = !(rayToLightLength < MAX_DIST);

                    // LIGHTING
                    float3 albedo = float3(0.4, 0.4, 0.4);
                    float3 ambient = float3(0.01, 0.02, 0.05);

                    float3 diff = saturate(dot(N, L)) * attenuation;
                    diff += ambient;

                    float3 spec = pow(saturate(dot(N, H)), 70.0) * (diff > 0) * attenuation;

                    color.rgb = albedo * diff + spec;


                    // AO
                    float ao = steps * 0.01;
                    ao = 1 - ao / (ao + 1.0);
                    ao = pow(ao, 2.0);
                    color *= ao;

                    // FOG
                    //float3 fogColor = float3(0.18, 0.49, 1.0);
                    
                    float sunAmount = max(dot(rd, L), 0.0);
                    float3  fogColor = lerp(
                        float3(0.5, 0.6, 0.7), // blue
                        float3(1.0, 0.9, 0.7), // yellow
                        pow(sunAmount, 8.0));
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
