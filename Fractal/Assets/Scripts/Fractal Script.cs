using UnityEngine;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;

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

    NativeArray<FractalPart>[] parts;
    NativeArray<Matrix4x4>[] matrices;

    ComputeBuffer[] matricesBuffers;

    static readonly int matricesId = Shader.PropertyToID("_Matrices");

    static MaterialPropertyBlock propertyBlock;

    struct UpdateFractalLevelJob : IJobFor {
        public NativeArray<FractalPart> levelParts;

        [WriteOnly]
        public NativeArray<Matrix4x4> levelMatrices;

        [ReadOnly]
        public NativeArray<FractalPart> parents;

        public float spinAngleDelta;
        public float scale;
        
        public void Execute(int i) {
            FractalPart parent = parents[i / 5];
            FractalPart part = levelParts[i];

            part.spinAngle += spinAngleDelta;
            part.worldRotation = parent.worldRotation * (part.rotation * Quaternion.Euler(0f, part.spinAngle, 0f));

            part.worldPosition = parent.worldPosition + parent.worldRotation * (1.5f * scale * part.direction);

            levelParts[i] = part;
            levelMatrices[i] = Matrix4x4.TRS(part.worldPosition, part.worldRotation, scale * Vector3.one);
        }
    }


    private void OnEnable() {
        parts = new NativeArray<FractalPart>[depth];
        matrices = new NativeArray<Matrix4x4>[depth];

        matricesBuffers = new ComputeBuffer[depth];

        if (propertyBlock == null) {
            propertyBlock = new MaterialPropertyBlock();
        }

        int length = 1;
        for (int i = 0; i < depth; i++) {
            parts[i] = new NativeArray<FractalPart>(length, Allocator.Persistent);
            matrices[i] = new NativeArray<Matrix4x4>(length, Allocator.Persistent);
            matricesBuffers[i] = new ComputeBuffer(length, 16 * 4);
            length *= 5;
        }

        parts[0][0] = CreatePart(0);
        for (int li = 1; li < parts.Length; li++) {  // level iterator
            NativeArray<FractalPart> levelParts = parts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi++) {  // fractal part indicator
                levelParts[fpi] = CreatePart(fpi % 5);
            }
        }
    }

    private void OnDisable() {
        for (int i = 0; i < matricesBuffers.Length; i++) {
            matricesBuffers[i].Release();
            parts[i].Dispose();
            matrices[i].Dispose();
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
        rootPart.worldRotation = transform.rotation * rootPart.rotation * Quaternion.Euler(0f, rootPart.spinAngle, 0f);
        rootPart.worldPosition = transform.position;

        float objectScale = transform.lossyScale.x;
        parts[0][0] = rootPart;
        matrices[0][0] = Matrix4x4.TRS(rootPart.worldPosition, rootPart.worldRotation, objectScale * Vector3.one);

        float scale = objectScale;

        JobHandle jobHandle = default;
        for (int li = 1; li < parts.Length; li++) {
            scale *= 0.5f;

            jobHandle = new UpdateFractalLevelJob {
                levelParts = parts[li],
                levelMatrices = matrices[li],
                parents = parts[li - 1],
                spinAngleDelta = spinAngleDelta,
                scale = scale,
            }.Schedule(parts[li].Length, jobHandle);
        }
        jobHandle.Complete();

        var bounds = new Bounds(rootPart.worldPosition, 3f * Vector3.one * objectScale);
        for (int i = 0; i < matricesBuffers.Length; i++) {
            ComputeBuffer buffer = matricesBuffers[i];
            buffer.SetData(matrices[i]);
            propertyBlock.SetBuffer(matricesId, buffer);
            Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, buffer.count, propertyBlock);
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

