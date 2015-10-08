{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if server.site is defined %}
{%- for site_name, site in server.site.iteritems() %}

{% if site.enabled %}

{{ server.vhost_dir }}/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}:
  file.managed:
  {%- if site.type in ['proxy', 'redirect', 'static', 'stats'] %}
  - source: salt://apache/files/{{ site.type }}.conf
  {%- else %}
  - source: salt://{{ site.type }}/files/apache.conf
  {%- endif %}
  - template: jinja
  - defaults:
    site_name: "{{ site_name }}"
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service

{%- if site.get('ssl', {'enabled': False}).enabled %}

/etc/ssl/certs/{{ site.host.name }}.crt:
  file.managed:
  {%- if site.ssl.cert is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:cert
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/certs/{{ site.host.name }}.cert.pem
  {%- endif %}
  - require:
    - pkg: apache_packages

/etc/ssl/private/{{ site.host.name }}.key:
  file.managed:
  {%- if site.ssl.key is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:key
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/certs/{{ site.host.name }}.key.pem
  {%- endif %}
  - require:
    - pkg: apache_packages

/etc/ssl/certs/ca-chain.crt:
  file.managed:
  {%- if site.ssl.chain is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:chain
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/{{ site.ssl.authority }}-chain.cert.pem
  {%- endif %}
  - require:
    - pkg: apache_packages

{%- endif %}

{%- if grains.os_family == "Debian" %}

/etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}:
  file.symlink:
  - target: {{ server.vhost_dir }}/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
  - require:
    - file: {{ server.vhost_dir }}/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
  - watch_in:
    - service: apache_service

/etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}:
  file.absent

{%- endif %}

{%- if site.type == "static" %}

{%- if site.source is defined %}

{{ site.name }}_dir:
  file.directory:
  - name: /srv/static/sites/{{ site.name }}
  - makedirs: true

{%- if site.source.engine == 'git' %}

{{ site.source.address }}:
  git.latest:
  - target: /srv/static/sites/{{ site.name }}
  - rev: {{ site.source.revision }}
  - require:
    - file: {{ site.name }}_dir

{%- endif %}

{%- endif %}

{%- endif %}

{%- else %}

{{ server.vhost_dir }}/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}:
  file.absent

{%- if grains.os_family == "Debian" %}

/etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}:
  file.absent

{%- endif %}

{%- endif %}

{%- endfor %}
{%- endif %}

{%- endif %}
