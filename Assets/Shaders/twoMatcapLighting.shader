Shader "Custom/Two Matcap Lighting"
{
	Properties
	{
		[NoScaleOffset] 	_LitTex ("Lit Matcap", 2D) = "white" {}
		[NoScaleOffset] 	_ShadowTex("Shadow Matcap", 2D) = "black" {}
		[HideInInspector]	_NormalTex("Normal Map", 2D) = "bump" {}
		_LightRamp("Light Ramp", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			// compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            // shadow helper functions and macros
            #include "AutoLight.cginc"

			//struct appdata
			//{
			//	float4 vertex : POSITION;
			//	float2 uv : TEXCOORD0;
			//	float3 normal	: NORMAL;
			//};

			struct v2f
			{
				float2 LitTex_uv	: TEXCOORD0;
				float2 ShadowTex_uv	: TEXCOORD1;
				float2 NormalTex_uv	: TEXCOORD2;

				float3 TtoV0		: TEXCOORD3;
				float3 TtoV1		: TEXCOORD4;

				float4 pos			: SV_POSITION;
				float4 diff			: COLOR0;
				UNITY_FOG_COORDS(1)
				SHADOW_COORDS(5) // put shadows data into TEXCOORD4
			};

			sampler2D _LitTex;
			float4 _LitTex_ST;
			sampler2D _ShadowTex;
			float4 _ShadowTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;

			float _LightRamp;
			
			v2f vert ( appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//o.uv = v.texcoord;
				//o.uv = TRANSFORM_TEX(v.texcoord, _LitTex);
				o.LitTex_uv = TRANSFORM_TEX(v.texcoord, _LitTex);
				o.ShadowTex_uv = TRANSFORM_TEX(v.texcoord, _ShadowTex);
				o.NormalTex_uv = TRANSFORM_TEX(v.texcoord, _NormalTex);

				UNITY_TRANSFER_FOG(o,o.vertex);

				//calculate diffuse shading
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half NdotL = max(0,dot(worldNormal, _WorldSpaceLightPos0.xyz));
				o.diff = NdotL;

				TANGENT_SPACE_ROTATION;
				o.TtoV0 = mul(rotation, UNITY_MATRIX_IT_MV[0].xyz);
				o.TtoV1 = mul(rotation, UNITY_MATRIX_IT_MV[1].xyz);

				TRANSFER_SHADOW(o) //compute shadow data
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed cast_shadow = SHADOW_ATTENUATION(i);
				fixed lighting = saturate((i.diff * cast_shadow) * _LightRamp);

				float3 normal = UnpackNormal(tex2D(_NormalTex, i.NormalTex_uv));
				half2 vn;
				vn.x = dot(i.TtoV0, normal);
				vn.y = dot(i.TtoV1, normal);

				//blend textures based on lighting
				fixed4 lit = tex2D(_LitTex, vn*0.5 + 0.5);
				fixed4 shadow = tex2D(_ShadowTex, vn*0.5 + 0.5);
				fixed4 col = lerp(shadow, lit, lighting);
				//fixed4 col = lit;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		//support for casting shadows
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
