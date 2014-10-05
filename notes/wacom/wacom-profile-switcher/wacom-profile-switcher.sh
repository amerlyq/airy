#!/bin/bash

    # awk — для поиска ID окна в выводе. Можно было обойтись и cutом или grepом, но почитав обсуждения, решил реализовать на awk
    # xprop — используется для получения текущего окна в фокусе
    # wmctrl — для получения списка ID окон, в которых есть нужное ключевое слово, например, Firefox — для переназначения клавиш при переключении на браузер. Также бывают случаи, когда запущено несколько окон, например, с именем Terminal, ID у них разные, а профиль должен быть один

# В целом алгоритм установки следующий:
#
# Копируем папку wacom-profile-switcher в свою домашнюю директорию.
# В файл programs вносим названия тех приложений, для которых нужны профили. Названия должны соответствовать надписям из окон приложений, например: gedit, LibreOffece и т. д.
# Для каждого такого названия создаем файл, в который вносим нужные нам настройки графического планшета. Имена файлов должны быть написаны также, как в файле programs.
# Далее можно либо запускать скрипт при надобности, либо кинуть его в автозагрузку. Пока пользователь не переключится с одного окна на другое, сценарий будет только раз в секунду проверять, не сменился ли ID окна в фокусе.


awk_string1="/"
awk_string2="/{print \$1}"
window_in_focus_old=""

while true
do
  #get ID of windows in the focus
  window_in_focus=`xprop -root |awk '/_NET_ACTIVE_WINDOW/ {print $5; exit;}'`
  #if the focus didn't change - do nothing
  if [[ "$window_in_focus" -ne "$window_in_focus_old" ]]
   then
   	  window_in_focus_old=$window_in_focus
  	  #reading program's name from file "programs"
      list_of_progr=$(<$HOME/wacom-profile-switcher/programs)
	  # program's names cycle
	  for name_of_progr in $list_of_progr
	  do
	  	awk_string_result="$awk_string1$name_of_progr$awk_string2"
		# getting the list of windows, wich titles has keyword from list of programs
	  	list_of_running_prog=`wmctrl -l | awk "${awk_string_result}"`
	  	# if in focus - then will execute script in the xsetwacom directory
	  	for running_progr in $list_of_running_prog
	  	do
	  		if [[ "$running_progr" -eq "$window_in_focus" ]]
	  		 then
	  			$HOME/wacom-profile-switcher/$name_of_progr

	  		fi
	  	done
	  done
  fi

sleep 1
done
