Shader "Custom/normalBlend_RNM" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Normal Map 1", 2D) = "white" {}
		_SecondTex ("Normal Map 2", 2D) = "white" {}
		_Blend ("Normal Blend", Range(0,1)) = 1
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#include "UnityCG.cginc"
		#include "NormalBlendFunctions.cginc"

		sampler2D _MainTex;
		sampler2D _SecondTex;

		struct Input {
			float2 uv_MainTex;
			float2 uv_SecondTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _Blend;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = _Color;
			fixed3 tex1 = UnpackNormal(tex2D (_MainTex, IN.uv_MainTex));
			fixed3 tex2 = UnpackNormal(tex2D (_SecondTex, IN.uv_SecondTex));

			fixed3 blended = rnmBlendUnpackedClampZ(tex1, tex2);

			o.Albedo = c.rgb;
			o.Normal = lerp(tex1, blended, _Blend);

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG 
	}
	FallBack "Diffuse"
}
