local request = {
    
}

function request.set_headers(ngx)
   local uuid = require('uuid')
   ngx.req.set_header('X-Beacon-Id', ngx.var.cookie_wikia_beacon_id)
   local req_headers = ngx.req.get_headers(100)
   ngx.req.set_header('X-Client-Ip', req_headers['Fastly-Client-IP'] or ngx.var.remote_addr)
   
   local request_id = uuid.gen()
   ngx.req.set_header('X-Request-Id', request_id)
   ngx.header['X-Request-Id'] = request_id
end

return request
