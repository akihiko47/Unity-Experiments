using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class MyLightingShaderGUI : ShaderGUI {

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    static GUIContent staticLabel = new GUIContent();

    enum SmoothnessSource {
        Uniform, Albedo, Metallic
    }

    bool alphaCutoutVisible;

    enum RenderingMode {
        Opaque, Cutout
    }

    [System.Obsolete]
    static ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this.editor = materialEditor;
        this.properties = properties;
        this.target = materialEditor.target as Material;
        DoRenderingMode();
        DoMain();
        DoSecondary();
    }

    [System.Obsolete]
    void DoMain() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_Albedo");
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, FindProperty("_Tint"));

        DoAlphaCutoff();

        DoMetallic();
        DoGlossiness();

        DoNormals();
        DoOcclusion();
        DoEmission();
        DoDetailMask();

        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoSecondary() {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(detailTex, "Albedo (RGB) * 2"), detailTex);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }

        DoSecondaryNormals();

        editor.TextureScaleOffsetProperty(detailTex);
    }

    void DoNormals() {
        MaterialProperty normalMap = FindProperty("_NormalMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(normalMap),
            normalMap,
            normalMap.textureValue ? FindProperty("_BumpScale") : null);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_NORMAL_MAP", normalMap.textureValue);
        }
    }

    void DoMetallic() {
        MaterialProperty map = FindProperty("_MetallicMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Metallic (R)"),
            map,
            map.textureValue ? null : FindProperty("_Metallic")
        );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_METALLIC_MAP", map.textureValue);
        }
    }

    [System.Obsolete]
    void DoEmission() {
        MaterialProperty map = FindProperty("_EmissionMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(
            MakeLabel("Emission (RGB)"), map, FindProperty("_Emission"),
            emissionConfig, false
        );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_EMISSION_MAP", map.textureValue);
        }
    }

    void DoOcclusion() {
        MaterialProperty map = FindProperty("_OcclusionMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map, "Occlusion (G)"),
            map,
            map.textureValue ? FindProperty("_OcclusionStrength") : null
        );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_OCCLUSION_MAP", map.textureValue);
        }
    }

    void DoDetailMask() {
        MaterialProperty mask = FindProperty("_DetailMask");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(mask, "Detail Mask (A)"), mask
        );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_MASK", mask.textureValue);
        }
    }

    void DoRenderingMode() {
        RenderingMode mode = RenderingMode.Opaque;
        alphaCutoutVisible = false;
        if (IsKeywordEnabled("_RENDERING_CUTOUT")) {
            mode = RenderingMode.Cutout;
            alphaCutoutVisible = true;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);
        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);

            RenderQueue queue = mode == RenderingMode.Opaque ? RenderQueue.Geometry : RenderQueue.AlphaTest;
            string renderType = mode == RenderingMode.Opaque ? "" : "TransparentCutout";
            foreach (Material m in editor.targets) {
                m.renderQueue = (int)queue;
                m.SetOverrideTag("RenderType", renderType);
            }
        }
    }

    void DoAlphaCutoff() {
        if (alphaCutoutVisible) {
            MaterialProperty slider = FindProperty("_AlphaCutoff");
            EditorGUI.indentLevel += 2;
            editor.ShaderProperty(slider, MakeLabel(slider));
            EditorGUI.indentLevel -= 2;
        }
    }

    void DoGlossiness() {
        SmoothnessSource source = SmoothnessSource.Uniform;
        if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO")) {
            source = SmoothnessSource.Albedo;
        } else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC")) {
            source = SmoothnessSource.Metallic;
        }

        MaterialProperty slider = FindProperty("_Gloss");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));

        EditorGUI.BeginChangeCheck();
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"), source);
        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Smoothness Source");
            SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
            SetKeyword("_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic);
        }

        EditorGUI.indentLevel -= 2;
    }

    void DoSecondaryNormals() {
        MaterialProperty map = FindProperty("_DetailNormalMap");
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(
            MakeLabel(map),
            map,
            map.textureValue ? FindProperty("_DetailBumpScale") : null);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
        }
    }

    MaterialProperty FindProperty(string name) {
        return FindProperty(name, properties);
    }

    static GUIContent MakeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null) {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword(string keyword, bool state) {
        if (state) {
            target.EnableKeyword(keyword);
        } else {
            target.DisableKeyword(keyword);
        }
    }

    bool IsKeywordEnabled(string keyword) {
        return target.IsKeywordEnabled(keyword);
    }

    void RecordAction(string label) {
        editor.RegisterPropertyChangeUndo(label);
    }

}
