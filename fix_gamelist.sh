#!/bin/bash
# Author - RobotJohnny
# Desc - This script is designed to rename games in gamelist.xml that are duplicates thanks to the gamesdb scraper. 
# It simply names them to their filename without the extension.

# check user input
user_input=$1
while [ -z "$user_input" ]; do
        echo "please enter the name of the system you want to fix the game list for"
        echo "(as it is labelled in /home/pi/RetroPie/roms)"
        read -r user_input
done

# ensure a console with that name exists
ls "/home/pi/RetroPie/roms/$user_input" >/dev/null 2>&1
if  [ "$?" -ne 0 ]; then
        echo "this doesn't appear to be a system installed here. exiting."
        exit 1
fi

# pull a list of duplicate games from the respective console's gamelist.xml
games_to_fix()
{
        IFS=$'\n'
        console=$1
        filepath="/opt/retropie/configs/all/emulationstation/gamelists/$console/gamelist.xml"
        game_array=($(fgrep "<name>" "$filepath" | sort | uniq -c | sort -rn | awk  '$1 > 1 {print $0}'| cut -d ">" -f 2 | cut -d "<" -f 1))
        number_to_fix=($(fgrep "<name>" "$filepath" | sort | uniq -c | sort -rn | awk  '$1 > 1 {print $1}'))
        if [ "${#game_array[@]}" = 0 ]; then
                echo "no games for $console to fix!"
        fi
}

# get the name to replace it with which is just the filename without the extension
get_new_name()
{
        mYpath=$1
        new_name=$(echo $mYpath | cut -d ">" -f 2 | cut -d "<" -f 1 \
        | sed -e 's/\.\///g' | sed -e 's/\.7z//g' | sed -e 's/\.z64//g' \
        | sed -e 's/\.zip//g' | sed -e 's/\.pbp//g' | sed -e 's/\.cue//g' \
        | sed -e 's/\.n64//g' | sed -e 's/\.PBP//g' | sed -e 's/\.gba//g' \
        | sed -e 's/\.rp//g')
}

# do the work
games_to_fix $user_input

IFS=$'\n'
index=0
for i in ${number_to_fix[@]}; do
        loop=1
        for game in "${game_array[@]:$index:$i}"; do
                echo "fixing $game"
                line_number=$(fgrep -n "<name>$game</name>"  $filepath | awk '{print $1}' | cut -d : -f 1 | tr -d ':' | sed -e "${loop}q;d")
                path_line_number=$(expr $line_number - 1 )
                path=$(sed "${path_line_number}q;d" $filepath | cut -d : -f 2)
                get_new_name "$path"
                sed -i "${line_number}s/$game/$new_name/g" $filepath
                ((loop++))
        done
        index=$(expr $index + $i);
done
