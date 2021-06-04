#!/usr/bin/env bash

set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

if [ -d "$HOME/.config/REAPER" ]; then
  BACKUP_TIMESTAMP=$(date -u "+%Y%m%dT%H%M%S")
  BACKUP_FOLDER="$HOME/.config/ultraschall/backups/$BACKUP_TIMESTAMP"
  mkdir -p "$BACKUP_FOLDER"
  cp -r "$HOME/.config/REAPER" "$BACKUP_FOLDER"
  if [ $? -eq 0 ]; then
    echo "Your current REAPER configuration has been saved to $BACKUP_FOLDER."
  fi
else
  echo "Please open REAPER first to set it up, then run this installer again."
fi

echo "Installing the Ultraschall REAPER Theme..."
tar xf ./themes/ultraschall-theme.tar -C "$HOME/.config/REAPER"
echo "Done."

echo "Installing the Ultraschall REAPER Plug-ins..."
cp -fr ./plugins/* "$HOME/.config/REAPER/UserPlugins"
echo "Done."

echo "Installing the Ultraschall StudioLink plugin..."
mkdir -p "$HOME/.lv2"
rm -rf "$HOME/.lv2/studio-link.lv2"
cp -fr ./custom-plugins/studio-link.lv2 "$HOME/.lv2"
echo "Done."

echo "Installing the Ultraschall StudioLink OnAir plugin..."
mkdir -p "$HOME/.lv2"
rm -rf "$HOME/.lv2/studio-link-onair.lv2"
cp -fr ./custom-plugins/studio-link-onair.lv2 "$HOME/.lv2"
echo "Done."


echo "Installing the Ultraschall Soundboard plugin..."
mkdir -p "$HOME/.vst3"
rm -rf "$HOME/.vst3/Soundboard.vst3"
cp -fr ./custom-plugins/Soundboard.vst3 "$HOME/.vst3"
echo "Done."

echo "Installing the Ultraschall REAPER Scripts..."
cp -fr ./scripts/* "$HOME/.config/REAPER/Scripts"
echo "Done."

trap - DEBUG
trap - EXIT
