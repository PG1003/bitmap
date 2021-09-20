-- Copyright (c) 2019 PG1003
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local color = require( "bitmap.color" )


--
-- Make frequently used and/or hot global library functions local to gain some performance
--

local math_min         = math.min
local math_max         = math.max
local math_type        = math.type
local math_abs         = math.abs
local table_concat     = table.concat
local table_move       = table.move
local string_pack      = string.pack
local string_unpack    = string.unpack
local coroutine_resume = coroutine.resume
local coroutine_yield  = coroutine.yield

local color_to_Lab    = color.to_Lab
local color_luminance = color.luminance
local color_delta_e94 = color.delta_e94

--
-- Local helper functions
--

-- Calculates the width and the left shift of the mask
local function _calc_mask_shift( mask )        
    -- Count leading least significant zeros
    for shift = 0, 31 do
        local m = mask >> shift
            -- Get width of the mask
        if ( m & 0x01 ) ~= 0 then
            return shift
        end
    end
    error( "No masking bits found" )
end

local function _calc_mask_width( mask )
    local width = math.log( mask + 1, 2 )
    assert( ( 2 ^ width ) - 1 == mask )
    return width
end

-- Calculates how much the masked value must shift to fit in the most significant
-- part at location elsewhere in a 32 bit word pointed by 'width' and 'offset'.
local function _calc_shift( from, to )
    
    local shift_from = _calc_mask_shift( from )
    local width_from = _calc_mask_width( from >> shift_from )
    local shift_to   = _calc_mask_shift( to )
    local width_to   = _calc_mask_width( to >> shift_to )
    
    assert( width_from ~= 0 or width_to ~= 0 )
    
    return ( width_to - width_from ) + ( shift_to - shift_from )
end


