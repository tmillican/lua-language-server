---@meta

---#DES 'require'
---@param modname string
---@return any
---#if VERSION >=5.4 then
---@return any loaderdata
---#end
function require(modname) end

---#DES 'package'
---@class package*
---@field conifg    string
---@field cpath     string
---@field loaded    table
---@field path      string
---@field preload   table
---#end
package = {}

---@version <5.1
---#DES 'package.loaders'
package.loaders = {}

---#DES 'package.loadlib'
---@param libname string
---@param funcname string
---@return any
function package.loadlib(libname, funcname) end

---#DES 'package.searchers'
---@version >5.2
package.searchers = {}

---#DES 'package.searchpath'
---@version >5.2,JIT
---@param name string
---@param path string
---@param sep? string
---@param rep? string
---@return string? filename
---@return string? errmsg
function package.searchpath(name, path, sep, rep) end

---#DES 'package.seeall'
---@version <5.1
---@param module table
function package.seeall(module) end

return package
