#!/bin/sh

install () {
    if grep -qe '#include "alps_ra_hook\.c"' alps.c; then
        echo "ALPS driver reverse analysis hook is already installed" >&2
        return;
    fi

    mv alps.c alps.c.tmp$$

    awk '

    BEGIN {
        mode = 0;  # plain copy to output
    }

    /^static psmouse_ret_t alps_process_byte\(struct psmouse \*psmouse\)$/ {
        mode = 1;  # alps_process_byte function definition
    }

    /^\t}$/ {
        if (1 == mode)
            mode = 2;  # end of alps_process_byte PS/2 packet processing
    }

    {
        print $0;

        if (2 == mode) {
            print "#include \"alps_ra_hook.c\"";  # install RA hook

            mode = 0;
        }
    }

    ' alps.c.tmp$$ > alps.c

    rm alps.c.tmp$$

    echo "ALPS driver reverse analysis hook was installed" >&2
}

uninstall () {
    mv alps.c alps.c.tmp$$

    grep -ve '^#include "alps_ra_hook\.c"' alps.c.tmp$$ > alps.c

    rm alps.c.tmp$$

    echo "ALPS driver reverse analysis hook was uninstalled" >&2
}


case "$1" in
    "install" | "")
        install
        ;;
    "uninstall")
        uninstall
        ;;
esac
