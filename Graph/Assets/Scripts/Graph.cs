using UnityEngine;

public class Graph : MonoBehaviour {
	[SerializeField]
	Transform pointPrefab;

	[SerializeField, Range(10, 100)]
	int resolution = 10;

	[SerializeField]
	FunctionLibrary.FunctionName function;

	Transform[] points;

	private void Awake()
	{
		float step = 2f / resolution;
		var scale = Vector3.one * step;
		Vector3 position = Vector3.zero;

		int i = 0;
		points = new Transform[resolution];
		for (i = 0; i < resolution; i++)
		{
			Transform point = points[i] = Instantiate(pointPrefab);
			position.x = (i + 0.5f) * step - 1f;
			point.localPosition = position;
			point.localScale = scale;
			point.SetParent(transform);
		}
	}

    private void Update()
    {
		FunctionLibrary.Function f = FunctionLibrary.GetFunction(function);

		float time = Time.time;
        for (int i = 0; i < points.Length; i++)
        {
			Transform point = points[i];
			Vector3 position = point.localPosition;

			position.y = f(position.x, time);

			point.localPosition = position;
		}
    }
}