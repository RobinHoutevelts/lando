Lando FOR MAC
=====

So if you also fucking hate the slow-as-fuck Docker-for-Mac experience you'll like this one:

*Lando* that uses php-fpm of the _host_. A version that totally ignores the php-fpm that comes with it by default.

Ofcourse there are a few downsides:

 - No php patch versions
 - You have to manually install php on your mac
 - You have to manually upgrade/maintain php on your mac

The upside is:

 - Fast as fuck. It's just php running natively on your mac.
 
----

## Still wanna use it?

Aight! My man!


### Install

If you're gonna drush on your machine you'll need the `mysql-client` package

```
brew install mysql-client
echo 'export PATH="/usr/local/opt/mysql-client/bin:$PATH"' >> ~/.zshrc
```

Let's first install some php on your machine

```
brew tap shivammathur/php

brew install shivammathur/php/php@7.4
brew install shivammathur/php/php@7.3
brew install shivammathur/php/php@7.2
brew install shivammathur/php/php@7.1
brew install shivammathur/php/php@7.0
```

Then install some much-needed modules.

```
/usr/local/opt/php@7.4/bin/pecl install redis xdebug-3.0.2

/usr/local/opt/php@7.3/bin/pecl install redis xdebug-3.0.2

/usr/local/opt/php@7.2/bin/pecl install redis xdebug-2.9.8

/usr/local/opt/php@7.1/bin/pecl install redis xdebug-2.9.8

/usr/local/opt/php@7.0/bin/pecl install redis xdebug-2.8.1
```

Let's make sure your default php version is 7.4

```
brew link --force php@7.4
```

### Configure php-packages

Now we need to configure the shit out of those thangs

`sudo nano /usr/local/etc/php/7.4/php.ini`

Remove the two added extensions ( we'll add them back later )

```
zend_extension="xdebug.so"
extension="redis.so"
```

And replace it with some configured shit.

This will make sure you have an xdebug that will connect to your host.

```
[xdebug]
zend_extension="xdebug.so"
xdebug.mode=develop,debug
xdebug.start_with_request=yes
xdebug.client_host=localhost
xdebug.client_port=9000
xdebug.log_level=0

[redis]
extension="redis.so"
```

<details><summary>For xdebug 2.x</summary>

```
[xdebug]
zend_extension="xdebug.so"
xdebug.remote_enable=1
xdebug.remote_autostart=1
xdebug.remote_host=localhost
xdebug.remote_port=9000

[redis]
extension="redis.so"
```

</details>

Also increase your max memory from 128M to 1G

*Perform the same steps also for php 7.0, 7.1, 7.2 and 7.3 ( they each have their own php.ini file)*

### Configure php-fpm

We need to define a port we'll listen on.

`sudo nano /usr/local/etc/php/7.4/php-fpm.d/www.conf`

In there replace

```
;listen = 127.0.0.1:9000
```

with

```
listen = 127.0.0.1:9174
```

Do the same for php 7.0, 7.1, 7.2 and 7.3 but use ports `9170`, `9171`, `9172`, `9173`

### Restart the services

```
brew services restart php
brew services restart php@7.3
brew services restart php@7.2
brew services restart php@7.1
brew services restart php@7.0
```


## Errors:

- php@7.x doesn't exist anymore in brew

ye.. That means it's EOL. You should just ignore it then.
But make sure to change `minSupportedPhpVersion` to `7x` then in `plugins/lando-services/services/nginx/builder.js` and create a new build.

You'll fall back to the slower lando version.

- dyld: Library not loaded: /usr/local/opt/openssl/lib/libcrypto.1.0.0.dyli

You probably installed something recently ( php 8 perhaps? ) and your openssl got
updated. You'll need to switch to a previous openssl implementation.

`brew switch openssl 1.0`

or if fnm stopped working: `brew upgrade Shiz/tap/fnm`

This might not work, but it'll tell you which versions are installed. I bet ya
you'll be able to use one that works.

- dyld: Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.64.dylib

Basically the same as the one above. But for `icu4c`

`brew switch icu4c 64.2`

## ProTip

Alias `php` to a script that loads correct versions based on your `.lando.yml` file.

```sh
#!/usr/bin/env bash
DEFAULT_PHP_VERSION="7.4"

ROOTDIR=$(pwd)

if git rev-parse --git-dir > /dev/null 2>&1; then
  ROOTDIR=$(git rev-parse --show-toplevel)
fi

PHP_VERSION="$DEFAULT_PHP_VERSION"
if [[ -f "$ROOTDIR/.lando.yml" ]]; then
    PHP_VERSION=$(cat "$ROOTDIR/.lando.yml" | grep "php:" | cut -d ":" -f2)
fi

PHP_VERSION=$(echo "$PHP_VERSION" | sed 's/[^0-9]*//g')
PHP_VERSION="$(echo "$PHP_VERSION" | cut -c1,1).$(echo "$PHP_VERSION" | cut -c2,2)"

if [[ ! -f "/usr/local/opt/php@$PHP_VERSION/bin/php" ]]; then
   PHP_VERSION=${DEFAULT_PHP_VERSION}
fi

# ICU4C_VERSION=$(brew list --versions icu4c | awk -F' ' '{print $NF}')
# Hardcoded for speed
#case "$PHP_VERSION" in
#    "7.0" | "7.1" | "7.2")
#        ICU4C_VERSION="64.2"
#        ;;
#    "7.3" | "7.4")
#        ICU4C_VERSION="66.1"
#        ;;
#esac

#brew switch icu4c "$ICU4C_VERSION" > /dev/null 2>&1

PHP_BIN="/usr/local/opt/php@$PHP_VERSION/bin/php"

${PHP_BIN} "$@"
exit $?
```
