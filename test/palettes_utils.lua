local bitmap   = require( "bitmap" )
local palettes = require( "bitmap.palettes" )
local test     = require( "test" )

local function _add_palette_color()
    local palette = {}
    local color1  = 0xFF007F00
    local color2  = 0xFF424242
    
    palettes.add_color( palette, color1 )
    test.is_same( #palette, 1 )
    test.is_same( palette[ 1 ], color1 )

    palettes.add_color( palette, color2 )
    test.is_same( #palette, 2 )
    test.is_same( palette[ 2 ], color2 )
end

local function _add_palette_colors()
    local palette = {}
    local color   = 0xFF007F00
    palettes.add_color( palette, color )
    test.is_same( #palette, 1 )
    test.is_same( palette[ 1 ], color )
end

local function _add_palette_gradient()
    local palette = {}
    local color1  = 0xFF007F00
    local color2  = 0xFF007FFF

    palettes.add_gradient( palette, color1, color2, 11 )
    test.is_same( #palette, 11 )
    test.is_same( palette[ 1 ], color1 )
    test.is_less( palette[ 1 ], palette[ 2 ] )
    test.is_less( palette[ 10 ], palette[ 11 ] )
    test.is_same( palette[ 11 ], color2 )
end

local function _add_palette_gradients()
    local palette = {}
    local color1  = 0xFF007F00
    local color2  = 0xFF007FFF
    local color3  = 0xFF7F00FF

    palettes.add_gradient( palette, color1, color2, 11 )
    test.is_same( #palette, 11 )
    test.is_same( palette[ 1 ], color1 )
    test.is_less( palette[ 1 ], palette[ 2 ] )
    test.is_less( palette[ 10 ], palette[ 11 ] )
    test.is_same( palette[ 11 ], color2 )

    palettes.add_gradient( palette, nil, color3, 10 )
    test.is_same( #palette, 21 )
    test.is_less( palette[ 11 ], palette[ 12 ] )
    test.is_less( palette[ 20 ], palette[ 21 ] )
    test.is_same( palette[ 21 ], color3 )
end

local function _unique_colors()
    local palette = {}

    palettes.add_color( palette, 0xFF0000, 3 )
    palettes.add_color( palette, 0x00FF00, 3 )
    palettes.add_color( palette, 0x0000FF, 3 )

    local unique = palettes.unique_colors( palette )

    test.is_same( #unique, 3 )
    test.is_same( unique[ 1 ], 0xFF0000 )
    test.is_same( unique[ 2 ], 0x00FF00 )
    test.is_same( unique[ 3 ], 0x0000FF )
end

local tests =
{
    add_palette_color     = _add_palette_color,
    add_palette_colors    = _add_palette_colors;
    add_palette_gradient  = _add_palette_gradient,
    add_palette_gradients = _add_palette_gradients,
    unique_colors         = _unique_colors
}

return tests
 
