#!/bin/bash
i3status -c ~/.i3/i3status.conf | (read line && echo $line && while :
do
  read line
  track=$(ncmpcpp --now-playing)
  track="[{ \"full_text\": \"${track}\" },"
  echo "${line/[/$track}" || exit 1
done)


