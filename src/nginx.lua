-- package nginx: An nginx auth handler

local SERVICE_PROXY_PATH = "/sub/service"

local nginx = {
  SERVICE_PROXY_PATH = SERVICE_PROXY_PATH,
}

local auth = require "auth"
local helios = require "gateway.helios"
local cookie = require "cookie"
local util = require "util"
local http = require "resty.http"
local headers = require "request_headers"

function nginx.init(config)
  config.SERVICE_LB_URL = util.strip_trailing_slash(config.SERVICE_LB_URL)

  local helios = helios:new(ngx)
  local auth = auth:new(helios)

  return {
    config = config,
    auth = auth,
    helios = helios,
    client = client
  }
end


function nginx.authenticate(app, headers)
  local user_id = nil
  if type(headers) ~= "table" then
    return nil
  end

  local cookie_string = headers[cookie.COOKIE_HEADER]
  if cookie_string and cookie_string ~= "" then
    user_id = app.auth:authenticate_by_cookie(cookie_string)
    if user_id then
      return user_id
    end
  end

  local token = headers[auth.ACCESS_TOKEN_HEADER]
  if token and token ~= "" then
    user_id = app.auth:authenticate_and_return_user_id(token)
    if user_id then
      return user_id
    end
  end

  return nil
end

function nginx.service_proxy(ngx, user_id)
  -- the X-User-Id header should either be set by a valid
  -- user id or cleared
  if user_id then
    ngx.req.set_header(headers.USER_ID, user_id)
    ngx.req.set_header(headers.WIKIA_USER_ID, user_id) --deprecated
  end

  -- clear the cookie; it should not be sent to the backend
  ngx.req.set_header(cookie.COOKIE_HEADER, "")
  ngx.req.set_header(headers.ACCESS_TOKEN, "")

  return ngx.exec("@service")
end


return nginx
