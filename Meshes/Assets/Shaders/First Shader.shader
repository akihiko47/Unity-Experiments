Shader "Unlit/First Shader"
{
    Properties{  // input data
        _Value("Value Name", float) = 1.0  // some value that can be set
    }

        SubShader{
            Tags { "RenderType" = "Opaque" }

            Pass {
                CGPROGRAM
                #pragma vertex vertex_shader_function
                #pragma fragment fragment_shader_function

                #include "UnityCG.cginc"  // some unity function for efficient work

                float _Value;  // get value from properties above


                // filled by Unity
                struct MeshData {  // per vertex data
                    float4 vertex : POSITION;

                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float4 color : COLOR;

                    float2 uv : TEXCOORD0;
                };

                struct v2f {  // data transfered from vertex shader to fragment shader
                    float2 uv : TEXCOORD0;  // some data (might be not uv)
                    float4 vertex : SV_POSITION;  // clip space position
                };

                v2f vertex_shader_function (MeshData v) {
                    v2f output;
                    output.vertex = UnityObjectToClipPos(v.vertex);  // local space to clip space (function from include)
                    return output;
                }

                // fixed4 - low precision float (mostly works only on scale from -1 to 1)
                // half4 - 4 floats of 16 bit
                // float4 - 4 loats of 32 bits
                // 
                // float4 -> half4 -> fixed4
                // float4x4 -> half 4x4 -> fixed4x4
                // and so on...
                float4 fragment_shader_function (v2f i) : SV_Target {
                    return float4(_Value, _Value, _Value, 1.0);
                }

                ENDCG
        }
    }
}
