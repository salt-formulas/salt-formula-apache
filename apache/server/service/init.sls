{%- from "apache/map.jinja" import server with context %}

apache_server_service_task:
  test.show_notification:
    - text: "Running apache.server.service"

include:
{%- if server.modules is defined %}
- apache.server.service.modules
{%- endif %}
{%- if server.mpm is defined %}
- apache.server.service.mpm
{%- endif %}

{%- if server.enabled %}

apache_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

apache_ports_config:
  file.managed:
  - name: {{ server.conf_dir }}/ports.conf
  - source: salt://apache/files/ports.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

apache_security_config:
  file.managed:
  - name: {{ server.conf_dir }}/security.conf
  - source: salt://apache/files/security.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

  {%- if server.ssl is defined %}
    {%- if server.get('ssl', {'enabled': False}).enabled %}
apache_httpd_ssl_config:
  file.managed:
  - name: {{ server.conf_dir }}/httpd_ssl.conf
  - source: salt://apache/files/httpd_ssl.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

      {%- if grains.os_family == "Debian" %}
apache_httpd_ssl_config_enable:
  cmd.run:
  - name: "a2enconf httpd_ssl"
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service
      {%- endif %}
    {%- endif %}
  {%- endif %}

{%- if grains.os_family == "Debian" %}
/etc/apache2/conf-enabled/security.conf:
  file.symlink:
  - target: {{ server.conf_dir }}/security.conf
  - require:
    - file: {{ server.conf_dir }}/security.conf
  {% if not grains.get('noservices', False) %}
  - watch_in:
    - service: apache_service
  {% endif %}

{%   if not grains.get('noservices', False) %}
/etc/apache2/sites-enabled/000-default.conf:
  file.absent:
    - watch_in:
      - service: apache_service
{%   endif %}

{%- elif grains.os_family == "RedHat" %}
apache_httpd_config:
  file.managed:
  - name: /etc/httpd/conf/httpd.conf
  - source: salt://apache/files/httpd.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

apache_conf_d_ssl_config:
  file.managed:
  - name: /etc/httpd/conf.d/ssl.conf
  - source: salt://apache/files/redhat_ssl.conf
  - template: jinja
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

{%- endif %}

apache_service:
  service.running:
  - name: {{ server.service }}
  - reload: true
  - enable: true
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
  - require:
    - pkg: apache_packages
{%- if grains.get('noservices') %}
  - onlyif: /bin/false
{%- endif %}

{%- else %}

apache_service_dead:
  service.dead:
  - name: {{ server.service }}

apache_remove_packages:
  pkg.purged:
  - pkgs: {{ server.pkgs }}
  - require:
    - service: apache_service_dead

{%- endif %}
