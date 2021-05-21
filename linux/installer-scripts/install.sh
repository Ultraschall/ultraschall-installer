#!/bin/sh

if [ -d "$HOME/.config/REAPER" ]; then
  BACKUP_TIMESTAMP=$(date -u "+%Y%m%dT%H%M%S")
  BACKUP_FOLDER="$HOME/.config/ultraschall/backups/$BACKUP_TIMESTAMP"
  mkdir -p "$BACKUP_FOLDER"
  cp -r "$HOME/.config/REAPER" "$BACKUP_FOLDER"
  if [ $? -eq 0 ]; then
    echo "Your current REAPER configuration has been saved to $BACKUP_FOLDER."
  else
    echo "Failed to backup your current REAPER configuration. Aborting installation..."
    exit -1
  fi
fi

echo "Installing the Ultraschall REAPER Theme..."
tar xf ./themes/ultraschall-theme.tar -C "$HOME/.config/REAPER"
if [ $? -eq 0 ]; then
    echo "Done."
    echo "Installing the Ultraschall REAPER Plug-ins..."
    cp -fr ./plugins/* "$HOME/.config/REAPER/UserPlugins"
    if [ $? -eq 0 ]; then
      echo "Done."
      echo "Installing the Ultraschall REAPER Scripts..."
      cp -fr ./scripts/* "$HOME/.config/REAPER/Scripts"
      if [ $? -eq 0 ]; then
        echo "Done."
        exit 0
      fi
    fi
  fi
fi

if [ $? -ne 0 ]; then
  echo "Failed to install Ultraschall."
  exit -1
fi
