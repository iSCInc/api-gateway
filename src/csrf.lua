local cors = require "cors"
local cookie = require "cookie"
local csrf = {}

function csrf.protect_cookie_from_cross_origin_requests(ngx)
  local origin = cors.get_origin(ngx)
  
  if origin ~= nil then -- perform the check only when origin header is present
    if not cors.origin_matches_whitelist(origin) then
        ngx.req.set_header(cookie.COOKIE_HEADER, "")
    end
  end
  -- when there is no Origin header, it means that the request isn't coming from the browser and thus can be safly handled as is
end

return csrf