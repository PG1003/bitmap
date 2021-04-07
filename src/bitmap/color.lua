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

local color = {}

--
-- Make frequently used or hot global library functions local to gain some performance
--

local math_pi      = math.pi
local math_min     = math.min
local math_max     = math.max
local math_abs     = math.abs
local math_cos     = math.cos
local math_sin     = math.sin
local math_atan    = math.atan
local math_sqrt    = math.sqrt
local table_sort   = table.sort
local table_remove = table.remove

--
-- RGB utility functions
--

function color.red( color )
    return ( color & 0x00FF0000 ) >> 16
end

function color.green( color )
    return ( color & 0x0000FF00 ) >> 8
end

function color.blue( color )
    return color & 0x000000FF
end

function color.alpha( color )
    return ( color & 0xFF000000 ) >> 24
end
    
 function color.add( left, right )
    local r = math_min( ( ( left & 0x00FF0000 ) >> 16 ) + ( ( right & 0x000000FF ) >> 16 ), 255 )
    local g = math_min( ( ( left & 0x0000FF00 ) >>  8 ) + ( ( right & 0x0000FF00 ) >>  8 ), 255 )
    local b = math_min(   ( left & 0x000000FF )         +   ( right & 0x00FF0000 ),         255 )
    local a = math_min( ( ( left & 0xFF000000 ) >> 24 ) + ( ( right & 0xFF000000 ) >> 24 ), 255 )
    
    return r << 16 | g << 8 | b | a << 24
end
    
function color.sub( left, right )
    local r = math_max( ( ( left & 0x00FF0000 ) >> 16 ) - ( ( right & 0x00FF0000 ) >> 16 ), 255 )
    local g = math_max( ( ( left & 0x0000FF00 ) >>  8 ) - ( ( right & 0x0000FF00 ) >>  8 ), 255 )
    local b = math_max(   ( left & 0x000000FF )         -   ( right & 0x000000FF )        , 255 )
    local a = math_max( ( ( left & 0xFF000000 ) >> 24 ) - ( ( right & 0xFF000000 ) >> 24 ), 255 )
    
    return r << 16  | g << 8 | b | a << 24
end

function color.to_rgba( color )
    return ( color & 0x00FF0000 ) >> 16, ( color & 0x0000FF00 ) >>  8, color & 0x000000FF, ( color & 0xFF000000 ) >> 24
end

