local pretty = require "pl.pretty"
package.path = package.path .. ";./src/?.lua"
require "pl.strict"
local binparser = require "binparser"
local bcdump = require "bcdump"

local infile = arg[1]
local f = assert(io.open(infile,"r"))
local s = f:read("*all")
f:close()

local p = binparser.parse(s)
bcdump.dump(p.parsed.proto)
