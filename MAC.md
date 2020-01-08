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
brew tap exolnet/homebrew-deprecated

brew install php@7.4
brew install php@7.3
brew install php@7.2
brew install php@7.1
brew install php@7.0
```

Then install some much-needed modules.

```
export PATH="/usr/local/opt/php@7.4/bin:$PATH"
export PATH="/usr/local/opt/php@7.4/sbin:$PATH"
pecl install redis
pecl install xdebug-2.9.0

export PATH="/usr/local/opt/php@7.3/bin:$PATH"
export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
pecl install redis
pecl install xdebug-2.9.0

export PATH="/usr/local/opt/php@7.2/bin:$PATH"
export PATH="/usr/local/opt/php@7.2/sbin:$PATH"
pecl install redis
pecl install xdebug-2.9.0

export PATH="/usr/local/opt/php@7.1/bin:$PATH"
export PATH="/usr/local/opt/php@7.1/sbin:$PATH"
pecl install redis
pecl install xdebug-2.9.0

export PATH="/usr/local/opt/php@7.0/bin:$PATH"
export PATH="/usr/local/opt/php@7.0/sbin:$PATH"
pecl install redis
pecl install xdebug-2.9.0

export PATH="/usr/local/opt/php@7.4/bin:$PATH"
export PATH="/usr/local/opt/php@7.4/sbin:$PATH"
```

Let's make sure your default php version is 7.4

```
brew link --force php@7.4
```

### Configure php-packages

Now we need to configure the shit out of those thangs

`sudo nano /usr/local/etc/php/7.3/php.ini`

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
xdebug.remote_enable=1
xdebug.remote_autostart=1
xdebug.remote_host=localhost
xdebug.remote_port=9000

[redis]
extension="redis.so"
```

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
sudo brew services restart php
sudo brew services restart php@7.3
sudo brew services restart php@7.2
sudo brew services restart php@7.1
sudo brew services restart php@7.0
```


## Errors:

- php@7.x doesn't exist anymore in brew

ye.. That means it's EOL. You should just ignore it then.
But make sure to change `minSupportedPhpVersion` to `7x` then in `plugins/lando-services/services/nginx/builder.js` and create a new build.

You'll fall back to the slower lando version.

# Caveats

Hmm, I do have one thing that bothers me..

In order to access services defined in your lando.yml file you *have to* portforward it and use that in your `.env`.

For example, I want to use the `database` service so in my `.env` you'll find

```
DB_HOST=127.0.0.1
DB_USERNAME=myproject
DB_PASSWORD=myproject
DB_DATABASE=myproject
DB_PORT=32813
```

You find the port by running `lando info` and look for the `external_connection:` port of the `database` service.

I usually work on a project for a longer amount of time. And I don't mind having multiple projects running.

It's only when you (re)start a service you have to remind yourself to set the port.
