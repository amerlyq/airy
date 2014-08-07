#!/bin/bash
#Copyright (c) 2012 Remy van Elst
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#first the vars
BASEURL="http://wallbase.cc/search/"
MODE="$1"
SEARCH="$2"
NEWWALLURL="http://wallbase.cc/search/0/0/213/eqeq/0x0/0/1/1/0/60/relevance/desc/wallpapers"
WALLR="http://wallbase.cc/random/"
CONFIGS="/0/213/eqeq/0x0/0/1/1/0/60/relevance/desc/wallpapers"

#now see what we need to do
case "$1" in
   s)
   if [ -e $2 ]; then
      echo "I need search terms"
      exit 1
   fi
   GETURL="$BASEURL$SEARCH$CONFIGS"
   ;;
   n)
   GETURL="$NEWWALLURL"
   ;;
   r)
   GETURL="$WALLR"
   ;;
   *)
   echo -e "Usage:n$0 r for randomn$0 n for newestn$0 s TERM for search TERM."
   exit 1
   ;;
esac

GETURL=$WALLR
#get the wallpaper overview page, grep the wallpaper page urls and dump them into a file for wget
wget -q --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:12.0) Gecko/20120403211507 Firefox/12.0" $GETURL -O- | egrep -o "http://[^[:space:]]*" | grep "/wallpaper/" | sed 's/"//g' > ./wallist

#put the url file in a variable, but first backup IFS and later restore it.
OLDIFS=$IFS
IFS='
'
urlsa=( $( < ./wallist ) )
IFS=$OLDIFS

#now loop trough the urls and wget the page, then grep the wallpaper URL, and then wget the wallpaper
for i in "${urlsa[@]}"
do
  echo $i
  wget -vv --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows NT 6.1; rv:12.0) Gecko/20120403211507 Firefox/12.0" $i -O- | wget -vv -nd -nc `egrep -o "http://[^[:space:]]*.jpg"`
done

#now a duplicate check...
find -not -empty -type f -printf "%sn" | sort -rn | uniq -d | xargs -I{} -n1 find -type f -size {}c -print0 | xargs -0 md5sum | sort | uniq -w32 | cut -d" " -f3 | xargs -P 10 -r -n 1 rm
