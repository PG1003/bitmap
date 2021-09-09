# Bitmap Manipulation Primitives

A pure Lua module to open, modify and save bitmap images.

## Features

* Pure Lua, easy to use in existing applications.
* Support for multiple kinds of uncopressed bitmap formats;
  * 1, 4 and 8 bit indexed.
  * regular 16, 24 and 32 bit RGB.
  * bitfields, including alpha.
* Additional color module providing the following features;
  * colorspace conversions back and forth between RGB and other formats like HSV, HSL, Lab and HCL.
  * color comparison with Delta E76 and Delta E94.
  * color quantisation using median cut.

See the [reference](/reference.md) for the complete overview of the API.

## Requirements

* Lua version 5.3 or 5.4

## Examples

The following example loads a btimap image and convert it to a 256 color 8 bit indexed bitmap.

``` lua
local bitmap = require( "bitmap" )
local color  = require( "bitmap.color" )

local bmp     = bitmap.open( "kodim23.bmp" )
local palette = color.quantize( bmp:pixels(), 256 )

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

You can find these and other examples in the [tests](/test).
