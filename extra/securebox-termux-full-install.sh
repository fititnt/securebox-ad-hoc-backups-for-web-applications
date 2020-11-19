#!/bin/sh
#===============================================================================
#
#          FILE:  securebox-termux-full-setup.sh
#
#         USAGE:  securebox-termux-full-setup.sh
#
#   DESCRIPTION:  ---
#
#       OPTIONS:  ---
#
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Emerson Rocha <rocha[at]ieee.org>
#       COMPANY:  Etica.AI
#       LICENSE:  Public Domain / Zero-Clause BSD
#                 SPDX-License-Identifier: Unlicense OR 0BSD
#       VERSION:  1.0
#       CREATED:  2020-11-19 11:32 UTC
#      REVISION:  ---
#===============================================================================
set -e

#### How to run this script from a new installed Termux ________________________
### Download the file from your termux .........................................
# curl https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extras/securebox-termux-full-setup.sh --output ~/securebox.sh
### It's a good idea inspect the file. Try vi or nano? cat works too
# cat ~/securebox.sh
### execute the file ...........................................................
# sh ~/securebox.sh
### If everyting works. remove the file ........................................
# rm ~/securebox.sh

# One-liner alternative for 4 steps (not recommended) ..........................
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extras/securebox-termux-full-setup.sh)"

pkg upgrade
pkg upgrade -y
yes | pkg install git rsync

#### termux-setup-storage ______________________________________________________
# @see https://wiki.termux.com/wiki/Termux-setup-storage
#  "If termux-setup-storage appears to do nothing, try rebooting your device and run the command again.""
#   "Execute termux-setup-storage (run apt update && apt upgrade to make sure that this tool is available) to ensure:"
termux-setup-storage


#### Install (master, lastest version) from GitHub _____________________________
### Download to temporary ......................................................
git clone https://github.com/fititnt/securebox-ad-hoc-backups-for-web-applications.git "$TMPDIR/securebox"

### $PREFIX/bin is on path on Termux ...........................................
cp -r "$TMPDIR/securebox/bin/*" "$PREFIX/bin"