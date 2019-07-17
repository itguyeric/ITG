#hosts:
  #  file.managed:
    #  - name: /etc/hosts
    #- source: salt://hostconfig/files/hosts.jinja
    #- user: root
    #- group: root
    #- mode: 644
    #- template: jinja
  #- context:
    #    host: {{ grains['host'] }}
    #   local_ip_address: {{ grains['ipv4'][0] }}
    #   local_host_name: {{ grains['fqdn'] }}
