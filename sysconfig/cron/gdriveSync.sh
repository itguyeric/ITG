#backups

#starbound
/usr/bin/rsync -avzh /home/ehendricks/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Starbound/ /home/ehendricks/Support/games/starbound/

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
	rclone sync --create-empty-src-dirs -v ~/"$i"/ itg:"$i"/
done

#rclone sync --create-empty-src-dirs -v ~/redHat/ rhat:
