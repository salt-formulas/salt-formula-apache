======
Apache
======

Install and configure Apache webserver

Available states
================

.. contents::
    :local:

``apache.server``
--------------------

Setup apache server

Available metadata
==================

.. contents::
    :local:

``metadata.apache.server.single``
--------------------------

Setup basic server

Configuration parameters
========================


Example reclass
===============

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

Tune the log configuration:

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

Example pillar
==============

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

Read more
=========

* https://httpd.apache.org/docs/
