include:
  - clam.freshclam

clamav:
  pkg.installed:
    - pkgs:
      - clamav
      - clamav-devel
      - clamav-filesystem
      - clamav-lib
      - clamav-scanner-systemd
      #- clamav-server  #Not sure why, but this caused the state to fail
      - clamav-server-systemd
      - clamav-update

/etc/clamd.d/clamd.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - source: salt://clam/files/clamd.conf
    - require:
      - pkg: clamav

/usr/lib/systemd/system/clamd@.service:
  file.absent:
    - require:
      - pkg: clamav

/usr/lib/systemd/system/clamd@scan.service:
  file.absent:
    - require:
      - pkg: clamav

/usr/lib/systemd/system/clamd.service:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - source: salt://clam/files/clamd.service
    - require:
      - pkg: clamav

/usr/lib/systemd/system/clamd-scan.service:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - source: salt://clam/files/clamd.service
    - require:
      - pkg: clamav

clamd-service:
  service:
    - name: clamd.service
    - running
    - enable: True
    - require:
      - file: /usr/lib/systemd/system/clamd.service
    - watch:
      - file: /etc/clamd.d/clamd.conf

clamd_scan-service:
  service:
    - name: clamd-scan.service
    - running
    - enable: True
    - require:
      - file: /usr/lib/systemd/system/clamd-scan.service
    - watch:
      - file: /etc/clamd.d/clamd.conf
