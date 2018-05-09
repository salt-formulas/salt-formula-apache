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
