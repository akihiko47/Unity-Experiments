using UnityEngine;
using UnityEditor;

public class MyLightingShaderGUI : ShaderGUI {

    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    static GUIContent staticLabel = new GUIContent();

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this.editor = materialEditor;
        this.properties = properties;
        this.target = materialEditor.target as Material;
        DoMain();
        DoSecondary();
    }

    void DoMain() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_Albedo");
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, FindProperty("_Tint"));

        DoNormals();
        DoMetallic();
        DoGlossiness();

        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoSecondary() {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");
        editor.TexturePropertySingleLine(MakeLabel(detailTex, "Albedo (RGB) * 2"), detailTex);

        DoSecondaryNormals();

        editor.TextureScaleOffsetProperty(detailTex);
    }

    void DoNormals() {
        MaterialProperty normalMap = FindProperty("_NormalMap");
        editor.TexturePropertySingleLine(MakeLabel(normalMap), normalMap, normalMap.textureValue ? FindProperty("_BumpScale") : null);
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

    void DoGlossiness() {
        MaterialProperty slider = FindProperty("_Gloss");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    void DoSecondaryNormals() {
        MaterialProperty map = FindProperty("_DetailNormalMap");
        editor.TexturePropertySingleLine(MakeLabel(map), map, map.textureValue ? FindProperty("_DetailBumpScale") : null);
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

}
