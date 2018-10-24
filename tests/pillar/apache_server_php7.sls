apache:
  server:
    enabled: true
    bind:
      address: 127.0.0.1
    modules:
      - cgi
      - php
      - auth_kerb
      - headers
      - rewrite
      - authnz_ldap
      - dav
      - dav_fs
    module_php: php7.0
    user:
      cloudlab:
        enabled: true
        password: cloudlab
        htpasswd: cloudlab.htpasswd
    robots:
      default:
        all:
          disallow:
            - /
    site:
      roundcube:
        enabled: true
        type: static
        name: roundcube
        root: /usr/share/roundcube
        robots: default
        locations:
          - uri: /admin
            path: /usr/share/postfixadmin
            auth:
             engine: kerberos
             name: "Kerberos Authentication"
             require:
               - "ldap-attribute memberOf='cn=jenkins,cn=groups,cn=accounts,dc=example,dc=eu'"
             kerberos:
               realms:
                 - EXAMPLE.EU
               keytab: /etc/apache2/ipa.keytab
               service: HTTP
               method:
                 negotiate: true
                 k5passwd: true
          - uri: /mailman
            path: /usr/lib/cgi-bin/mailman
            script: true
            auth:
              engine: basic
              htpasswd: cloudlab.htpasswd
          - uri: /pipermail
            path: /var/lib/mailman/archives/public
            webdav:
              enabled: true
          - uri: /images/mailman
            path: /usr/share/images/mailman
        host:
          name: mail.example.com
          aliases:
            - mail.example.com
            - lists.example.com
            - mail01.example.com
            - mail01
    default_mpm: prefork
    mpm:
      prefork:
        enabled: true
        servers:
          start: 5
          spare:
            min: ${apache:server:mpm:prefork:servers:start}
            max: 10
          # Avoid memory leakage by restarting workers every x requests
          max_requests: 0
        # Should be 80% of server memory / average memory usage of one worker
        max_clients: 150
        # Should be same or more than max clients
        limit: ${apache:server:mpm:prefork:max_clients}
