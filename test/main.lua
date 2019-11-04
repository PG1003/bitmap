-- Make sure we have access to the 'src' and 'test' directories from our working directory.
local short_src = debug.getinfo( 1 ).short_src
local src_path  = string.gsub( short_src, "main.lua$", "../src/?.lua" )
local test_path = string.gsub( short_src, "main.lua$", "../test/?.lua" )
package.path    = package.path .. ";./" .. src_path .. ";./".. test_path

local test = require( "test" )

local available_test_modules = 
{
    bitmap_formats = true,
    bitmap_utils   = true,
    color_utils    = true
}

if arg[ 1 ] then
    local test_modules = {}
    for i = 1, #arg do
        local module = arg[ i ] 
        if available_test_modules[ module ] then
            test_modules[ module ] = true
        else
            print( "Module " .. arg[ i ] .. " not available." )
            return
        end
    end
    return test.run_test_modules( test_modules )
else
    return test.run_test_modules( available_test_modules )
end
