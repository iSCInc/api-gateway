# vim:set ft=perl ts=4 sw=4 et:
use warnings;
use strict;
use File::Basename;
use Test::Nginx::Socket;
use Cwd qw(cwd abs_path);
use lib dirname(abs_path($0));
use TestHelper;

our $pwd = cwd();
our $APIGatewayTestMock = $ENV{"API_GATEWAY_TEST_MOCK"} || "wikia-api-gateway-backends.getsandbox.com";

create_configured_locations($pwd . '/t/lua/configured_locations.lua');
create_lua_config($pwd . '/src/config.lua');
our $HttpConfig = create_http_config($pwd, $APIGatewayTestMock);

plan tests => repeat_each(1) * (2 * blocks());

no_shuffle();
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

=== TEST 2: X-Forwarded-For
--- http_config eval: $::HttpConfig
--- config   
    include "/gateway/nginx/conf/api-gateway/conf.d/*.conf";
    include "/gateway/nginx/conf/api-gateway/locations/*.conf";    
--- more_headers eval
"Fastly-Client-IP: 10.10.10.10
Host: $::APIGatewayTestMock"
--- request
    GET /test/x-forwarded-for
--- response_body_like
.*"ip": "10.10.10.10".*
--- error_code: 200
