#!/bin/sh

usage() {
    cat >&2 <<HERE
Usage: $0 linux-source-package

HERE
}

quit() {
    exit_code=$1

    shift

    test $# -gt 0 && echo "$*" >&2

    test -n "$exit_code" || exit_code=0

    exit $exit_code
}

usage_and_quit() {
    usage

    quit $1
}


# Do not overwrite existing code by mistake
if test -d ./a -o -d ./b; then
    cat >&2 <<HERE
Source in ./a and/or ./b already exists.
If you're sure you want to overwrite it, remove the directories
yourself and run the script again.

HERE

    quit 1
fi


# Environment settings
pkg="$1"

test -f "$pkg" || usage_and_quit 1

base_dir=`basename "$pkg" | sed -e 's/\.tar\..*$//'`


# Unpack source
mkdir ./a

tar -xJf "$pkg" --strip-components=1 -C ./a \
    "$base_dir/drivers/input/mouse" \
    "$base_dir/Documentation/input/alps.txt" \
|| quit 2 "$pkg doesn't appear to be linux source package"

# Create working copy
cp -r ./a ./b

# Backup Makefile
cp ./b/drivers/input/mouse/Makefile ./b/drivers/input/mouse/Makefile.bak

# Create out-of-tree Makefile
cat ./Makefile.ra >> ./b/drivers/input/mouse/Makefile
cp ./Makefile.config ./b/drivers/input/mouse/

# Install helpers
ln -s ../../../../alps_ra_hook.c      ./b/drivers/input/mouse/
ln -s ../../../../set_alps_ra_hook.sh ./b/drivers/input/mouse/
ln -s ../../../../show_pkt.pl         ./b/drivers/input/mouse/

cat >&2 <<HERE
Source unpacked to directories ./a and ./b.
In ./b, the psmouse driver Makefile was adapted
to enable off-tree compilation of the driver.

HERE
