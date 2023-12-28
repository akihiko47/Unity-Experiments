using UnityEngine;

public class Fractal : MonoBehaviour {

    [SerializeField, Range(1, 8)]
    int depth = 4;

    [SerializeField]
    Mesh mesh;

    [SerializeField]
    Material material;

    static Vector3[] directions = { Vector3.up, Vector3.right, Vector3.left, Vector3.forward, Vector3.back };

    static Quaternion[] rotations = {
        Quaternion.identity,
        Quaternion.Euler(0f, 0f, -90f), Quaternion.Euler(0f, 0f, 90f),
        Quaternion.Euler(90f, 0f, 0f), Quaternion.Euler(-90f, 0f, 0f)
    };

    struct FractalPart {
        public Vector3 direction;
        public Quaternion rotation;
        public Transform transform;
    }

    FractalPart[][] parts;


    private void Awake() {
        parts = new FractalPart[depth][];

        int length = 1;
        for (int i = 0; i < depth; i++) {
            parts[i] = new FractalPart[length];
            length *= 5;
        }

        float scale = 1f;
        parts[0][0] = CreatePart(0, 0, scale);
        for (int li = 1; li < parts.Length; li++) {  // level iterator
            scale *= 0.5f;
            FractalPart[] levelParts = parts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi++) {  // fractal part indicator
                levelParts[fpi] = CreatePart(li, fpi % 5, scale);
            }
        }
    }

    private void Update() {
        Quaternion deltaRotation = Quaternion.Euler(0f, 22.5f * Time.deltaTime, 0f);
        FractalPart rootPart = parts[0][0];
        rootPart.rotation = rootPart.rotation * deltaRotation;
        rootPart.transform.localRotation = rootPart.rotation;
        parts[0][0] = rootPart;

        for (int li = 1; li < parts.Length; li++) {
            for (int fpi = 0; fpi < parts[li].Length; fpi++) {
                Transform parentTransform = parts[li - 1][fpi / 5].transform;
                FractalPart part = parts[li][fpi];

                part.rotation *= deltaRotation;
                part.transform.localRotation = parentTransform.rotation * part.rotation;

                part.transform.localPosition = parentTransform.localPosition + parentTransform.localRotation * (1.5f * part.transform.localScale.x * part.direction);

                parts[li][fpi] = part;
            }
        }
    }

    FractalPart CreatePart(int levelIndex, int childIndex, float scale) {
        GameObject go = new GameObject("Fractal Part L" + levelIndex + " C" + childIndex);
        go.transform.SetParent(transform, false);
        go.AddComponent<MeshFilter>().mesh = mesh;
        go.AddComponent<MeshRenderer>().material = material;
        go.transform.localScale = scale * Vector3.one;

        return new FractalPart
        {
            direction = directions[childIndex],
            rotation = rotations[childIndex],
            transform = go.transform
        };
    }
}

