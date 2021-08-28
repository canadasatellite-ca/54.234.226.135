#!/bin/bash
#--with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
#    --add-module=$(MODULESDIR)/naxsi/naxsi_src \


NGINX_VERSION=1.12.1
NPS_VERSION=1.12.34.2-stable

SRCDIR=/etc/nginx/source
BASEDIR=$SRCDIR/nginx-$NGINX_VERSION
MODULESDIR=$BASEDIR/modules
NGPREFIX=/var/www/html
CPUNUMBER=`nproc`

export NGX_BROTLI_STATIC_MODULE_ONLY=1

cd  $BASEDIR

#--with-cc-opt='-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -m64 -march=native' \
#--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \

mkdir -p /var/lib/nginx
mkdir -p /var/cache/nginx/client_temp \
mkdir -p /var/cache/nginx/proxy_temp \
mkdir -p /var/cache/nginx/fastcgi_temp \
mkdir -p /var/cache/nginx/uwsgi_temp \
mkdir -p /var/cache/nginx/scgi_temp \
mkdir -p $NGPREFIX

chown -R www-data:www-data /var/lib/nginx
chown -R www-data:www-data /var/cache/nginx
#find /var/cache/nginx -type d -exec chmod 755 {} \;
#find /var/cache/nginx -type f -exec chmod 644 {} \;
#find /var/lib/nginx -type d -exec chmod 755 {} \;
#find /var/lib/nginx -type f -exec chmod 644 {} \;

#    --with-cc-opt="$debian_cflags" \
#    --with-ld-opt="$debian_ldflags" \
#

./configure \
    --with-cc-opt='-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -m64 -march=native' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
    --with-libatomic \
    --prefix=$NGPREFIX \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=www-data \
    --group=www-data \
    --with-debug \
    --with-pcre-jit \
    --with-pcre \
    --with-poll_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_auth_request_module \
    --with-http_xslt_module \
    --with-http_v2_module \
    --with-http_gunzip_module \
    --with-http_geoip_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module \
    --with-file-aio \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
    --without-mail_imap_module \
    --add-module=$MODULESDIR/naxsi/naxsi_src \
    --add-module=$MODULESDIR/ngx_cache_purge \
    --add-module=$MODULESDIR/ngx_brotli \
    --add-module=$MODULESDIR/ngx_pagespeed-${NPS_VERSION}

    # --add-module=$MODULESDIR/echo-nginx-module \
    # --add-module=$MODULESDIR/ngx_devel_kit \
    # --add-module=$MODULESDIR/srcache-nginx-module \
    # --add-module=$MODULESDIR/redis2-nginx-module \
    # --add-module=$MODULESDIR/set-misc-nginx-module \
    # --add-module=$MODULESDIR/ngx_http_redis-0.3.7 \
    # --add-module=$MODULESDIR/headers-more-nginx-module \
    
make -j $CPUNUMBER
make install
ldconfig
systemctl daemon-reload && systemctl enable nginx && systemctl start nginx && systemctl status nginx.service


# --with-http_spdy_module \
# --add-module=$MODULESDIR/set-misc-nginx-module \
# --add-module=$MODULESDIR/nginx-upstream-fair \
    #--prefix=/usr/share/nginx \

# --with-ipv6 # IPv6 now compiled-in automatically if support is found.