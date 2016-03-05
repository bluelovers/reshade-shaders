#include EFFECT_CONFIG(Otis)

#if USE_GOLDENRATIO

#pragma message "GoldenRatio by Otis\n"

namespace Otis
{
	texture GOR_texSpirals < source = "Reshade\\Shaders\\Otis\\Textures\\GoldenSpirals.png"; > { Width = 1748; Height = 1080; MipLevels = 1; Format = RGBA8; };
	sampler GOR_samplerSpirals { Texture = GOR_texSpirals; };

	void PS_Otis_GOR_RenderSpirals(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
	{
		float4 colFragment = tex2D(ReShade::BackBuffer, texcoord);
		float phiValue = ((1.0 + sqrt(5.0)) / 2.0);
		float idealWidth = ReShade::ScreenSize.y * phiValue;
		float idealHeight = ReShade::ScreenSize.x / phiValue;
		float4 sourceCoordFactor = float4(1.0, 1.0, 1.0, 1.0);

#if GOR_ResizeMode
		if (ReShade::AspectRatio < phiValue)
		{
			// display spirals at full width, but resize across height
			sourceCoordFactor = float4(1.0, ReShade::ScreenSize.y / idealHeight, 1.0, idealHeight / ReShade::ScreenSize.y);
		}
		else
		{
			// display spirals at full height, but resize across width
			sourceCoordFactor = float4(ReShade::ScreenSize.x / idealWidth, 1.0, idealWidth / ReShade::ScreenSize.x, 1.0);
		}
#endif
		float4 spiralFragment = tex2D(GOR_samplerSpirals, float2((texcoord.x * sourceCoordFactor.x) - ((1.0 - sourceCoordFactor.z) / 2.0),
																 (texcoord.y * sourceCoordFactor.y) - ((1.0 - sourceCoordFactor.w) / 2.0)));

		outFragment = saturate(colFragment + (spiralFragment * GOR_Opacity));
	}
}

technique Otis_GOR_Tech < enabled = false; toggle = GOR_ToggleKey; >
{
	pass Otis_GOR_Desaturate
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = Otis::PS_Otis_GOR_RenderSpirals;
	}
}

#endif

#include EFFECT_CONFIG_UNDEF(Otis)
