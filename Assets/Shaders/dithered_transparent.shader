Shader "Custom/dithered_transparent" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0,1))=0.5
		_DitherPattern ("Dither Pattern", 2D) = "white" {}
		_DitherSteps ("Dither Steps", Float) = 8
	}
	SubShader {
		Tags { "RenderType"="Opaque"}
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _DitherPattern;
		float _DitherSteps;
		float _Cutoff;

		struct Input {
			float2 uv_MainTex;
			//float2 uv_DitherPattern;
			float4 screenPos;
		};

		fixed4 _Color;

    	//void UnityApplyDitherCrossFade(float2 vpos)
    	//{
    	//    vpos /= 4; // the dither mask texture is 4x4
    	//    vpos.y = frac(vpos.y) * 0.0625 /* 1/16 */ + unity_LODFade.y; // quantized lod fade by 16 levels
    	//    clip(tex2D(_DitherPattern, vpos).a - 0.5);
    	//}

    	//void ApplyDither(float mask, float2 vpos)
    	//{
    	//    vpos /= _DitherSteps; // the dither mask texture is 4x4
    	//    vpos.x = frac(vpos.x) * (1 / (_DitherSteps * _DitherSteps)) + mask;
    	//    clip(tex2D(_DitherPattern, vpos).a - 0.5);
    	//}


		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			c.a = clamp( 1- c.a, 0, 0.99);
    		float2 vpos = IN.screenPos.xy / IN.screenPos.w;// * _ScreenParams.xy;
    		vpos.y = fmod(vpos.y, (1/_DitherSteps)) + floor(c.a*_DitherSteps)/_DitherSteps;// + floor(_Cutoff * _DitherSteps);
    		//vpos.y = frac(vpos.y);
			//vpos /= _DitherSteps; // the dither mask texture is 4x4
    		//vpos.x = frac(vpos.x) * 0.015625 /* 1/64 */ + _Color.a; // quantized lod fade by 16 levels


    	    //vpos = fmod(vpos, (1/_DitherSteps)) + fmod (_Color.a, _DitherSteps);// * (1 / pow(_DitherSteps,2));
    	    //vpos =+ frac(_Color.a);
    	    //clip(tex2D(_DitherPattern, vpos).a - 0.5);
			//ApplyDither(_Color.a, vpos);
			// Metallic and smoothness come from slider variables
			o.Albedo = c.rgb;
			clip(tex2D(_DitherPattern, vpos)- _Cutoff);
			//o.Albedo = float3( ceil(_Cutoff*8)/8 ,0,0);
			
			o.Alpha = _Color.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
