#/bin/bash
# take a variable and build a VM

APP="$1"
SERVER=itg-prd-$APP

# create new OS disk
# clone builder image
# add Ansible sudoers and hostname
# import system

/usr/bin/qemu-img create -f qcow2 /var/lib/libvirt/images/$SERVER.qcow2 64G;
/usr/bin/virt-resize --expand /dev/sda4 /var/lib/libvirt/templates/rhel09-latest.qcow2 /var/lib/libvirt/images/$SERVER.qcow2;
/usr/bin/virt-customize -a /var/lib/libvirt/images/$SERVER.qcow2 --hostname $SERVER --upload /etc/sudoers.d/ansible:/etc/sudoers.d/ansible;
/usr/bin/virt-install --name $SERVER --memory 4096 --vcpus 2 --disk path=/var/lib/libvirt/images/$SERVER.qcow2 --import --os-variant rhel9.0 --network default --graphics vnc --noautoconsole --autostart

# ansible init
#<<<<<<< HEAD
#echo $SERVER >> ~/git/itg-ans/hosts
#sleep 15
#=======
#echo $SERVER >> ~/git/itg-ans/hosts
#sleep 15
#>>>>>>> 785b9bd4bec773cac3b5861c7116c27ab51d41ad
#cd ~/git/itg-ans && /usr/bin/ansible-playbook site.yml
#/usr/bin/ansible-playbook -u ansible --private-key ~/.ssh/id_rsa_ans -i $SERVER, /home/ehendricks/git/itg-ans/roles/common/main.yml
#/usr/bin/ansible-playbook -u ansible --private-key ~/.ssh/id_rsa_ans -i $SERVER, /home/ehendricks/git/itg-ans/roles/server/main.yml

# final system reboot
#/usr/bin/ansible -i /home/ehendricks/git/itg-ans/site.yml $SERVER -b -a "/sbin/shutdown -r now"

echo "$SERVER is standing by!"
