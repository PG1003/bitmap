local bitmap = require( "bitmap" )
local color  = require( "color" )
local test   = require( "test" )

local tests = {}

local kodim23 = bitmap.open( test.get_resource_file( "kodim23.bmp" ) )

local function _test_rgb( formats )
    for _, format in ipairs( formats ) do
        local file_1 = test.get_results_file( "kodim23_%s_%d.bmp", format, 1 )
        kodim23:save( file_1, format )
        local bmp_1, format_1, palette_1 = bitmap.open( file_1 )
        
        local file_2 = test.get_results_file( "kodim23_%s_%d.bmp", format, 2 )
        bmp_1:save( file_2, format_1 )
        local bmp_2, format_2, palette_2 = bitmap.open( file_2 )
        
        test.is_same( type( bmp_1 ), "table" )
        test.is_same( format_1,  format )
        test.is_nil( palette_1 )    
        test.is_same_bitmap( bmp_1, bmp_2 )
    end
end

function tests.test_RGBxx()
    local formats = { "RGB32", "RGB24", "RGB16"}
    _test_rgb( formats )
end

function tests.test_RGB_bitfields()
    local formats = { "RGB888", "GBR888", "BRG888", "ARGB2222", "GARB8888" }
    _test_rgb( formats )
end

function tests.test_indexed()
    local formats = { [ 1 ] = "RGB1", [ 4 ] ="RGB4", [ 8 ] = "RGB8" }
    for n_bits, format in pairs( formats ) do
        local n_colors = math.tointeger( 2 ^ n_bits )
        local palette  = color.quantize( kodim23:pixels(), n_colors )
        
        local file_1 = test.get_results_file( "kodim23_%s_%d.bmp", format, 1 )
        kodim23:save( file_1, format, palette )
        local bmp_1, format_1, palette_1 = bitmap.open( file_1 )
        
        local file_2 = test.get_results_file( "kodim23_%s_%d.bmp", format, 2 )
        bmp_1:save( file_2, format_1, palette )
        local bmp_2, format_2, palette_2 = bitmap.open( file_2 )
        
        test.is_same( type( bmp_1 ), "table" )
        test.is_same( format_1, format )
        test.is_same( type( palette_1 ), "table" )
        
        test.is_same( type( bmp_1 ), type( bmp_2 ) )
        test.is_same( format_1, format_2 )
        test.is_same( type( palette_1 ), type( palette_2 ) )
        
        test.is_same_bitmap( bmp_1, bmp_2 )
    end
end

return tests
