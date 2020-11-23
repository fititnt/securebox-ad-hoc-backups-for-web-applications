#!/bin/sh
#===============================================================================
#
#          FILE:  securebox-termux-full-setup.sh
#
#         USAGE:  curl https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extra/securebox-termux-full-install.sh --output ~/securebox.sh
#                 cat ~/securebox.sh
#                 sh ~/securebox.sh
#
#   DESCRIPTION:  This setup script help to get the lastest version of
#                 fititnt/securebox-ad-hoc-backups-for-web-applications
#                 running on Android phone. Uses the App Termux
#                 https://play.google.com/store/apps/details?id=com.termux
#
#       OPTIONS:  ---
#
#  REQUIREMENTS:  1. Android Phone (with access to internet and GitHub)
#                 2. Termux App (https://play.google.com/store/apps/details?id=com.termux)
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

#### How to run this script from a new installed Termux, START _________________

### [Recommended] Download, review, then (if ok) install ......................,
# 1 Download the file from your termux
#     curl https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extra/securebox-termux-full-install.sh --output ~/securebox.sh
# 2. It's a good idea inspect the file. Try vi or nano? cat works too
#     cat ~/securebox.sh
# 3. execute the file
#     sh ~/securebox.sh
# 4. If everyting works. remove the file
#     rm ~/securebox.sh

# One-liner alternative for 4 steps (not recommended) ..........................
#     sh -c "$(curl -fsSL https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extra/securebox-termux-full-install.sh)"

#### How to run this script from a new installed Termux, END ___________________
if command -v termux-setup-storage  ; then
  echo ">>> securebox-termux-full-setup.sh: OK. Detected Termux"
else
  echo ">>> securebox-termux-full-setup.sh: ERROR! This setup is mean to run o Termux"
  echo "    Aborting"
  exit 1
fi

echo ">>> securebox-termux-full-setup.sh: pkg update"
yes | pkg update -y
echo ">>> securebox-termux-full-setup.sh: pkg upgrade"
yes | pkg upgrade -y
echo ">>> securebox-termux-full-setup.sh: pkg install -y git rsync (dependencies)"
yes | pkg install -y git rsync

#### termux-setup-storage (disabled) ___________________________________________
# @see https://wiki.termux.com/wiki/Internal_and_external_storage
# @see https://wiki.termux.com/wiki/Termux-setup-storage
#  "If termux-setup-storage appears to do nothing, try rebooting your device and run the command again.""
#   "Execute termux-setup-storage (run apt update && apt upgrade to make sure that this tool is available) to ensure:"

# TODO: tecnicacly speaking, if we only use "$HOME/backups" the
#       termux-setup-storage command is not need. Review this on future
#       (fititnt, 2020-11-19 13:12 UTC)
# TODO: the next lines are commented. If need we can uncoment and allow more
#       complex setups on the future. But just using $HOME (on termux, $PREFIX)
#       can still be an alternative (fititnt, 2020-11-23 10:50 UTC)

# echo ">>> securebox-termux-full-setup.sh: termux-setup-storage"
# echo ">>> securebox-termux-full-setup.sh: Your Android will ask to allow termux access to storage"
# termux-setup-storage
# sleep 10


#### Install (master, lastest version) from GitHub _____________________________
### Download to temporary ......................................................
git clone https://github.com/fititnt/securebox-ad-hoc-backups-for-web-applications.git "$TMPDIR/securebox"

### $PREFIX/bin is on path on Termux ...........................................
cp -r "$TMPDIR/securebox/bin/" "$PREFIX/bin"

#### Directories for Securebox _________________________________________________
# @TODO: while Rocha was unable to test on external storage (he uses Adaptive
#        storage) we could also add ~/storage/external-1 instead of ~/ on
#        the search path (fititnt, 2020-11-19 13:07 UTC)

echo ">>> securebox-termux-full-setup.sh: preparing $HOME/backups"
mkdir "$HOME/backups" || echo "$HOME/backups already exists"
chmod 0700 "$HOME/backups"

echo ">>> securebox-termux-full-setup.sh: preparing $HOME/backups/tmp"
mkdir "$HOME/backups/tmp" || echo "$HOME/backups/tmp already exists"
chmod 0700 "$HOME/backups/tmp"

echo ">>> securebox-termux-full-setup.sh: preparing $HOME/backups/mirror"
mkdir "$HOME/backups/mirror" || echo "$HOME/backups/mirror already exists"
chmod 0700 "$HOME/backups/mirror"

echo ">>> securebox-termux-full-setup.sh: preparing $HOME/backups/archives"
mkdir "$HOME/backups/archives" || echo "$HOME/backups/archives already exists"
chmod 0700 "$HOME/backups/archives"

echo ">>> securebox-termux-full-setup.sh: For more information about storage, see"
echo "    https://wiki.termux.com/wiki/Internal_and_external_storage"
