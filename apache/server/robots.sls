{%- from "apache/map.jinja" import server with context %}
{%- if server.enabled %}

{%- for name, robots in server.get('robots', {}).iteritems() %}
robots_{{ name }}:
  file.managed:
    - name: {{ server.www_dir }}/robots_{{ name }}.txt
    - template: jinja
    - source: salt://apache/files/robots.txt
    - defaults:
        robots_name: "{{ name }}"
{%- endfor %}

{%- endif %}
