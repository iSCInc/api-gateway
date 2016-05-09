local request = {
    BEACON_ID = 'X-Beacon-Id',
    CLIENT_IP = 'X-Client-Ip',
    REQUEST_ID = 'X-Trace-Id',
    WIKIA_USER_ID = "X-Wikia-UserId",
    USER_ID = "X-User-Id",
    ACCESS_TOKEN = "X-Wikia-AccessToken",
    FASTLY_CLIENT_IP = 'Fastly-Client-IP',
}

function request.sanitize(ngx)
    ngx.req.clear_header(request.BEACON_ID)
    ngx.req.clear_header(request.CLIENT_IP)
    ngx.req.clear_header(request.REQUEST_ID)
    ngx.req.clear_header(request.USER_ID)
    ngx.req.clear_header(request.WIKIA_USER_ID)
end

function request.set_headers(ngx)    
    ngx.req.set_header(request.BEACON_ID, ngx.var.cookie_wikia_beacon_id)
    
    local req_headers = ngx.req.get_headers(100)
    ngx.req.set_header(request.CLIENT_IP, req_headers[request.FASTLY_CLIENT_IP] or ngx.var.remote_addr)

    local uuid = require('uuid')
    local request_id = uuid.gen()
    ngx.req.set_header(request.REQUEST_ID, request_id)
end

return request
