#!/bin/sh

if [ -d "$HOME/.config/REAPER" ]; then
  BACKUP_TIMESTAMP=$(date --iso-8601=seconds)
  BACKUP_FOLDER="$HOME/.config/ultraschall/backups/$BACKUP_TIMESTAMP"
  mkdir -p "$BACKUP_FOLDER"
  cp -r "$HOME/.config/REAPER" "$BACKUP_FOLDER"
fi

cp -fr ./plugins/* "$HOME/.config/REAPER/UserPlugins"
cp -fr ./scripts/* "$HOME/.config/REAPER/Scripts"
gzip -df ./themes/Ultraschall_4.0.ReaperConfigZip "$HOME/.config/REAPER"
