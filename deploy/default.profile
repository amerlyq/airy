# vim: ft=sh

### General ###
CURR_PROF="default"
LANG=en_US.UTF-8
# LANGUAGE=en_US
LC_NUMERIC=en_US.UTF-8
EDITOR=vim
VISUAL=vim

### Profile Mgmt ###
CURR_PLTF=$(expr substr $(uname -s) 1 5)
CURR_USER=${SUDO_USER:-${USER:-${USERNAME:-`whoami`}}}
CURR_HOST=${HOSTNAME:-`uname -n`}

### Git ###
MAIN_NAME=""
MAIN_MAIL=""
WORK_NAME=$MAIN_NAME
WORK_MAIL=$MAIN_MAIL

### HW ###
MAIN_DPI=96
CURR_DIR_PKG=~/pkg
CURR_DIR_SYNC=~/synchro
CURR_PKG_LIST=""

### SDK ###
JAVA32_HOME=/usr/lib/jvm/java-7-openjdk-i386
JAVA64_HOME=/usr/lib/jvm/java-7-openjdk-amd64
JAVA64_ORACLE_HOME=/usr/lib/jvm/java-7-oracle
JAVA_HOME=$JAVA64_ORACLE_HOME
#SDL2=$CURR_DIR_PKG/SDL

### END ###
PATH+=$PATH:$HOME/.bin:$JAVA_HOME/include
