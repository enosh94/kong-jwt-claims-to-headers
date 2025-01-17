local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt-claims-headers",
  fields = {
    -- Tells Kong that this plugin does not apply to consumers
    { consumer = typedefs.no_consumer },
    {
      config = {
        type = "record",
        fields = {
          {
            uri_param_names = {
              type = "array",
              default = { "jwt" },
              elements = { type = "string" },
              required = true,
            },
          },
          {
            claims_to_include = {
              type = "array",
              default = { ".*" },
              elements = { type = "string" },
              required = true,
            },
          },
          {
            continue_on_error = {
              type     = "boolean",
              default  = true,
              required = true,
            },
          },
        },
      },
    },
  },
}
