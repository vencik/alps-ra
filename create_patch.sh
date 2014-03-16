#!/bin/sh

# Make (suggestion of) list of excluded files
for b_file in `find b`; do
    a_file=`echo "$b_file" | sed -e 's/^b/a/'`

    test -e "$a_file" || echo "$b_file" >> exclude.list$$
done

# Also add our patched Makefile to excludes
echo "b/drivers/input/mouse/Makefile" >> exclude.list$$

cat exclude.list$$
diff -uprN -X exclude.list$$ a b

rm exclude.list$$
