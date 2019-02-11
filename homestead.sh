#!/bin/bash

action=$1
domain=$2
folderName=$3
type=$4

if [[ "$action" != 'create' ]] && [[ "$action" != 'destroy' ]]; then
    echo "\e[31mPlease specify an action (create or destroy). Lower-case only"
    exit 1;
fi

result=`echo $domain | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`
if [[ -z "$result" ]]; then
    echo -e "\e[31mInvalid domain. Try \"$domain.test\""
    exit 1
fi

if [[ $# -eq 2 ]]; then
    folderName="${domain%%[.]*}"
fi

rootFolder="/home/vagrant/projects/$folderName"
user="$(who | awk '{print $1}')"
localFolder="/home/$user/workspace/www/homestead/$folderName"
homesteadIp="192.168.10.10"
hostsFile="/etc/hosts"
hostsEntry="$homesteadIp $domain"
homesteadRoot="/home/$user/workspace/Homestead"
homesteadConfigFile="$homesteadRoot/Homestead.yaml"

indent1="  "
indent2="$indent1$indent1"

if [[ "$action" == 'create' ]]; then

    if [ "$(whoami)" != "root" ]; then
        echo -e "\e[31mPlease run this command with 'sudo' or run as root"
        exit 1
    fi

    if (( ! $(grep -c "$hostsEntry" $hostsFile) )); then
        echo -e "\e[32mAdding entry to $hostsFile"
        echo $hostsEntry >> $hostsFile
    else
        echo -e "\e[33m'$hostsEntry' is already in $hostsFile. Skipping"
    fi

    if [[ ! -d "$localFolder" ]]; then
        echo -e "\e[32mCreating folder \"$localFolder\""
        su -c "mkdir -p $localFolder" $user

        indexFile="$localFolder/index.html"
        echo "Creating file \"$indexFile\""
        su -c "echo '<!DOCTYPE html>
<html>
    <head>
        <title>Index</title>
    </head>
    <body>
        <h1 style=\"text-align: center\">Build something great!</h1>
    </body>
</html>' >> $indexFile" $user
    fi

    if [[ -z "$type" ]]; then
        webserverType=""
    else
        webserverType="\n\r $indent2 type: $type"
    fi

    if (( ! $(grep -c "$domain" $homesteadConfigFile) )); then
        echo -e "\e[32mAdding entry to $homesteadConfigFile"
    	sed -i "/sites:/a \ $indent1 - map: $domain \n\r $indent2 to: $rootFolder$webserverType" $homesteadConfigFile
    else
    	echo -e "\e[33m'$domain' is already in $homesteadConfigFile. Skipping"
    fi

    echo -e "\e[33m\e[1mReloading and re-provisioning Homestead. \n\rGo grab a cup of tea, because this may take a while\e[39m"
    su -c "cd $homesteadRoot && vagrant reload --provision" $user

    echo -e "\e[32m\e[1mAll done. Site now live at http://$domain \n\rNow you go make things happen!\e[39m"
    exit 0
else
    # check whether domain already exists
    if (( ! $(grep -c "$hostsEntry" $hostsFile) )); then
        echo -e $"This domain does not exist."
        exit;
    else
        # Delete domain in /etc/hosts
        echo -e "\e[32mRemoving entry from $hostsFile"
        newhost=${domain//./\\.}
        sed -i "/$newhost/d" $hostsFile

        echo -e "\e[32mRemoving entry from $homesteadConfigFile"
        # I'm sure there's a much better way to do this but what is happening here is
        # We first assume that the type option is set for the block 
        sed -i "/- map:/{:a;N;/type:/!ba};/$domain/d" $homesteadConfigFile
        # If I can still find the domain in the homestead config file
        # that means the last command did not work
        # So, the type option was not set for the block
        if (( $(grep -c $domain $homesteadConfigFile) )); then
            sed -i "/- map:/{:a;N;/to:/!ba};/$domain/d" $homesteadConfigFile
        fi
        # Regex breakdown:
        # /- map:/ { # Match '- map:'
        # :a             # Create label a
        # N              # Read next line into pattern space
        # /to:/!    # If not matching 'to:'...
        #            ba  # Then goto a
        # }              # End /- map:/ block
        # /$domain/d     # If pattern space matched '$domain' then delete it.
    fi

    # check if directory exists or not
    if [ -d $localFolder ]; then
        echo -e $"Delete host root directory? (y/n)"
        read deldir

        if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
            # Delete the directory
            rm -rf $localFolder
            echo -e $"Directory deleted"
        else
            echo -e $"Host directory reserved"
        fi
    else
        echo -e $"Host directory not found. Ignored"
    fi

    # show the finished message
    echo -e $"All done!\n$domain removed"
    exit 0;
fi