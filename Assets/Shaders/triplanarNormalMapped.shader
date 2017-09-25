Shader "Custom/triplanarNormalMapped" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_BumpMap ("Normal Map", 2D) = "white" {}
		_BlendPower ("Blend Sharpness", Float) = 4
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
		#include "NormalBlendFunctions.cginc"

		sampler2D _BumpMap;

		struct Input {
			float2 uv_BumpMap;
			float3 worldPos;
			float3 worldNormal; 
			INTERNAL_DATA 
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _BlendPower;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = _Color;

			// Triplanar uvs
			float2 uvX = IN.worldPos.zy; // x facing plane
			float2 uvY = IN.worldPos.xz; // y facing plane
			float2 uvZ = IN.worldPos.xy; // z facing plane
			// Tangent space normal maps
			half3 tnormalX = UnpackNormal(tex2D(_BumpMap, uvX));
			half3 tnormalY = UnpackNormal(tex2D(_BumpMap, uvY));
			half3 tnormalZ = UnpackNormal(tex2D(_BumpMap, uvZ));
			// Get absolute value of normal to ensure positive tangent "z" for blend
			half3 absVertNormal = abs(IN.worldNormal);
			// Swizzle world normals to match tangent space and apply RNM blend
			tnormalX = rnmBlendUnpacked(half3(IN.worldNormal.zy, absVertNormal.x), tnormalX);
			tnormalY = rnmBlendUnpacked(half3(IN.worldNormal.xz, absVertNormal.y), tnormalY);
			tnormalZ = rnmBlendUnpacked(half3(IN.worldNormal.xy, absVertNormal.z), tnormalZ);
			// Get the sign (-1 or 1) of the surface normal
			half3 axisSign = sign(IN.worldNormal);
			// Reapply sign to Z
			tnormalX.z *= axisSign.x;
			tnormalY.z *= axisSign.y;
			tnormalZ.z *= axisSign.z;

			// Triblend normals and add to world normal
			/*float3 blend = pow(IN.worldNormal.xyz, 4);
			blend /= dot(blend, float3(1,1,1));*/
			
			half3 blend = pow (abs(IN.worldNormal), 4);
			// Divide our blend mask by the sum of it's components, this will make x+y+z=1
			//blend = (blend.x + blend.y + blend.z);
			
			half3 triNormal = normalize(
			    tnormalX.xyz * blend.x +
			    tnormalY.xyz * blend.y +
			    tnormalZ.xyz * blend.z //+
			    //IN.worldNormal
			    );

			o.Normal = triNormal;
			float3 worldNormal = WorldNormalVector (IN, o.Normal);
			o.Albedo = triNormal;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
