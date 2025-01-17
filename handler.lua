local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local ngx_re_gmatch = ngx.re.gmatch

-- Declare your plugin handler
local JwtClaimsHeadersHandler = {
  VERSION  = "1.0.0",
  -- Choose a priority that makes sense for your use-case:
  -- If you need to run after Kong's built-in JWT plugin (which has priority = 1450),
  -- pick a lower priority.  Otherwise, pick a higher/lower number as needed.
  PRIORITY = 1449,
}

-- Helper function to retrieve the token from either a query param or the `Authorization` header
local function retrieve_token(conf)
  -- Read query parameters from Kong’s PDK instead of ngx.req
  local uri_parameters = kong.request.get_query()

  -- Check all configured query param names
  for _, param_name in ipairs(conf.uri_param_names) do
    local param_value = uri_parameters[param_name]
    if param_value then
      return param_value
    end
  end

  -- Check the Authorization header
  local authorization_header = kong.request.get_header("authorization")
  if authorization_header then
    -- Use the built-in ngx regex to parse out a Bearer token
    local iterator, iter_err = ngx_re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, iter_err
    end

    local m, err = iterator()
    if err then
      return nil, err
    end

    if m and #m > 0 then
      return m[1]
    end
  end
end

-- Access phase handler
function JwtClaimsHeadersHandler:access(conf)
  local continue_on_error = conf.continue_on_error

  -- Attempt to retrieve the token
  local token, err = retrieve_token(conf)
  if err and not continue_on_error then
    return kong.response.exit(500, { message = err })
  end

  -- Token not found
  if not token and not continue_on_error then
    return kong.response.exit(401, { message = "Missing JWT token" })
  elseif not token and continue_on_error then
    -- Gracefully do nothing and continue
    return
  end

  -- Decode the JWT
  local jwt, jwt_err = jwt_decoder:new(token)
  if jwt_err and not continue_on_error then
    return kong.response.exit(500, { message = "Failed to decode JWT: " .. jwt_err })
  elseif not jwt and continue_on_error then
    return
  end

  -- Extract claims and set them as headers
  local claims = jwt.claims or {}
  for claim_key, claim_value in pairs(claims) do
    for _, claim_pattern in ipairs(conf.claims_to_include) do
      if string.match(claim_key, "^" .. claim_pattern .. "$") then
        -- Use the PDK to set upstream headers
        kong.service.request.set_header("X-" .. claim_key, claim_value)
      end
    end
  end
end

-- Return our plugin object
return JwtClaimsHeadersHandler
