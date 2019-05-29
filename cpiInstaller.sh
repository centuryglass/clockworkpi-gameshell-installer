#!/bin/bash
# Adds a program to the Clockworkpi Gameshell menu. This script manages
# application file directories, display info, and custom keybindings.
# 
# As an example, the script is currently set up to install and configure mupdf
# in the 'Utils' category, loading .pdf, .epub, and .xps files from
# /home/cpi/Documents/Books/*
############################### License: ######################################
# Copyright (C) 2019 Anthony Brown
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

######################### Installation Options: ################################
# Update these values for whatever application you want to install.

# Application display name:
appName=Reader

# Command used to launch the application:
launchCommand=mupdf

# Menu directory where the application will be installed:
appDir="$HOME/apps/Menu/60_Utils/$appName"

# If using an existing file as an icon, define the path here:
iconPath="" 

# If downloading an icon from a URL instead, define it here:
iconURL="https://publicdomainvectors.org/photos/great-tome.png"

# Define all required debian packages here:
pkgList=('mupdf' 'xmodmap')

# Set to 1 if using a SNES-style button layout, 0 for Xbox-style:
useSnesKeys=1

### Application File Directory: ###
# Only define these values if the application should be launched to open
# specific files.

# Path to the directory where the application's files are stored:
appFileDir="$HOME/Documents/PDF"

# All file extensions supported by the application, seperated with commas:
appExtensions="pdf,epub,xps"

# Title to use for the application file list:
appFileListTitle="PDF Documents"

# Optional path to a file needed to run the application, e.g. a RetroArch core:
requiredFilePath=""

# Optional URL where that file could be downloaded:
requiredFileURL=""

################# Gameshell default keyboard mappings: #########################
# Lists the X11 hexadecimal keycodes used by each Gameshell button.
# Don't forget to update these values if you reprogram the keypad module.
################################################################################
keyUp='0x6f'          # up arrow key
keyDown='0x74'        # down arrow key
keyLeft='0x71'        # left arrow key
keyRight='0x72'       # right arrow key
if [ "$useSnesKeys" ]; then
    keyY='0x1e'       # 'u'
    keyX='0x1f'       # 'i'
    keyB='0x2c'       # 'j'
    keyA='0x2d'       # 'k'
    keyShiftY='0x1d'  # 'y'
    keyShiftX='0x20'  # 'o'
    keyShiftB='0x2b'  # 'h'
    keyShiftA='0x21'  # 'l'
else #XBox-style keys:
    keyX='0x1e'       # 'u'
    keyY='0x1f'       # 'i'
    keyA='0x2c'       # 'j'
    keyB='0x2d'       # 'k'
    keyShiftX='0x1d'  # 'y'
    keyShiftY='0x20'  # 'o'
    keyShiftA='0x2b'  # 'h'
    keyShiftB='0x21'  # 'l'
fi
keyStart='0x24'       # Enter
keySelect='0x41'      # Space
keyMenu='0x9'         # Escape
keyL1='0x2b'          # 'h'
keyL2='0x1d'          # 'y'
keyL4='0x20'          # 'o'
keyL5='0x2e'          # 'l'
keyShiftStart='0x86'  # '+'
keyShiftSelect='0x52' # '-'
keyShiftMenu='0x16'   # Backspace
keyShiftL1='0x6e'     # Home
keyShiftL2='0x70'     # PgUp
keyShiftL4='0x75'     # PgDown
keyShiftL5='0x73'     # End


################## Custom Application Key Bindings: ############################
# Defines all remapped keys, formatted as "OldKey = Newkey" strings.
# Edit this array to suit your application's keybindings.
#
# Double letter bindings:
# If you assign "$keyX = H" with xModMap, it assumes you want the 'h' key with
# normal modifier behavior, e.g. typing $keyX prints 'h' normally and 'H' with
# shift held down. Using "$keyX = H H" makes it explicitly clear that you really
# do want it to print 'H' even without shift held down.
################################################################################
remappedKeys=(
    # If not remapped, left/right change page in mupdf:
    "$keyLeft = h"         # Scroll left
    "$keyRight = l"        # Scroll right

    # page navigation:
    "$keyX = BackSpace"    # Move one screen up
    "$keyShiftX = comma"   # Previous page (bottom)
    "$keyB = space"        # Move one screen down
    "$keyShiftB = period"  # Next page (top)

    "$keyMenu = q"         # Quit
    "$keyShiftMenu = r"    # Reload the page
    "$keyStart = m"        # Mark your current page
    "$keySelect = t"       # Go back to the last marked page
    "$keyY = Z Z"          # Fit page to display width/height as appropriate
    "$keyShiftY = W W"     # Fit page to display width
    "$keyA = i"            # Invert colors
    "$keyShiftA = H H"     # Fit page to display height
    "$keyShiftL1 = Return" # Go to first page
    "$keyShiftL2 = L L"    # Rotate page left
    "$keyShiftL4 = R R"    # Rotate page right
    "$keyShiftL5 = G G"    # Go to last page
)

# Unchanged keys:
# Up and down already scroll up and down in the pages.
# - and + (shift+select, shift+start) already zoom in and out.

# Find and replace regex matches in a file:
function perlReplace {
    # $1 = file, $2 = pattern
    perl -0777 -pi -w -e "$2" "$1"
}

# Ensures that a directory exists, creating it and each parent directory
# if necessary. Exit with an error message if directory creation fails.
function dirInit {
    fullPath=$1
    innerPath=""
    while [ "$innerPath" != "$fullPath" ]
    do
        innerPath=`echo "$fullPath" | grep -Po "^$innerPath.+?(?:/|$)"`
        if [ ! -d "$innerPath" ]; then
            mkdir "$innerPath"
            if [ ! -d "$innerPath" ]; then
                echo "Error: failed to create directory \"$innerPath\""
                exit 1
            fi
        fi
    done
}

