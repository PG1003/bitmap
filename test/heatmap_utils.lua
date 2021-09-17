local bitmap   = require( "bitmap" )
local heatmap  = require( "bitmap.heatmap" )
local palettes = require( "bitmap.palettes" )
local test     = require( "test" )

local function _default_creation()
    local hm = heatmap.create( 2, 4 )
    test.is_same( hm:width(), 2 )
    test.is_same( hm:height(), 4 )
    test.is_same( #hm, hm:height() )
    
    for y = 1, hm:height() do
        local row = hm[ y ]
        test.is_same( #row, hm:width() )
        for x = 1, hm:width() do
            test.is_same( row[ x ], 0.0 )
        end
    end
end

local function _creation_with_initial_value()
    local hm = heatmap.create( 4, 2, 42 )
    test.is_same( hm:width(), 4 )
    test.is_same( hm:height(), 2 )
    test.is_same( #hm, hm:height() )
    
    for y = 1, hm:height() do
        local row = hm[ y ]
        test.is_same( #row, hm:width() )
        for x = 1, hm:width() do
            test.is_same( row[ x ], 42 )
        end
    end
end

local function _heatmap_set_value()
    local hm    = heatmap.create( 3, 3, 0.0 )
    local value = 1337
    
    for y = 1, hm:height() do
        for x = 1, hm:width() do
            hm:set( x, y, value )
            test.is_same( hm:get( x, y ), value )
        end
    end
end

local function _heatmap_increase_value()
    local hm        = heatmap.create( 3, 3, 24 )
    local increment = 18
    local value     = 42
    
    for y = 1, hm:height() do
        for x = 1, hm:width() do
            hm:increase( x, y, increment )
            test.is_same( hm:get( x, y ), value )
        end
    end
end

local function _heatmap_decrease_value()
    local hm        = heatmap.create( 3, 3, 56 )
    local decrement = 14
    local value     = 42
    
    for y = 1, hm:height() do
        for x = 1, hm:width() do
            hm:decrease( x, y, decrement )
            test.is_same( hm:get( x, y ), value )
        end
    end
end

local function _heatmap_palette()
    local palette            = {}
    local color1             = 0xFF0000FF
    local color2             = 0xFFFFFFFF
    local color3             = 0xFFFF0000
    local out_of_range_color = 0xFF7F7F7F
    
    palettes.add_gradient( palette, color1, color2, 3 )
    palettes.add_gradient( palette, null, color3, 2 )
    test.is_same( #palette, 5 )
    
    local hm_palette1 = heatmap.make_heatmap_palette( 1, 5, palette, out_of_range_color )
    test.is_same( hm_palette1( 0 ), out_of_range_color )
    test.is_same( hm_palette1( 1 ), color1 )
    test.is_same( hm_palette1( 3 ), color2 )
    test.is_same( hm_palette1( 5 ), color3 )
    test.is_same( hm_palette1( 6 ), out_of_range_color )
    
    local hm_palette2 = heatmap.make_heatmap_palette( 0.1, 0.5, palette, out_of_range_color )
    test.is_same( hm_palette2( 0.0 ), out_of_range_color )
    test.is_same( hm_palette2( 0.1 ), color1 )
    test.is_same( hm_palette2( 0.30001 ), color2 )  -- Some floating point valuess are problematic due to nature of floating points.
    test.is_same( hm_palette2( 0.5 ), color3 )      -- Users of this library should be aware of this when using limited ranges with a few colors.
    test.is_same( hm_palette2( 0.6 ), out_of_range_color )
end

local function _bitmap_view()
    local hm = heatmap.create( 3, 5 )
    
    for y = 1, hm:height() do
        hm:set( 1, y, y - 1 )
        hm:set( 2, y, y )
        hm:set( 3, y, y + 1 )
    end
    
    local palette = {}
    local color1  = 0xFF07FFFF
    local color2  = 0xFF9F4FFF
    palettes.add_gradient( palette, color1, color2, 5, "LAB" )
    
    local hm_palette = heatmap.make_heatmap_palette( 1, 5, palette )
    local hm_view    = heatmap.make_bitmap_view( hm, 5, 5, hm_palette )
    test.is_same( hm_view:width(), 15 )
    test.is_same( hm_view:height(), 25 )
    
    -- Test the colors we know for sure, not the interpolated ones.
    -- Sample on each corner of the view's cells
    
    -- hm[ 1 ][ 1 ]
    test.is_same( 0xFF000000, hm_view:get( 1, 1 ) )
    test.is_same( 0xFF000000, hm_view:get( 1, 5 ) )
    test.is_same( 0xFF000000, hm_view:get( 5, 1 ) )
    test.is_same( 0xFF000000, hm_view:get( 5, 5 ) )
    
    -- hm[ 5 ][ 3 ]
    test.is_same( 0xFF000000, hm_view:get( 11, 21 ) )
    test.is_same( 0xFF000000, hm_view:get( 15, 21 ) )
    test.is_same( 0xFF000000, hm_view:get( 11, 25 ) )
    test.is_same( 0xFF000000, hm_view:get( 15, 25 ) )
    
    -- hm[ 2 ][ 1 ]
    test.is_same( color1, hm_view:get( 6, 1 ) )
    test.is_same( color1, hm_view:get( 6, 5 ) )
    test.is_same( color1, hm_view:get( 10, 1 ) )
    test.is_same( color1, hm_view:get( 10, 5 ) )
    
    -- hm[ 1 ][ 2 ]
    test.is_same( color1, hm_view:get( 1, 6 ) )
    test.is_same( color1, hm_view:get( 1, 10 ) )
    test.is_same( color1, hm_view:get( 5, 6 ) )
    test.is_same( color1, hm_view:get( 5, 10 ) )
    
    -- hm[ 4 ][ 3 ]
    test.is_same( color2, hm_view:get( 11, 16 ) )
    test.is_same( color2, hm_view:get( 11, 16 ) )
    test.is_same( color2, hm_view:get( 15, 20 ) )
    test.is_same( color2, hm_view:get( 15, 20 ) )
    
    -- hm[ 5 ][ 2 ]
    test.is_same( color2, hm_view:get( 6, 21 ) )
    test.is_same( color2, hm_view:get( 6, 21 ) )
    test.is_same( color2, hm_view:get( 10, 25 ) )
    test.is_same( color2, hm_view:get( 10, 25 ) )
       
end

local function _heatmap_view_file_roundtrip()
    local reference_file   = test.get_resource_file( "heatmap.bmp" )    
    local reference_bitmap = bitmap.open( reference_file )
    
    local pal = {}
    palettes.add_gradient( pal, 0xFF0000FF, 0xFFFFFFFF, 8 )
    palettes.add_gradient( pal, nil, 0xFFFF0000, 7 )

    local hm_palette = heatmap.make_heatmap_palette( 2, 16, pal )

    local hm = heatmap.create( 8, 8 )
    for y = 1, hm:height() do
        for x = 1, hm:width() do
            hm:set( x, y, x + y )
        end
    end

    local hm_view = heatmap.make_bitmap_view( hm, 14, 14, hm_palette )
    test.is_same_bitmap( hm_view, reference_bitmap )

    local result_file = test.get_results_file( "heatmap.bmp" )
    bitmap.save( hm_view, result_file, "RGB4", pal )
    
    local result_bitmap = bitmap.open( result_file )    
    test.is_same_bitmap( result_bitmap, reference_bitmap )
end


local tests =
{
    default_creation            = _default_creation,
    creation_with_initial_value = _creation_with_initial_value,
    heatmap_set_value           = _heatmap_set_value,
    heatmap_increase_value      = _heatmap_increase_value,
    heatmap_decrease_value      = _heatmap_decrease_value,
    heatmap_palette             = _heatmap_palette,
    bitmap_view                 = _bitmap_view,
    heatmap_view_file_roundtrip = _heatmap_view_file_roundtrip
}

return tests
