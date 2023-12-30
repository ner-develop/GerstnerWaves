Shader "GerstnerWaves"
{
	Properties
	{
		_Albedo ("Albedo", Color) = (1, 1, 1, 1)
		
		[Header(Wave1)]
		[MaterialToggle] _Active1 ("Active1", Float) = 1
		_Direction1X ("Direction1X", Range(-1, 1)) = 1
		_Direction1Z ("Direction1Z", Range(-1, 1)) = 0
		_Amplitude1 ("Amplitude1", Float) = 1
		_WaveLength1 ("WaveLength1", Float) = 1
		_Speed1 ("Speed1", Float) = 1
		_QRatio1 ("Q Ratio1", Range(0, 1)) = 1
		
		[Header(Wave2)]
		[MaterialToggle] _Active2 ("Active2", Float) = 1
		_Direction2X ("Direction2X", Range(-1, 1)) = 1
		_Direction2Z ("Direction2Z", Range(-1, 1)) = 0
		_Amplitude2 ("Amplitude2", Float) = 1
		_WaveLength2 ("WaveLength2", Float) = 1
		_Speed2 ("Speed2", Float) = 1
		_QRatio2 ("Q Ratio2", Range(0, 1)) = 1
		
		[Header(Wave3)]
		[MaterialToggle] _Active3 ("Active3", Float) = 1
		_Direction3X ("Direction3X", Range(-1, 1)) = 1
		_Direction3Z ("Direction3Z", Range(-1, 1)) = 0
		_Amplitude3 ("Amplitude3", Float) = 1
		_WaveLength3 ("WaveLength3", Float) = 1
		_Speed3 ("Speed3", Float) = 1
		_QRatio3 ("Q Ratio3", Range(0, 1)) = 1
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
			"UniversalMaterialType" = "Lit"
			"IgnoreProjector" = "True"
		}
		LOD 300

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _Albedo;

		float _Active1;
		float _Direction1X;
		float _Direction1Z;
		float _Amplitude1;
		float _WaveLength1;
		float _Speed1;
		float _QRatio1;

		float _Active2;
		float _Direction2X;
		float _Direction2Z;
		float _Amplitude2;
		float _WaveLength2;
		float _Speed2;
		float _QRatio2;

		float _Active3;
		float _Direction3X;
		float _Direction3Z;
		float _Amplitude3;
		float _WaveLength3;
		float _Speed3;
		float _QRatio3;
		CBUFFER_END

		ENDHLSL

		Pass
		{
			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			Blend SrcAlpha OneMinusSrcAlpha
			ZTest LEqual
			ZWrite On
			Cull Back

			HLSLPROGRAM
			#pragma vertex ProcessVertex
			#pragma fragment ProcessFragment
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float4 normalOS : NORMAL;
				float2 texcoord : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : NORMAL;
				float3 positionWS : TEXCOORD0;
			};

			/// <summary>
			/// 位置ずれ
			/// </summary>
			/// <param name="xy"> 元の座標 </param>
			/// <param name="QRatio"> Qの割合0~1 </param>
			/// <param name="A"> Amplitude </param>
			/// <param name="D"> Direction </param>
			/// <param name="t"> Time </param>
			/// <param name="L"> WaveLength </param>
			/// <param name="S"> Speed </param>
			float3 ShiftPosition(const float2 xy, const half QRatio, const half A, const half2 D, const float t, const float L, const float S)
			{
				const float w = 2 * PI / L;
				const float phi = S * w;
				const float Q = (1 / (w * A)) * QRatio;
				const float theta = w * dot(D, xy) + phi * t;
				return float3(
					Q * A * D.x * cos(theta),
					Q * A * D.y * cos(theta),
					A * sin(theta)
				);
			}

			float3 CalculateSumTermOfNormal(const float2 xy, const half QRatio, const half A, const half2 D, const float t, const float L, const float S)
			{
				const float w = 2 * PI / L;
				const float WA = w * A;
				const float phi = S * w;
				const float theta = w * dot(D, xy) + phi * t;
				const float sinTheta = sin(theta);
				const float cosTheta = cos(theta);
				const float Q = (1 / (w * A)) * QRatio;
				return float3(
					D.x * WA * cosTheta,
					D.y * WA * cosTheta,
					Q * WA * sinTheta
				);
			}

			float3 P(float2 xy, float t)
			{
				return float3(xy, 0)
					+ ShiftPosition(xy, _QRatio1, _Amplitude1, normalize(float2(_Direction1X, _Direction1Z)), t, _WaveLength1, _Speed1) * _Active1
					+ ShiftPosition(xy, _QRatio2, _Amplitude2, normalize(float2(_Direction2X, _Direction2Z)), t, _WaveLength2, _Speed2) * _Active2
					+ ShiftPosition(xy, _QRatio3, _Amplitude3, normalize(float2(_Direction3X, _Direction3Z)), t, _WaveLength3, _Speed3) * _Active3;
			}

			float3 N(float2 xy, float t)
			{
				const float3 normalTerm1 = CalculateSumTermOfNormal(xy, _QRatio1, _Amplitude1, normalize(float2(_Direction1X, _Direction1Z)), t, _WaveLength1, _Speed1) * _Active1;
				const float3 normalTerm2 = CalculateSumTermOfNormal(xy, _QRatio2, _Amplitude2, normalize(float2(_Direction2X, _Direction2Z)), t, _WaveLength2, _Speed2) * _Active2;
				const float3 normalTerm3 = CalculateSumTermOfNormal(xy, _QRatio3, _Amplitude3, normalize(float2(_Direction3X, _Direction3Z)), t, _WaveLength3, _Speed3) * _Active3;
				return normalize(float3(
					- (normalTerm1.x + normalTerm2.x + normalTerm3.x),
					- (normalTerm1.y + normalTerm2.y + normalTerm3.y),
					1 - (normalTerm1.z + normalTerm2.z + normalTerm3.z)
				));
			}

			Varyings ProcessVertex(Attributes input)
			{
				float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

				// Gemsに合わせて記号は水平平面をxyとしている。実際はxz平面なので渡すのはxz。
				const float2 xy = positionWS.xz;
				const float t = _Time.y;

				Varyings output = (Varyings)0;
				output.positionWS = P(xy, t).xzy;
				output.normalWS = N(xy, t).xzy;
				output.positionCS = TransformWorldToHClip(output.positionWS);
				return output;
			}

			half4 ProcessFragment(Varyings input) : SV_Target
			{
				const float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				const Light light = GetMainLight(shadowCoord);
				const half3 surfaceNormal = normalize(input.normalWS);
				const float NoL = saturate(dot(surfaceNormal, light.direction));
				const half3 diffuse = _Albedo.rgb * light.color * NoL;
				return half4(diffuse, 1);
			}
			ENDHLSL
		}
	}
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
