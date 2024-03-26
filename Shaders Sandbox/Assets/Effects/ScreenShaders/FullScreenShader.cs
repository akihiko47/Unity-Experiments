using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class FullScreenShader : MonoBehaviour {

    [SerializeField]
    private Shader _screenShader;

    private Material _renderMaterial;

    private Camera _currentCamera;

    private void Start() {
        if (_screenShader == null) {
            _renderMaterial = null;
            return;
        } 
        
        _renderMaterial = new Material(_screenShader);
        _currentCamera = GetComponent<Camera>();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (_renderMaterial == null) {
            Graphics.Blit(source, destination);
            return;
        }

        _renderMaterial.SetMatrix("_FrustumCornersMatrix", GetFrustumCorners(_currentCamera));
        _renderMaterial.SetMatrix("_CameraToWorldMatrix", _currentCamera.cameraToWorldMatrix);
        _renderMaterial.SetVector("_CameraWorldPos", _currentCamera.transform.position);

        Graphics.Blit(source, destination, _renderMaterial);
    }

    private Matrix4x4 GetFrustumCorners(Camera cam) {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }

}
