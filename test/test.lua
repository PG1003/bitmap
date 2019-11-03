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


local math_abs = math.abs

local _total_checks  = 0
local _failed_checks = 0

local function _report_fail( ... )
    _failed_checks = _failed_checks + 1
    local msg   = string.format( ... )
    local stack = debug.traceback( msg, 3 )
    local start, stop = string.find( stack, "[%s%c]+%C+run_test_modules" )
    print( string.sub( stack, 1, start - 1 ) )
end

local function _is_not_nil( value )
    _total_checks = _total_checks + 1
    if value == nil then
        _report_fail( "Is nil" )
        return false
    end
    return true
end

local function _is_nil( value )
    _total_checks = _total_checks + 1
    if value ~= nil then
        _report_fail( "Is nil" )
        return false
    end
    return true
end

local function _is_same( value_1, value_2 )
    _total_checks = _total_checks + 1
    if value_1 ~= value_2 then
        _report_fail( "Not same; value 1: '%s', value 2: '%s'",
                      tostring( value_1 ), tostring( value_2 ) )
        return false
    end
    return true
end

local function _is_not_same( value_1, value_2 )
    _total_checks = _total_checks + 1
    if value_1 == value_2 then
        _report_fail( "Same; value 1: '%s', value 2: '%s'",
                      tostring( value_1 ), tostring( value_2 ) )
        return false
    end
    return true
end

local function _is_same_float( value_1, value_2, abs_tolerance )
    _total_checks = _total_checks + 1
    local delta   = math_abs( value_1 - value_2 )
    if delta > abs_tolerance then
        _report_fail( "Not same float; value 1: '%g', value 2: '%g'",
                      value_1, value_2 )
        return false
    end
    return true
end    

local function _is_same_bitmap( bmp_1, bmp_2 )
    _total_checks = _total_checks + 1
    if bmp_1:height() ~= bmp_1:height() then
        _report_fail( "Bitmap height not same" )
        return false
    end
    if bmp_1:width() ~= bmp_2:width() then
        _report_fail( "Bitmap width not same" )
        return false
    end
    for y = 1, bmp_1:height() do
        for x = 1, bmp_1:width() do
            if bmp_1[ y ][ x ] ~= bmp_2[ y ][ x ] then
                local msg = string.format(
                    "Pixel not same at position x = %d, y = %d; bmp 1: 0x%08X, bmp 2: 0x%08X",
                    x, y, bmp_1[ y ][ x ], bmp_2[ y ][ x ] )
                _report_fail( msg )
                return false
            end
        end
    end
    return true
end

local function _run_test_modules( test_modules )
    assert( type( test_modules ) == "table" )
    local total_tests  = 0
    local failed_tests = 0
    for module, run in pairs( test_modules ) do
        if run then
            print( "-- " .. module .. " --" )
            local tests = require( module )
            for test, f in pairs( tests ) do
                print( "> " .. test )
                local failed_checks_before_test = _failed_checks
                f()
                if _failed_checks > failed_checks_before_test then
                    failed_tests = failed_tests + 1
                end
                total_tests = total_tests + 1
            end
        end
    end
    
    local status = _failed_checks ~= 0 and 1 or 0
    
    local summary = string.format( "-- Test summary --\n" ..
                                   "        Tests   Checks\n" ..
                                   "Total:  %5d   %6d\n" ..
                                   "Failed: %5d   %6d",
                                   total_tests, _total_checks,
                                   failed_tests, _failed_checks )
    print( summary )

    _total_checks  = 0
    _failed_checks = 0
    
    return status
end

local function _get_resource_file( ... )
    local info         = debug.getinfo( 1 )
    local resource_dir = string.gsub( info.short_src, "^./(.*)test.lua$", "%1resources/" )
    return resource_dir .. string.format( ... )
end

local function _get_results_file( ... )
    local info         = debug.getinfo( 1 )
    local resource_dir = string.gsub( info.short_src, "^./(.*)test.lua$", "%1results/" )
    return resource_dir .. string.format( ... )
end

return
    {
        is_nil            = _is_nil,
        is_not_nil        = _is_not_nil,
        is_same           = _is_same,
        is_not_same       = _is_not_same,
        is_same_float     = _is_same_float,
        is_same_bitmap    = _is_same_bitmap,
        run_test_modules  = _run_test_modules,
        get_resource_file = _get_resource_file,
        get_results_file  = _get_results_file
    }
