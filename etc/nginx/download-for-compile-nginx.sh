#!/bin/bash

# Check version
# https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
# https://developers.google.com/speed/pagespeed/module/release_notes
# https://github.com/pagespeed/ngx_pagespeed/
# http://nginx.org/en/download.html
# https://github.com/vozlt/nginx-module-vts

NGINX_VERSION=1.12.1
NPS_VERSION=1.12.34.2-stable

SRCDIR=/etc/nginx/source
BASEDIR=$SRCDIR/nginx-$NGINX_VERSION

CPUNUMBER=`nproc`

if [ ! -d $BASEDIR ]; then
  mkdir -p $BASEDIR && mkdir -p $BASEDIR/modules
else
 :
fi

# Download Nginx
cd $SRCDIR
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz


# Download Page speed
cd $BASEDIR/modules
#wget https://github.com/pagespeed/ngx_pagespeed/archive/latest-stable.tar.gz
#tar -xvzf latest-stable.tar.gz
#cd ngx_pagespeed-latest-stable

# wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
# unzip release-${NPS_VERSION}-beta.zip
# cd ngx_pagespeed-release-${NPS_VERSION}-beta/
#wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
#tar -xzvf ${NPS_VERSION}.tar.gz  # extracts to psol/

wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}.zip
unzip v${NPS_VERSION}.zip
cd ngx_pagespeed-${NPS_VERSION}/
NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})  # extracts to psol/

#Download modules
cd $BASEDIR/modules
git clone https://github.com/nbs-system/naxsi.git
git clone https://github.com/FRiCKLE/ngx_cache_purge.git
git clone https://github.com/gnosek/nginx-upstream-fair.git
git clone https://github.com/openresty/set-misc-nginx-module.git
git clone https://github.com/simpl/ngx_devel_kit.git
git clone https://github.com/openresty/srcache-nginx-module.git
git clone https://github.com/openresty/redis2-nginx-module.git
git clone https://github.com/openresty/set-misc-nginx-module.git
git clone https://github.com/google/ngx_brotli.git

#git clone https://github.com/cloudflare/ngx_brotli_module.git
# HTTP Redis https://www.nginx.com/resources/wiki/modules/index.html
wget http://people.freebsd.org/~osa/ngx_http_redis-0.3.7.tar.gz
tar -xzvf ngx_http_redis-0.3.7.tar.gz
#mkdir ngx_http_redis
#tar -C ngx_http_redis -xzf ngx_http_redis-0.3.7.tar.gz
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git

# Install libbrotli to /usr/local/lib
git clone https://github.com/bagder/libbrotli.git
cd $BASEDIR/modules/libbrotli
./autogen.sh
./configure
make -j $CPUNUMBER
make install

cd $BASEDIR/modules/ngx_brotli
git submodule update --init 

#apt-get -o Acquire::ForceIPv4=true build-dep nginx && aptitude install build-essential libpcre3 libpcre3-dev libxml2-dev libxslt1-dev python-dev libgeoip-dev openssl libssl-dev libperl-dev libgd2-xpm-dev zlib1g-dev libcurl4-openssl-dev geoip-database cmake libatomic-ops-dev brotli

aptitude build-dep nginx && aptitude install build-essential libpcre3 libpcre3-dev libxml2-dev libxslt1-dev python-dev libgeoip-dev openssl libssl-dev libperl-dev libgd2-xpm-dev zlib1g-dev libcurl4-openssl-dev geoip-database cmake libatomic-ops-dev
#brotli

# Ubuntu Upstart
# https://www.nginx.com/resources/wiki/start/topics/examples/ubuntuupstart/
# http://kbeezie.com/debian-ubuntu-nginx-init-script/

### NGINX systemd service file

tee -a /lib/systemd/system/nginx.service <<"EOF"
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

#systemctl daemon-reload && systemctl enable nginx && systemctl start nginx && systemctl status nginx.service
#systemctl unmask nginx

### Debian/Ubuntu Nginx init Script
#http://kbeezie.com/debian-ubuntu-nginx-init-script/

### Ubuntu Upstart
#https://www.nginx.com/resources/wiki/start/topics/examples/ubuntuupstart/


#git clone https://github.com/google/brotli.git
#./configure && make
#mkdir out && cd out && cmake -DCMAKE_INSTALL_PREFIX='/' .. && make && make test && make install


tee -a /etc/logrotate.d/nginx <<"EOF"
/var/log/nginx/*.log {
	weekly
	missingok
	rotate 52
	compress
	delaycompress
	notifempty
	create 0640 www-data adm
	sharedscripts
	prerotate
		if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
			run-parts /etc/logrotate.d/httpd-prerotate; \
		fi \
	endscript
	postrotate
		[ -s /run/nginx.pid ] && kill -USR1 `cat /run/nginx.pid`
	endscript
}
EOF
