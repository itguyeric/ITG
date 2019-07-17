libvirt:
  pkgrepo.managed:
    - humanname: libvirt-latest
    - baseurl: http://mirror.centos.org/centos/7/virt/x86_64/libvirt-latest/
    - gpgcheck: 0
    - require_in:
      - pkg: libvirt_install

libvirt_install:
  pkg.installed:
    - pkgs:
      - qemu-kvm
      - libguestfs
      - libguestfs-tools
      - libvirt-python
      - nbd
      - qemu-img

libvirt_daemon:
  service.running:
    - name: libvirtd
    - require:
      - pkg: libvirt_install

libvirt.keys:
  virt.keys

### To Fix
# nbd kernel module
#   - Meantime use losetup
