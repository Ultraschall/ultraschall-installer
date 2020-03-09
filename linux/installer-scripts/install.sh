#!/bin/sh

if [ -d "$HOME/.config/REAPER" ]; then
  BACKUP_TIMESTAMP=$(date --iso-8601=seconds)
  BACKUP_FOLDER="$HOME/.config/ultraschall/backups/$BACKUP_TIMESTAMP"
  mkdir -p "$BACKUP_FOLDER"
  cp -r "$HOME/.config/REAPER" "$BACKUP_FOLDER"
fi

unzip -o ./themes/Ultraschall_4.0.ReaperConfigZip -d "$HOME/.config/REAPER"
cp -fr ./plugins/* "$HOME/.config/REAPER/UserPlugins"
cp -fr ./scripts/* "$HOME/.config/REAPER/Scripts"
