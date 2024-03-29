# Bitmap Manipulation Primitives for Lua - Reference

## Contents
  
### bitmap

[blit](#blit-dst-x-y-src-)  
[create](#create-width-height--init_color--0-)  
[diff](#diff-left-right-)  
[dither](#dither-bmp-format-palette-)  
[dither_bw](#dither_bw-bmp-)  
[make_viewport](#make_viewport-src_bmp-x-y-width-height-)  
[open](#open-file-)  
[psnr](#psnr-reference-other-)  
[pixels](#pixels-bmp-)  
[save](#save-bmp-file-format--palette-)  
[bitmap:get](#bitmapget-x-y-)  
[bitmap:height](#bitmapheight)  
[bitmap:set](bitmapset-x-y-color-)  
[bitmap:width](#bitmapwidth)
  
### bitmap.color

[add](#add-left-right-)  
[blue](#blue-color-)  
[delta_e76](#delta_e76-l1-a1-b1-l2-a2-b2-)  
[delta_e94](#delta_e94-l1-a1-b1-l2-a2-b2-)  
[green](#green-color-)  
[from_hcl](#from_hcl-h-c-l-)  
[from_hsl](#from_hsl-h-s-l-)  
[from_hsv](#from_hsv-h-s-v--a--255-)  
[from_Lab](#from_lab-l-a-b-)  
[from_rgba](#from_rgba-r-g-b--a--255-)  
[lerp](#lerp-color_1-color_2-t--colorspace--rgb-)  
[luminance](#luminance-color-)  
[quantize](#quantize-colors-n_colors-)  
[red](#red-color-)  
[sub](#sub-left-right-)  
[to_hcl](#to_hcl-color-)  
[to_hsl](#to_hsl-color-)  
[to_hsv](#to_hsv-color-)  
[to_Lab](#to_lab-color-)  
[to_rgba](#to_rgba-color-)

### bitmap.heatmap

[create](#create-width-height--init--0-)  
[make_bitmap_view](#make_bitmap_view-hm-cell_size_x-cell_size_y-hm_palette-)  
[make_heatmap_palette](#make_heatmap_palette-min-max-palette--out_of_range_color--0xff000000-)  
[heatmap:decrease](#heatmapdecrease-x-y--value--1-)  
[heatmap:get](#heatmapget-x-y-)  
[heatmap:height](#heatmapheight)  
[heatmap:increase](#heatmapincrease-x-y--value--1-)  
[heatmap:set](#heatmapset-x-y-value-)  
[heatmap:width](#heatmapwidth)  
[bitmap_view:get](#bitmap_viewget-x-y-)  
[bitmap_view:height](#bitmap_viewheight)  
[bitmap_view:width](#bitmap_viewwidth)
  
### bitmap.palettes

[add_color](#add_color-palette-color--count--1-)  
[add_gradient](#add_gradient-palette-from_color-to_color-count--colorspace--rgb-)  
[palette_2](#palette_2)  
[palette_16](#palette_16)  
[palette_256](#palette_256)  
[unique_colors](#unique_colors-palette-)

## bitmap

A bitmap follows the same structure as a bitmap file which is a two dimentional table with rows of pixels.
This means when accessing a pixel, first the row is selected, then the column, e.g. `pixel = bitmap[ y ][ x ]`.
You can also use the [bitmap:get](#bitmapget-x-y-) and [bitmap:set](bitmapset-x-y-color-) functions which are more intuitive but slightly slower.

The origin of the bitmap is placed at lower left corner.
This choice was made to simplify the visualization of datapoints.

See the [color](#bitmapcolor-1) support library about how the color value of a pixel is defined.

### `blit( dst, x, y, src )`

Copies the contents from the `src` bitmap to the `dst` bitmap.
`x` and `y` is position of lower left corner of the `src` in the `dst` bitmap.
The pixels of `src` that do not overlap the `dst` bitmap dimentions are discarded during the copy.

### `create( width, height [, init_color = 0] )`

Creates a new bitmap with the given `width` and `height`.
If the optional `init_color` was not provided then the value '0' (black) will be used as initial value of the pixels.

### `diff( left, right )`

Takes two identical sized bitmaps and creates a new bitmap with color values that are the difference between the two bitmaps.
The difference in color values are absolute; the color component values ranges from 0 up to 255.

### `dither( bmp, format [, palette] )`

Quantizes the pixels of `bmp` given the `format` and applies dithering using the Floyd-Steinberg algorithm.
`format` is a string following a pattern as described in [format patterns](#Format-patterns).
`palette` is required when `format` is RGB1, RGB4 or RGB8.

### `dither_bw( bmp )`

Quantizes the pixels of `bmp` to black/white and applies dithering using the Floyd-Steinberg algorithm.
This function gives better results than the [dither](#dither-bmp-format-palette-) function with a RGB1 format combined with a black/white palette.

### `make_viewport( src_bmp, x, y, width, height )`

Returns a viewport that targets an area in the bitmap `src_bmp`.
`x` and `y` is the position in the bitmap of the viewport's lower left corner.
`width` and `height` are the dimentions of the viewport.  
The viewport area must be defined within the dimentions of `src_bmp`.

### `open( file )`

Reads a bitmap file and returns a bitmap object and format.
If the opened file was an indexed bitmap, a third value containing the palette is returned.
The format is a string with a pattern that discribes what kind of bitmap format was opened.
See [format patterns](#Format-patterns) about how a pattern is encoded.

### `pixels( bmp )`

Returns a proxy table that transforms the bitmap or a bitmap view to an one-dimentional table.
This table can be used to iterate through all the pixels of a bitmap, for example with `ipairs`.

### `psnr( reference, other )`

Calculates the Peak Signal-to-Noise Ratio between the bitmaps `reference` and `other`.
The sizes of the bitmaps must be same.
Returns 4 values; psnr of the color components combined, psnr red, psnr green and psnr blue.

### `save( bmp, file, format [, palette] )`

Saves `bmp` to `file` with the given `format`.
`bmp` can be any bitmap like structure such as returned by [open](#open-file-), [make_viewport](#make_viewport-src_bmp-x-y-width-height-) and [make_bitmap_view](#make_bitmap_view-hm-cell_size_x-cell_size_y-hm_palette-).  
The `format` is a string folowing a pattern as described in [format patterns](#Format-patterns).
`palette` is required when `format` is RGB1, RGB4 or RGB8.
A `palette` is a table with a maximum size of 256 which has for each index a color.

### `bitmap:get( x, y )`

Returns the color value of the pixel at the given `x` and `y` of the bitmap.  
Using this function may be slower than accessing the pixels directly on the table structure but is more intuitive.

### `bitmap:height()`

Returns the bitmap's height in pixels.

### `bitmap:set( x, y, color )`

Sets the color value `color` on the given `x` and `y` of the bitmap.  
Using this function may be slower than modifying the pixels directly on the table structure but is more intuitive.

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
The red, green and blue components are required, alpha is optional.

|Example | Pixel bit pattern|
|--------|------------------|
|`RGB565` | `RRRRRGGGGGGBBBBB`|
|`ABGR1555` | `ABBBBBGGGGGRRRRR`|
|`RGBA2222` | `--------RRGGBBAA`|
|`RGB888` | `--------RRRRRRRRGGGGGGGGBBBBBBBB`|
|`AGRB8888` | `AAAAAAAAGGGGGGGGRRRRRRRRBBBBBBBB`|

The minimum size of a pixel for bitfield type formats is 16 bits.
The pixel size is 32 bits for formats with a total bit count of more than 16 bits.

## bitmap.color

A color is a 32 bit value that represents an RGB colorspace with an alpha.
Each color component is an 8 bit value ranging from 0 up to 255 and is packed as in the table below.

|Color component | Bit mask|
|----------------|---------|
|Alpha | `0xFF000000`|
|Red | `0x00FF0000`|
|Green | `0x0000FF00`|
|Blue | `0x000000FF`|

### `add( left, right )`

Adds two colors.
The resulting value of color components is clipped to 255.

### `blue( color )`

Returns the blue component value from a color.

### `delta_e76( L1, a1, b1, L2, a2, b2 )`

Takes two colors in the Lab colorspace and calculates the distance between two colors using the CIE76 formula.
The value 0.0 means both colors are same.  
This calculation is faster but less accurate than the [delta_e94](#delta_e94-l1-a1-b1-l2-a2-b2-) function.

### `delta_e94( L1, a1, b1, L2, a2, b2 )`

Takes two colors in the Lab colorspace and calculates the distance between two colors using the CIE94 formula.
The value 0.0 means both colors are same.

### `green( color )`

Returns the green component value from a color.

### `from_hcl( h, c, l )`

Returns a color that is converted from the HCL color model values.

### `from_hsl( h, s, l )`

Returns a color that is converted from the HSL colorspace values.

### `from_hsv( h, s, v [, a = 255] )`

Returns a color that is converted from the HSV colorspace values.
The optional parameter `a` is a value between 0.0 up to 1.0 that is transformed to an alpha.

### `from_Lab( L, a, b )`

Returns a color that is converted from the CIE Lab colorspace values.

### `from_rgba( r, g, b [, a = 255] )`

Returns a color that is converted from the RGB color component values.
When the optional alpha is not provided the default value of 255 will be used.

### `lerp( color_1, color_2, t [, colorspace = RGB] )`

Returns an interpolated color between `color_1` and `color_2` using factor `t` where `t = 0` returns `color_1` while `t = 1` returns `color_2`.
The colorspace is the colorspace in which the interpolation takes place.

The optional `colorspace` argument is a string that defines colorspace in which the linear interpolation is calculated.
Valid values are `"RGB"`, `"HSL"`, `"HSV"`, `"LAB"` and `"HCL"`.
The default is colorspace is RGB.

### `luminance( color )`

Returns the _L_ component of the Lab color spaces which is the luminance of the color.
The advantage over this function over the [to_Lab](#to_lab-color-) function is the simplified and faster calculation.

### `quantize( colors, n_colors )`

Quantizes the colors in the table `colors` to a total of `n_colors` using the median cut algorithm in the RGB colorspace.
A table with a maximum of `n_colors` quantized is returned.
Less colors are returned when the image doesn't contain at least `n_colors`.

### `red( color )`

Returns the red component value from a color.

### `sub( left, right )`

Substracts two color.
The resulting value of color components is clipped to 0.

### `to_hcl( color )`

Returns the representation of `color` in HCL color model values.

### `to_hsl( color )`

Returns the representation of `color` in HSL colorspace values.

### `to_hsv( color )`

Returns the representation of `color` in HSV colorspace values.
The fourth returned value is the alpha ranging from 0.0 up to 1.0.

### `to_Lab( color )`

Returns the representation of `color` in CIE Lab colorspace values.

### `to_rgba( color )`

Returns the red, green, blue and alpha color components of `color`.

## bitmap.heatmap

### `create( width, height [, init = 0] )`

Returns a new heatmap with `width` number of cells for X and `height` number of cells for Y.  
`init` is an optional parameter which will be the initial value of the cells.
The cells are initialized with 0 when `init` is not provided.

### `make_bitmap_view( hm, cell_size_x, cell_size_y, hm_palette )`

Creates a _read-only_ bitmap like view for the given heatmap `hm`.
Each cell is given a width and height of `cell_size_x` and `cell_size_y` pixels.  
`hm_palette` is a heatmap palette created by [make_heatmap_palette](#make_heatmap_palette-min-max-palette--out_of_range_color--0xff000000-) that is used to translate the heatmap cell values to colors.

### `make_heatmap_palette( min, max, palette [, out_of_range_color = 0xFF000000] )`

Creates a heatmap palette object.
The range of the palette is defined by `min` and `max` parameters.
`palette` is a table that is used as a list and contains at least one color.  
The optional parameter `out_of_range_color` color is returned when a value outside the is requested range.
Default value for `out_of_range_color` is `0xFF000000`.

The range is _including_ the `max` value.
This means that `palette` must have one color more than you may expect when you use palettes containing a small number of colors e.g. when visualize catagories using a descrete palette.
For example when the values 0 and 10 used for `min` and `max` combined with a `palette` of 21 colors, then the 'bucket size' for each color is;  
`( max - min ) / ( #palette - 1 ) = ( 10 - 0 ) / ( 21 - 1 ) = 0.5`.  
This results in a heatmap palette that has a larger effective range, in this case 10.5.

You must also be aware when using floating point numbers that a heatmap palette may return an adjacent color because floating points numbers are not infinit accurate.
This effect may be noticeable when using a descrete palette.

The interface of the heamap palette is an implementation detail and therefore not documented.

### `heatmap:decrease( x, y [, value = 1] )`

Decreases a heatmap cell at position `x`,`y` with `value`.
The cell's value is decreased by 1 when `value` is not provided.

### `heatmap:get( x, y )`

Returns heatmap cell value at position `x`,`y`.  
Using this function may be slower than accessing the cells directly on the table structure but is more intuitive.

### `heatmap:height()`

Returns the number of cells available for Y.

### `heatmap:increase( x, y [, value = 1] )`

Increases a heatmap cell at position `x`,`y` with `value`.
The cell's value is increased by 1 when `value` is not provided.

### `heatmap:set( x, y, value )`

Sets a heatmap cell at position `x`,`y` with `value`.  
Using this function may be slower than accessing the cells directly on the table structure but is more intuitive.

### `heatmap:width()`

Returns the number of cells available for X.

### `bitmap_view:get( x, y )`

Returns the color value of the pixel at the given `x` and `y` of the bitmap view.

### `bitmap_view:height()`

Returns the height in pixels of a `bitmap_view`.

### `bitmap_view:width()`

Returns the width in pixels of a `bitmap_view`.

## bitmap.palettes

### `add_color( palette, color [, count = 1] )`

Appends a `count` number of `color` values to `palette`.
`count` must be at least 1 and less then 65536.
When `count` is ommited a default of 1 is used.

### `add_gradient( palette, from_color, to_color, count [, colorspace = "RGB"] )`

Appends a gradient from `from_color` to `to_color` with `count` number of colors to `palette`.
If `from_color` is a false-like type (`nil` or `false`) then the value of `palette[ #palette ]` will be used to interpolate from but is not added (again) to `palette`.
`count` must be equal or less then 65536 and at least be 2 when `from_color` is provided or 1 when `from_color` is a false-like type.  

The optional `colorspace` parameter is the colorspace used by the linear interpolation between `from_color` and `to_color`.
Valid values are `"RGB"`, `"HSL"`, `"HSV"`, `"LAB"` and `"HCL"`.
The default is colorspace is RGB.

### `palette_2`

A read-only palette with 2 default colors derived from 1 bit bitmap image saved by MS Paint.

### `palette_16`

A read-only palette with 16 default colors derived from 4 bit bitmap image saved by MS Paint.

### `palette_256`

A read-only palette with 256 default colors derived from 8 bit bitmap image saved by MS Paint.

### `unique_colors( palette )`

Returns a new palette with all the unique colors from `palette`.
The function itterates over `palette` from index `1` until `#palette`.
The first occurence of a color is added to the new palette.
