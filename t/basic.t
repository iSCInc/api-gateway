# vim:set ft=perl ts=4 sw=4 et:
use warnings;
use strict;
use File::Basename;
use Test::Nginx::Socket;
use Cwd qw(cwd abs_path);
use lib dirname(abs_path($0));
use TestHelper;

our $pwd = cwd();
create_configured_locations($pwd . '/t/lua/configured_locations.lua');
create_lua_config($pwd . '/src/config.lua');
our $HttpConfig = create_http_config($pwd, "localhost:1984");
our $Config = << 'CONFIG';
    include "/gateway/nginx/conf/api-gateway/conf.d/common.conf";
    include "/gateway/nginx/conf/api-gateway/locations/*.conf";
    location /headers {
        content_by_lua_block {
            local h = ngx.req.get_headers(100);
            for key,value in pairs(h) do
                ngx.header['MIRRORED-' .. key] = value
            end

            ngx.say(ngx.var.host);
        }
    }

    location /info {
        content_by_lua_block {
            ngx.say('{"status": "git", "user_id": "90061"}');
        }
    }
CONFIG

plan tests => repeat_each(3) * 23;

no_root_location();
run_tests();
__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location /echo {
        echo_before_body hello;
        echo world;
    }
--- request
    GET /echo
--- response_body
hello
world
--- error_code: 200

=== TEST 2: Headers
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- more_headers
Fastly-Client-IP: 10.10.10.10
Cookie: wikia_beacon_id=somebacon
X-User-Id: someUserId
X-Wikia-UserId: someUserId
--- request
    GET /test/headers
--- response_headers
MIRRORED-X-Forwarded-For: 127.0.0.1
MIRRORED-Fastly-Client-IP: 10.10.10.10
MIRRORED-X-Client-Ip: 10.10.10.10
MIRRORED-X-Beacon-Id: somebacon
MIRRORED-X-User-Id:
MIRRORED-X-Wikia-UserId:
--- response_headers_like
MIRRORED-X-Trace-Id: [a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}
--- error_code: 200


=== TEST 3: Headers - trace id
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request
    GET /test/headers
--- response_headers_like
MIRRORED-X-Trace-Id: [a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}
--- error_code: 200

=== TEST 4: Headers - can't provide x-client-ip from outside
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- more_headers
X-Client-Ip: 10.10.10.10
--- request
    GET /test/headers
--- response_headers
MIRRORED-Fastly-Client-IP:
MIRRORED-X-Client-Ip: 127.0.0.1
--- error_code: 200


=== TEST 5: Headers - fake helios
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- more_headers
Cookie: access_token=token
--- request
    GET /test/headers
--- response_headers
MIRRORED-X-User-Id: 90061
MIRRORED-X-Wikia-UserId: 90061
--- error_code: 200

=== TEST 6: Headers - upstream name and X-Served-By
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request
    GET /test/headers
--- response_headers
X-Upstream-Name: test
--- response_headers_like
X-Served-By: .*127.0.0.1:1984.*
--- error_code: 200

=== TEST 7: Headers - X-Forwarded-For
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- more_headers
X-Forwarded-For: upstream_server
--- request
    GET /test/headers
--- response_headers
MIRRORED-X-Forwarded-For: upstream_server, 127.0.0.1
--- error_code: 200

=== TEST 8: Headers - returns trace-id
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request
    GET /test/headers
--- response_headers_like
X-Trace-Id: [a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}
--- error_code: 200
