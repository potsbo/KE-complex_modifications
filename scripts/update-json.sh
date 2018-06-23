#!/bin/bash

for srcfile in src/json/*.json.*; do
  extension="${srcfile##*.}"

  dstfile="docs/json/`basename $srcfile .$extension`"
  if [ "$srcfile" -nt "$dstfile" ]; then
    failed=0

    if [ $extension = 'erb' ]; then
      if scripts/erb2json.rb < "$srcfile" > "$dstfile"; then
        if scripts/lint.rb < "$dstfile"; then
          echo "$dstfile"
          failed=1
        fi
      fi
    fi

    if [ $extension = 'rb' ]; then
      if ruby "$srcfile" > "$dstfile"; then
        if scripts/lint.rb < "$dstfile"; then
          echo "$dstfile"
          failed=1
        fi
      fi
    fi

    if [ $failed -eq 0 ]; then
      rm -f "$dstfile"
      exit 1
    fi
  fi
done
