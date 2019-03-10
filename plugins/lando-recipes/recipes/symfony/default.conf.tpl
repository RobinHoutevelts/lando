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
      try_files $uri /index.php?$query_string;
  }

  location ~ '\.php$' {
      fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
      include fastcgi_params;
      fastcgi_param HTTP_PROXY "";
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_param PATH_INFO $fastcgi_path_info;
      fastcgi_param QUERY_STRING $query_string;
      fastcgi_intercept_errors on;
      fastcgi_pass fpm:9000;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
      expires max;
      log_not_found off;
  }
}
