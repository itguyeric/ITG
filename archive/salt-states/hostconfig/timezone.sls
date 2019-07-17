{% if grains['location'] == "home" %}
America/Chicago:
{% elif grains['location'] == "do" %}
America/Atikokan:
{% endif %}
  timezone.system
