--[[
    Files System Operations

    @author skitsanos
    @version 1.0

    Ref: https://docs.coronalabs.com/guide/data/LFS/index.html#adding-directories
]] --

rawset(_G, 'lfs', false)
local localfilesystem = require('lfs')

local fs = {}

function fs.cwd()
    return localfilesystem.currentdir()
end

function fs.mode(path)
    return localfilesystem.attributes(path, 'mode')
end

function fs.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end

    return t
end

function fs.dir(path)
    return localfilesystem.dir(path)
end

function fs.makeDir(path)
    local ok, result = pcall(localfilesystem.mkdir, path)
    if (ok) then
        return true
    else
        return false
    end
    --[[local items = fs.split(path, "/")

    local d = ""

    for key, value in pairs(items) do
        d = d .. '/' .. value
        localfilesystem.mkdir(d)
        print('creating' .. d)
    end

    return true]]
end

function fs.isFile(name)
    if type(name) ~= "string" then
        return false
    end
    if not fs.isDir(name) then
        return os.rename(name, name) and true or false
        -- note that the short evaluation is to
        -- return false instead of a possible nil
    end
    return false
end

function fs.isDir(path)
    --[[if type(name) ~= "string" then
        return false
    end

    local cd = localfilesystem.currentdir()
    local is = localfilesystem.chdir(name) and true or false
    localfilesystem.chdir(cd)
    return is]]
    if (localfilesystem.attributes(path, 'mode') == 'directory') then
        return true
    else
        return false
    end
end

function fs.list(path)
    local files = {}
    local counter = 1
    for file in localfilesystem.dir(path) do
        if (file ~= '.') and (file ~= '..') then
            local fullPath = path .. '/' .. file

            files[counter] = {
                item = file,
                mode = localfilesystem.attributes(fullPath, "mode")
            }
            counter = counter + 1
        end
    end

    return files
end

function fs.rmdir(path)
    return localfilesystem.rmdir(path)
end

function fs.remove(path)
    local mode = localfilesystem.attributes(path, 'mode')
    if (mode == nil) then
        return nil
    elseif (mode == 'directory') then
        os.execute('rm -r ' .. path)
        return true
    elseif (mode == 'file') then
        os.execute("rm -r " .. path)
        return true
    end
end

function fs.baseName(path)
    local handle = io.popen('dirname ' .. path)
    local result = handle:read("*a")
    handle:close()
    return result:gsub('\n','')
end

function fs.move(source, target)
    local mode = localfilesystem.attributes(source, 'mode')
    if (mode == nil) then
        return nil
    elseif (mode == 'directory' or mode == 'file') then
        os.execute('mv ' .. source .. ' ' .. target)
        return true
    else
        return false
    end
end

return fs
