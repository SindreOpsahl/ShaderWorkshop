using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class CatlikeShaderGUI : ShaderGUI {

	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;

	public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties) 
	{
		this.target = editor.target as Material;
		this.editor = editor;
		this.properties = properties;
		DoRenderingMode();
		DoMain();
		DoSecondary();
	}

	void DoMain()
	{
		GUILayout.Label("Main Maps", EditorStyles.boldLabel);

		MaterialProperty mainTex = FindProperty("_MainTex");
		editor.TexturePropertySingleLine(
			MakeLabel(mainTex, "Albedo (RGB)"), 
			mainTex, 
			FindProperty("_Tint")
		);
		if (showAlphaCutoff){DoAlphaCutoff();}
		DoSmoothness();
		DoMetallic();
		DoNormals();
		DoOcclusion();
		DoEmission();
		DoDetailMask();
		editor.TextureScaleOffsetProperty(mainTex);
	}

	void DoSecondary()
	{
		GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);
		MaterialProperty detailTex = FindProperty("_DetailTex");
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(detailTex, "Albedo (RGB) multipled by 2"),
			detailTex
		);
		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
		}
		DoSecondaryNormals();
		editor.TextureScaleOffsetProperty(detailTex);
	}

	enum RenderingMode {Opaque, Cutout, Fade}

	struct RenderingSettings
	{
		public RenderQueue queue;
		public string renderType;

		public static RenderingSettings[] modes =
		{
			new RenderingSettings()
			{
				queue = RenderQueue.Geometry,
				renderType = ""
			},
			new RenderingSettings()
			{
				queue = RenderQueue.AlphaTest,
				renderType = "TransparentCutout"
			},
			new RenderingSettings()
			{
				queue = RenderQueue.Transparent,
				renderType = "Transparent"
			}
		};
	}

	bool showAlphaCutoff;

	void DoRenderingMode () 
	{
		RenderingMode mode = RenderingMode.Opaque;
		showAlphaCutoff = false;
		if (IsKeywordEnabled("_RENDERING_CUTOUT")) 
		{
			mode = RenderingMode.Cutout;
			showAlphaCutoff = true;
		}
		else if (IsKeywordEnabled("_RENDERING_FADE"))
		{
			mode = RenderingMode.Fade;
		}

		EditorGUI.BeginChangeCheck();
		mode = (RenderingMode)EditorGUILayout.EnumPopup
		(
			MakeLabel("Rendering Mode"), mode
		);

		if (EditorGUI.EndChangeCheck()) 
		{
			RecordAction("Rendering Mode");
			SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
			SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
		}

		RenderingSettings settings = RenderingSettings.modes[(int)mode];
		foreach (Material m in editor.targets)
		{
			m.renderQueue = (int)settings.queue;
			m.SetOverrideTag("RenderType", settings.renderType);
		}
	}

	void DoAlphaCutoff () 
	{
		MaterialProperty slider = FindProperty("_AlphaCutoff");
		EditorGUI.indentLevel += 2;
		editor.ShaderProperty(slider, MakeLabel(slider));
		EditorGUI.indentLevel -= 2;
	}

	void DoNormals()
	{
		MaterialProperty map = FindProperty("_NormalMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(map), 
			map, 
			tex ? FindProperty("_BumpScale") : null
		);
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue) 
		{
			SetKeyword("_NORMAL_MAP", map.textureValue);
		}
	}

	void DoSecondaryNormals()
	{
		MaterialProperty map = FindProperty("_DetailNormalMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(map),
			map,
			tex ? FindProperty("_DetailBumpScale") : null
		);
		if (EditorGUI.EndChangeCheck()&& tex != map.textureValue) 
		{
			SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
		}
	}

	void DoMetallic()
	{
		MaterialProperty map = FindProperty("_MetallicMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(map, "Metallic (R)"),
			map, 
			tex ? null : FindProperty("_Metallic")
			);
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
		{
			SetKeyword("_METALLIC_MAP", map.textureValue);
		}
	}

	void DoDetailMask() 
	{
		MaterialProperty mask = FindProperty("_DetailMask");
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(mask, "Detail Mask (A)"), mask
		);
		if (EditorGUI.EndChangeCheck()) {
			SetKeyword("_DETAIL_MASK", mask.textureValue);
		}
	}

	enum SmoothnessSource {Uniform, Albedo, Metallic}

	void DoSmoothness()
	{
		SmoothnessSource source = SmoothnessSource.Uniform;
		if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
		{
			source = SmoothnessSource.Albedo;	
		}
		else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC"))
		{
			source = SmoothnessSource.Metallic;
		}

		MaterialProperty slider = FindProperty("_Smoothness");
		EditorGUI.indentLevel += 2;
		editor.ShaderProperty(slider, MakeLabel(slider));
		EditorGUI.indentLevel += 1;

		EditorGUI.BeginChangeCheck();
		source = (SmoothnessSource)EditorGUILayout.EnumPopup("Source", source);
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Smoothness Source");
			SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
			SetKeyword("_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic);
		}
		EditorGUI.indentLevel -= 3;
	}

	void DoOcclusion()
	{
		MaterialProperty map = FindProperty("_OcclusionMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(map, "Occlusion (G)"),
			map,
			tex ? FindProperty("_OcclusionStrength") : null
			);
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
		{
			SetKeyword("_OCCLUSION_MAP", map.textureValue);
		}
	}

	void DoEmission()
	{
		MaterialProperty map = FindProperty("_EmissionMap");
		Texture tex = map.textureValue;
		ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertyWithHDRColor(
			MakeLabel(map, "Emission (RGB)"),
			map,
			FindProperty("_Emission"),
			emissionConfig,
			false
		);
		if(EditorGUI.EndChangeCheck() && tex != map.textureValue)
		{
			SetKeyword("_EMISSION_MAP", map.textureValue);
		}
	}

	MaterialProperty FindProperty (string name)
	{
		return FindProperty(name, properties);
	}

	static GUIContent staticLabel = new GUIContent();

	static GUIContent MakeLabel (MaterialProperty property, string tooltip = null)
	{
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}

	static GUIContent MakeLabel (string text, string tooltip = null) 
	{
		staticLabel.text = text;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}

	bool IsKeywordEnabled (string keyword)
	{
		return target.IsKeywordEnabled(keyword);
	}

	void SetKeyword (string keyword, bool state)
	{
		if (state)
		{
			foreach (Material m in editor.targets)
			{
				m.EnableKeyword(keyword);
			}
		}
		else
		{
			foreach (Material m in editor.targets)
			{
				m.DisableKeyword(keyword);
			}
		}
	}

	void RecordAction (string label)
	{
		editor.RegisterPropertyChangeUndo(label);
	}
}
