Shader "Effects/ChromaticAberration" {

    Properties{
        [NoScaleOffset]_MainTex("Texture", 2D) = "white" {}
        _Intencity("Intencity", Range(0.0, 1.0)) = 0.5
        _OffsetX("Offset X", Range(0.0, 0.1)) = 0.0
        _OffsetY("Offset Y", Range(0.0, 0.1)) = 0.0
        _OffsetZ("Offset Z", Range(0.0, 0.1)) = 0.0
    }

        SubShader{

            Tags { "RenderType" = "Opaque" }

            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float _Intencity;
                float _OffsetX, _OffsetY, _OffsetZ;

                struct MeshData {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct Interpolators {
                    float2 uv : TEXCOORD0;
                    float4 OffsetPosX : TEXCOORD1;
                    float3 OffsetPosY : TEXCOORD2;
                    float3 OffsetPosZ : TEXCOORD3;
                    float4 vertex : SV_POSITION;
                };

                Interpolators vert (MeshData v) {
                    Interpolators o;
                    /*v.vertex.x += _OffsetX;
                    v.vertex.y += _OffsetY;
                    v.vertex.z += _OffsetZ;*/
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    return o;
                }

                fixed4 frag(Interpolators i) : SV_Target{

                    float3 col;

                    col.x = tex2D(_MainTex, float2(i.uv.x + _OffsetX, i.uv.y)).x;
                    col.y = tex2D(_MainTex, float2(i.uv.x, i.uv.y + _OffsetY)).y;
                    col.z = tex2D(_MainTex, i.uv + _OffsetZ).z;
                
                    return float4(col, 1.0);
                }

                ENDCG
        }
    }
}
