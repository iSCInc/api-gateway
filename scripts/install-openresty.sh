#!/bin/bash
VERSION=1.7.10.2
PACKAGE=ngx_openresty-${VERSION}.tar.gz
DOWNLOAD_BASE=https://openresty.org/download
TEMPDIR=$HOME/tmp
PREFIX=$HOME/local

mkdir -p $TEMPDIR
mkdir -p $PREFIX


cd $TEMPDIR
rm -rf ngx_openresty-${VERSION}

wget $DOWNLOAD_BASE/$PACKAGE
tar zxvf $PACKAGE

cd ngx_openresty-${VERSION}
./configure \
		--prefix=$HOME/local \
		--with-cc-opt="-I/usr/local/opt/openssl/include/ -I/usr/local/opt/pcre/include/" \
		--with-ld-opt="-L/usr/local/opt/openssl/lib/ -L/usr/local/opt/pcre/lib/" \
		-j8
make
make install

