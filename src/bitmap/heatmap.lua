-- Copyright (c) 2021 PG1003
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


local math_tointeger = math.tointeger


local function _mask_new_values( self, key, value )
    assert( false, "Accessing element outside the heatmap" )
end

local _mask_new_values_mt =
{
    __metatable = false,
    __newindex  = _mask_new_values
}

local function _get( self, x, y )
    return self[ y ][ x ]
end

local function _set( self, x, y, value )
    self[ y ][ x ] = value
end

local function _increase( self, x, y, value )
    value = value or 1
    self[ y ][ x ] = self[ y ][ x ] + value
end

local function _decrease( self, x, y, value )
    value = value or 1
    self[ y ][ x ] = self[ y ][ x ] - value
end

local function _width( self )
    return #self[ 1 ]
end

local function _height( self )
    return #self
end

local _heatmap_mt =
{
    __metatable = false,
    __index     =
        {
            get      = _get,
            set      = _set,
            increase = _increase,
            decrease = _decrease,
            width    = _width,
            height   = _height
        },
    __len      = rawlen,
    __newindex = _mask_new_values
}

local function _create( width, height, init )
    assert( math.type( width ) == "integer" and width > 0 )
    assert( math.type( height ) == "integer" and height > 0 )
    init = type( init ) == "number" and init or 0
    
    local hm = {}
    
    local row = {}
    for x = 1, width do
        row[ x ] = init
    end
    
    hm[ 1 ] = setmetatable( row, _mask_new_values_mt )
    
    for y = 2, height do
        hm[ y ] = setmetatable( table.move( row, 1, width, 1, {} ), _mask_new_values_mt )
    end
    
    return setmetatable( hm, _heatmap_mt )
end

local function _assert_read_only()
    assert( false, "Attempt to modify bitmap_view of a heatmap" )
end

local _bitmap_view_mt =
{
    __metatable = false,
    __index     =
        {
            width  = function( self ) return #self[ 1 ] end,
            height = function( self ) return #self end,
            get    = function( self, x, y ) return self[ y ][ x ] end
        },
    
    __newindex = _assert_read_only
}

local function _make_bitmap_view( hm, cell_size_x, cell_size_y, hm_palette )
    assert( math.type( cell_size_x ) == "integer" and cell_size_x > 0 )
    assert( math.type( cell_size_y ) == "integer" and cell_size_y > 0 )
    
    local hm_x_mapping = {}
    for x = 1, hm:width() do
        for _ = 1, cell_size_x do
            hm_x_mapping[ #hm_x_mapping + 1 ] = x
        end
    end
    
    local len_x = function( self ) return #hm_x_mapping end
    
    local view = {}
    for y = 1, hm:height() do
        local hm_y       = hm[ y ]
        local x_proxy_mt =
        {
            __metatable = false,
            __index     = function( self, key ) return hm_palette( hm_y[ hm_x_mapping[ key ] ] ) end,
            __newindex  = _assert_read_only,
            __len       = len_x 
        }
        local x_proxy = setmetatable( {}, x_proxy_mt )

        for _ = 1, cell_size_y do
            view[ #view + 1 ] = x_proxy
        end
    end
    
    return setmetatable( view, _bitmap_view_mt )
end

local function _make_heatmap_palette( min, max, palette, out_of_range_color )
    out_of_range_color = out_of_range_color or 0xFF000000
    
    assert( type( min ) == "number", "number expected" )
    assert( type( max ) == "number", "number expected" )
    assert( min < max, "min is larger or equal to max" )
    assert( type( palette ) == "table" and #palette > 0 )
    assert( math.type( out_of_range_color ) == "integer" )
    
    local range       = max - min
    local bucket_size = range / ( #palette - 1 )
    
    return function( value )
                local offset = ( value - min ) / bucket_size
                local bucket = 1 + math_tointeger( offset // 1 )
                return palette[ bucket ] or out_of_range_color
            end
end

local heatmap =
{
    create               = _create,
    make_bitmap_view     = _make_bitmap_view,
    make_heatmap_palette = _make_heatmap_palette
}

return heatmap
