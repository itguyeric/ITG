ntp-install:
  pkg.installed:
    - name: ntp

ntp-config:
  file.managed:
    - name: /etc/ntp.conf
    - source: salt://ntp/files/ntp.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: ntp-install

ntp-service:
  service:
    - name: ntpd
    - running
    - enable: True
    - require:
      - file: ntp-config
    - watch:
      - file: ntp-config
