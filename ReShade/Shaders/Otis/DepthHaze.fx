/**
 * This effect works like a one-side DoF for distance haze, which slightly
 * blurs far away elements. A normal DoF has a focus point and blurs using
 * two planes. 
 *
 * It works by first blurring the screen buffer using 2-pass block blur and
 * then blending the blurred result into the screen buffer based on depth
 * it uses depth-difference for extra weight in the blur method so edges
 * of high-contrasting lines with high depth diffence don't bleed.
 */

#include EFFECT_CONFIG(Otis)

#if USE_DEPTHHAZE

#pragma message "DepthHaze by Otis\n"

#if (HDR_MODE == 0)
	#define Otis_RENDERMODE RGBA8
#elif (HDR_MODE == 1)
	#define Otis_RENDERMODE RGBA16F
#else
	#define Otis_RENDERMODE RGBA32F
#endif

namespace Otis
{
	texture FragmentBuffer1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = Otis_RENDERMODE; };
	texture FragmentBuffer2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = Otis_RENDERMODE; };
	sampler SamplerFragmentBuffer1 { Texture = FragmentBuffer1; };
	sampler SamplerFragmentBuffer2 { Texture = FragmentBuffer2; };

	float CalculateWeight(float distanceFromSource, float sourceDepth, float neighborDepth)
	{
		return (1.0 - abs(sourceDepth - neighborDepth)) * (1 / distanceFromSource) * neighborDepth;
	}

	void PS_DEH_BlockBlurHorizontal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
	{
		float4 color = tex2D(ReShade::BackBuffer, texcoord);
		float colorDepth = tex2D(ReShade::LinearizedDepth, texcoord).r;
		float n = 1.0f;

		[loop]
		for (float i = 1; i < 5; ++i) 
		{
			float2 sourceCoords = texcoord + float2(i * ReShade::PixelSize.x, 0.0);
			float weight = CalculateWeight(i, colorDepth, tex2D(ReShade::LinearizedDepth, sourceCoords).r);
			color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
			n += weight;

			sourceCoords = texcoord - float2(i * ReShade::PixelSize.x, 0.0);
			weight = CalculateWeight(i, colorDepth, tex2D(ReShade::LinearizedDepth,sourceCoords).r);
			color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
			n += weight;
		}

		outFragment = color / n;
	}
	void PS_DEH_BlockBlurVertical(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
	{
		float4 color = tex2D(SamplerFragmentBuffer1, texcoord);
		float colorDepth = tex2D(ReShade::LinearizedDepth, texcoord).r;
		float n = 1.0f;

		[loop]
		for (float j = 1; j < 5; ++j) 
		{
			float2 sourceCoords = texcoord + float2(0.0, j * ReShade::PixelSize.y);
			float weight = CalculateWeight(j, colorDepth, tex2D(ReShade::LinearizedDepth,sourceCoords).r);
			color += (tex2D(SamplerFragmentBuffer1, sourceCoords) * weight);
			n += weight;

			sourceCoords = texcoord - float2(0.0, j * ReShade::PixelSize.y);
			weight = CalculateWeight(j, colorDepth, tex2D(ReShade::LinearizedDepth,sourceCoords).r);
			color += (tex2D(SamplerFragmentBuffer1, sourceCoords) * weight);
			n += weight;
		}

		outFragment = color/n;
	}
	void PS_DEH_BlendBlurWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
	{
		fragment = lerp(tex2D(ReShade::BackBuffer, texcoord), tex2D(SamplerFragmentBuffer2, texcoord), clamp(tex2D(ReShade::LinearizedDepth,texcoord).r * DEH_EffectStrength, 0, 1)); 
	}
}

technique Otis_DEH_Tech < enabled = false; toggle = DEH_ToggleKey; >
{
	// 3 passes. First 2 passes blur screenbuffer into FragmentBuffer2 using 2 pass block blur with 10 samples each (so 2 passes needed)
	// 3rd pass blends blurred fragments based on depth with screenbuffer.

	pass Otis_DEH_Pass0
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = Otis::PS_DEH_BlockBlurHorizontal;
		RenderTarget = Otis::FragmentBuffer1;
	}
	pass Otis_DEH_Pass1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = Otis::PS_DEH_BlockBlurVertical;
		RenderTarget = Otis::FragmentBuffer2;
	}
	pass Otis_DEH_Pass2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = Otis::PS_DEH_BlendBlurWithNormalBuffer;
	}
}

#endif

#include EFFECT_CONFIG_UNDEF(Otis)
