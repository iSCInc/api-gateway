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
    include "/gateway/nginx/conf/api-gateway/conf.d/*.conf";
    include "/gateway/nginx/conf/api-gateway/locations/*.conf";
    location /headers {
        content_by_lua_block {
            local h = ngx.req.get_headers(100);
            for key,value in pairs(h) do 
                ngx.header[key] = value 
            end            
            ngx.say(ngx.var.host);            
        } 
    }
CONFIG

plan tests => repeat_each() * (4 * blocks()) - 2;

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

=== TEST 2: Headers
--- http_config eval: $::HttpConfig
--- config eval: $::Config  
--- more_headers eval
"Fastly-Client-IP: 10.10.10.10
Cookie: wikia_beacon_id=somebacon"
--- request
    GET /test/headers
--- response_headers
Fastly-Client-IP: 10.10.10.10
X-Client-Ip: 10.10.10.10
X-Beacon-Id: somebacon
X-User-Id:
X-Wikia-UserId:
--- error_code: 200


=== TEST 2: Headers
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request
    GET /test/headers
--- response_headers_like    
X-Trace-Id: [a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}
--- error_code: 200
