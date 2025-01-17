
# kong-jwt-claims-to-headers

Add unencrypted, base64-decoded claims from a JWT payload as request headers to the upstream service.

Inspired by the original [[kong-plugin-jwt-claims-headers](https://github.com/wshirey/kong-plugin-jwt-claims-headers)](https://github.com/wshirey/kong-plugin-jwt-claims-headers/tree/master) , this plugin inspects the JWT token in your request and forwards specified claims as headers in the format:

```
X-<claim-name>: <claim-value>

```

----------

## Table of Contents

-   [Overview](#overview)
-   [How It Works](#how-it-works)
-   [Configuration](#configuration)
-   [Example Usage](#example-usage)
-   [Using Docker](#using-docker)
-   [Installation and Development](#installation-and-development)
-   [License](#license)

----------

## Overview

When Kong Gateway proxies an HTTP request to an upstream service, this plugin intercepts the request during the access phase, extracts the JWT token from either a query parameter or the Authorization header, decodes its payload (claims), and sets corresponding HTTP headers in the upstream request.

**Plugin Name:** kong-jwt-claims-to-headers  
**Kong Compatibility:** 3.9.x

----------

## How It Works

If the JWT payload (decoded claims) looks like this:

```json
{
  "sub": "1234567890",
  "name": "John Doe",
  "admin": true
}

```

Then, this plugin will add the following headers to the upstream request:

```
X-Sub: "1234567890"
X-Name: "John Doe"
X-Admin: true

```

By default, the plugin will attempt to decode and expose all claims (`claims_to_include = ".*"`), but you can restrict which claims are added by using Lua patterns. For example, using `"kong-.*"` will only match claims that start with `kong-`.

----------

## Configuration

Below is an example of how to configure the plugin:

```bash
curl -X POST http://localhost:8001/services/user-service/plugins \
  --data "name=kong-jwt-claims-to-headers" \
  --data "config.uri_param_names=jwt" \
  --data "config.claims_to_include=.*" \
  --data "config.continue_on_error=true"

```

This plugin can be attached at the **Service**, **Route**, or even **Globally**, depending on your needs.

### Form Parameters

|         Parameter        | Required |                                   Description                                   |
|:------------------------:|:--------:|:-------------------------------------------------------------------------------:|
| name                     | yes      | The name of the plugin to use: kong-jwt-claims-to-headers.                      |
| config.uri_param_names   | no       | List of query parameter names to inspect for a JWT token (default: jwt).        |
| config.claims_to_include | yes      | Array of Lua patterns matching claims to include as headers (default: .*).      |
| config.continue_on_error | yes      | Boolean to decide if traffic continues when JWT decoding fails (default: true). |

----------

## Example Usage

### 1. Enable the Plugin

You can enable the plugin on:

-   A specific **Service**
-   A specific **Route**
-   **Globally** (applies to all routes and services)

Here is an example enabling it on a specific **Service**:

```bash
curl -i -X POST http://localhost:8001/services/<SERVICE_ID>/plugins \
     --data "name=kong-jwt-claims-to-headers" \
     --data "config.uri_param_names=jwt" \
     --data "config.claims_to_include=name,sub" \
     --data "config.continue_on_error=false"

```

This configuration will:

-   Search for `jwt` parameter in the query string.
-   If absent, look for a Bearer token in the Authorization header.
-   Decode any found token and add only the `name` and `sub` claims to the upstream request as `X-Name` and `X-Sub`.
-   Return a `401` if any error occurs (e.g., no token, invalid token).

### 2. Send a Request with a JWT

Using a query parameter:

```bash
curl -i http://<HOST>/<ROUTE>?jwt=<YOUR_JWT>

```

Or via an Authorization header:

```bash
curl -i http://<HOST>/<ROUTE> \
     -H "Authorization: Bearer <YOUR_JWT>"

```

### 3. Observe the Upstream Headers

Confirm from upstream logs or debugging tools that headers `X-Name`, `X-Sub`, etc., are present.

----------

## Using Docker

If using Docker, add the plugin files to the `kong-jwt-claims-to-headers` folder on your host machine and mount the volume to the Kong container.

### Steps:

1.  **Organize Plugin Files on Host:** Ensure your plugin files are located in a directory on your host machine:
    
    ```
    kong-plugins/
      lua-plugins/
        kong-jwt-claims-to-headers/
          handler.lua
          schema.lua
    
    ```
    
2.  **Update Docker Configuration:** Modify your `docker-compose.yml` to mount the plugin directory into the Kong container:
    
    ```yaml
    services:
      kong:
        image: kong:3.9
        volumes:
          - ./kong-plugins/lua-plugins/kong-jwt-claims-to-headers:/usr/local/share/lua/5.1/kong/plugins/kong-jwt-claims-to-headers
        environment:
          KONG_PLUGINS: bundled,kong-jwt-claims-to-headers
        ports:
          - "8000:8000"
          - "8001:8001"
    
    ```
    
3.  **Restart Kong Container:** After updating the Docker configuration, restart your Kong container:
    
    ```bash
    docker-compose up -d
    
    ```
    
4.  **Verify Plugin Installation:** Confirm the plugin is recognized by Kong:
    
    ```bash
    curl http://localhost:8001/plugins/enabled
    
    ```
    
    You should see `kong-jwt-claims-to-headers` listed.
    

----------

## Installation and Development

1.  **Clone the Repository:**
    
    ```bash
    git clone https://github.com/enosh94/kong-jwt-claims-to-headers
    
    ```
    
2.  **Place Plugin Files:** Ensure the plugin files are located in a directory accessible by Kong:
    
    ```bash
    /usr/local/share/lua/5.1/kong/plugins/kong-jwt-claims-to-headers/
    
    ```
    
3.  **Update Kong Configuration:** Add the plugin to your `kong.conf` or set the `KONG_PLUGINS` environment variable:
    
    **In `kong.conf`:**
    
    ```ini
    plugins = bundled,kong-jwt-claims-to-headers
    
    ```
    
    **Or using an environment variable:**
    
    ```bash
    export KONG_PLUGINS=bundled,kong-jwt-claims-to-headers
    
    ```
    
4.  **Restart or Reload Kong:**
    
    ```bash
    kong reload
    
    ```
    
5.  **Verify Plugin Installation:**
    
    ```bash
    curl http://localhost:8001/plugins
    
    ```
    
    You should see `kong-jwt-claims-to-headers` listed.
    

----------
## License

GNU General Public License v3.0

_Disclaimer:_ This plugin is inspired by the excellent work at [github.com/wshirey/kong-plugin-jwt-claims-headers](https://github.com/wshirey/kong-plugin-jwt-claims-headers). It has been extended and refactored for compatibility with Kong Gateway 3.9.x.

If you encounter any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request.
