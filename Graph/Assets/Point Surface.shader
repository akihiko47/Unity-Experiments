Shader "Graph/Point Surface" {

	SubShader{
		CGPROGRAM
		#pragma surface ConfigureSurface Lambert
		#pragma target 3.0

		struct Input {
			float3 worldPos;
		};

		void ConfigureSurface (Input input, inout SurfaceOutput surface) {
			surface.Albedo = saturate(input.worldPos * 0.5 + 0.5);
		}

		ENDCG
	}

	FallBack "Diffuse"
}
