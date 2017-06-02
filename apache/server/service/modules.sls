{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- for module in server.modules %}

{%- if module == 'passenger' %}

apache_passenger_package:
  pkg.installed:
  - name: libapache2-mod-passenger
  - require:
    - pkg: apache_packages

{%- endif %}

{%- if module == 'php' %}

apache_php_package:
  pkg.installed:
  - name: {{ server.mod_php }}
  - require:
    - pkg: apache_packages

{%- set module = server.module_php %}

{%- endif %}

{%- if module == 'perl' %}

apache_perl_package:
  pkg.installed:
  - name: {{ server.mod_perl }}
  - require:
    - pkg: apache_packages

{%- endif %}

{%- if module == 'wsgi' %}

apache_wsgi_package:
  pkg.installed:
  - name: {{ server.mod_wsgi }}
  - require:
    - pkg: apache_packages

{%- endif %}

{%- if module == 'xsendfile' %}

apache_xsendfile_package:
  pkg.installed:
  - name: {{ server.mod_xsendfile }}
  - require:
    - pkg: apache_packages

{%- endif %}

{%- if module == 'auth_kerb' %}

apache_auth_kerb_package:
  pkg.installed:
  - name: {{ server.mod_auth_kerb }}
  - require:
    - pkg: apache_packages

{%- endif %}

apache_{{ module }}_enable:
  cmd.run:
  - name: "a2enmod {{ module }}"
  - creates: /etc/apache2/mods-enabled/{{ module }}.load
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

{%- endfor %}

{%- endif %}
