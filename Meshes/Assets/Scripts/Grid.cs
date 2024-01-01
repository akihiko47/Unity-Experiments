using System.Collections;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class Grid : MonoBehaviour
{
    [SerializeField]
    int xSize, ySize;

    private Vector3[] vertices;

    private Mesh mesh;

	private float timeElapsed = 0f;

    private void Awake() {
        Generate();
    }

    private void Update() {

		Animate();

		timeElapsed += Time.deltaTime;
    }

	private void Animate() {
		for (int i = 0; i < vertices.Length; i++) {
			vertices[i].z = Mathf.Sin(timeElapsed * Mathf.PI + vertices[i].x + vertices[i].y) - 1f;
		}

		GetComponent<MeshFilter>().mesh.vertices = vertices;
	}

    private void OnDrawGizmos() {
        if (vertices == null) {
            return;
        }

        Gizmos.color = Color.red;

        for (int i = 0; i < vertices.Length; i++) {
            Gizmos.DrawSphere(transform.TransformPoint(vertices[i]), 0.1f);
        }
    }

	private void Generate() {
		GetComponent<MeshFilter>().mesh = mesh = new Mesh();
		mesh.name = "Procedural Grid";

		vertices = new Vector3[(xSize + 1) * (ySize + 1)];
		for (int i = 0, y = 0; y <= ySize; y++) {
			for (int x = 0; x <= xSize; x++, i++) {
				vertices[i] = new Vector3(x, y);
			}
		}
		mesh.vertices = vertices;

		int[] triangles = new int[xSize * ySize * 6];
		for (int ti = 0, vi = 0, y = 0; y < ySize; y++, vi++) {
			for (int x = 0; x < xSize; x++, ti += 6, vi++) {
				triangles[ti] = vi;
				triangles[ti + 3] = triangles[ti + 2] = vi + 1;
				triangles[ti + 4] = triangles[ti + 1] = vi + xSize + 1;
				triangles[ti + 5] = vi + xSize + 2;
			}
		}
		mesh.triangles = triangles;
	}
}