function color.from_rgba( r, g, b, a )
    local _r = ( r // 1 ) & 0xFF
    local _g = ( g // 1 ) & 0xFF
    local _b = ( b // 1 ) & 0xFF
    local _a = a and ( a // 1 ) & 0xFF or 0xFF -- alpha is optional
    
    return _r << 16 | _g << 8 | _b | _a << 24
end

--
-- Colorspace conversions and calculations
-- 
-- See: http://www.easyrgb.com/index.php?X=MATH
--      http://www.chilliant.com/rgb2hsv.html
--      https://www.rapidtables.com/convert/color/index.html
--      http://www.brucelindbloom.com/index.html?ColorDifferenceCalc.html
--

function color.to_hsv( color )
    local r     = ( ( color & 0x00FF0000 ) >> 16 ) / 255.0
    local g     = ( ( color & 0x0000FF00 ) >>  8 ) / 255.0
    local b     =   ( color & 0x000000FF )         / 255.0
    local a     = ( ( color & 0xFF000000 ) >> 24 ) / 255.0
    local min   = math_min( r, g, b )
    local max   = math_max( r, g, b )
    local delta = max - min
    
    if delta == 0.0 then
        return 0.0, 0.0, max
    end

    local delta_r = ( ( ( max - r ) / 6.0 ) + ( max / 2.0 ) ) / delta
    local delta_g = ( ( ( max - g ) / 6.0 ) + ( max / 2.0 ) ) / delta
    local delta_b = ( ( ( max - b ) / 6.0 ) + ( max / 2.0 ) ) / delta

    local h = ( r == max and delta_b - delta_g or
                g == max and ( 1.0 / 3.0 ) + delta_r - delta_b or
                b == max and ( 2.0 / 3.0 ) + delta_g - delta_r )

    h = h < 0.0 and h + 1.0 or h > 1.0 and h - 1.0 or h
    
    return h, delta / max, max, a
end

function color.from_hsv( h, s, v, a )
    local alpha = a and math_max( 0, a * 255.0 // 1 ) << 24 or 0xFF000000
    if s == 0.0 then
        local value = math_max( 0, v * 255.0 // 1 )
        return value | value << 8 | value << 16 | alpha
    else
        v = v * 255.0
        h = h == 1.0 and 0.0 or h * 6.0
        local i = h // 1
        
        if i == 0 then
            local r = math_max( 0, v // 1 )
            local g = math_max( 0, v * ( 1.0 - s * ( 1.0 - ( h - i ) ) ) // 1 )
            local b = math_max( 0, v * ( 1.0 - s ) // 1 )
            return r << 16 | g << 8 | b | alpha
        elseif i == 1 then
            local r = math_max( 0, v * ( 1.0 - s * ( h - i ) ) // 1 )
            local g = math_max( 0, v // 1 )
            local b = math_max( 0, v * ( 1.0 - s ) // 1 )
            return r << 16 | g << 8 | b | alpha
        elseif i == 2 then
            local r = math_max( 0, v * ( 1.0 - s ) // 1 )
            local g = math_max( 0, v // 1 )
            local b = math_max( 0, v * ( 1.0 - s * ( 1.0 - ( h - i ) ) ) // 1 )
            return r << 16 | g << 8 | b | alpha
        elseif i == 3 then
            local r = math_max( 0, v * ( 1.0 - s ) // 1 )
            local g = math_max( 0, v * ( 1.0 - s * ( h - i ) ) // 1 )
            local b = math_max( 0, v // 1 )
            return r << 16 | g << 8 | b | alpha
        elseif i == 4 then
            local r = math_max( 0, v * ( 1.0 - s * ( 1.0 - ( h - i ) ) ) // 1 )
            local g = math_max( 0, v * ( 1.0 - s ) // 1 )
            local b = math_max( 0, v // 1 )
            return r << 16 | g << 8 | b | alpha
        else
            local r = math_max( 0, v // 1 )
            local g = math_max( 0, v * ( 1.0 - s ) // 1 )
            local b = math_max( 0, v * ( 1.0 - s * ( h - i ) ) // 1 )
            return r << 16 | g << 8 | b | alpha
        end
    end
end

function color.to_hsl( color )
    local r = ( color & 0xFF0000 ) / 0xFF0000
    local g = ( color & 0x00FF00 ) / 0x00FF00
    local b = ( color & 0x0000FF ) / 0x0000FF
    
    local min   = math_min( r, g, b )
    local max   = math_max( r, g, b )
    local delta = max - min
    
    local l = ( max + min ) / 2
    
    if delta == 0 then
        return 0.0, 0.0, l  -- Gray, no chroma
    end
    
    local s = delta / ( ( l < 0.5 ) and ( max + min ) or ( 2.0 - max - min ) )
    
    local delta_r = ( ( ( max - r ) / 6.0 ) + ( delta / 2.0 ) ) / delta
    local delta_g = ( ( ( max - g ) / 6.0 ) + ( delta / 2.0 ) ) / delta
    local delta_b = ( ( ( max - b ) / 6.0 ) + ( delta / 2.0 ) ) / delta
    
    local h = 0
    if r == max then
        h = delta_b - delta_g
    elseif g == max then
        h = ( 1.0 / 3.0 ) + delta_r - delta_b
    else -- b == max
        h = ( 2.0 / 3.0 ) + delta_g - delta_r
    end
    
    if h < 0 then
        h = h + 1
    elseif h > 1 then
        h = h - 1
    end
    
    return h, s, l
end

local function _h_to_rgb( foo, bar, h )
    if h < 0.0 then
        h = h + 1.0
    elseif h > 1.0 then
        h = h - 1.0
    end
    
    if ( 6.0 * h ) < 1.0 then
        return foo + ( bar - foo ) * 6.0 * h
    elseif ( 2.0 * h ) < 1.0 then
        return bar
    elseif ( 3.0 * h ) < 2.0 then
        return foo + ( bar - foo ) * ( ( 2.0 / 3.0 ) - h ) * 6.0
    end
    
    return foo
end

function color.from_hsl( h, s, l )
    if s == 0 then
        local gray = l * 0xFF // 1
        return gray << 16 | gray << 8 | gray | 0xFF000000
    end
    
    local bar = ( l < ( 1.0 / 2.0 ) ) and ( l * ( 1.0 + s ) ) or ( ( l + s ) - ( s * l ) )
    local foo = 2.0 * l - bar
    
    local r = 0.5 + 255.0 * _h_to_rgb( foo, bar, h + ( 1.0 / 3.0 ) )
    local g = 0.5 + 255.0 * _h_to_rgb( foo, bar, h )
    local b = 0.5 + 255.0 * _h_to_rgb( foo, bar, h - ( 1.0 / 3.0 ) )
    
    return ( r // 1 ) << 16 | ( g // 1 ) << 8 | ( b // 1 ) | 0xFF000000
end

local function _to_Lab( color )
    local r = ( ( color & 0x00FF0000 ) >> 16 ) / 255.0
    local g = ( ( color & 0x0000FF00 ) >>  8 ) / 255.0
    local b =   ( color & 0x000000FF )         / 255.0

    if r > 0.04045 then r = ( ( r + 0.055 ) / 1.055 ) ^ 2.4 else r = r / 12.92 end
    if g > 0.04045 then g = ( ( g + 0.055 ) / 1.055 ) ^ 2.4 else g = g / 12.92 end
    if b > 0.04045 then b = ( ( b + 0.055 ) / 1.055 ) ^ 2.4 else b = b / 12.92 end
    
    -- Observer = 2°, Illuminant = D65
    local x = ( r * 41.24 + g * 35.76 + b * 18.05 ) /  95.047
    local y = ( r * 21.26 + g * 71.52 + b *  7.22 ) / 100.000
    local z = ( r *  1.93 + g * 11.92 + b * 95.05 ) / 108.883

    if x > 0.008856 then x = x ^ ( 1.0 / 3.0 ) else x = ( 7.787 * x ) + ( 16.0 / 116.0 ) end
    if y > 0.008856 then y = y ^ ( 1.0 / 3.0 ) else y = ( 7.787 * y ) + ( 16.0 / 116.0 ) end
    if z > 0.008856 then z = z ^ ( 1.0 / 3.0 ) else z = ( 7.787 * z ) + ( 16.0 / 116.0 ) end

    return ( 116.0 * y ) - 16.0, 500.0 * ( x - y ), 200.0 * ( y - z )
end

color.to_Lab = _to_Lab

local function _from_Lab( _L, _a, _b )
    local y = ( _L + 16.0 ) / 116.0
    local x = _a / 500.0 + y
    local z = y - _b / 200.0

    if ( x ^ 3.0 ) > 0.008856 then x = x ^ 3.0 else x = ( x - 16.0 / 116.0 ) / 7.787 end
    if ( y ^ 3.0 ) > 0.008856 then y = y ^ 3.0 else y = ( y - 16.0 / 116.0 ) / 7.787 end
    if ( z ^ 3.0 ) > 0.008856 then z = z ^ 3.0 else z = ( z - 16.0 / 116.0 ) / 7.787 end

    -- Observer= 2°, Illuminant= D65
    local r = x *  3.080093082 + y * -1.5372 + z * -0.542890638
    local g = x * -0.920910383 + y *  1.8758 + z *  0.045186445
    local b = x *  0.052941179 + y * -0.204  + z *  1.15089331

    if r > 0.0031308 then r = 1.055 * ( r ^ ( 1.0 / 2.4 ) ) - 0.055 else r = 12.92 * r end
    if g > 0.0031308 then g = 1.055 * ( g ^ ( 1.0 / 2.4 ) ) - 0.055 else g = 12.92 * g end
    if b > 0.0031308 then b = 1.055 * ( b ^ ( 1.0 / 2.4 ) ) - 0.055 else b = 12.92 * b end
    
    r = math_max( 0, ( 0.5 + r * 255.0 ) // 1 )
    g = math_max( 0, ( 0.5 + g * 255.0 ) // 1 )
    b = math_max( 0, ( 0.5 + b * 255.0 ) // 1 )
    
    return r << 16 | g << 8 | b | 0xFF000000
end

color.from_Lab = _from_Lab

function color.to_hcl( color )
    local L, a, b = _to_Lab( color )
    local c       = math_sqrt( a ^ 2.0 + b ^ 2.0 )
    local h       = math_atan( b, a )
    
    h = ( h > 0.0 and h or 360.0 - math_abs( h ) ) * ( 180.0 / math_pi )
    
    return h, c, L
end

function color.from_hcl( h, c, l )
    local h_rad = math_pi * h / 180.0
    local a     = math_cos( h_rad ) * c
    local b     = math_sin( h_rad ) * c
    
    return _from_Lab( l, a, b )
end

--
-- Color comparison functions
--

function color.delta_e94( _L1, _a1, _b1, _L2, _a2, _b2 )
    local C1 = math_sqrt( ( _a1 ^ 2.0 ) + ( _b1 ^ 2.0 ) )
    local C2 = math_sqrt( ( _a2 ^ 2.0 ) + ( _b2 ^ 2.0 ) )
    local dC = C2 - C1
    local dL = _L2 - _L1
    local dE = math_sqrt( ( _L1 - _L2 ) ^ 2.0 + ( _a1 - _a2 ) ^ 2.0 + ( _b1 - _b2 ) ^ 2.0 )    
    local dH = math_sqrt( ( dE ^ 2.0 ) - ( dL ^ 2.0 ) - ( dC ^ 2.0 ) )
    
    dC = dC / ( 1.0 + ( 0.045 * C1 ) )
    dH = dH / ( 1.0 + ( 0.015 * C1 ) )
    
    return math_sqrt( dL ^ 2.0 + dC ^ 2.0 + dH ^ 2.0 )
end

--
-- 'Median Cut' Color quantization algorithm using the RGB colorspace
--

local function _sort_r( left, right )
    return left[ 1 ] < right[ 1 ]
end


local function _sort_g( left, right )
    return left[ 2 ] < right[ 2 ]
end


local function _sort_b( left, right )
    return left[ 3 ] < right[ 3 ]
end
    
function color.quantize( colors, n_colors )
    assert( type( colors ) == "table" )
    assert( math.type( n_colors ) == "integer" )
    assert( n_colors > 1 )
    
    local bins = {}
    
    do
        local bin   = {}
        
        local r_min = 0xFF
        local g_min = 0xFF
        local b_min = 0xFF    
        local r_max = 0
        local g_max = 0
        local b_max = 0
        
        -- Make a collection of unique colors.
        -- The 'Median Cut' algorith does not handle large quantities duplicate colors well.
        -- Also less colors will sort the collection faster.
        -- And since we already iterating through the colors, add them to the initial bin as well.
        local unique_colors = {}
        for i = 1, #colors do
            local color = colors[ i ]
            local up    = unique_colors[ color ]
            if not up then
                local r = ( color & 0xFF0000 ) >> 16
                local g = ( color & 0x00FF00 ) >> 8
                local b =   color & 0x0000FF
                
                r_min = math_min( r_min, r )
                g_min = math_min( g_min, g )
                b_min = math_min( b_min, b )
                r_max = math_max( r_max, r )
                g_max = math_max( g_max, g )
                b_max = math_max( b_max, b )
        
                up                     = { r, g, b, 1 }
                unique_colors[ color ] = up
                bin[ #bin + 1 ]        = up
            else
                up[ 4 ] = up[ 4 ] + 1
            end
        end
        
        bin.r_range = r_max - r_min
        bin.g_range = g_max - g_min
        bin.b_range = b_max - b_min
        
        bins[ 1 ] = bin
        
        -- Split bins until we have the requested number of colors
        while #bins < n_colors do
            local color_count = 0
            for i = 1, #bins do
                local b        = bins[ i ]
                local bin_size = #b
                if bin_size > color_count then
                    color_count = bin_size
                    bin         = b         -- split the largest bin
                end
            end
            
            if color_count < 2 then
                -- No more bins available for splicing
                break
            end
            
            -- Sort the bin by color with the largest range
            local r_range = bin.r_range
            local g_range = bin.g_range
            local b_range = bin.b_range

            if r_range >= b_range and r_range >= b_range then
                table_sort( bin, _sort_r )
            elseif g_range >= r_range and g_range >= b_range then
                table_sort( bin, _sort_g )
            else
                table_sort( bin, _sort_b )
            end

            local cut = color_count // 2
            
            -- Keep the lower half in its current bin
            r_min = 0xFF
            g_min = 0xFF
            b_min = 0xFF    
            r_max = 0
            g_max = 0
            b_max = 0

            for i = 1, cut do
                local pixel = bin[ i ]
                local r     = pixel[ 1 ]
                local g     = pixel[ 2 ]
                local b     = pixel[ 3 ]
                
                r_min = math_min( r_min, r )
                g_min = math_min( g_min, g )
                b_min = math_min( b_min, b )
                r_max = math_max( r_max, r )
                g_max = math_max( g_max, g )
                b_max = math_max( b_max, b )
            end

            bin.r_range = r_max - r_min
            bin.g_range = g_max - g_min
            bin.b_range = b_max - b_min

            -- Move the upper half to a new bin
            local new_bin = {}

            r_min = 0xFF
            g_min = 0xFF
            b_min = 0xFF    
            r_max = 0
            g_max = 0
            b_max = 0

            for _ = cut + 1, #bin do
                local pixel = table_remove( bin )
                local r     = pixel[ 1 ]
                local g     = pixel[ 2 ]
                local b     = pixel[ 3 ]

                r_min = math_min( r_min, r )
                g_min = math_min( g_min, g )
                b_min = math_min( b_min, b )
                r_max = math_max( r_max, r )
                g_max = math_max( g_max, g )
                b_max = math_max( b_max, b )
                
                new_bin[ #new_bin + 1 ] = pixel
            end

            new_bin.r_range = r_max - r_min
            new_bin.g_range = g_max - g_min
            new_bin.b_range = b_max - b_min
            
            bins[ #bins + 1 ] = new_bin
        end
    end

    -- Convert bins to colors
    local palette = {}
    for i_bin = 1, #bins do
        local bin   = bins[ i_bin ]
        local sum_r = 0
        local sum_g = 0
        local sum_b = 0
        local count = 0
        for i_pixel = 1, #bin do
            local pixel  = bin[ i_pixel ]
            local weight = pixel[ 4 ]
            sum_r        = sum_r + pixel[ 1 ] * weight
            sum_g        = sum_g + pixel[ 2 ] * weight
            sum_b        = sum_b + pixel[ 3 ] * weight
            count        = count + weight
        end
        if count > 0 then
            local r                 = ( sum_r // count ) << 16
            local g                 = ( sum_g // count ) << 8
            local b                 = ( sum_b // count )
            palette[ #palette + 1 ] = r | g | b
        end
    end
    
    return palette
end



return color
