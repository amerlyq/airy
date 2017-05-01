#!/usr/lib/j8/bin/jconsole
NB. USAGE: { echo 1 2 3; echo 1 + 4; } | ./repl.ijs
NB. demo showing how to make a simple repl in j.

readln =: [: (1!:1) 1:
donext =: [: (9!:29) 1: [ 9!:27

main =: verb define
  echo 'main loop. type ''bye'' to exit.'
  echo '--------------------------------'
  while. (s:'`bye') ~: s:<input=:readln'' do.
    echo '---'
    try.
        echo ".input
    catch.
        1!:2&5]13!:12''
        2!:55>:13!:11''
    end.
  end.
  echo '--------------------------------'
  echo 'loop complete. returning to j.'
  NB. or put (  exit'' ) here to exit j.
)

donext 'main _'
