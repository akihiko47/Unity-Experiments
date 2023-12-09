using UnityEngine;

public class Graph : MonoBehaviour {
	[SerializeField]
	Transform pointPrefab;

	[SerializeField, Range(10, 100)]
	int resolution = 10;

	[SerializeField]
	FunctionLibrary.FunctionName function;

	[SerializeField, Min(0f)]
	float functionDuration = 1f, transitionDuration = 1f;
	
	public enum TransitionMode { Cycle, Random };
	[SerializeField]
	TransitionMode transitionMode = 0;

	float duration = 0f;

	bool transitioning = false;
	FunctionLibrary.FunctionName transitionFunction;

	Transform[] points;

	private void Awake()
	{
		float step = 2f / resolution;
		var scale = Vector3.one * step;

		points = new Transform[resolution * resolution];
		for (int i = 0; i < points.Length; i++)
		{
			Transform point = points[i] = Instantiate(pointPrefab);
			point.localScale = scale;
			point.SetParent(transform);
		}
	}

    private void Update()
    {
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

		if (transitioning) {
			UpdateFunctionTransition();
        } else {
			UpdateFunction();
		}
	}

	void UpdateFunction()
    {
		FunctionLibrary.Function f = FunctionLibrary.GetFunction(function);
		float step = 2f / resolution;
		float time = Time.time;
		float v = 0.5f * step - 1f;
		for (int i = 0, x = 0, z = 0; i < points.Length; i++, x++)
		{
			if (x == resolution)
			{
				x = 0;
				z += 1;
				v = (z + 0.5f) * step - 1f;
			}

			float u = (x + 0.5f) * step - 1f;
			points[i].localPosition = f(u, v, time);
		}
	}

	void UpdateFunctionTransition() {
		FunctionLibrary.Function 
			from = FunctionLibrary.GetFunction(transitionFunction),
			to = FunctionLibrary.GetFunction(function);

		float progress = duration / transitionDuration;
		float step = 2f / resolution;
		float time = Time.time;
		float v = 0.5f * step - 1f;
		for (int i = 0, x = 0, z = 0; i < points.Length; i++, x++) {
			if (x == resolution) {
				x = 0;
				z += 1;
				v = (z + 0.5f) * step - 1f;
			}

			float u = (x + 0.5f) * step - 1f;
			points[i].localPosition = FunctionLibrary.Morph(u, v, time, from, to, progress);
		}
	}
}