local function _decode_bitmap_format( format )
    format = string.upper( format )
    
    local rgb, bits_per_pixel = string.match( format, "^(RGB)(%d+)$" )
    
    if rgb == "RGB" and bits_per_pixel then
        bits_per_pixel = tonumber( bits_per_pixel )
        if bits_per_pixel == 1 or
           bits_per_pixel == 4 or
           bits_per_pixel == 8 then
            return "indexed", bits_per_pixel
        elseif bits_per_pixel == 16 then
            return "rgb", 16, 0x7C00, 0x03E0, 0x001F
        elseif bits_per_pixel == 24 then
            return "rgb", 24, 0xFF0000, 0x00FF00, 0x0000FF
        elseif bits_per_pixel == 32 then
            return "rgb", 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000
        end
    end

    bits_per_pixel = 0
    local r_mask = nil
    local g_mask = nil
    local b_mask = nil
    local a_mask = nil
    
    do
        local order, size = string.match( format, "^([RGBA]+)([1-8]+)$" )
        assert( order and size, "Unrecognized format" )
        
        local it_order, s_order, color_order = order:gmatch( "." )
        local it_size, s_size, color_size    = size:gmatch( "." )
        
        local colors = {}
        
        while true do
            color_order = it_order( s_order, color_order )
            color_size  = it_size( s_size, color_size )
            assert( color_order and color_size or not color_order and not color_size, "Count of color field order and masks don't match" )
            
            if color_order and color_size then
                local color_width     = math.tointeger( color_size )
                local color_mask      = 2 ^ color_width - 1
                bits_per_pixel        = bits_per_pixel + color_width
                colors[ #colors + 1 ] = { color_order, color_width }
            else
                break
            end
        end
        
        local shift = bits_per_pixel
        for i = 1, #colors do
            local color                    = colors[ i ]
            local color_order, color_width = table.unpack( color )
            assert( color_width > 0 and color_width <= 8, "Unsupported numer of bits per color component; minimum 1 bit, maximum 8 bits" )
            
            shift      = shift - color_width
            local mask = ( 2 ^ color_width - 1 ) << shift
            if color_order == "R" then
                r_mask = assert( not r_mask and mask, "Mask for R field already defined" )
            elseif color_order == "G" then
                g_mask = assert( not g_mask and mask, "Mask for G field already defined" )
            elseif color_order == "B" then
                b_mask = assert( not b_mask and mask, "Mask for B field already defined" )
            elseif color_order == "A" then
                a_mask = assert( not a_mask and mask, "Mask for A field already defined" )
            end
        end
        
        assert( shift == 0 )
    end
    
    -- Bitfields always packed as 16 or 32 bits per pixel
    bits_per_pixel = assert( bits_per_pixel <= 16 and 16 or bits_per_pixel <= 32 and 32 )
    
    return "bitfields",
           bits_per_pixel, 
           assert( r_mask, "Mask for R field not defined" ),
           assert( g_mask, "Mask for G field not defined" ),
           assert( b_mask, "Mask for B field not defined" ),
           a_mask
end

local function _encode_bitmap_bitfields_format( bitfields )
    table.sort( bitfields, function( l, r ) return l[ 1 ] > r[ 1 ] end )
    
    local order = {}
    local size  = {}
    for i = 1, #bitfields do
        local v          = bitfields[ i ]
        local mask_shift = _calc_mask_shift( v[ 1 ] )
        local mask_width = _calc_mask_width( v[ 1 ] >> mask_shift )
        
        size[ #size + 1 ]   = string.format( "%d", mask_width )
        order[ #order + 1 ] = v[ 2 ]
    end
    
    return table_concat( order ) .. table_concat( size )
end

local function _encode_bitmap_format( compression, bits_per_pixel, r_mask, g_mask, b_mask, a_mask )
    if compression == "indexed" then
        if bits_per_pixel == 1 or
           bits_per_pixel == 4 or
           bits_per_pixel == 8 then
            return string.format( "RGB%d", bits_per_pixel )
        end
    elseif compression == "rgb" then
        if bits_per_pixel == 16 or
           bits_per_pixel == 24 or
           bits_per_pixel == 32 then
            return string.format( "RGB%d", bits_per_pixel )
        end
    elseif compression == "bitfields" then
        local masks = { { r_mask, "R" }, { g_mask, "G" }, { b_mask, "B" } }
        if a_mask > 0 then
            masks[ #masks + 1 ] = { a_mask, "A" }
        end
        return _encode_bitmap_bitfields_format( masks )
    end
end

--
-- Bitmap library
--

local function _save( bmp, file, format, palette )
        
    local f = io.open( file, "w+b" )
    if not f then
        error( "Cannot create file: " .. file, 0 )
    end
    
    local compression, bits_per_pixel, red_mask, green_mask, blue_mask, alpha_mask = _decode_bitmap_format( format )
    
    palette = bits_per_pixel <= 8 and palette
    
    local width  = bmp:width()
    local height = bmp:height()
    
    -- A bitmap row must always be a multiple of 4 bytes
    local padding_in_bytes = ( 4 - ( width * bits_per_pixel ) & 0x03 )
    local row_in_bytes     = ( width * bits_per_pixel ) // 32 + padding_in_bytes
    local bitmap_size      = row_in_bytes * height
    
    -- Use dib v3 indexed bitmaps or v4 for larger pixel sizes
    -- The v4 header is larger and contains data which is not used by indexed bitmaps
    local dib_version = compression == "bitfields" and 4 or 3
    
    -- Bitmap file header
    local bitmap_header_size = 14
    local dib_size           = assert( dib_version == 3 and 40 or dib_version == 4 and 108 )
    local color_table_size   = palette and #palette * 4 or 0    -- Each entry in the color table is 4 bytes
    
    local signature        = "BM"
    local file_size        = bitmap_header_size + dib_size + color_table_size + bitmap_size
    local bitmap_reserved1 = 0
    local bitmap_reserved2 = 0
    local bitmap_offset    = bitmap_header_size + dib_size + color_table_size
    
    f:write( signature )
    f:write( string_pack( "<I4<I2<I2<I4", file_size, bitmap_reserved1, bitmap_reserved2, bitmap_offset ) )

    -- Bitmap dib
    f:write( string_pack( "I4i4i4I2I2I4I4I4I4I4I4",
             dib_size,
             width,
             height,
             1,                         -- Color planes, only 1 supported
             bits_per_pixel,
             compression == "indexed" and 0 or compression == "rgb"and 0 or compression == "bitfields" and 3,
             bitmap_size,
             7787,                      -- Horizontal resolution, Gimp uses 7787  pixels per meter
             7787,                      -- Vertical resolution
             palette and #palette or 0, -- Number palette colors
             0 ) )                      -- Color important, the number of colors used from the color table. 0 means all colors are important
    
    if dib_version >= 4 then
        f:write( string_pack( "I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4",
                 red_mask,
                 green_mask,
                 blue_mask,
                 alpha_mask or 0,
                 0,      -- Color space type
                 0,      -- Red X
                 0,      -- Red Y
                 0,      -- Red Z
                 0,      -- Green X
                 0,      -- Green Y
                 0,      -- Green Z
                 0,      -- Blue X
                 0,      -- Blue Y
                 0,      -- Blue Z
                 0,      -- Gamma red
                 0,      -- Gamma green
                 0 ) )   -- Gamma blue
    end
    
    -- Write color table
    if palette then
        assert( #palette <= ( 2 ^ bits_per_pixel ) )
        for i = 1, #palette do            
            f:write( string_pack( "I4", palette[ i ] ) )
        end
    end
    
    local x_start = width > 0 and 1 or width
    local x_stop  = width > 0 and width or 1
    local x_step  = width > 0 and 1 or -1
    local y_start = height > 0 and 1 or height
    local y_stop  = height > 0 and height or 1
    local y_step  = height > 0 and 1 or -1
    if compression == "indexed" then
        if bits_per_pixel <= 8 then
            assert( palette, "Format '" .. format .. "' requires a palette" )
            
            local fast_lookup = {}
            local Lab_lookup  = {}
            for i = 1, #palette do
                local value          = palette[ i ]
                fast_lookup[ value ] = i - 1
                Lab_lookup[ i ]      = { color_to_Lab( value ) }
            end
            
            local shift_start = 32 - bits_per_pixel
            for y = y_start, y_stop, y_step do
                local row   = bmp[ y ]
                local shift = shift_start
                local chunk = 0
                for x = x_start, x_stop, x_step do
                    if shift < 0 then
                        f:write( string_pack( ">I4", chunk ) )
                        shift = shift_start
                        chunk = 0
                    end
                    local value       = row[ x ]
                    local color_index = fast_lookup[ value ]
                    if not color_index then
                        -- Find index in color table of the color closesed to 'value'
                        local L1, a1, b1       = color_to_Lab( value )
                        local nearest_distance = 100   -- Maximum distance
                        color_index            = 1
                        for i = 1, #palette do
                            local Lab      = Lab_lookup[ i ]
                            local distance = color_delta_e94( L1, a1, b1, Lab[ 1 ], Lab[ 2 ], Lab[ 3 ] )
                            if distance < nearest_distance then
                                color_index      = i
                                nearest_distance = distance
                            end
                        end
                        color_index          = color_index - 1  -- Make zero based
                        fast_lookup[ value ] = color_index      -- Memorize result
                    end
                    chunk = chunk | ( color_index << shift )
                    shift = shift - bits_per_pixel
                end
                f:write( string_pack( ">I4", chunk ) )
            end
        end
    elseif compression == "rgb" or compression == "bitfields" then        
        local red_shift   = _calc_shift( 0x00FF0000, red_mask )
        local green_shift = _calc_shift( 0x0000FF00, green_mask )
        local blue_shift  = _calc_shift( 0x000000FF, blue_mask )
        local alpha_shift = 0
        
        local red_pixel_mask   = red_mask   >> red_shift
        local green_pixel_mask = green_mask >> green_shift
        local blue_pixel_mask  = blue_mask  >> blue_shift
        local alpha_pixel_mask = 0
        
        if alpha_mask and alpha_mask > 0 then
            alpha_shift = _calc_shift( 0xFF000000, alpha_mask )
            alpha_pixel_mask = alpha_mask >> alpha_shift
        end
        
        local pixel_size   = assert( bits_per_pixel <= 16 and 2 or bits_per_pixel == 24 and 3 or bits_per_pixel <= 32 and 4 )
        local pack_pattern = string.format( "I%d", pixel_size )
        local padding_mod  = ( width * pixel_size ) & 0x03
        local padding      = padding_mod > 0 and string_pack( "I".. 4 - padding_mod, 0 ) or ""
        for y = y_start, y_stop, y_step do
            local row = bmp[ y ]
            for x = x_start, x_stop, x_step do
                local value = row[ x ]
                local red   = ( value & red_pixel_mask )   << red_shift
                local green = ( value & green_pixel_mask ) << green_shift
                local blue  = ( value & blue_pixel_mask )  << blue_shift
                local alpha = alpha_mask and ( value & alpha_mask ) << alpha_shift or 0

                f:write( string_pack( pack_pattern, red | green | blue | alpha ) )
            end
            f:write( padding )
        end
    end
    
    f:close()
end


local function _pixels_len( self )
    return self.len
end

local function _pixels_index( self, index )
    index     = index - 1    
    local row = self.bmp[ 1 + ( index // self.width ) ]
    return row and row[ 1 + index % self.height ]
end
    

local function _pixels( bmp )
    return setmetatable(
        {
            bmp    = bmp,
            width  = bmp:width(),
            height = bmp:height(),
            len    = bmp:width() * bmp:height()
        },
        {
            __metatable = false,
            __len       = _pixels_len,
            __index     = _pixels_index,
            __newindex  = false
        } )
end

local function _width( self )
    return #self[ 1 ]
end

local function _height( self )
    return #self
end

local function _get( self, x, y )
    return self[ y ][ x ]
end

local function _set( self, x, y, color )
    self[ y ][ x ] = color
end

local function _mask_new_pixels( self, key, value )
    if type( key ) ~= "number" then
        self[ key ] = value
    end
end


local _row_pixel_mask_mt =
{
    __metatable = false,
    __newindex  = _mask_new_pixels
} 


local _bmp_mt =
{
    __metatable = false,
    
    __index = 
        {
            width     = _width,
            height    = _height,
            get       = _get,
            set       = _set
        },

    __newindex = _mask_new_pixels
}

local function _compression_format_type( compression_type, bits_per_pixel )
    if bits_per_pixel > 8 then
        return assert( compression_type == 0 and "rgb" or       -- No alpha
                       compression_type == 3 and "bitfields" or -- (alpha) bitfields only for 16 and 32 bit per pixel bitmaps
                       compression_type == 6 and "bitfields",
                       "Unsupported compression method" )
    else
        return assert( compression_type == 0 and "indexed", "Unsupported compression method" )
    end
end

local function _read_dib( f )
   
    local dib_size = string_unpack( "I4", f:read( 4 ) )
    local version  = assert( dib_size == 12 and 2 or
                             dib_size == 40 and 3 or
                             dib_size == 108 and 4 or
                             dib_size == 124 and 5 )

    if version == 2 then
        local width, height, color_planes, bits_per_pixel = string_unpack( "i2i2I2I2", f:read( 8 ) ) -- width, height, color planes, bits per pixel
        return dib_size, width, height, bits_per_pixel 
    else
        local width, height, color_planes, bits_per_pixel = string_unpack( "i4i4I2I2", f:read( 12 ) )
        assert( color_planes == 1 )    -- Only support for one plane
        
        local compression_type = string_unpack( "I4", f:read( 4 ) )        
        local compression      = _compression_format_type( compression_type, bits_per_pixel )
        
        -- Skip bitmap size
        -- Skip horizontal resolution
        -- Skip vertical resolution
        f:seek( "cur", 12 )
        local number_palette_colors = string_unpack( "I4", f:read( 4 ) )
        -- Skip important color
        f:seek( "cur", 4 )
        
        if compression ~= "bitfields" then
            if bits_per_pixel <= 8 then
                return dib_size, width, height, bits_per_pixel, compression, number_palette_colors
            elseif bits_per_pixel == 16 then
                return dib_size, width, height, bits_per_pixel, compression, number_palette_colors, 0x7C00, 0x03E0, 0x001F
            elseif bits_per_pixel == 24 then
                return dib_size, width, height, bits_per_pixel, compression, number_palette_colors, 0xFF0000, 0x00FF00, 0x0000FF
            elseif bits_per_pixel == 32 then
                return dib_size, width, height, bits_per_pixel, compression, number_palette_colors, 0x00FF0000, 0x0000FF00, 0x000000FF
            end
        end

        local red_mask, green_mask, blue_mask, alpha_mask = string_unpack( "I4I4I4I4", f:read( 16 ) )
        -- Skip remaining fields of DIB v4 header; this library has no support for colorspaces
        
        return dib_size, width, height, bits_per_pixel, compression, number_palette_colors, red_mask, green_mask, blue_mask, alpha_mask
        
        -- DIB v5 is not used by this library
    end
end

local function _open( file )
    
    local f = io.open( file, "rb" )
    if not f then
        error( "Cannot open file: " .. file )
    end

    -- Bitmap file dib
    local signature = f:read( 2 )
    if signature ~= "BM" then
        error( "Unsupported bitmap file type" )
    end

    local file_size, bitmap_reserved1, bitmap_reserved2, bitmap_offset = string_unpack( "<I4<I2<I2<I4", f:read( 12 ) )
    local dib_size, width, height, bits_per_pixel, compression, number_palette_colors, red_mask, green_mask, blue_mask, alpha_mask = _read_dib( f )
    
    -- Allocate bimap
    assert( height > 0 or height < 0 )
    assert( width > 0 or width < 0 )
    local bmp = {}
    for y = 1, height do
        bmp[ y ] = {}
    end 
    
    local x_start = width > 0 and 1 or width
    local x_stop  = width > 0 and width or 1
    local x_step  = width > 0 and 1 or -1
    local y_start = height > 0 and 1 or height
    local y_stop  = height > 0 and height or 1
    local y_step  = height > 0 and 1 or -1
    
    local row_data_len = bits_per_pixel * math.abs( width ) // 8
    row_data_len       = row_data_len + ( 4 - row_data_len & 0x03 )
    
    assert( f:seek( "set", bitmap_offset ) == bitmap_offset )
    
    local palette = nil
    if compression == "indexed" then
        -- We have a color table...
        palette                 = {}
        local color_table_start = 14 + dib_size -- Bitmap dib is 14 bytes + size of dib
        assert( f:seek( "set", color_table_start ) )
        -- Fill table
        local entries    = number_palette_colors == 0 and 2 ^ bits_per_pixel or number_palette_colors
        local table_data = f:read( 4 * entries )
        local table_pos  = 1
        for index = 1, entries do
            palette[ index ], table_pos = string_unpack( "<I4", table_data, table_pos )
        end
        
        local mask           = 2 ^ bits_per_pixel - 1
        local shift_start    = 32 - bits_per_pixel
        for y = y_start, y_stop, y_step do
            local row_data     = f:read( row_data_len )
            local row_data_pos = 1
            local row          = bmp[ y ]
            local shift        = -1
            local chunk        = 0
            for x = x_start, x_stop, x_step do
                if shift < 0 then
                    chunk, row_data_pos = string_unpack( ">I4", row_data, row_data_pos )
                    shift               = shift_start
                end
                local value = ( chunk >> shift ) & mask
                row[ x ]    = assert( palette[ value + 1 ] )
                shift       = shift - bits_per_pixel
            end
            setmetatable( row, _row_pixel_mask_mt )
        end
    elseif compression == "rgb" or compression == "bitfields" then
        -- Only 16 or 32 bits are supported by bitfields
        local pixel_size     = assert( bits_per_pixel <= 16 and 2 or bits_per_pixel == 24 and 3 or bits_per_pixel <= 32 and 4 )
        local unpack_pattern = string.format( "I%d", pixel_size )

        local red_shift   = _calc_shift( red_mask,   0x00FF0000 )
        local green_shift = _calc_shift( green_mask, 0x0000FF00 )
        local blue_shift  = _calc_shift( blue_mask,  0x000000FF )
        local alpha_shift = 0
        
        if alpha_mask and alpha_mask > 0 then
            alpha_shift = _calc_shift( alpha_mask, 0xFF000000 )
        end
        
        local unpack_format = string.format( "I%d", bits_per_pixel // 8 )
        for y = y_start, y_stop, y_step do
            local row_data     = f:read( row_data_len )
            local row_data_pos = 1
            local row          = bmp[ y ]
            local chunk
            for x = x_start, x_stop, x_step do
                local value         = 0
                chunk, row_data_pos = string_unpack( unpack_format, row_data, row_data_pos )
                
                local red   = ( chunk & red_mask )   << red_shift
                local green = ( chunk & green_mask ) << green_shift
                local blue  = ( chunk & blue_mask )  << blue_shift
                local alpha = alpha_mask and ( chunk & alpha_mask ) << alpha_shift or 0xFF000000
                
                row[ x ] = red | green | blue | alpha
            end
                setmetatable( row, _row_pixel_mask_mt )
        end
    end
    
    setmetatable( bmp, _bmp_mt )
    
    local format = _encode_bitmap_format( compression, bits_per_pixel, red_mask, green_mask, blue_mask, alpha_mask )
    
    return bmp, format, palette
end


local function _create( width, height, init_color )
    assert( math.type( width ) == "integer" and width > 0 )
    assert( math.type( height ) == "integer" and height  > 0 )
    assert( init_color == nil or math.type( init_color ) == "integer" and ( init_color > 0 ) )
    
    init_color = init_color or 0
    
    local bmp = {}
    for y = 1, height do
        local row = {}
        for x = 1, width do
            row[ x ] = init_color
        end
        bmp[ y ] = setmetatable( row, _row_pixel_mask_mt )
    end
    
    return setmetatable( bmp, _bmp_mt )
end

local function _make_viewport_table( t, len, offset )
    assert( #t >= ( len + offset - 1 ) )
    return setmetatable(
        {},
        {
            __metatable = false,
            __len       = function( self ) return len end,
            __index     = function( self, i ) return t[ i + offset ] end,
            __newindex  = function( self, i, v ) t[ i + offset ] = v end
        } )
end

local function _make_viewport( src_bmp, x, y, width, height )
    assert( x > 0 )
    assert( y > 0 )
    assert( width > 0 )
    assert( height  > 0 )
    assert( src_bmp:width() >= ( x + width - 1 ) )
    assert( src_bmp:height() >= ( y + height - 1 ) )
    
    local bmp_proxy = {}
    for y_proxy = 1, height do
        bmp_proxy[ y_proxy ] = _make_viewport_table( src_bmp[ y_proxy + y - 1 ], width, x - 1 )
    end 
    
    return setmetatable( bmp_proxy, _bmp_mt )
end

local function _blit( dst, x, y, src )
    if x > dst:width() or x <= -src:width() or y > dst:height() or y <= -src:height() then
        -- No overlap
        return
    end
    
    -- Calculate the overlapping part of the source with the destination
    local src_start_x = math.max( 1, 1 + -x )
    local src_stop_x  = math.min( math.abs( 1 + dst:width() - x ), src:width() )
    local src_start_y = math.max( 1, 1 + -y )
    local src_stop_y  = math.min( math.abs( 1 + dst:height() - y ), src:height() )

    -- Calculate indices where to insert at the destination
    local dst_x = math.max( 1, x )
    local dst_y = math.max( 1, y )
    
    for src_y = src_start_y, src_stop_y do
       table_move( src[ src_y ], src_start_x, src_stop_x, dst_x , dst[ dst_y ] )
       dst_y = dst_y + 1
    end
end

local function _diff( left, right )
    assert( left:width() == right:width() )
    assert( left:height() == right:height() )
    
    local diff = {}
    
    for y = 1, left:height() do
        local diff_row  = setmetatable( {}, _row_pixel_mask_mt )
        local left_row  = left[ y ]
        local right_row = right[ y ]
        for x = 1, left:width() do
            local l_value = left_row[ x ]
            local r_value = right_row[ x ]
            
            local r = math_abs( ( ( l_value & 0x00FF0000 ) >> 16 ) - ( ( r_value & 0x00FF0000 ) >> 16 ) )
            local g = math_abs( ( ( l_value & 0x0000FF00 ) >>  8 ) - ( ( r_value & 0x0000FF00 ) >>  8 ) )
            local b = math_abs(   ( l_value & 0x000000FF )         -   ( r_value & 0x000000FF )         )
            
            diff_row[ x ] = r << 16 | g << 8 | b
        end
        diff[ y ] = diff_row
    end
    
    return setmetatable( diff, _bmp_mt )
end

local function _psnr( reference, other )
    assert( reference:width() == other:width() )
    assert( reference:height() == other:height() )
    
    local count = reference:width() * reference:height()
    local mse_r = 0.0
    local mse_g = 0.0
    local mse_b = 0.0
    
    for y = 1, reference:height() do
        local ref_row   = reference[ y ]
        local other_row = other[ y ]
        for x = 1, reference:width() do
            local ref_pixel   = ref_row[ x ]
            local other_pixel = other_row[ x ]
            
            local ref_r   = ( ref_pixel & 0xFF0000 ) >> 16
            local ref_g   = ( ref_pixel & 0x00FF00 ) >>  8
            local ref_b   =   ref_pixel & 0x0000FF
            local other_r = ( other_pixel & 0xFF0000 ) >> 16
            local other_g = ( other_pixel & 0x00FF00 ) >>  8
            local other_b =   other_pixel & 0x0000FF
            
            local d_r = ref_r - other_r
            local d_g = ref_g - other_g
            local d_b = ref_b - other_b
            
            mse_r = mse_r + ( d_r * d_r ) / count
            mse_g = mse_g + ( d_g * d_g ) / count
            mse_b = mse_b + ( d_b * d_b ) / count
        end
    end
    
    local log_255    = 20 * math.log( 255 , 10 )
    local mse_total  = ( mse_r + mse_g + mse_b ) / 3.0
    
    local psnr_total = log_255 - 10 * math.log( mse_total, 10 )
    local psnr_r     = log_255 - 10 * math.log( mse_r, 10 )
    local psnr_g     = log_255 - 10 * math.log( mse_g, 10 )
    local psnr_b     = log_255 - 10 * math.log( mse_b, 10 )
    
    return psnr_total, psnr_r, psnr_g, psnr_b
end

-- https://tannerhelland.com/2012/12/28/dithering-eleven-algorithms-source-code.html
-- https://shihn.ca/posts/2020/dithering/

local function _dither_bw( bmp )
    local quatization_lookup = {}
    local diffuse_0          = {}
    local diffuse_1          = {}
    
    local width = bmp:width()
    
    for i = 1, width do
        diffuse_1[ i ] = 0.0
    end
    
    for _, row in ipairs( bmp ) do
        diffuse_0, diffuse_1 = diffuse_1, diffuse_0
        
        -- Reset diffusion buffer.
        -- For Floyd-Steinberg only the first item needs to be zero'd.
        -- The remaining values are overwritten by the algoritm.
        diffuse_1[ 1 ] = 0.0
        
        for x, value in ipairs( row ) do
            local x_next = x + 1
            local x_prev = x - 1
            local L      = color_luminance( value ) + ( diffuse_0[ x ] / 16.0 )
            
            if L >= 50.0 then
                L        = L - 100.0
                row[ x ] = 0xFFFFFFFF
            else
                row[ x ] = 0xFF000000
            end
            
            diffuse_1[ x ] = diffuse_1[ x ] + 5.0 * L
            
            if x_prev >= 1 then
                diffuse_1[ x_prev ] = diffuse_1[ x_prev ] + 3.0 * L
            end
            if x_next <= width then
                diffuse_0[ x_next ] = diffuse_0[ x_next ] + 7.0 * L
                diffuse_1[ x_next ] = L
            end
        end
    end    
end

local function _dither( bmp, format, palette )
    local compression, bits_per_pixel, red_mask, green_mask, blue_mask, alpha_mask = _decode_bitmap_format( format )
    
    local quantize = nil
    if compression == "indexed" then
        assert( type( palette ) == "table" and #palette > 0 )
        
        local quatization_lookup = {}
        local palette_Lab_lookup = {}
        
        for _, value in ipairs( palette ) do
            palette_Lab_lookup[ value & 0x00FFFFFF ] = { color_to_Lab( value ) }
            quatization_lookup[ value ]              = value
        end
        
        quantize = function( color )   
            local quantized_color = quatization_lookup[ color ]
            if not quantized_color then
                local L1, a1, b1       = color_to_Lab( color )
                local nearest_distance = 100.0   -- Maximum distance
                
                quantized_color = palette[ 1 ]
                for palette_color, Lab2 in pairs( palette_Lab_lookup ) do
                    local distance = color_delta_e94( L1, a1, b1, Lab2[ 1 ], Lab2[ 2 ], Lab2[ 3 ] )
                    if distance < nearest_distance then
                        quantized_color  = palette_color
                        nearest_distance = distance
                    end
                end
                quatization_lookup[ color ] = quantized_color
            end
            
            return quantized_color
        end
    else
        local all_masks = { { "R", red_mask }, { "G", green_mask }, { "B", blue_mask }, { "A", alpha_mask or 0 } }
        table.sort( all_masks, function( l, r ) return l[ 2 ] < r[ 2 ] end )
        
        local red_pixel_mask   = nil
        local green_pixel_mask = nil
        local blue_pixel_mask  = nil
        
        local shift = 0
        for _, color_mask in ipairs( all_masks ) do
            local color     = color_mask[ 1 ]
            local mask      = color_mask[ 2 ] >> shift
            local mask_size = math.log( 1 + mask, 2 )
            if color == "R" then
                red_pixel_mask = mask << ( 24 - mask_size )
            elseif color == "G" then
                green_pixel_mask = mask << ( 16 - mask_size )
            elseif color == "B" then
                blue_pixel_mask = mask << ( 8 - mask_size )
            end
            shift = shift + mask_size
        end
        
        local quantize_mask = red_pixel_mask | green_pixel_mask | blue_pixel_mask | 0xFF000000
        
        quantize = function( color )
            return color & quantize_mask
        end
    end
    
    local diffuse_0 = {}
    local diffuse_1 = {}
    
    local width = bmp:width()
    
    for x = 1, width do
        diffuse_0[ x ] = { 0, 0, 0 }
        diffuse_1[ x ] = { 0, 0, 0 }
    end
    
    for _, row in ipairs( bmp ) do
        diffuse_0, diffuse_1 = diffuse_1, diffuse_0
        
        diffuse_1[ 1 ][ 1 ] = 0
        diffuse_1[ 1 ][ 2 ] = 0
        diffuse_1[ 1 ][ 3 ] = 0

        for x, value in ipairs( row ) do
            local x_next = x + 1
            local x_prev = x - 1
            
            local r = ( value & 0xFF0000 ) >> 16
            local g = ( value & 0x00FF00 ) >>  8
            local b =   value & 0x0000FF
        
            local diffusion_error = diffuse_0[ x ]
            local r_diffused      = math_min( math_max( r + ( diffusion_error[ 1 ] // 16.0 ), 0 ), 255 )
            local g_diffused      = math_min( math_max( g + ( diffusion_error[ 2 ] // 16.0 ), 0 ), 255 )
            local b_diffused      = math_min( math_max( b + ( diffusion_error[ 3 ] // 16.0 ), 0 ), 255 )

            local diffused_color  = r_diffused << 16 | g_diffused << 8 | b_diffused
            local quantized_color = quantize( diffused_color )
            
            local r_quantized = ( quantized_color & 0xFF0000 ) >> 16
            local g_quantized = ( quantized_color & 0x00FF00 ) >>  8
            local b_quantized =   quantized_color & 0x0000FF
            
            local r_error = r_diffused - r_quantized
            local g_error = g_diffused - g_quantized
            local b_error = b_diffused - b_quantized
            
            local diffuse_1_x = diffuse_1[ x ]
            diffuse_1_x[ 1 ]  = diffuse_1_x[ 1 ] + 5 * r_error
            diffuse_1_x[ 2 ]  = diffuse_1_x[ 2 ] + 5 * g_error
            diffuse_1_x[ 3 ]  = diffuse_1_x[ 3 ] + 5 * b_error
            
            if x_prev >= 1 then
                local diffuse_1_prev = diffuse_1[ x_prev ]
                diffuse_1_prev[ 1 ]  = diffuse_1_prev[ 1 ] + 3 * r_error
                diffuse_1_prev[ 2 ]  = diffuse_1_prev[ 2 ] + 3 * g_error
                diffuse_1_prev[ 3 ]  = diffuse_1_prev[ 3 ] + 3 * b_error
            end
            if x_next <= width then
                local diffuse_0_next = diffuse_0[ x_next ]
                diffuse_0_next[ 1 ]  = diffuse_0_next[ 1 ] + 7 * r_error
                diffuse_0_next[ 2 ]  = diffuse_0_next[ 2 ] + 7 * g_error
                diffuse_0_next[ 3 ]  = diffuse_0_next[ 3 ] + 7 * b_error
                
                local diffuse_1_next = diffuse_1[ x_next ]
                diffuse_1_next[ 1 ]  = r_error
                diffuse_1_next[ 2 ]  = g_error
                diffuse_1_next[ 3 ]  = b_error
            end
            
            row[ x ] = quantized_color
        end
    end
end


local bitmap =
{
    save          = _save,
    pixels        = _pixels,
    create        = _create,
    open          = _open,
    make_viewport = _make_viewport,
    blit          = _blit,
    diff          = _diff,
    psnr          = _psnr,
    dither_bw     = _dither_bw,
    dither        = _dither
}

return bitmap
