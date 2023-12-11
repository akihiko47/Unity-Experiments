using UnityEngine;

public class GPUGraph : MonoBehaviour {

	[SerializeField, Range(10, 100)]
	int resolution = 10;

	[SerializeField]
	FunctionLibrary.FunctionName function;

	[SerializeField, Min(0f)]
	float functionDuration = 1f, transitionDuration = 1f;

	[SerializeField]
	ComputeShader computeShader;

	[SerializeField]
	Material material;

	[SerializeField]
	Mesh mesh;

	static readonly int positionsId = Shader.PropertyToID("_Positions");
	static readonly int stepId = Shader.PropertyToID("_Step");
	static readonly int timeId = Shader.PropertyToID("_Time");
	static readonly int resolutionId = Shader.PropertyToID("_Resolution");


	public enum TransitionMode { Cycle, Random };
	[SerializeField]
	TransitionMode transitionMode = 0;

	float duration = 0f;

	bool transitioning = false;
	FunctionLibrary.FunctionName transitionFunction;

	ComputeBuffer positionBuffer;

	void UpdateFunctionOnGPU() {
		float step = 2f / resolution;
		computeShader.SetInt(resolutionId, resolution);
		computeShader.SetFloat(stepId, step);
		computeShader.SetFloat(timeId, Time.time);

		computeShader.SetBuffer(0, positionsId, positionBuffer);
		int groups = Mathf.CeilToInt(resolutionId / 8f);
		computeShader.Dispatch(0, groups, groups, 1);

		material.SetBuffer(positionsId, positionBuffer);
		material.SetFloat(stepId, step);

		var bounds = new Bounds(Vector3.zero, Vector3.one * (2f + 2f / resolution));
		Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, positionBuffer.count);
    }

    private void OnEnable() {
		positionBuffer = new ComputeBuffer(resolution * resolution, 3 * 4);
    }

    private void OnDisable() {
		positionBuffer.Release();
		positionBuffer = null;
    }

    private void Update() {
		duration += Time.deltaTime;
		if (transitioning) {
			if (duration >= transitionDuration) {
				duration -= transitionDuration;
				transitioning = false;
			}
		} else if (duration >= functionDuration) {
			duration -= functionDuration;

			transitioning = true;
			transitionFunction = function;

			if (transitionMode == TransitionMode.Cycle) {
				function = FunctionLibrary.GetNextFunctionName(function);
			} else {
				function = FunctionLibrary.GetNextFunctionNameOtherThan(function);
			}
		}

		UpdateFunctionOnGPU();
	}
}