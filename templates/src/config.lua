-- templatized configuration: DO NOT EDIT
--
local config = {
  SERVICE_LB_URL = "{{key "config/api-gateway/SERVICE_LB_URL"}}",
  AUTH_UPSTREAM_NAME = "{{key "config/api-gateway/AUTH_UPSTREAM_NAME"}}",
  SERVICE_HTTP_TIMEOUT = 0.1,
}

return config
