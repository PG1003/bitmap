local bmp  = require( "bitmap" )
local test = require( "test" )

local reference = bmp.open( test.get_resource_file( "reference.bmp" ) )
    
local tests = {}

function tests.blit()
    local dst  = bmp.create( 10, 10, 0xFFFF0000 )
    local src1 = bmp.create( 4, 4, 0xFF00FF00 )
    local src2 = bmp.create( 4, 4, 0xFF0000FF )

    -- Center
    bmp.blit( dst, 4, 4, src1 )

    -- Partial verlap
    bmp.blit( dst, -2, -2, src1 )
    bmp.blit( dst, -2,  9, src1 )
    bmp.blit( dst,  9,  9, src1 )
    bmp.blit( dst,  9, -2, src1 )

    if not test.is_same_bitmap( reference, dst ) then
        bmp.save( dst, test.get_results_file( "blit_partial_overlap.bmp" ), "RGB24" )
    end

    -- No overlap
    bmp.blit( dst, 11,  1, src2 )
    bmp.blit( dst,  1, 11, src2 )
    bmp.blit( dst, -4,  1, src2 )
    bmp.blit( dst,  1, -4, src2 )
    
    if not test.is_same_bitmap( reference, dst ) then
        bmp.save( dst, test.get_results_file( "blit_no_overlap.bmp" ), "RGB24" )
    end
end


local function _fill_vp( vp, color )
    for y = 1, #vp do
        local row = vp[ y ]
        for x = 1, #row do
            row[ x ] = color
        end
    end
end

function tests.modify_via_viewport()
    local dst = bmp.create( 10, 10, 0xFFFF0000 )

    local vp1 = bmp.make_viewport( dst, 4, 4, 4, 4 )    -- center
    local vp2 = bmp.make_viewport( dst, 1, 1, 2, 2 )    -- ll
    local vp3 = bmp.make_viewport( dst, 1, 9, 2, 2 )    -- ul
    local vp4 = bmp.make_viewport( dst, 9, 9, 2, 2 )    -- ur
    local vp5 = bmp.make_viewport( dst, 9, 1, 2, 2 )    -- lr

    _fill_vp( vp1, 0xFF00FF00 )
    _fill_vp( vp2, 0xFF00FF00 )
    _fill_vp( vp3, 0xFF00FF00 )
    _fill_vp( vp4, 0xFF00FF00 )
    _fill_vp( vp5, 0xFF00FF00 )

    if not test.is_same_bitmap( reference, dst ) then
        bmp.save( dst, test.get_results_file( "modify_via_viewport.bmp" ), "RGB24" )
    end
end

function tests.save_viewport_content()
    local dst = bmp.create( 12, 12, 0xFFFF0000 )
    local src = bmp.create( 4, 4, 0xFF00FF00 )

    bmp.blit( dst,  5,  5, src )
    bmp.blit( dst, -1, -1, src )
    bmp.blit( dst, -1, 10, src )
    bmp.blit( dst, 10, 10, src )
    bmp.blit( dst, 10, -1, src )
    
    local vp = bmp.make_viewport( dst, 2, 2, 10, 10 )

    if not test.is_same_bitmap( reference, vp ) then
        bmp.save( vp, test.get_results_file( "save_viewport_content.bmp" ), "RGB24" )
    end
end

function test.iterate_pixels()
    local pixel_count = 0
    local pixels      = bmp.pixels( reference )
    
    test.is_same( #pixels, reference:width() * reference:height() )
    
    for i = 1, #pixels do
        test.is_not_nil( pixels[ i ] )
    end
end

function test.iterate_pixels_ipairs()
    for i, pixel in ipairs( reference:pixels() ) do
        test.is_not_nil( pixel )
    end
end


return tests
