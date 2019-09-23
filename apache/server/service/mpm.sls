{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if grains.os_family == 'Debian' %}

{%- for mpm_type, mpm in server.mpm.iteritems() %}

{%- if mpm_type == server.get('default_mpm', 'prefork') %}

apache_mpm_{{ mpm_type }}_enable:
  cmd.run:
  - name: "a2enmod mpm_{{ mpm_type }}"
  - creates: /etc/apache2/mods-enabled/mpm_{{ mpm_type }}.load
  - require:
    - file: apache_mpm_{{ mpm_type }}_config
    {%- for mpm_name, dummy in server.mpm.iteritems() if mpm_name != mpm_type %}
    - file: apache_mpm_{{ mpm_name }}_disable
    {%- endfor %}
  - watch_in:
    - service: apache_service

apache_mpm_{{ mpm_type }}_config:
  file.managed:
  - name: /etc/apache2/mods-available/mpm_{{ mpm_type }}.conf
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

apache_mpm_{{ mpm_type }}_conf_disable:
  file.absent:
  - name: /etc/apache2/mods-enabled/mpm_{{ mpm_type }}.conf
  - watch_in:
    - service: apache_service

{%- endif %}

{%- endfor %}

{%- endif %}

{%- endif %}