############################ Installation Process: #############################

### 1. Check for existing install: ###
if [ -d "$appDir" ]; then
    echo "Directory '$appDir' already exists, remove and replace it?(y/n)"
    read replaceDir
    if [ "$replaceDir" == "y" ]; then
        echo "Replacing existing directory for $appName."
        rm -r "$appDir"
        mkdir "$appDir"
    else
        echo "Cancelling installation of $appName."
        exit 0
    fi
else
    echo "Creating installation directory '$appDir':"
    dirInit "$appDir"
fi

### 2. Get icon: ###
# Copy an icon from another path or from the internet, or just use the default.

# find image file extension:
if [ ! -z $iconPath ]; then
    if [ ! -f $iconPath ]; then
        echo "Icon path '$iconPath' is invalid, ignoring it."
        iconPath=""
    else
        iconExtension="${iconPath##*.}"
        if [[ $iconExtension == *"/"* ]]; then
            echo "Icon path '$iconPath' has no valid file extension, ignoring it"
            iconPath=""
            iconExtension=""
        fi
    fi
fi
if [ -z $iconExtension ] && [ ! -z $iconURL ]; then
    iconExtension="${iconURL##*.}"
    if [[ $iconExtension == *"/"* ]]; then
        echo "Icon URL '$iconPath' has no valid file extension, ignoring it"
        iconURL=""
        iconExtension=""
    fi
fi
if [ ! -z $iconExtension ]; then
    iconFile="$appName.$iconExtension"
    echo "Creating icon file $iconFile"
fi
# download or copy icon image file:
if [ ! -z $iconFile ]; then
    if [ ! -z $iconPath ]; then
        echo "Copying icon from '$iconPath'"
        cp "$iconPath" "$appDir/$iconFile"
    elif [ ! -z $iconURL ]; then
        echo "Downloading icon from '$iconURL'"
        wget "$iconURL" -O "$appDir/$iconFile" 
        if [ ! -f "$appDir/$iconFile" ]; then
            echo "Download failed, using default icon."
        fi
    else
        echo "Icon URL and path both failed."
    fi
else
    echo "No icon provided, using default icon."
fi

### 3. Save keybindings to a file: ###
# Keymaps will be loaded by xmodmap when the application launches, and reset
# when the application closes.

for mapping in "${remappedKeys[@]}"
do
    echo "keycode $mapping" >> "$appDir/keymaps"
done

### 4. Ensure required packages are installed: ###
for pkgName in "${pkgList[@]}"
do
    # For each package, either it must be installed, or a command with
    # the same name must exist:
    if [ ! "`dpkg -s "$pkgName"`" ] && [ ! "`command -v "$pkgName"`" ]; then
        echo "Installing required package \"$pkgName\":"
        sudo apt-get install $pkgName
        if [ ! `dpkg -s "$pkgName"` ]; then
            echo "Error: failed to install required package $pkgName."
            exit 1
        fi
    fi
done

### 5. Create launch script: ###
# Create launch script by copying this script, cutting everything but the launch
# script template, and filling in variables.

launchScript="$appDir/$appName.sh"
cp "$0" "$launchScript"
perlReplace $launchScript 's/^.*#LAUNCH_SCRIPT_START\s*//s'
perlReplace $launchScript 's/\s*#LAUNCH_SCRIPT_END.*?$//s'
perlReplace $launchScript "s/APPNAME/$appName/gs"
perlReplace $launchScript "s/LAUNCH_COMMAND/$launchCommand/gs"
if [ ! -f "$launchScript" ]; then
    echo "Error: failed to create launch script \"$launchScript\""
    exit 1
fi

### 6. Configure file directory: ###
# If the application should be launched with specific file types, set up the
# file directory:
if [ ! -z "$appFileDir" ]; then
    dirInit "$appFileDir"
    echo "Creating action.config file"
    actionConfig="$appDir/action.config"
    echo "ROM=$appFileDir" >> "$actionConfig"
    if [ ! -z "$requiredFilePath" ]; then
        echo "ROM_SO=$requiredFilePath" >> "$actionConfig"
    fi
    # Make sure the file directory exists:
    echo "EXT=$appExtensions" >> "$actionConfig"
    echo "LAUNCHER=cd $appDir && ./$appName.sh" >> "$actionConfig"
    echo "TITLE=$appFileListTitle" >> "$actionConfig"
    if [ ! -z "$requiredFileURL" ]; then
        echo "SO_URL=$requiredFileURL" >> "$actionConfig"
    fi
    if [ ! -f "$actionConfig" ]; then
        echo "Error: failed to create action.config file."
        echo "       Installation may have partially succeeded."
        exit 1
    fi
fi

echo "Finished installing '$appName', please restart the launcher."

exit 0

########################### Launch script template: ############################
#LAUNCH_SCRIPT_START
#!/bin/bash

# apply any alternate key bindings:"
if [ -f keymaps ]; then
    echo "Saving temporary keybindings to \"tempKeys\""
    # backup previous xmodmap state:
    xmodmap -pke > tempKeys
    xmodmap keymaps
fi

# Launch the application, passing on all arguments:
LAUNCH_COMMAND "$@"

# restore original keybindings when finished:
if [ -f keymaps ] && [ -f tempKeys ]; then
    echo "Restoring temporary keybindings from \"tempKeys\""
    xmodmap tempKeys
fi

#LAUNCH_SCRIPT_END
