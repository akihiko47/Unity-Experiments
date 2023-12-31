using System.Collections;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class Grid : MonoBehaviour
{
    [SerializeField]
    int xSize, ySize;

    private Vector3[] vertices;

    private void Awake() {
        StartCoroutine(Generate());
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

    private IEnumerator Generate() {
        vertices = new Vector3[(xSize + 1) * (ySize + 1)];

        for (int y = 0, i = 0; y < ySize; y++, i++) {
            for (int x = 0; x < xSize; x++, i++) {
                vertices[i] = new Vector3(x, y, 0f);
                yield return new WaitForSeconds(0.05f);
            }
        }
    }
}
