local cors = require("cors")

cors.add_origin_to_vary_header(ngx)
cors.set_whitelisted_control_headers(ngx)

local resp_headers = ngx.resp.get_headers(100)
if ngx.ctx.upstream_name and ngx.ctx.upstream_name ~= "__not_found" then
    ngx.header['X-Upstream-Name'] = ngx.ctx.upstream_name 
end

ngx.header['X-Served-By'] = resp_headers['X-Served-By'] or ngx.var.upstream_addr
