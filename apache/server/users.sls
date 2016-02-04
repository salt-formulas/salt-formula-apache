{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- for user_name, user in server.get('user', {}).iteritems() %}
{%- if user.enabled %}

apache_setup_user_{{ user_name }}:
  webutil.user_exists:
  - name: {{ user_name }}
  {%- if user.htpasswd is defined %}
  - htpasswd_file: {{ server.htpasswd_dir }}/{{ user.htpasswd }}
  {%- else %}
  - htpasswd_file: {{ server.htpasswd_dir }}/htpasswd
  {%- endif %}
  - password: {{ user.password }}
  {%- if user.opts is defined %}
  - options: '{{ user.opts }}'
  {%- endif %}
  - require:
    - pkg: apache_packages

{%- else %}

apache_setup_user_{{ user_name }}_absent:
  module.run:
  - name: htpasswd.userdel
  - user: {{ user_name }}
  {%- if user.htpasswd is defined %}
  - pwfile: /etc/apache/{{ user.htpasswd }}
  {%- else %}
  - pwfile: {{ server.htpasswd_dir }}/htpasswd
  {%- endif %}
  - require:
    - pkg: apache_packages

{%- endif %}
{%- endfor %}

{%- endif %}
