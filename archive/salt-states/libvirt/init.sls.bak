libvirt:
  pkg.installed: []
  file.managed:
    - name: /etc/sysconfig/libvirtd
    - contents: 'libvirtd_args="--listent"'
    - require:
      -pkg: libvirt
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt
      - network: virbr0
      - libvirt: libvirt
    - watch:
      - file: libvirt

libvirt-python:
  pkg.installed: []

libvirt-guestfs:
  pkg.installed:
    - pkgs:
      - libguestfs
      - libguestfs-tools

libvirt.keys:
  virt.keys
