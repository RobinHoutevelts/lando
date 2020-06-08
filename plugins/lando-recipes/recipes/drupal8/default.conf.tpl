server {
  listen 80 default_server;
  listen 443 ssl;

  server_name localhost;

  ssl_certificate           /certs/cert.crt;
  ssl_certificate_key       /certs/cert.key;
  ssl_verify_client         off;

  ssl_session_cache    shared:SSL:1m;
  ssl_session_timeout  5m;

  ssl_ciphers  HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers  on;

  port_in_redirect off;
  client_max_body_size 100M;

  root "{{LANDO_WEBROOT}}";

  # CSS, JS and Images
  location ~* \.(?:js|css|png|jpg|jpeg|gif|ico|svg)$ {
    access_log off;
    add_header Cache-Control "max-age=3600, public, s-maxage=31536000";
  }

  location = /favicon.ico {
      log_not_found off;
      access_log off;
  }

  location = /robots.txt {
      allow all;
      log_not_found off;
      access_log off;
  }

  # Very rarely should these ever be accessed outside of your lan
  location ~* \.(txt|log)$ {
      allow 192.168.0.0/16;
      deny all;
  }

  location ~ \..*/.*\.php$ {
      return 403;
  }

  location ~ ^/sites/.*/private/ {
      return 403;
  }

  # Allow "Well-Known URIs" as per RFC 5785
  location ~* ^/.well-known/ {
      allow all;
  }

  # Block access to "hidden" files and directories whose names begin with a
  # period. This includes directories used by version control systems such
  # as Subversion or Git to store control files.
  location ~ (^|/)\. {
      return 403;
  }

  location / {
      # try_files $uri @rewrite; # For Drupal <= 6
      try_files $uri /index.php?$query_string; # For Drupal >= 7
  }

  location @rewrite {
      rewrite ^/(.*)$ /index.php?q=$1;
  }

  # Don't allow direct access to PHP files in the vendor directory.
  location ~ /vendor/.*\.php$ {
      deny all;
      return 404;
  }

  # Wieni Faster-Than-Light endpoint
  location ^~ /swoole/ {
    proxy_set_header Host $http_host;
    proxy_set_header Scheme $scheme;
    proxy_set_header SERVER_PORT $server_port;
    proxy_set_header REMOTE_ADDR $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_pass http://fpm:8337;
  }

  # In Drupal 8, we must also match new paths where the '.php' appears in
  # the middle, such as update.php/selection. The rule we use is strict,
  # and only allows this pattern with the update.php front controller.
  # This allows legacy path aliases in the form of
  # blog/index.php/legacy-path to continue to route to Drupal nodes. If
  # you do not have any paths like that, then you might prefer to use a
  # laxer rule, such as:
  #   location ~ \.php(/|$) {
  # The laxer rule will continue to work if Drupal uses this new URL
  # pattern with front controllers other than update.php in a future
  # release.
  location ~ '\.php$|^/update.php' {
      fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
      # Security note: If you're running a version of PHP older than the
      # latest 5.3, you should have "cgi.fix_pathinfo = 0;" in php.ini.
      # See http://serverfault.com/q/627903/94922 for details.
      include fastcgi_params;
      # Block httpoxy attacks. See https://httpoxy.org/.
      fastcgi_param HTTP_PROXY "";
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_param PATH_INFO $fastcgi_path_info;
      fastcgi_param QUERY_STRING $query_string;
      fastcgi_intercept_errors on;
      # PHP 5 socket location.
      #fastcgi_pass unix:/var/run/php5-fpm.sock;
      # PHP 7 socket location.
      #fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
      #lando
      fastcgi_pass fpm:9000;
  }

  # Fighting with Styles? This little gem is amazing.
  # location ~ ^/sites/.*/files/imagecache/ { # For Drupal <= 6
  location ~ ^(/[a-z\-]+)?/sites/.*/files/styles/ { # For Drupal >= 7
      try_files $uri @rewrite;
  }

  # Handle private files through Drupal. Private file's path can come
  # with a language prefix.
  location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
      try_files $uri /index.php?$query_string;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
      expires max;
      log_not_found off;
  }

}
