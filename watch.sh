#!/bin/bash

sigint_handler()
{
  kill $(jobs -pr)
  exit
}

trap sigint_handler SIGINT
while true; do
  rm -f /tmp/docs2web.cp.exe
  cp _build/default/bin/docs2web.exe /tmp/docs2web.cp.exe
  echo "running: /tmp/docs2web.cp.exe"
  /tmp/docs2web.cp.exe &
  inotifywait -e modify -e close_write -e attrib -e move _build/default/bin/docs2web.exe
  echo "restarting..."
  kill $(jobs -pr)
done
