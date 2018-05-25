{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if server.site is defined %}
{%- set ssl_certificates = {} %}

{%- for site_name, site in server.site.iteritems() %}

{% if site.enabled or site.get('available', False) %}

  {%- if site.get('ssl', {'enabled': False}).enabled %}
    {%- if site.ssl.get('dhparam', {'enabled': False}).enabled %}
apache_generate_{{ site_name }}_dhparams:
  cmd.run:
  - name: openssl dhparam -out /etc/ssl/dhparams_apache_{{ site_name }}.pem {% if site.ssl.dhparam.numbits is defined %}{{ site.ssl.dhparam.numbits }}{% else %}2048{% endif %}
  - unless: "test -f /etc/ssl/dhparams_apache_{{ site_name }}.pem && [ $(openssl dhparam -inform PEM -in /etc/ssl/dhparams_apache_{{ site_name }}.pem -check -text | grep -Po 'DH Parameters: \\(\\K[0-9]+') = {% if site.ssl.dhparam.numbits is defined %}{{ site.ssl.dhparam.numbits }}{% else %}2048{% endif %} ]"
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service
    {% endif %}

    {%- if site.ssl.get('ticket_key', {'enabled': False}).enabled %}
apache_generate_{{ site_name }}_ticket_key:
  cmd.run:
  - name: openssl rand {% if site.ssl.ticket_key.numbytes is defined %}{{ site.ssl.ticket_key.numbytes }}{% else %}48{% endif %} > /etc/ssl/ticket_apache_{{ site_name }}.key
  - unless: "test -f /etc/ssl/ticket_apache_{{ site_name }}.key && [ $(wc -c < /etc/ssl/ticket_apache_{{ site_name }}.key) = {% if site.ssl.ticket_key.numbytes is defined %}{{ site.ssl.ticket_key.numbytes }}{% else %}48{% endif %} ]"
  - require:
    - pkg: apache_packages
  - watch_in:
    - service: apache_service
    {% endif %}
  {% endif %}

{{ server.vhost_dir }}/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}:
  file.managed:
  {%- if site.type in ['proxy', 'redirect', 'static', 'stats', 'wsgi' ] %}
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

{%- if site.get('webdav', {}).get('enabled', False) %}
{{ site.name }}_webdav_dir:
  file.directory:
  - name: {{ site.root }}
  - user: {{ server.service_user }}
  - group: {{ server.service_group }}
  - makedirs: true
{%- endif %}

{%- for location in site.get('locations', []) %}
{%- if location.get('webdav', {}).get('enabled', False) %}
{{ site.name }}_webdav_{{ location.uri }}_dir:
  file.directory:
  - name: {{ location.path }}
  - user: {{ server.service_user }}
  - group: {{ server.service_group }}
  - makedirs: true
{%- endif %}
{%- endfor %}

{%- if site.get('ssl', {'enabled': False}).enabled and site.host.name not in ssl_certificates.keys() %}
  {%- if 'key_file' not in site.get('ssl') %}
{%- set _dummy = ssl_certificates.update({site.host.name: []}) %}

/etc/ssl/certs/{{ site.host.name }}.crt:
  file.managed:
  {%- if site.ssl.cert is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:ssl:cert
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/certs/{{ site.host.name }}.cert.pem
  {%- endif %}
  - require:
    - pkg: apache_packages
  {%- if site.enabled %}
  - require_in:
    - file: /etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
  {%- endif %}

/etc/ssl/private/{{ site.host.name }}.key:
  file.managed:
  {%- if site.ssl.key is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:ssl:key
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/certs/{{ site.host.name }}.key.pem
  {%- endif %}
  - require:
    - pkg: apache_packages
  {%- if site.enabled %}
  - require_in:
    - file: /etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
  {%- endif %}

/etc/ssl/certs/{{ site.host.name }}-ca-chain.crt:
  file.managed:
  {%- if site.ssl.chain is defined %}
  - contents_pillar: apache:server:site:{{ site_name }}:ssl:chain
  {%- else %}
  - source: salt://pki/{{ site.ssl.authority }}/{{ site.ssl.authority }}-chain.cert.pem
  {%- endif %}
  - require:
    - pkg: apache_packages
  {%- if site.enabled %}
  - require_in:
    - file: /etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
  {%- endif %}

  {%- else %}
    {%- set certs_files = [ site.ssl.key_file, site.ssl.cert_file] %}
    {%- if site.ssl.chain_file is defined %}
      {%- do certs_files.append(site.ssl.chain_file) %}
    {%- endif %}
{{ site.name }}_certs_files_exist:
  file.exists:
    - names: {{ certs_files }}
    {%- if site.enabled %}
    - require_in:
      - file: /etc/apache2/sites-enabled/{{ site.type }}_{{ site.name }}{{ server.conf_ext }}
    {%- endif %}
{%- endif %}

{%- endif %}

{%- if grains.os_family == "Debian" %}

{%- if site.enabled %}

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
