==============
Apache Formula
==============

Install and configure Apache webserver

Sample Pillars
==============

Simple Apache proxy

.. code-block:: yaml

    apache:
      server:
        enabled: true
        bind:
          address: '0.0.0.0'
          ports:
          - 80
        modules:
        - proxy
        - proxy_http
        - proxy_balancer


Apache plain static sites (eg. sphinx generated, from git/hg sources)

.. code-block:: yaml

    apache:
      server:
        enabled: true
        bind:
          listen_default_ports: false
          address: '0.0.0.0'
          ports:
          - 80
        modules:
        - rewrite
        - status
        site:
        - enabled: true
          name: 'sphinxdoc'
          type: 'static'
          host:
            name: 'doc.domain.com'
            port: 80
          source:
            engine: local
        - enabled: true
          name: 'impressjs'
          type: 'static'
          host:
            name: 'pres.domain.com'
            port: 80
          source:
            engine: git
            address: 'git@repo1.domain.cz:impress/billometer.git'
            revision: 'master'

Tune settings of mpm_prefork

.. code-block:: yaml

    parameters:
      apache:
        mpm:
          prefork:
            max_clients: 250
            servers:
              min: 32
              max: 64
              max_requests: 4000

Apache kerberos authentication:

.. code-block:: yaml

    parameters
      apache:
        server:
          site:
            auth:
             engine: kerberos
             name: "Kerberos Authentication"
             require:
               - "ldap-attribute memberOf='cn=somegroup,cn=groups,cn=accounts,dc=example,dc=com'"

             kerberos:
               realms:
                 - EXAMPLE.COM
               # Bellow is optional
               keytab: /etc/apache2/ipa.keytab
               service: HTTP
               method:
                 negotiate: true
                 k5passwd: true

             ldap:
               url: "ldaps://idm01.example.com/dc=example,dc=com?krbPrincipalName"
               # mech is optional
               mech: GSSAPI

Tune security settings (these are default):

.. code-block:: yaml

    parameters:
      apache:
        server:
          # ServerTokens
          tokens: Prod
          # ServerSignature, can be also set per-site
          signature: false
          # TraceEnable, can be also set per-site
          trace: false
          # Deny access to .git, .svn, .hg directories
          secure_scm: true
          # Required for settings bellow
          modules:
            - headers
          # Set X-Content-Type-Options
          content_type_options: nosniff
          # Set X-Frame-Options
          frame_options: sameorigin

Tuned up log configuration.

