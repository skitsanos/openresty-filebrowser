local response = {}

function response.error(msg)
    return json.encode({ error = { message = msg }, execTime = 0, status = ngx.status })
end

function response.result(obj)
    return json.encode({ result = obj, status = 200 })
end

return response
