location:
  grains.present:
    {% if grains['fqdn'][2] == "q" %}
    - value: home
    {% elif grains['fqdn'][2] == "d" %}
    - value: do 
    {% endif %}

env:
  grains.present:
    {% if grains['fqdn'][8] == "p" %}
    - value: prd
    {% elif grains['fqdn'][8] == "s" %}
    - value: stg
    {% elif grains['fqdn'][8] == "q" %}
    - value: qa 
    {% elif grains['fqdn'][8] == "d" %}
    - value: dev
    {% endif %}
