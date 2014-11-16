#!/bin/bash

function aa_256 ()
{
    local o= i= x=`tput op` cols=`tput cols` y= oo= yy=;
    y=`printf %$(($cols-6))s`;
    yy=${y// /=};
    for i in {0..256};
    do
        o=00${i};
        oo=`echo -en "setaf ${i}\nsetab ${i}\n"|tput -S`;
        echo -e "${o:${#o}-3:3} ${oo}${yy}${x}";
    done
}

function aa_c666 ()
{
    local r= g= b= c= CR="`tput sgr0;tput init`" C="`tput op`" n="\n\n\n" t="  " s="    ";
    echo -e "${CR}${n}";
    function c666 ()
    {
        local b= g=$1 r=$2;
        for ((b=0; b<6; b++))
        do
            c=$(( 16 + ($r*36) + ($g*6) + $b ));
            echo -en "setaf ${c}\nsetab ${c}\n" | tput -S;
            echo -en "${s}";
        done
    };
    function c666b ()
    {
        local g=$1 r=;
        for ((r=0; r<6; r++))
        do
            echo -en " `c666 $g $r`${C} ";
        done
    };
    for ((g=0; g<6; g++))
    do
        c666b=`c666b $g`;
        echo -e " ${c666b}";
        echo -e " ${c666b}";
        echo -e " ${c666b}";
        echo -e " ${c666b}";
        echo -e " ${c666b}";
    done;
    echo -e "${CR}${n}${n}"
}

aa_256
