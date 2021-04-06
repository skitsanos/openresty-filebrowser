---
--- File Processing and Caching
--- Created by skitsanos.
--- DateTime: 1/6/21 2:38 PM
---
--- Dependencies:
--- luarocks install array
---
local fs = require('fs')
local array = require('lib.array.init')

local m = {
    filePath = ngx.var.mediaPath
}

function m.processFile(f)
    local _path = string.gsub(ngx.var.uri, [[/media]], '')

    if (not _path:match('^/')) then
        _path = '/' .. _path
    end

    local ext = fs.getExtension(f.name)
    if (ext:lower() == '.pdf' or ext:lower() == '.zip') then
        local filePath = _path  .. '/' .. f.name
        if(_path == '/') then
            filePath = '/' .. f.name;
        end

        local hash = fs.hash(filePath);

        local cachedPath = ngx.var.cachePath .. '/' .. hash
        if (fs.mode(cachedPath) == nil) then
            fs.makeDir(cachedPath)
        end

        local uploadedFile = m.filePath .. '/' .. f.name

        local runByExtension = {
            ['.pdf'] = function()
                --
                -- creating metadata file
                --
                local metaFile = cachedPath .. '/' .. f.name .. '.meta'
                os.execute('pdfinfo "' .. uploadedFile .. '" >"' .. metaFile .. '" &')
                --
                -- creating thumbnails, first low-res pics
                --
                local lowResPics = cachedPath .. '/low/'
                fs.makeDir(lowResPics)
                os.execute('pdftopng -q -r 20 "' .. uploadedFile .. '" "' .. lowResPics .. '" &')
                -- then high-res ones
                local highResPics = cachedPath .. '/high/'
                fs.makeDir(highResPics)
                os.execute('pdftopng -q -r 200 "' .. uploadedFile .. '" "' .. highResPics .. '" &')
            end,

            ['.zip'] = function()
                --local metaFile = cachedPath .. '/' .. f.name .. '.meta'
                local scormParser = fs.cwd() .. '/app/api/media/scorm/index.js'
                local _cmd = 'node "' .. scormParser .. '" "' .. uploadedFile .. '" "' .. cachedPath .. '" &';
                os.execute(_cmd)
            end,
        }

        runByExtension[ext:lower()]()
    end
end

function m.process(files)
    for _, f in pairs(files) do
        if (array.is_array(f)) then
            m.process(f)
        else
            m.processFile(f)
        end
    end
end

return m
