#!/bin/bash

# Run script
# for create domain one domain test.com ./create_php_site.sh test.com
# for create sub domain qwerty for test.com ./create_php_site.sh test.com qwerty
# http://console.support

NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php5/fpm/pool.d'
WEB_SERVER_GROUP='www-data'
NGINX_INIT='/etc/init.d/nginx'

SED=`which sed`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1
SUBDOMAINS=$2

# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Creating hosting for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi

mkdir -p /var/www/$DOMAIN/logs

if [ -z "$2" ];
	then
		PUBLIC_HTML_DIR='httpdocs'
		CONFIG=$NGINX_CONFIG/$DOMAIN.conf
		CACHENAME=$DOMAIN
		SITENAMED=$DOMAIN
		mkdir -p /var/www/$DOMAIN/$PUBLIC_HTML_DIR
                mkdir -p /var/www/$DOMAIN
		touch /var/log/nginx/$DOMAIN-access.log
		touch /var/log/nginx/$DOMAIN-error.log
		ln -s /var/log/nginx/$DOMAIN-access.log /var/www/$DOMAIN/logs/$DOMAIN-access.log
		ln -s /var/log/nginx/$DOMAIN-error.log /var/www/$DOMAIN/logs/$DOMAIN-error.log
		ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN.conf
	else
		PUBLIC_HTML_DIR='subdomains/'$SUBDOMAINS/'httpdocs'
		CONFIG=$NGINX_CONFIG/$SUBDOMAINS'.'$DOMAIN.conf
		CACHENAME=$SUBDOMAINS'.'$DOMAIN
		SITENAMED=$SUBDOMAINS'.'$DOMAIN
		mkdir -p /var/www/$DOMAIN/$PUBLIC_HTML_DIR
		mkdir -p /var/www/$DOMAIN/$SUBDOMAINS
		touch /var/log/nginx/$SUBDOMAINS'.'$DOMAIN-access.log
		touch /var/log/nginx/$SUBDOMAINS'.'$DOMAIN-error.log
		ln -s /var/log/nginx/$SUBDOMAINS'.'$DOMAIN-access.log /var/www/$DOMAIN/logs/$SUBDOMAINS'.'$DOMAIN-access.log
		ln -s /var/log/nginx/$SUBDOMAINS'.'$DOMAIN-error.log /var/www/$DOMAIN/logs/$SUBDOMAINS'.'$DOMAIN-error.log
		ln -s $CONFIG $NGINX_SITES_ENABLED/$SUBDOMAINS'.'$DOMAIN.conf
	fi

cp $CURRENT_DIR/nginx.vhost.conf_proxy_apache.template $CONFIG
$SED -i "s/@@CACHENAME@@/$CACHENAME/g" $CONFIG
$SED -i "s/@@HOSTNAME@@/$SITENAMED/g" $CONFIG
$SED -i "s#@@PATH@@#\/var\/www\/$DOMAIN\/"$PUBLIC_HTML_DIR"#g" $CONFIG


chmod 600 $CONFIG

chmod g+rx /var/www/$DOMAIN/$PUBLIC_HTML_DIR

chown -R $WEB_SERVER_GROUP:$WEB_SERVER_GROUP /var/www/$DOMAIN/
find /var/www/$DOMAIN/$PUBLIC_HTML_DIR -type d -exec chmod 774 {} \;
find /var/www/$DOMAIN/$PUBLIC_HTML_DIR -type f -exec chmod 664 {} \;

$NGINX_INIT reload

echo -e "\nSite Created for $DOMAIN with PHP support"
