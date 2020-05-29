#backups

#starbound
#/usr/bin/rsync -avzh /home/ehendricks/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Starbound/ /home/ehendricks/Support/games/starbound/

dirs=(
	Desktop
	Documents
	Downloads
	Music
	Public
	Support
	Templates
	Videos
)

for i in "${dirs[@]}"; do
	rsync -auzhn  /home/ehendricks/"$1"/ jarvis:/home/ehendricks/"$i"/
done
