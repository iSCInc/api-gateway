package TestHelper;
use strict;
use Exporter;
use File::Basename;

our @ISA= qw( Exporter );

# these are exported by default.
our @EXPORT = qw( create_configured_locations create_http_config create_lua_config );

sub create_configured_locations {
    my ($filename) = @_;
    mkdir(dirname($filename));
    open(my $configured_locations, '>', $filename) || die "Couldn't open filename $filename!";
    print $configured_locations qq{
      local url_routes = {}
      url_routes['test'] = "test"
      return url_routes
    };
    close $configured_locations;
}

sub create_lua_config {
    my ($filename) = @_;
    if (-e $filename) {
      return;
    }
    open(my $lua_config, '>', $filename) || die "Couldn't open filename $filename!";
    print $lua_config qq{
      local config = {}
      config.SERVICE_LB_URL = ""
      return config
    };
    close $lua_config;
}

sub create_http_config {
    my ($pwd, $backend) = @_;
    return qq{
  lua_package_path '${pwd}/t/lua/?.lua;${pwd}/src/?.lua;/usr/local/openresty/lualib/?.lua;;';
  upstream test {
    server ${backend};
  }
  limit_req_zone Client-Ip zone=registration:100m rate=12r/m;

  log_format log_format_with_perf '\$remote_addr - \$remote_user [\$time_local] '
                                '"\$request" \$status \$body_bytes_sent '
                                '\$request_length \$request_time '
                                '"\$http_referer" "\$http_user_agent" "\$gzip_ratio"';
  map \$host \$api_gateway_root {
    default "${pwd}";
  }  
};

}

1;
