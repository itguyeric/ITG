{% if grains.os == 'CentOS' %}
saltstack:
  pkgrepo.managed:
    - humanname: SaltStack
    - baseurl: https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/SALTSTACK-GPG-KEY.pub
{% endif %}

/etc/salt/minion.d/highstate.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0640
    - source: salt://salt/files/highstate.conf