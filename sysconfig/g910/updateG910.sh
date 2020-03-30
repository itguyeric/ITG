# update g810 profile

# ensure argument provided
if [ $# -eq 0 ]; then
  echo "Please provide a valid profile name."
  exit 1
fi
# delete old link
sudo /usr/bin/rm /etc/g810-led/profile
# update link on variable
sudo /usr/bin/ln -s /home/ehendricks/git/itg/sysconfig/g910/$1 /etc/g810-led/profile
# apply new profile
/usr/bin/g810-led -p /etc/g810-led/profile
