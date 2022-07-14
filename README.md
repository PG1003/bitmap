# Bitmap Manipulation Primitives

A pure Lua module to open, create, modify and save bitmap images.

## Features

* Pure Lua for easy integration into existing applications.
* Support for multiple kinds of uncompressed bitmap formats;
  * 1, 4 and 8 bit indexed.
  * regular 16, 24 and 32 bit RGB.
  * bitfields, including alpha.
* Auxiliary functions such as;
  * Dithering bitmaps in black/white and color.
  * Calculating PSNR.
  * Generating diffs from bitmaps.
* Creating heatmaps.
* Additional color module providing the following features;
  * colorspace conversions back and forth between RGB and the HSV, HSL and Lab colorspaces.
  * color comparison with Delta E76 and Delta E94.
  * color quantization using median cut in the RGB colorspace.

See the [reference](/reference.md) for the complete overview of the API.

## Requirements

* Lua version 5.3 or 5.4

## Examples

The following example loads a bitmap image and convert it to a 256 color 8 bit indexed bitmap.

``` lua
local bitmap = require( "bitmap" )
local color  = require( "bitmap.color" )

local bmp     = bitmap.open( "kodim23.bmp" )
local palette = color.quantize( bitmap.pixels( bmp ), 256 )

bitmap.save( bmp, "kodim23_8bit.bmp", "RGB8", palette )
```

The next example loads a bitmap image, creates a viewport at the lower left part of the bitmap.
Then the content of the viewport is saved to a bitmap file with the same format and palette (in case `kodim23.bmp` was an indexed bitmap).

``` lua
local bitmap = require( "bitmap" )

local bmp, format, palette = bitmap.open( "kodim23.bmp" )
local viewport             = bitmap.make_viewport( bmp, 1, 1, 42, 42 )

bitmap.save( viewport, "kodim23_vp.bmp", format, palette )
```

This example shows the usage of a heatmap and saving it to a bitmap file.

``` lua
local bitmap   = require( "bitmap" )
local palettes = require( "bitmap.palettes" )
local heatmap  = require( "bitmap.heatmap" )

-- Create an 8 by 8 heatmap and fill it with data.
local hm = heatmap.create( 8, 8 )
for y = 1, hm:height() do
    for x = 1, hm:width() do
        hm:set( x, y, x + y )
    end
end

-- Generate a palette with a gradient from blue to white to red.
local pal = {}
palettes.add_gradient( pal, 0xFF0000FF, 0xFFFFFFFF, 8 )
palettes.add_gradient( pal, nil, 0xFFFF0000, 7 )

-- Create a heatmap palette object with a range from 2 until 16.
local hm_pal = heatmap.make_heatmap_palette( 2, 16, pal )

-- Create a bitmap like interface for the heatmap with a cell size of 14 by 14 pixels.
local hm_view = heatmap.make_bitmap_view( hm, 14, 14, hm_pal )

-- Save the heatmap as bitmap image.
bitmap.save( hm_view, "heatmap.bmp", "RGB4", pal )
```

Results in the bitmap below.

![Heatmap image](/test/resources/heatmap.bmp)
