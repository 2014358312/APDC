Includes = {
}

PixelShader =
{
	Samplers =
	{
		BaseTexture =
		{
			Index = 0
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		MaskTexture =
		{
			Index = 1
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}


VertexStruct VS_INPUT
{
	float3 vPosition : POSITION;
	float2 vTexCoord : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
	float4 vPosition : PDX_POSITION;
	float4 vTexCoord : TEXCOORD0;
};


ConstantBuffer( 0, 0 )
{
	float4x4 WorldViewProjectionMatrix;
	float4 FlagCoords; // xy = atlas offset, zw = atlas-cell size
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main( const VS_INPUT v )
		{
			VS_OUTPUT Out;
			Out.vPosition = mul( WorldViewProjectionMatrix, float4( v.vPosition.xyz, 1 ) );
			Out.vTexCoord.zw = v.vTexCoord.xy;

			// Keep the four UV edges at the centres of this 41x26 atlas cell's
			// outer texels. This prevents point sampling from selecting a row or
			// column belonging to an adjacent dynamic flag.
			float2 HalfFlagTexel = 0.5 * FlagCoords.zw / float2( 41.0, 26.0 );
			Out.vTexCoord.xy = FlagCoords.xy + HalfFlagTexel;
			Out.vTexCoord.xy += v.vTexCoord.xy * ( FlagCoords.zw - 2.0 * HalfFlagTexel );
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShader
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 OutColor = tex2D( BaseTexture, v.vTexCoord.xy );
			float4 MaskColor = tex2D( MaskTexture, v.vTexCoord.zw );
			OutColor.a = MaskColor.a;
			return OutColor;
		}
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 OutColor = tex2D( BaseTexture, v.vTexCoord.xy );
			float4 MaskColor = tex2D( MaskTexture, v.vTexCoord.zw );
			OutColor.a = MaskColor.a;
			OutColor.rgb += float3( 0.1, 0.1, 0.1 );
			return OutColor;
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 OutColor = tex2D( BaseTexture, v.vTexCoord.xy );
			float4 MaskColor = tex2D( MaskTexture, v.vTexCoord.zw );
			OutColor.a = MaskColor.a;
			OutColor.rgb -= float3( 0.1, 0.1, 0.1 );
			return OutColor;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 OutColor = tex2D( BaseTexture, v.vTexCoord.xy );
			float4 MaskColor = tex2D( MaskTexture, v.vTexCoord.zw );
			OutColor.a = MaskColor.a;
			float Grey = dot( OutColor.rgb, float3( 0.212671f, 0.715160f, 0.072169f ) );
			OutColor.rgb = float3( Grey, Grey, Grey );
			return OutColor;
		}
	]]
}


BlendState BlendState
{
	BlendEnable = yes
	AlphaTest = no
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDown"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderOver"
}
