using UnityEngine;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;

using static Unity.Mathematics.math;
using quaternion = Unity.Mathematics.quaternion;

public class Fractal : MonoBehaviour {

    [SerializeField, Range(2, 8)]
    int depth = 4;

    [SerializeField]
    Mesh mesh;

    [SerializeField]
    Material material;

    [SerializeField]
    Gradient gradient;

    static float3[] directions = { up(), right(), left(), forward(), back() };

    static quaternion[] rotations = {
        quaternion.identity,
        quaternion.RotateZ(-0.5f * PI), quaternion.RotateZ(0.5f * PI),
        quaternion.RotateX(0.5f * PI), quaternion.RotateX(-0.5f * PI)
    };

    struct FractalPart {
        public float3 direction, worldPosition;
        public quaternion rotation, worldRotation;
        public float spinAngle;
    }

    NativeArray<FractalPart>[] parts;
    NativeArray<float3x4>[] matrices;

    ComputeBuffer[] matricesBuffers;

    static readonly int matricesId = Shader.PropertyToID("_Matrices"),
                        baseColorId = Shader.PropertyToID("_BaseColor");

    static MaterialPropertyBlock propertyBlock;

    [BurstCompile(FloatPrecision.Standard, FloatMode.Fast, CompileSynchronously = true)]
    struct UpdateFractalLevelJob : IJobFor {
        public NativeArray<FractalPart> levelParts;

        [WriteOnly]
        public NativeArray<float3x4> levelMatrices;

        [ReadOnly]
        public NativeArray<FractalPart> parents;

        public float spinAngleDelta;
        public float scale;
        
        public void Execute(int i) {
            FractalPart parent = parents[i / 5];
            FractalPart part = levelParts[i];

            part.spinAngle += spinAngleDelta;
            part.worldRotation = mul(parent.worldRotation, mul(part.rotation, quaternion.RotateY(part.spinAngle)));

            part.worldPosition = parent.worldPosition + mul(parent.worldRotation, (1.5f * scale * part.direction));

            levelParts[i] = part;

            float3x3 r = float3x3(part.worldRotation) * scale;
            levelMatrices[i] = float3x4(r.c0, r.c1, r.c2, part.worldPosition);
        }
    }


    private void OnEnable() {
        parts = new NativeArray<FractalPart>[depth];
        matrices = new NativeArray<float3x4>[depth];

        matricesBuffers = new ComputeBuffer[depth];

        if (propertyBlock == null) {
            propertyBlock = new MaterialPropertyBlock();
        }

        int length = 1;
        for (int i = 0; i < depth; i++) {
            parts[i] = new NativeArray<FractalPart>(length, Allocator.Persistent);
            matrices[i] = new NativeArray<float3x4>(length, Allocator.Persistent);
            matricesBuffers[i] = new ComputeBuffer(length, 12 * 4);
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
        float spinAngleDelta = 0.125f * PI * Time.deltaTime;
        FractalPart rootPart = parts[0][0];
        rootPart.spinAngle += spinAngleDelta;
        rootPart.worldRotation = mul(transform.rotation, mul(rootPart.rotation, quaternion.RotateY(rootPart.spinAngle)));
        rootPart.worldPosition = transform.position;

        float objectScale = transform.lossyScale.x;
        parts[0][0] = rootPart;

        float3x3 r = float3x3(rootPart.rotation) * objectScale;
        matrices[0][0] = float3x4(r.c0, r.c1, r.c2, rootPart.worldPosition);

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
            }.ScheduleParallel(parts[li].Length, 5, jobHandle);
        }
        jobHandle.Complete();

        var bounds = new Bounds(rootPart.worldPosition, 3f * float3(objectScale));
        for (int i = 0; i < matricesBuffers.Length; i++) {
            ComputeBuffer buffer = matricesBuffers[i];
            buffer.SetData(matrices[i]);
            propertyBlock.SetColor(baseColorId, gradient.Evaluate(i / (matricesBuffers.Length - 1f)));
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

