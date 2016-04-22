local request = {
    BEACON_ID = 'X-Beacon-Id',
    CLIENT_IP = 'X-Client-Ip',
    REQUEST_ID = 'X-Trace-Id',
    FASTLY_CLIENT_IP = 'Fastly-Client-IP',
}

function request.set_headers(ngx)
   local uuid = require('uuid')
   ngx.req.set_header(request.BEACON_ID, ngx.var.cookie_wikia_beacon_id)
   local req_headers = ngx.req.get_headers(100)
   ngx.req.set_header(request.CLIENT_IP, req_headers[request.FASTLY_CLIENT_IP] or ngx.var.remote_addr)
   
   local request_id = uuid.gen()
   ngx.req.set_header(request.REQUEST_ID, request_id)
   ngx.header[request.REQUEST_ID] = request_id
end

return request
