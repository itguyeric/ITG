/etc/freshclam.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - source: salt://clam/files/freshclam.conf

/usr/lib/systemd/system/freshclam.service:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - source: salt://clam/files/freshclam.service

antivirus_can_scan_system:
  selinux.boolean:
    - value: True
    - persist: True
    - require:
      - pkg: clamav

freshclam-service:
  service:
    - name: freshclam.service
    - running
    - enable: True
    - require:
      - file: /usr/lib/systemd/system/freshclam.service
    - watch:
      - file: /etc/freshclam.conf
