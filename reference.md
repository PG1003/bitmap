# Bitmap Manipulation Primitives for Lua - Reference

## Contents
  
### bitmap

[blit](#blit-dst-x-y-src-)  
[create](#create-width-height--init_color-)  
[diff](#diff-left-right-)  
[make_viewport](#make_viewport-src_bmp-x-y-width-height-)  
[open](#open-file-)  
[psnr](#psnr-reference-other-)  
[bitmap.height](#bitmapheight)  
[bitmap.pixels](#bitmappixels)  
[bitmap.save](#bitmapsave-file-format--palette-)  
[bitmap.width](#bitmapwidth)  
  
### color

[add](#add-left-right-)  
[blue](#blue-color-)  
[delta_e94](#delta_e94-l1-a1-b1-l2-a2-b2-)  
[green](#green-color-)  
[from_hcl](#from_hcl-h-c-l-)  
[from_hsl](#from_hsl-h-s-l-)  
[from_hsv](#from_hsv-h-s-v--a-)  
[from_Lab](#from_lab-l-a-b-)  
[from_rgba](#from_rgba-r-g-b--a-)  
[red](#red-color-)  
[sub](#sub-left-right-)  
[to_hcl](#to_hcl-color-)  
[to_hsl](#to_hsl-color-)  
[to_hsv](#to_hsv-color-)  
[to_Lab](#to_lab-color-)  
[to_rgba](#to_rgba-color-)  
[quantize](#quantize-colors-n_colors-)
  
### palettes

[palette_2](#palette_2)  
[palette_16](#palette_16)  
[palette_256](#palette_256)

## bitmap

A bitmap follows the same structure as a bitmap file which is a two dimentional table with rows of pixels.
This means when accessing a pixel, first the row is selected, then the column, e.g. `pixel = bitmap[ y ][ x ]`.

The origin of the bitmap is placed at lower left corner.
This choise was made to simplify the visualization of datapoints.

See the [color](#color) support library about how the color value of a pixel is defined.

### `blit( dst, x, y, src )`

Copies the contents from the `src` bitmap to the `dst` bitmap.
`x` and `y` is position of lower left corner of the `src` in the `dst` bitmap.
The pixels of `src` that do not overlap the `dst` bitmap dimentions are discarded during the copy.

### `create( width, height [, init_color] )`

Creates a new bitmap with the given `width` and `height`.
If the optional `init_color` was not provided then the value '0' (black) will be used as initial value of the pixels.

### `diff( left, right )`

Takes two identical size bitmaps and creates a new bitmap with color values that are the difference between the two bitmaps.
The difference in color values are absolute; the color component values ranges from 0 up to 255.

### `make_viewport( src_bmp, x, y, width, height )`

Returns a viewport that targets an area in the bitmap `src_bmp`.
`x` and `y` is the position int the bitmap of the viewport's lower left corner.
`width` and `height` are the dimentions of the viewport.  
The viewport area must be defined within the dimentions of `src_bmp`.

### `open( file )`

Opens a bitmap file and returns a bitmap table and format.
If the opened file was an indexed bitmap, a third value is returned containing the palette.
The format is a string with a pattern that discribes what kind of bitmap format was opened.
See [Format patterns](#Format-patterns) about how a pattern is encoded.

### `psnr( reference, other )`

Calculates the Peak Signal-to-Noise Ratio between the bitmaps `reference` and `other`.
The sizes of the bitmaps must be same.
Returns 4 values; psnr of the color components combined, psnr red, psnr green and psnr blue.

### `bitmap:height()`

Returns the bitmap's height in pixels.

### `bitmap:pixels()`

Returns a proxy table that transforms the bitmap to an one dimentional array.
This table can be used to iterate through the pixels, for example with `ipairs`.

### `bitmap:save( file, format [, palette] )`

Saves the bitmap to `file` with the given `format`.
The `format` is a string folowing a pattern as described [here](#Format-patterns).
`palette` is required if `format` is a pattern of an indexed bitmap type.
A `palette` is a table with maximum of 256 that has for each index a color.

### `bitmap:width()`

Returns the bitmap's width in pixels.

### Format patterns

A format pattern is a string that discribes the bitmap format.
There are 2 main format catagories; fixed and bitfields.

#### Fixed type formats

The following fixed formats can be encoded in the format string.

|Format | Description|
|-------|------------|
|RGB1 | 1 bit per pixel indexed bitmap supporting 2 colors per pixel|
|RGB4 | 4 bits per pixel indexed bitmap supporting 16 colors per pixel|
|RGB8 | 8 bits per pixel indexed bitmap supporting 256 colors per pixel|
|RGB16 | 16 bits per pixel; 5 bits for each red, green and blue color component, 1 bit unused|
|RGB24 | 24 bits per pixel; 8 bits for each red, green and blue color component|
|RGB32 | 32 bits per pixel; 8 bits for each red, green and blue color component, 8 bits unused|

#### Bitfield type formats

With bitfield type formats it is possible to define the position and the number of bits for each color component.
Besides the red, green and blue color component this format also supports alpha.

A bitfield format defines first the order of the color components followed by the size of each component.
Each color component can be defined only once with a maximum size of 8 bits.
The red, green and blue component are required, alpha is optional.

|Format | Pixel bit pattern|
|-------|------------------|
|`RGB565` | `RRRRRGGGGGGBBBBB`|
|`ABGR1555` | `ABBBBBGGGGGRRRRR`|
|`RGBA2222` | `--------RRGGBBAA`|
|`RGB888` | `--------RRRRRRRRGGGGGGGGBBBBBBBB`|
|`AGRB888` | `AAAAAAAAGGGGGGGGRRRRRRRRBBBBBBBB`|

The minimum size of a pixel for bitfield type formats is 16 bits.
The pixel size is 32 bits for formats with a total bit count of more than 16 bits.

## color

A color is a 32 bit value that represents an RGB color model with an alpha.
Each color component is an 8 bit value ranging from 0 up to 255 and packed as in the table below.

|Color component | Bit mask|
|----------------|---------|
|Alpha | `0xFF000000`|
|Red | `0x00FF0000`|
|Green | `0x0000FF00`|
|Blue | `0x000000FF`|

### `add( left, right )`

Adds two colors.
The resulting value of color components clipped to 255.

### `blue( color )`

Returns the blue component value from a color.

### `delta_e94( L1, a1, b1, L2, a2, b2 )`

Takes two colors in the Lab color model and calculates the distance between two colors using the CIE94 formula.
The value '0.0' means both colors are same.

### `green( color )`

Returns the green component value from a color.

### `from_hcl( h, c, l )`

Returns a color that is converted from the HCL color model values.

### `from_hsl( h, s, l )`

Returns a color that is converted from the HSL color model values.

### `from_hsv( h, s, v [, a] )`

Returns a color that is converted from the HSV color model values.
The optional parameter `a` is a value between 0.0 up to 1.0 that is transformed to an alpha.

### `from_Lab( L, a, b )`

Returns a color that is converted from the CIE Lab color model values.

### `from_rgba( r, g, b [, a] )`

Returns a color that is converted from the RGB color component values.
When the optional alpha is not provided the default value of 255 will be used.

### `red( color )`

Returns the red component value from a color.

### `sub( left, right )`

Substracts two color.
The resulting value of color components clipped to 0.

### `to_hcl( color )`

Returns the representation of `color` in HCL color model values.

### `to_hsl( color )`

Returns the representation of `color` in HSL color model values.

### `to_hsv( color )`

Returns the representation of `color` in HSV color model values.
The fourth returned value is the alpha ranging from 0.0 up to 1.0.

### `to_Lab( color )`

Returns the representation of `color` in CIE Lab color model values.

### `to_rgba( color )`

Returns the red, green, blue and alpha color components of `color`.

### `quantize( colors, n_colors )`

Quantizes the colors in the table `colors` to a total of `n_colors` using the median cut algorithm.
A table with a maximum of `n_colors` quantized is returned.
Less colors are returned when the image doesn't contain `n_colors`.

## palettes

### `palette_2`

A read-only palette with 2 default colors derived from 1 bit bitmap image saved by MS Paint.

### `palette_16`

A read-only palette with 16 default colors derived from 4 bit bitmap image saved by MS Paint.

### `palette_256`

A read-only palette with 256 default colors derived from 8 bit bitmap image saved by MS Paint.
