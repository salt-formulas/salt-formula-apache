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
             ldap:
               url: "ldaps://idm01.example.eu/dc=example,dc=eu?krbPrincipalName"
               mech: GSSAPI
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

