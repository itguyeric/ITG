postfix_install:
  pkg.installed:
    - name: postfix

postfix_service:
  service:
    - name: postfix
    - running
    - enable: True
    - require:
      - pkg: postfix_install
