--[[
    Media Browser/File-server API handler
    
    @author skitsanos, https://github.com/skitsanos
    @version 4.1.20201212
--]]

local resty_post = require("resty.post")
local fs = require 'fs'
local response = require('server-response')

local replyWithJson = function()
    ngx.header['Content-Type'] = 'application/json'
end

local function send404()
    replyWithJson()
    ngx.status = 404
    ngx.say(response.error('Path not found'))
    ngx.exit(404)
end

local _method = ngx.var.request_method
local _path = ngx.var.pathRequested

if (_path == '') then
    _path = '/'
end

local filePath = ngx.var.mediaPath .. _path
local mode = fs.mode(filePath);

if (mode == nil and (_method == 'GET' or _method == 'DELETE')) then
    send404()
end

local runByMethod = {
    --
    -- if mode is directory, we list its content, otherwise
    -- if mode is file, we pass request to nginx handler to serve it
    --
    ['GET'] = function()
        -- check if file
        if (mode == 'directory') then
            -- directory content list
            replyWithJson()
            ngx.say(response.result(fs.list(filePath)))

        elseif (mode == 'file') then
            -- serving file
            ngx.exec('/media_files' .. _path)
        else
            send404()
        end
    end,
    --
    -- if mode is directory we upload file into a folder selected, or
    -- folder is not yet exist, we create it and then upload into it
    --
    -- if mode is file, we need to throw an error, since for post
    -- we expect url path to be a folder
    --
    ['POST'] = function()
        replyWithJson()

        if (mode == 'directory' or mode == nil) then
            --if mode==nil, create folder
            if (mode == nil) then
                local makeDirResult = fs.makeDir(filePath)

                if (makeDirResult == false) then
                    ngx.status = 500
                    ngx.say(response.error('Failed to create path'))
                    ngx.exit(500)
                end
            end

            -- check content type
            if (ngx.var.http_content_type == nil or not ngx.var.http_content_type:match('^multipart/form%-data')) then
                ngx.status = 406
                ngx.say(response.error('Incorrect content type'))
                ngx.exit(406)
            end

            local post = resty_post:new({
                path = filePath .. '/',
                no_tmp = true,
                --[[name = function(name, field) -- overide name with user defined function
                    return name.."_"..field
                end]]
            })

            local m = post:read()
            ngx.say(response.result(m.files))

        elseif (mode == 'file') then
            ngx.status = 409
            ngx.say(response.error('Conflict. Can\'t create folder while file with the saame name exists'))
            ngx.exit(409)

        elseif (mode == nil) then
            send404()
        end
    end,
    --
    -- requires application/json content type
    --
    -- if mode is directory, rename selected folder, otherwise,
    -- if mode is file, rename the file
    --
    ['PUT'] = function()
        replyWithJson()

        if (mode == nil) then
            send404()
        end

        if (ngx.var.http_content_type == nil or not ngx.var.http_content_type:match('^application/json')) then
            ngx.status = 406
            ngx.say(response.error('Incorrect content type'))
            ngx.exit(406)
        end

        -- check the JSON payload
        ngx.req.read_body()
        if (ngx.req.get_body_data() == nil) then
            ngx.status = 409
            ngx.say(response.error('Conflict. Payload is missing'))
            ngx.exit(409)
        end

        local ok, res = pcall(json.decode, ngx.req.get_body_data())
        if (not ok) then
            ngx.status = 409
            ngx.say(response.error('Conflict. Failed to parse JSON'))
            ngx.exit(409)
        end

        if (res.target == nil) then
            ngx.status = 409
            ngx.say(response.error('Conflict. Target is missing'))
            ngx.exit(409)
        end

        -- strip all the / characters
        local _target = res.target:gsub('/', '_')
        local targetPath = fs.baseName(filePath) .. '/' .. _target

        local result = fs.move(filePath, targetPath)
        ngx.say(response.result(result))
    end,
    -- if mode is directory, - recursive deletion will be performed, otherwise,
    -- if file, we just remove the file
    ['DELETE'] = function()
        replyWithJson()

        local ret = fs.remove(filePath)

        if (ret == true) then
            ngx.say(response.result(ret))

        else
            ngx.status = 500
            ngx.say(response.error('Failed to delete'))
            ngx.exit(500)
        end
    end
}

runByMethod[_method]()