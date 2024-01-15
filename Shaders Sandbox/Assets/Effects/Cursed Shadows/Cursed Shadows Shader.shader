Shader "Effects/Cursed Shadows" {
    Properties {
        _MainTex("Main Texture", 2D) = "white" {}
        _ShadowTexture ("Texture in shadows", 2D) = "black" {}
        _Gloss ("Glossiness", float) = 1.0
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            sampler2D _ShadowTexture, _MainTex;
            float4 _ShadowTexture_ST, _MainTex_ST;
            float _Gloss;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };

            v2f vert (MeshData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target{
                i.normal = normalize(i.normal);
                
                // diffuse light
                float3 albedo = tex2D(_MainTex, i.uv);
                float3 lightDir = _WorldSpaceLightPos0;
                float3 lightColor = _LightColor0;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                float diffuse = saturate(dot(lightDir, i.normal));

                float3 diffuseColored = diffuse * lightColor * albedo;

                // specular light
                float3 halfVector = normalize(lightDir + viewDir);
                float specular = saturate(dot(i.normal, halfVector));
                specular = pow(specular, _Gloss) * (diffuse > 0);

                float3 specularColored = specular * lightColor;

                // cursed shadows
                float3 shadowAlbedo = tex2D(_ShadowTexture, i.uv);
                float wave = (sin(i.uv.y - _Time.y * 0.05 * 6.28 * 2.0) * 0.5 + 0.5) * (sin(_Time.y * 3.0) * 0.5 + 1.0);

                float3 shadowColor = shadowAlbedo * (diffuse <= 0.0) * float3(1.0, 0.0, 0.0) * 0.1 * wave;

                return float4(diffuseColored + specularColored + shadowColor, 1.0);
            }

            ENDCG
        }
    }
}
