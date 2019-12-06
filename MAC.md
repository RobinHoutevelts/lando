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

Let's first install some php on your machine

```
brew tap exolnet/homebrew-deprecated

brew install php@7.3
brew install php@7.2
brew install php@7.1
brew install php@7.0
```

Then install some much-needed modules.

```
export PATH="/usr/local/opt/php@7.3/bin:$PATH"
export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
pecl install redis
pecl install xdebug-2.7.2

export PATH="/usr/local/opt/php@7.2/bin:$PATH"
export PATH="/usr/local/opt/php@7.2/sbin:$PATH"
pecl install redis
pecl install xdebug-2.7.2

export PATH="/usr/local/opt/php@7.1/bin:$PATH"
export PATH="/usr/local/opt/php@7.1/sbin:$PATH"
pecl install redis
pecl install xdebug-2.7.2

export PATH="/usr/local/opt/php@7.0/bin:$PATH"
export PATH="/usr/local/opt/php@7.0/sbin:$PATH"
pecl install redis
pecl install xdebug-2.7.2

export PATH="/usr/local/opt/php@7.3/bin:$PATH"
export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
```

Let's make sure your default php version is 7.3

```
brew link --force php@7.3
```

### Configure

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

*Perform the same steps also for php 7.0, 7.1 and 7.2 ( they each have their own php.ini file)*

### Restart the services

```
sudo brew services restart php
sudo brew services restart php@7.2
sudo brew services restart php@7.1
```


## Errors:

- php@7.1 doesn't exist anymore in brew

ye.. That means it's EOL. You should just ignore it then.
But make sure to change `minSupportedPhpVersion` to `72` then in `plugins/lando-services/services/nginx/builder.js` and create a new build.

You'll fall back to the slower lando version.


# Caveats

Hmm, I do have one thing that bothers me..

In order to access services defined in your lando.yml file you *have to* portforward it and use that in your `.env`.

For example, I want to use the `database` service. So I add this to my `lando.yml`

```yml
services:
  database:
    portforward: 9410
```

And in my `.env` you'll find

```
DB_HOST=127.0.0.1
DB_USERNAME=myproject
DB_PASSWORD=myproject
DB_DATABASE=myproject
DB_PORT=9410
```

It sucks you have to do this. Any help on the matter is accepted.
( But don't 'fix' it by having `database` accept connections from anywhere 😅 )
