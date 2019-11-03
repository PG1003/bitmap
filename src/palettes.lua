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


local palette = {}


local _palette_2 =
{
    0x00000000,
    0x00FFFFFF
}

local _palette_16 =
{
    0x00000000, 0x00800000, 0x00008000, 0x00808000, 0x00000080, 0x00800080,
    0x00008080, 0x00808080, 0x00C0C0C0, 0x00FF0000, 0x0000FF00, 0x00FFFF00,
    0x000000FF, 0x00FF00FF, 0x0000FFFF, 0x00FFFFFF
}

local _palette_256 =
{
    0x00000000, 0x00800000, 0x00008000, 0x00808000, 0x00000080, 0x00800080,
    0x00008080, 0x00C0C0C0, 0x00C0DCC0, 0x00A6CAF0, 0x00402000, 0x00602000,
    0x00802000, 0x00A02000, 0x00C02000, 0x00E02000, 0x00004000, 0x00204000,
    0x00404000, 0x00604000, 0x00804000, 0x00A04000, 0x00C04000, 0x00E04000,
    0x00006000, 0x00206000, 0x00406000, 0x00606000, 0x00806000, 0x00A06000,
    0x00C06000, 0x00E06000, 0x00008000, 0x00208000, 0x00408000, 0x00608000,
    0x00808000, 0x00A08000, 0x00C08000, 0x00E08000, 0x0000A000, 0x0020A000,
    0x0040A000, 0x0060A000, 0x0080A000, 0x00A0A000, 0x00C0A000, 0x00E0A000,
    0x0000C000, 0x0020C000, 0x0040C000, 0x0060C000, 0x0080C000, 0x00A0C000,
    0x00C0C000, 0x00E0C000, 0x0000E000, 0x0020E000, 0x0040E000, 0x0060E000,
    0x0080E000, 0x00A0E000, 0x00C0E000, 0x00E0E000, 0x00000040, 0x00200040,
    0x00400040, 0x00600040, 0x00800040, 0x00A00040, 0x00C00040, 0x00E00040,
    0x00002040, 0x00202040, 0x00402040, 0x00602040, 0x00802040, 0x00A02040,
    0x00C02040, 0x00E02040, 0x00004040, 0x00204040, 0x00404040, 0x00604040,
    0x00804040, 0x00A04040, 0x00C04040, 0x00E04040, 0x00006040, 0x00206040,
    0x00406040, 0x00606040, 0x00806040, 0x00A06040, 0x00C06040, 0x00E06040,
    0x00008040, 0x00208040, 0x00408040, 0x00608040, 0x00808040, 0x00A08040,
    0x00C08040, 0x00E08040, 0x0000A040, 0x0020A040, 0x0040A040, 0x0060A040,
    0x0080A040, 0x00A0A040, 0x00C0A040, 0x00E0A040, 0x0000C040, 0x0020C040,
    0x0040C040, 0x0060C040, 0x0080C040, 0x00A0C040, 0x00C0C040, 0x00E0C040,
    0x0000E040, 0x0020E040, 0x0040E040, 0x0060E040, 0x0080E040, 0x00A0E040,
    0x00C0E040, 0x00E0E040, 0x00000080, 0x00200080, 0x00400080, 0x00600080,
    0x00800080, 0x00A00080, 0x00C00080, 0x00E00080, 0x00002080, 0x00202080,
    0x00402080, 0x00602080, 0x00802080, 0x00A02080, 0x00C02080, 0x00E02080,
    0x00004080, 0x00204080, 0x00404080, 0x00604080, 0x00804080, 0x00A04080,
    0x00C04080, 0x00E04080, 0x00006080, 0x00206080, 0x00406080, 0x00606080,
    0x00806080, 0x00A06080, 0x00C06080, 0x00E06080, 0x00008080, 0x00208080,
    0x00408080, 0x00608080, 0x00808080, 0x00A08080, 0x00C08080, 0x00E08080,
    0x0000A080, 0x0020A080, 0x0040A080, 0x0060A080, 0x0080A080, 0x00A0A080,
    0x00C0A080, 0x00E0A080, 0x0000C080, 0x0020C080, 0x0040C080, 0x0060C080,
    0x0080C080, 0x00A0C080, 0x00C0C080, 0x00E0C080, 0x0000E080, 0x0020E080,
    0x0040E080, 0x0060E080, 0x0080E080, 0x00A0E080, 0x00C0E080, 0x00E0E080,
    0x000000C0, 0x002000C0, 0x004000C0, 0x006000C0, 0x008000C0, 0x00A000C0,
    0x00C000C0, 0x00E000C0, 0x000020C0, 0x002020C0, 0x004020C0, 0x006020C0,
    0x008020C0, 0x00A020C0, 0x00C020C0, 0x00E020C0, 0x000040C0, 0x002040C0,
    0x004040C0, 0x006040C0, 0x008040C0, 0x00A040C0, 0x00C040C0, 0x00E040C0,
    0x000060C0, 0x002060C0, 0x004060C0, 0x006060C0, 0x008060C0, 0x00A060C0,
    0x00C060C0, 0x00E060C0, 0x000080C0, 0x002080C0, 0x004080C0, 0x006080C0,
    0x008080C0, 0x00A080C0, 0x00C080C0, 0x00E080C0, 0x0000A0C0, 0x0020A0C0,
    0x0040A0C0, 0x0060A0C0, 0x0080A0C0, 0x00A0A0C0, 0x00C0A0C0, 0x00E0A0C0,
    0x0000C0C0, 0x0020C0C0, 0x0040C0C0, 0x0060C0C0, 0x0080C0C0, 0x00A0C0C0,
    0x00FFFBF0, 0x00A0A0A4, 0x00808080, 0x00FF0000, 0x0000FF00, 0x00FFFF00,
    0x000000FF, 0x00FF00FF, 0x0000FFFF, 0x00FFFFFF
}

local function _assert_read_only()
    assert( false, "Attempt to modify read-only table" )
end

local function _make_read_only( t )
    return setmetatable(
        {},
        {
            __metatable = false,
            __len       = function( self ) return #t end,
            __index     = t,
            __newindex  = _assert_read_only
        } )
end

palette.palette_2   = _make_read_only( _palette_2 )
palette.palette_16  = _make_read_only( _palette_16 )
palette.palette_256 = _make_read_only( _palette_256 )

return palette
