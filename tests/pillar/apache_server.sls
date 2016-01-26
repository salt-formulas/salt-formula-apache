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

