#!/usr/bin/env sh

junk=(
	"$HOME/.node_repl_history"
	"$HOME/.python_history"
	"$HOME/.xsession_errors*"
	"$HOME/.viminfo"
	"$HOME/.mysql_history"
	"$HOME/.sudo_as_admin_successful"
	"$HOME/.mongorc.json"
	"$HOME/.lesshst"
	"$HOME/.yarnrc"
	"$HOME/.dir_colors"
	"$HOME/.dbshell"
	"$HOME/.NERDTreeBookmarks"
	"$HOME/.angular-config.json"
	"$HOME/.install4j"
	"$HOME/.wget-hsts"
)

for j in ${junk[@]}; do
	if [ -n "$j" ] && [ -e "$j" ]; then
		rm -v "$j"
	fi
done


