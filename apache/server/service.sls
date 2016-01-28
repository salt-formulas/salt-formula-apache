{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

apache_packages:
  pkg.installed:
  - names: {{ server.pkgs }} 

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

{%- set module = 'php5' %}

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

/etc/apache2/sites-enabled/000-default.conf:
  file.absent

apache_service:
  service.running:
  - name: {{ server.service }}
  - reload: true
  - enable: true
  - require:
    - pkg: apache_packages

{%- else %}

apache_service_dead:
  service.dead:
  - name: {{ server.service }}

apache_remove_packages:
  pkg.purged:
  - pkgs: {{ server.pkgs }}
  - require:
    - service: apache_service_dead

{%- for mpm_type, mpm in server.mpm.iteritems() %}

{%- if mpm.enabled %}

apache_mpm_{{ mpm_type }}_enable:
  cmd.run:
  - name: "a2enmod mpm_{{ mpm_type }}"
  - creates: /etc/apache2/mods-enabled/mpm_{{ mpm_type }}.load
  - require:
    - file: apache_mpm_{{ mpm_type }}_config
  - watch_in:
    - service: apache_service

apache_mpm_{{ mpm_type }}_config:
  file.managed:
  - name /etc/apache2/mods-available/mpm_{{ mpm_type }}.conf
  - source: salt://apache/files/mpm/mpm_{{ mpm_type }}.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

{%- else %}

apache_mpm_{{ mpm_type }}_disable:
  file.absent:
  - name: /etc/apache2/mods-enabled/mpm_{{ mpm_type }}.load
  - watch_in:
    - service: apache_service

{%- endif %}

{%- endfor %}

{%- endif %}
