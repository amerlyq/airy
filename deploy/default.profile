# vim: ft=sh

### General ###
CURR_PROF="default"
# Set your language environment
LANG=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
# LANGUAGE=en_US

EDITOR=vim
VISUAL=vim
TERMCMD=urxvt
# speed up ranger start time
RANGER_LOAD_DEFAULT_RC=FALSE

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
CURR_DIR_HUB=~/hub
CURR_DIR_SYNC=~/synchro
CURR_PKG_LIST=""

### SDK ###
JAVA32_HOME=/usr/lib/jvm/java-7-openjdk-i386
JAVA64_HOME=/usr/lib/jvm/java-7-openjdk-amd64
JAVA64_ORACLE_HOME=/usr/java/jdk1.8.0_31  #/usr/lib/jvm/java-8-oracle
JAVA_HOME=$JAVA64_ORACLE_HOME
#SDL2=$CURR_DIR_PKG/SDL

### END ###
PATH+="$JAVA_HOME/bin:$JAVA_HOME/include:$PATH:$HOME/.bin"
