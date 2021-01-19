'use strict';

// Modules
const _ = require('lodash');

const minSupportedPhpVersion = 70;

// Builder
module.exports = {
  name: 'nginx',
  config: {
    version: '1.17',
    supported: ['1.14', '1.16', '1.17', '1.18'],
    legacy: ['1.14'],
    pinPairs: {
      '1.18': 'bitnami/nginx:1.18.0-debian-10-r28',
      '1.17': 'bitnami/nginx:1.17.10-debian-10-r52',
      '1.16': 'bitnami/nginx:1.16.1-debian-10-r106',
      '1.14': 'bitnami/nginx:1.14.2-r125',
    },
    patchesSupported: true,
    confSrc: __dirname,
    defaultFiles: {
      params: 'fastcgi_params',
      server: 'nginx.conf',
      vhosts: 'default.conf.tpl',
    },
    finalFiles: {
      params: '/opt/bitnami/nginx/conf/fastcgi_params',
      server: '/opt/bitnami/nginx/conf/nginx.conf',
      vhosts: '/opt/bitnami/nginx/conf/lando.conf',
    },
    remoteFiles: {
      params: '/tmp/fastcgi_params.lando',
      server: '/tmp/server.conf.lando',
      vhosts: '/tmp/vhosts.conf.lando',
    },
    ssl: false,
    webroot: '.',
    useLocalFpm: true,
    localFpmHost: 'host.docker.internal',  // todo: use LANDO_HOST_IP instead of hardcoded mac-only value
  },
  parent: '_webserver',
  builder: (parent, config) => class LandoNginx extends parent {
    constructor(id, options = {}) {
      options = _.merge({}, config, options);

      // Use different default for ssl
      if (options.ssl) options.defaultFiles.vhosts = 'default-ssl.conf.tpl';

      // If we are using the older 1.14 version we need different locations
      if (options.version === '1.14') {
        options.finalFiles = _.merge({}, options.finalFiles, {
          server: '/opt/bitnami/extra/nginx/templates/nginx.conf.tpl',
          vhosts: '/opt/bitnami/extra/nginx/templates/default.conf.tpl',
        });
        options.defaultFiles = _.merge({}, options.defaultFiles, {server: 'nginx.conf.tpl'});
      }

      // Get the config files final destination
      // @TODO: we cp the files instead of directly mounting them to
      // prevent unexpected edits to this files
      // See: https://github.com/lando/lando/issues/2383
      const {params, server, vhosts} = options.finalFiles;

      // Build the default stuff here
      const phpVersion = options.php_version.replace('.', '');
      const nginx = {
        image: `bitnami/nginx:${options.version}`,
        command: `/launch.sh ${vhosts} ${server} ${params}`,
        environment: {
          NGINX_HTTP_PORT_NUMBER: '80',
          NGINX_DAEMON_USER: 'root',
          NGINX_DAEMON_GROUP: 'root',
          LANDO_NEEDS_EXEC: 'DOEEET',
          LANDO_REAL_WEBROOT: options.webroot,
          LANDO_FPM_HOST: (options.useLocalFpm && phpVersion >= minSupportedPhpVersion) ? options.localFpmHost : 'fpm', // Only > php@7.1 is still brew-supported
          LANDO_FPM_PORT: (options.useLocalFpm && phpVersion >= minSupportedPhpVersion) ? ('91'+phpVersion) : 9000,   // So for older versions we'll still use the docker fpm
          LANDO_FPM_ROOT: (options.useLocalFpm && phpVersion >= minSupportedPhpVersion) ? 'raw_root' : 'document_root',
        },
        ports: ['80'],
        user: 'root',
        volumes: [
          `${options.confDest}/launch.sh:/launch.sh`,
          `${options.confDest}/${options.defaultFiles.params}:${options.remoteFiles.params}:ro`,
          `${options.confDest}/${options.defaultFiles.vhosts}:${options.remoteFiles.vhosts}:ro`,
          `${options.confDest}/${options.defaultFiles.server}:${options.remoteFiles.server}:ro`,
        ],
      };

      // Send it downstream
      super(id, options, {services: _.set({}, options.name, nginx)});
    };
  },
};
