using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class FullScreenShader : MonoBehaviour {

    [SerializeField]
    private Shader _screenShader;

    private Material _renderMaterial;

    private void Start() {
        if (_screenShader == null) {
            _renderMaterial = null;
            return;
        } 
        
        _renderMaterial = new Material(_screenShader);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (_renderMaterial == null) {
            Graphics.Blit(source, destination);
            return;
        }

        Graphics.Blit(source, destination, _renderMaterial);
    }

}
