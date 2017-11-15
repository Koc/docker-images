#!/bin/bash
set -e

# Note: we don't just use "apache2ctl" here because it itself is just a shell-script wrapper around apache2 which provides extra functionality like "apache2ctl start" for launching apache2 in the background.
# (also, when run as "apache2ctl <apache args>", it does not use "exec", which leaves an undesirable resident shell process)

# backup env variables
declare -A ENVVARS_BAK
for e in "${!APACHE_@}"; do
    k=${e}
    ENVVARS_BAK[$k]=${!e}
done

: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

# restore env variables
for e in ${!ENVVARS_BAK[@]}; do
    declare $e=${ENVVARS_BAK[$e]}
done

# Apache gets grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
sudo rm -f "$APACHE_PID_FILE"

# create missing directories
# (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
for e in "${!APACHE_@}"; do
	if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
		# handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
		#   mkdir: cannot create directory '/var/lock': File exists
		dir="${!e}"
		while [ "$dir" != "$(dirname "$dir")" ]; do
			dir="$(dirname "$dir")"
			if [ -d "$dir" ]; then
				break
			fi
			absDir="$(readlink -f "$dir" 2>/dev/null || :)"
			if [ -n "$absDir" ]; then
				mkdir -p "$absDir"
			fi
		done

		mkdir -p "${!e}"
	fi
done

if [ -n "$PHP_CONFIG" ]; then
	echo "$PHP_CONFIG" | sudo tee $PHP_INI_DIR/apache2/conf.d/90-config.ini > /dev/null
	echo "$PHP_CONFIG" | sudo tee $PHP_INI_DIR/cli/conf.d/90-config.ini > /dev/null
fi

if [ -n "$PHP_CONFIG_WEB" ]; then
	echo "$PHP_CONFIG_WEB" | sudo tee $PHP_INI_DIR/apache2/conf.d/95-config.ini > /dev/null
fi

if [ -n "$PHP_CONFIG_CLI" ]; then
	echo "$PHP_CONFIG_CLI" | sudo tee $PHP_INI_DIR/cli/conf.d/95-config.ini > /dev/null
fi

if [ -n "$PASSWORD" ]; then
	echo -e "$PASSWORD\n$PASSWORD\n" | sudo passwd $USER
fi

#TODO: use gosu instead of sudo?
#TODO: is it possible to get rid of this?
export HOME=/home/$USER

USER=$(whoami)
sudo chown $USER:$USER -R $HOME/.composer/

if [ -n "$COMPOSER_AUTH" ]; then
    #mkdir -p $HOME/.config/composer
	#echo "$COMPOSER_AUTH" | tee $HOME/.config/composer/auth.json > /dev/null
    mkdir -p $HOME/.config/composer
	echo "$COMPOSER_AUTH" | tee $HOME/.composer/auth.json > /dev/null
fi

#sudo chown $USER:$USER -R $HOME/.config/composer/
#sudo chown $USER:$USER -R /var/www/html/

echo $(git --version)
#echo $(hg --version)

echo $(php --version)
echo $(composer --version)
echo $(phpunit --version)
echo $(phpcs --version)

echo 'Node Version' $(node --version)
echo 'Npm Version' $(npm --version)
echo 'Yarn Version' $(yarn --version)
echo 'Bower Version' $(bower --version)

echo $(apache2 -v)

exec sudo -E apache2 -DFOREGROUND "$@"
