#!/bin/sh
GAME_DIR=/home/steam/Steam/steamapps/common/VRisingDedicatedServer
SETTINGS_DIR=$GAME_DIR/VRisingServer_Data/StreamingAssets/Settings
check_req_vars() {
if [ -z "${V_RISING_NAME}" ]; then
    echo "V_RISING_NAME has to be set"

    exit
fi

if [ -z "${V_RISING_PASSW}" ]; then
    echo "V_RISING_PASSW has to be set"

    exit
fi

if [ -z "${V_RISING_SAVE_NAME}" ]; then
    echo "V_RISING_SAVE_NAME has to be set"

    exit
fi

if [ -z "${V_RISING_PUBLIC_LIST}" ]; then
    echo "V_RISING_PUBLIC_LIST has to be set"

    exit
fi
}

setServerHostSettings() {
    WRITE_DIR=$SETTINGS_DIR

    if [ -d "/saves/Settings" ]; then
        WRITE_DIR=/saves/Settings
    fi

    echo "Using env vars for ServerHostSettings"
    envsubst < /templates/ServerHostSetting.templ >> $WRITE_DIR/ServerHostSettings.json
}

setServerGameSettings() {
    WRITE_DIR=$SETTINGS_DIR

    if [ -d "/saves/Settings" ]; then
        WRITE_DIR=/saves/Settings
    fi

    echo "Using env vars for ServerGameSettings"
    envsubst < /templates/ServerGameSettings.templ >> $WRITE_DIR/ServerGameSettings.json
}

createSettingsSaves() {
    if [ ! -d "/saves/Settings" ]; then
        mkdir /saves/Settings
    fi
}

# This logic is flawed and I don't have the energy to fix this
checkGameSettings() {
    if [ ! -f "/saves/Settings/ServerGameSettings.json" ]; then
        # necessary for backwards compatabiltiy
        if [ -f "/var/settings/ServerGameSettings.json" ]; then
            createSettingsSaves
            cp /var/settings/ServerGameSettings.json /saves/Settings/ServerGameSettings.json
        else
            setServerGameSettings
        fi
    else
        echo "Using /saves/Settings/ServerGameSettings.json for settings"
    fi
}

# This logic is flawed and I don't have the energy to fix this
checkHostSettings() {
    if [ ! -f "/saves/Settings/ServerHostSettings.json" ]; then
        # necessary for backwards compatabiltiy
        if [ -f "/var/settings/ServerHostSettings.json" ]; then
            createSettingsSaves
            cp /var/settings/ServerHostSettings.json /saves/Settings/ServerHostSettings.json
            checkGameSettings
        else
            check_req_vars
            setServerHostSettings
        fi
    else
        echo "Using /saves/Settings/ServerHostSettings.json for settings"
    fi
}

if [ -d "/saves" ]; then
    checkGameSettings
    checkHostSettings
else
    setServerGameSettings
    check_req_vars
    setServerHostSettings
fi

./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +app_update 1829350 validate +quit

cd $GAME_DIR
xvfb-run -a wine ./VRisingServer.exe -persistentDataPath Z:\\saves
