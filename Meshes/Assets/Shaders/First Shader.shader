Shader "Unlit/First Shader"
{
    Properties{  // input data
        // _Color("Color", Color) = (0.5, 0.5, 0.5, 1.0)  // some value that can be set (variable name (name in editor, data type) = value)
        _UVScale("UV Scale", float) = 1.0
        _UVOffset("UV Offset", float) = 0.0
        _ColorA("Color A", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorB("Color B", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorStart("Color Start", float) = 0.0
        _ColorEnd("Color End", float) = 1.0
    }

        SubShader{
            Tags { "RenderType" = "Opaque" }

            Pass {
                CGPROGRAM
                #pragma vertex vertex_shader_function
                #pragma fragment fragment_shader_function
                #pragma multi_compile_fragment DUMMY

                #include "UnityCG.cginc"  // some unity function for efficient work

                // float4 _Color;  // get value from properties above
                float _UVScale;
                float _UVOffset;
                float4 _ColorA;
                float4 _ColorB;
                float _ColorStart;
                float _ColorEnd;


                // filled by Unity
                struct MeshData {  // per vertex data
                    float4 vertex : POSITION;

                    float3 normal : NORMAL;
                    // float4 tangent : TANGENT;
                    // float4 color : COLOR;

                    float2 uv : TEXCOORD0;
                };

                struct v2f {  // data transfered from vertex shader to fragment shader. Not related to mesh data.
                    // float2 uv : TEXCOORD0;  // some data (might be not uv)
                    float4 vertex : SV_POSITION;  // clip space position
                    float3 normal : TEXCOORD0; // just an index, not related to mesh data
                    float2 uv : TEXCOORD1; // transfer uv coordinates to channel 1
                };

                float InverseLerp(float a, float b, float v) {
                    return (v - a) / (b - a);
                }

                v2f vertex_shader_function (MeshData v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);  // local space to clip space (function from include)
                    o.normal = mul(unity_ObjectToWorld, v.normal);
                    o.uv = (v.uv + _UVOffset) * _UVScale;
                    return o;
                }

                // fixed4 - low precision float (mostly works only on scale from -1 to 1)
                // half4 - 4 floats of 16 bit
                // float4 - 4 loats of 32 bits
                // 
                // float4 -> half4 -> fixed4
                // float4x4 -> half 4x4 -> fixed4x4
                // and so on...
                float4 fragment_shader_function(v2f i) : SV_Target{

                    float t = InverseLerp(_ColorStart, _ColorEnd, i.uv.xxx);
                    t = saturate(t); // clamp to 0 or 1

                    float4 outColor = lerp(_ColorA, _ColorB, t);

                    return outColor;
                }

                ENDCG
        }
    }
}
