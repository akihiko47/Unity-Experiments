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
        public Vector3 direction, worldPosition;
        public Quaternion rotation, worldRotation;
        public float spinAngle;
    }

    FractalPart[][] parts;

    Matrix4x4[][] matrices;

    ComputeBuffer[] matricesBuffers;


    private void OnEnable() {
        parts = new FractalPart[depth][];
        matrices = new Matrix4x4[depth][];
        matricesBuffers = new ComputeBuffer[depth];

        int length = 1;
        for (int i = 0; i < depth; i++) {
            parts[i] = new FractalPart[length];
            matrices[i] = new Matrix4x4[length];
            matricesBuffers[i] = new ComputeBuffer(length, 16 * 4);
            length *= 5;
        }

        parts[0][0] = CreatePart(0);
        for (int li = 1; li < parts.Length; li++) {  // level iterator
            FractalPart[] levelParts = parts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi++) {  // fractal part indicator
                levelParts[fpi] = CreatePart(fpi % 5);
            }
        }
    }

    private void OnDisable() {
        for (int i = 0; i < depth; i++) {
            matricesBuffers[i].Release();
        }
        parts = null;
        matrices = null;
        matricesBuffers = null;
    }

    private void OnValidate() {
        if (parts != null && enabled) {
            OnDisable();
            OnEnable();
        }
    }

    private void Update() {
        float spinAngleDelta = 22.5f * Time.deltaTime;
        FractalPart rootPart = parts[0][0];
        rootPart.spinAngle += spinAngleDelta;
        rootPart.worldRotation = rootPart.rotation * Quaternion.Euler(0f, rootPart.spinAngle, 0f);
        parts[0][0] = rootPart;
        matrices[0][0] = Matrix4x4.TRS(rootPart.worldPosition, rootPart.worldRotation, Vector3.one);

        float scale = 1f;
        for (int li = 1; li < parts.Length; li++) {
            scale *= 0.5f;
            for (int fpi = 0; fpi < parts[li].Length; fpi++) {
                FractalPart parent = parts[li - 1][fpi / 5];
                FractalPart part = parts[li][fpi];

                part.spinAngle += spinAngleDelta;
                part.worldRotation = parent.worldRotation * (part.rotation * Quaternion.Euler(0f, part.spinAngle, 0f));

                part.worldPosition = parent.worldPosition + parent.worldRotation * (1.5f * scale * part.direction);

                parts[li][fpi] = part;
                matrices[li][fpi] = Matrix4x4.TRS(part.worldPosition, part.worldRotation, scale * Vector3.one);
            }
        }

        for (int i = 0; i < depth; i++) {
            matricesBuffers[i].SetData(matrices[i]); 
        }
    }

    FractalPart CreatePart(int childIndex) {
        return new FractalPart
        {
            direction = directions[childIndex],
            rotation = rotations[childIndex],
        };
    }
}