.. code-block:: yaml

    parameters:
      apache:
        server:
          site:
            foo:
              enabled: true
              type: static
              log:
                custom:
                  enabled: true
                  file: /var/log/apache2/mylittleponysitecustom.log
                  format: >-
                     %{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"
                error:
                  enabled: false
                  file: /var/log/apache2/foo.error.log
                  level: notice

Apache wsgi application.

.. code-block:: yaml

    apache:
      server:
        enabled: true
        default_mpm: event
        site:
          manila:
            enabled: false
            available: true
            type: wsgi
            name: manila
            wsgi:
              daemon_process: manila-api
              threads: 2
              user: manila
              group: manila
              display_name: '%{GROUP}'
              script_alias: '/ /usr/bin/manila-wsgi'
              application_group: '%{GLOBAL}'
              authorization: 'On'
            limits:
              request_body: 114688

Apache ssl cipher management

.. code-block:: yaml

    parameters:
      apache:
        server:
          enabled: true
          site:
            example:
              enabled: true
              ssl:
                enabled: true
                mode: secure
                ...

.. code-block:: yaml

    parameters:
      apache:
        server:
          enabled: true
          site:
            example:
              enabled: true
              ssl:
                enabled: true
                mode: normal
                ...

.. code-block:: yaml

    parameters:
      apache:
        server:
          enabled: true
          site:
            example:
              enabled: true
              ssl:
                enabled: true
                mode: strict
                ciphers:
                  ECDHE_RSA_AES256_GCM_SHA384:
                    name: 'ECDHE-RSA-AES256-GCM-SHA384'
                    enabled: True
                  ECDHE_ECDSA_AES256_GCM_SHA384:
                    name: 'ECDHE-ECDSA-AES256-GCM-SHA384'
                    enabled: True
                protocols:
                  TLS1:
                    name: 'TLSv1'
                    enabled: True
                  TLS1_1:
                    name: 'TLSv1.1'
                    enabled: True
                  TLS1_2:
                    name: 'TLSv1.2'
                    enabled: False
                prefer_server_ciphers: 'on'
                ...

Advanced SSL configuration, more information about SSL options can be found
at https://httpd.apache.org/docs/2.4/mod/mod_ssl.html
!Please note that if mode = 'secure' or mode = 'normal' and 'ciphers' or 'protocols' are set - they should have
type "string", if mode = 'manual', their type should be "dict" (like shown below)

SSL settings on SITE level:

.. code-block:: yaml

    parameters:
      apache:
        server:
          enabled: true
          site:
            example:
              enabled: true
              ssl:
                enabled: true
                engine: salt
                authority: "${_param:salt_minion_ca_authority}"
                key_file: "/etc/ssl/private/internal_proxy.key"
                cert_file: "/etc/ssl/certs/internal_proxy.crt"
                chain_file: "/etc/ssl/certs/internal_proxy-with-chain.crt"
                mode: 'strict'
                session_timeout: '300'
                protocols:
                  TLS1:
                    name: 'TLSv1'
                    enabled: True
                  TLS1_1:
                    name: 'TLSv1.1'
                    enabled: True
                  TLS1_2:
                    name: 'TLSv1.2'
                    enabled: False
                ciphers:
                  ECDHE_RSA_AES256_GCM_SHA384:
                    name: 'ECDHE-RSA-AES256-GCM-SHA384'
                    enabled: True
                  ECDHE_ECDSA_AES256_GCM_SHA384:
                    name: 'ECDHE-ECDSA-AES256-GCM-SHA384'
                    enabled: True
                prefer_server_ciphers: "off"
                dhparam:
                  enabled: True
                  numbits: 2048
                ecdh_curve:
                  secp384r1:
                    name: 'secp384r1'
                    enabled: False
                secp521r1:
                    name: 'secp521r1'
                    enabled: True
                ticket_key:
                  enabled: True
                  numbytes: 48
                session_tickets: 'on'
                stapling: 'off'
                crl:
                  file: '/etc/ssl/crl/crl.pem'
                  path: '/etc/ssl/crl'
                  value: 'chain'
                  enabled: False
                verify_client: 'none'
                client_certificate:
                  file: '/etc/ssl/client_cert.pem'
                  enabled: False
                compression: 'off'
                ssl_engine: 'on'
                insecure_renegotiation: 'off'
                ocsp:
                  default_responder: 'http://responder.example.com:8888/responder'
                  ocsp_enable: 'off'
                  override_responder: 'off'
                  responder_timeout: '50'
                  max_age: '300'
                  time_skew: '300'
                  nonce: 'on'
                  enabled: True
                conf_cmd:
                  sessionticket:
                    command_name: 'Options'
                    command_value: '-SessionTicket'
                    enabled: True
                  serverpreference:
                    command_name: 'Options'
                    command_value: '-ServerPreference'
                    enabled: False
                ssl_options:
                  fakebasicauth:
                    option: '+FakeBasicAuth'
                    enabled: 'True'
                  strictrequire:
                    option: '-StrictRequire'
                    enabled: True
                proxy:
                  ca_cert_file: '/etc/ssl/client_cert.pem'
                  ca_cert_path: '/etc/ssl/client/'
                  crl:
                    file: '/etc/ssl/crl/crl.pem'
                    path: '/etc/ssl/crl'
                    value: 'chain'
                    enabled: False
                  check_peer_cn: 'off'
                  check_peer_expire: 'off'
                  check_peer_name: 'off'
                  ciphers:
                    ECDHE_RSA_AES256_GCM_SHA384:
                      name: 'ECDHE-RSA-AES256-GCM-SHA384'
                      enabled: True
                    ECDHE_ECDSA_AES256_GCM_SHA384:
                      name: 'ECDHE-ECDSA-AES256-GCM-SHA384'
                      enabled: False
                  ssl_engine: 'on'
                  proxy_chain_file: '/etc/ssl/proxy_chain.pem'
                  proxy_cert_file: '/etc/ssl/proxy.pem'
                  proxy_cert_path: '/etc/ssl/proxy'
                  verify: 'none'
                  verify_depth: '1'
                  srp_unknown_seed: 'secret_string'
                  srp_verifier_file: '/path/to/file.srpv'
                ssl_stapling:
                  error_cache_timeout: '600'
                  fake_try_later: 'off'
                  stapling_responder: 'http://responder.example.com:8888/responder'
                  responder_timeout: '600'
                  response_max_age: '300'
                  response_time_skew: '300'
                  responder_errors: 'off'
                  standard_cache_timeout: '600'
                sniv_host_check: 'off'
                verify_depth: '1'

SSL settings on SERVER level:

.. code-block:: yaml

  apache:
    server:
      ssl:
        enabled: True
        crypto_device: 'rdrand'
        fips: 'off'
        passphrase: 'builtin'
        random_seed:
          seed1:
            context: 'startup'
            source: 'file:/dev/urandom 256'
            enabled: True
          seed2:
            context: 'connect'
            source: 'builtin'
            enabled: True
        session_cache: 'none'
        stapling_cache: 'default'
        ssl_user_name: 'SSL_CLIENT_S_DN_CN'


Roundcube webmail, postfixadmin and mailman

.. code-block:: yaml

    classes:
    - service.apache.server.single
    parameters:
      apache:
        server:
          enabled: true
          modules:
            - cgi
            - php
          site:
            roundcube:
              enabled: true
              type: static
              name: roundcube
              root: /usr/share/roundcube
              locations:
                - uri: /admin
                  path: /usr/share/postfixadmin
                - uri: /mailman
                  path: /usr/lib/cgi-bin/mailman
                  script: true
                - uri: /pipermail
                  path: /var/lib/mailman/archives/public
                - uri: /images/mailman
                  path: /usr/share/images/mailman
              host:
                name: mail.example.com
                aliases:
                  - mail.example.com
                  - lists.example.com
                  - mail01.example.com
                  - mail01

Logrotate settings which allow you to rotate the logs in
a random time in a given time interval. Time in seconds

.. code-block:: yaml

  apache:
    server:
      logrotate:
        start_period: 600
        end_period: 1200


More Information
================

* https://httpd.apache.org/docs/


Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-apache/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-apache

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
