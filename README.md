[![Build Status](https://travis-ci.org/Wikia/api-gateway.svg?branch=master)](https://travis-ci.org/Wikia/api-gateway)

# API Gateway

The API gateway provides a Lua package that can be integrated into a “host”
such as nginx to marshal authentication tokens embedded in HTTP cookies into a
user id header suitable for user identification by services running behind the
gateway.

## Resources

 * `/healthcheck`: Returns 200 status code on success. Checks to see that the
	 helios heartbeat responds as expected.
 * `/(.*)`: Proxies requests to the services. See below for more details regarding the access token handling. And routing mechanism


If the `access_token` cookie exists and is not empty then an attempt will be
made to authenticate the token against helios and retrieve the user id of the
user to whom the token belongs. If a user id is returned from helios then that
user id will be provided in the `X-User-Id` (also `X-Wikia-UserId` for compatibility with older software) header sent to the service.

If the `access_token` cookie is absent, expired, or invalid then no
`X-User-Id` will be sent to the service.

## Service Routing

Only services configured in consul under `/{DATACENTER}/kv/registry/{ENV}/api-gateway`
are registered and routed via the api-gateway. See the [service
registry](https://github.com/Wikia/guidelines/tree/master/ConsulAndServiceDiscovery#service-registries)
guidelines for more information.

The configuration works as follows. If `prod.helios` is provided as the value to
the `auth` key under the consul key value path above then the following
configuration will be produced in nginx:

```
upstream prod_helios {
   server A<ip>:A<port>;
   server B<ip>:B<port>;
}
```

Similarly, the gateway will include an upstream configuration with the following
key value pairs:

```
url_routes["auth"] = "prod_helios"
```

Note that some sanitization is done on the `{tag}.{service}` values used to
reference APIs to ensure they are compatible with nginx.

In the examples above, `{DATACENTER}` is the consul datacenter and `{ENV}` is
the environment as specificed by the `WIKIA_ENVIRONMENT` environment variable.

## Developing with Nginx Locally

### API-gateway dev Docker image

API gateway has some extensive dependencies. To make it easier to run on different platforms its been Dockerized for the purpose of development.

Building image:
```
docker build -t api-gateway ./
```


# Running local instance

The `scripts/` director contains helpers for stopping and starting nginx. The
nginx config file in `nginx/conf/nginx.conf` should be enough to test.

To start:

```
# generate configs from consul
docker run -v $(pwd):/gateway -t -i  api-gateway scripts/templatize

# run
docker run -p 8100:8100 -v $(pwd):/gateway -t -i  api-gateway scripts/run-nginx
```

You can test the basic functionality with:

```
curl -H “Cookie: access_token=<token>” http://127.0.0.1:8100/service/...
```

The current implementation relies upon DNS to resolve the load balancers. This
is accomplished via the `resolver` directive under the `/service` `location`. If
you are developing locally and do not have DNS running on port 8600 (the
expectation in production) you can “fake” it with the following:

```
socat udp4-recvfrom:8600,reuseaddr,fork \
	udp-sendto:`cat /etc/resolv.conf | grep nameserver | sed ‘s/nameserver \(\.*\)/\1/g’`:53
```

`socat` can be installed via `homebrew` on OS X or via a package manager on
Linux.


## Testing

The lua source code is tested using [busted](http://olivinelabs.com/busted/). To run the tests do
the following:

```
docker run -p 8100:8100 -v $(pwd):/gateway -t -i  api-gateway busted spec 
```

The lua+nginx integration is tested using `Test::Nginx::Socket`. To run the
tests, set `TEST_NGINX_BINARY` (see the Environment section below) and execute:

```
docker run -p 8100:8100 -v $(pwd):/gateway -t -i  api-gateway prove -r t/
```

See `t/basic.t` for the Perl dependencies and example code.

## Local Integration Testing

The integration testing local to this repository also uses busted. To run the
integration tests do the following:

```
busted spec_integration
```

The integration tests require the following environment variables:

 * `USERNAME`: the user name used to request a token from helios
 * `PASSWORD`: the password used to request a token from helios
 * `LOGIN_URL`: the login URL for helios
 * `SERVICE_URL`: the service URL to attempt `GET` once a token has been
	 aquired. This URL should require a token for the tests to work as expected.

## Deployment

The `api-gateway` has been configured to use the deploy tools. To deploy to
production:

```
dt prep -a api-gateway -e prod -r api-gateway@master
dt push -a api-gateway -e prod
```

## Dependencies

 * [busted](http://olivinelabs.com/busted/)
 * [lua-httpclient](https://github.com/lusis/lua-httpclient) Can be installed with `luarocks`
 * [lua-cjson](https://github.com/mpx/lua-cjson)
 * [nginx](http://nginx.org/) or [openresty](http://openresty.org)
 * [consul-template](https://github.com/hashicorp/consul-template)

### Troubleshooting

Below are some problems you may encounter when trying to install on OS X. If you
get the following error from running `luarocks`

```
attempt to call global 'tonumber' (a nil value)
```

Add the following line to the top of `$LUAJIT_PATH/bin/luarocks`:
```
local tonumber = function(s) return s + 0 end
```

If you get the following error when running `luarocks`:

```
luajit-2.1.0-alpha: bad interpreter: No such file or directory
```

Edit `$LUAJIT_PATH/bin/luarocks` and remove the interpreter suffix on the first
line so that the fully qualified path ends in `luajit` instead of
`luajit-2.1.0-alpha`.

## Environement variables

 * `NGINX_BIN`: Set to the location of your nginx binary.
 * `TEST_NGINX_BINARY`: Set to the location of nginx.
		E.g. `export TEST_NGINX_BINARY=`which openresty` on OS X.
 * `API_GATEWAY_TEST_MOCK`: Set to change the default api-gateway test mock.

## Contributors

 * [Artur Klajnerok](https://github.com/ArturKlajnerok)
 * [Damon Snyder](https://github.com/drsnyder)
 * [Frank Farmer](https://github.com/frankfarmer)
 * [Jarek Cellary](https://github.com/jcellary)
 * [Pawel Chojnacki](https://github.com/pchojnacki)

## TODO

 * Create an app table and pass it around. This will provide an easy and light on-ramp to
   dependency injection which should help improve the testability.
