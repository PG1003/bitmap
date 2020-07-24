# Bitmap Manipulation Primitives for Lua

A pure Lua module to open, modify and save bitmap images.

## Features

* Pure Lua, easy to use in existing applications.
* Support for multiple kinds of uncopressed bitmap formats;
  * 1, 4 and 8 bit indexed.
  * regular 16, 24 and 32 bit RGB.
  * bitfields, including alpha.
* Additional color module providing the following features;
  * colorspace conversions back and forth between RGB and other formats like HSV, HSL, Lab and HCL.
  * color comparison with Delta E94.
  * color quantisation using median cut.

See the [reference](/reference.md) for the complete overview of the API.

## Requirements

* Minimum Lua 5.3

## Examples

The following example loads an image and convert it to a 256 color 8 bit indexed bitmap.

``` lua
local bitmap = require( "bitmap" )
local color  = require( "color" )

local bmp     = bitmap.open( "kodim23.bmp" )
local palette = color.quantize( bmp.pixels(), 256 )

bmp:save( "kodim23_8bit.bmp", "RGB8", palette )
```

The next example loads an image, creates a viewport at the lower left part of the bitmap.
Then the content of the viewport is saved to a bitmap file with the same format and palette (in case `kodim23.bmp` was an indexed bitmap).

``` lua
local bitmap = require( "bitmap" )
local color  = require( "color" )

local bmp, format, palette = bitmap.open( "kodim23.bmp" )
local viewport             = bitmap.make_viewport( bmp, 0, 0, 42, 42 )

viewport:save( "kodim23_vp.bmp", format, palette )
```

You can find these and other examples in the [tests](/test).
