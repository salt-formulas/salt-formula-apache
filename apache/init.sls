
include:
{%- if pillar.apache.server is defined %}
- apache.server
{%- endif %}
