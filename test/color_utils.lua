local color    = require( "color")
local palettes = require( "palettes" )
local test     = require( "test" )


local tests = {}


local function _from_color( from_color, colors )
    for rgb, values in pairs( colors ) do
        local p, q, r = from_color( rgb )
        test.is_same_float( values[ 1 ], p, 0.000005 )
        test.is_same_float( values[ 2 ], q, 0.000005 )
        test.is_same_float( values[ 3 ], r, 0.000005 )
    end
end

local function _to_color( to_color, colors )
    for rgb, values in pairs( colors ) do
        local value = to_color( values[ 1 ], values[ 2 ], values[ 3 ] )
        test.is_same( rgb, value )
    end
end

local _rgb_hsl =
{
    [ 0xFFFF0000 ] = { 0.00000,   1.00000, 1.0 / 2.0 },
    [ 0xFF00FF00 ] = { 1.0 / 3.0, 1.00000, 1.0 / 2.0 },
    [ 0xFF0000FF ] = { 2.0 / 3.0, 1.00000, 1.0 / 2.0 },
    [ 0xFF00FFFF ] = { 1.0 / 2.0, 1.00000, 1.0 / 2.0 },
    [ 0xFFFF00FF ] = { 5.0 / 6.0, 1.00000, 1.0 / 2.0 },
    [ 0xFFFFFF00 ] = { 1.0 / 6.0, 1.00000, 1.0 / 2.0 },
    [ 0xFF000000 ] = { 0.00000,   0.00000, 0.00000 },
    [ 0xFFFFFFFF ] = { 0.00000,   0.00000, 1.00000 }
}

function test.color_to_hsl()
    _from_color( color.to_hsl, _rgb_hsl )
end

function tests.hsl_to_color()
    _to_color( color.from_hsl, _rgb_hsl )
end

local _rgb_hsv =
{
    [ 0xFFFF0000 ] = { 0.00000,   1.00000, 1.00000 },
    [ 0xFF00FF00 ] = { 1.0 / 3.0, 1.00000, 1.00000 },
    [ 0xFF0000FF ] = { 2.0 / 3.0, 1.00000, 1.00000 },
    [ 0xFF00FFFF ] = { 1.0 / 2.0, 1.00000, 1.00000 },
    [ 0xFFFF00FF ] = { 5.0 / 6.0, 1.00000, 1.00000 },
    [ 0xFFFFFF00 ] = { 1.0 / 6.0, 1.00000, 1.00000 },
    [ 0xFF000000 ] = { 0.00000,   0.00000, 0.00000 },
    [ 0xFFFFFFFF ] = { 0.00000,   0.00000, 1.00000 }
}

function test.color_to_hsv()
    _from_color( color.to_hsv, _rgb_hsv )
end

function tests.hsv_to_color()
    _to_color( color.from_hsv, _rgb_hsv )
end

local _rgb_Lab =
{
    [ 0xFFFF0000 ] = {  53.241,  80.092,   67.203 },
    [ 0xFF00FF00 ] = {  87.735, -86.183,   83.179 },
    [ 0xFF0000FF ] = {  32.297,  79.188, -107.860 },
    [ 0xFF00FFFF ] = {  91.113, -48.088,  -14.131 },
    [ 0xFFFF00FF ] = {  60.324,  98.234,  -60.825 },
    [ 0xFFFFFF00 ] = {  97.139, -21.554,   94.478 },
    [ 0xFF000000 ] = {   0.000,   0.000,    0.000 },
    [ 0xFFFFFFFF ] = { 100.000,   0.000,    0.000 }
}

function test.color_to_Lab()
    _from_color( color.to_Lab, _rgb_Lab )
end

function tests.Lab_to_color()
    _to_color( color.from_Lab, _rgb_Lab )
end

local _rgb_hcl =
{
    [ 0xFFFF0000 ] = {  39.999, 104.552,  53.241 },
    [ 0xFF00FF00 ] = { 136.016, 119.776,  87.735 },
    [ 0xFF0000FF ] = { 306.285, 133.808,  32.297 },
    [ 0xFF00FFFF ] = { 196.376,  50.121,  91.113 },
    [ 0xFFFF00FF ] = { 328.235, 115.541,  60.324 },
    [ 0xFFFFFF00 ] = { 102.851,  96.905,  97.139 },
    [ 0xFF000000 ] = {   0.000,   0.000,   0.000 },
    [ 0xFFFFFFFF ] = { 270.000,   0.000, 100.000 }
}

function test.color_to_hcl()
    _from_color( color.to_hcl, _rgb_hcl )
end

function tests.hcl_to_color()
    _to_color( color.from_hcl, _rgb_hcl )
end

function tests.quantize_reference()
    local colors = color.quantize( palettes.palette_16, 42 )
    test.is_same( #colors, 16 )  -- the reference bitmap has only 16 colors
end

function tests.quantize_lena()
    local colors = color.quantize( palettes.palette_256, 32 )
    test.is_same( #colors, 32 )
    
    -- Check uniqueness of the pixels
    for i = 1, #colors do
        local color_i = colors[ i ]
        for n = i + 1, #colors do
            test.is_not_same( color_i, colors[ n ] )
        end
    end
end

    
local _delta_e =
{
    { {  53.241,  80.092,   67.203 }, {  87.735, -86.183,   83.179 },  73.430543 }, -- 0xFF00FF00, 0xFFFF0000
    { {  32.297,  79.188, -107.860 }, {  91.113, -48.088,  -14.131 },  74.765039 }, -- 0xFF0000FF, 0xFF00FFFF
    { {  60.324,  98.234,  -60.825 }, {  97.139, -21.554,   94.478 },  80.421818 }, -- 0xFFFF00FF, 0xFFFFFF00
    { {   0.000,   0.000,    0.000 }, { 100.000,   0.000,    0.000 }, 100.0      }, -- 0xFF000000, 0xFFFFFFFF
    { {   0.000,   0.000,    0.000 }, {  32.297,  79.188, -107.860 }, 137.650337 }, -- 0xFF000000, 0xFF0000FF
    { { 100.000,   0.000,    0.000 }, {  97.139, -21.554,   94.478 },  96.947680 }  -- 0xFFFFFFFF, 0xFFFFFF00
}
    
function tests.delta_e94()
    for i = 1, #_delta_e do
        local combination = _delta_e[ i ]
        local L1, a1, b1  = table.unpack( combination[ 1 ] )
        local L2, a2, b2  = table.unpack( combination[ 2 ] )
        local e94         = combination[ 3 ]
        test.is_same_float( color.delta_e94( L1, a1, b1, L2, a2, b2 ), e94, 0.0000005 )
    end
end


return tests
