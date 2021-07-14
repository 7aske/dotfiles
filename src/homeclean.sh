#!/usr/bin/env sh

junk=(
	"$HOME/.NERDTreeBookmarks"
	"$HOME/.angular-config.json"
	"$HOME/.babel.json"
	"$HOME/.bash_history"
	"$HOME/.calc_history"
	"$HOME/.dbshell"
	"$HOME/.dir_colors"
	"$HOME/.emulator_console_auth_token"
	"$HOME/.install4j"
	"$HOME/.isomaster"
	"$HOME/.lesshst"
	"$HOME/.mbsyncrc"
	"$HOME/.mongorc.js"
	"$HOME/.mongorc.json"
	"$HOME/.mysql_history"
	"$HOME/.node_repl_history"
	"$HOME/.psql_history"
	"$HOME/.python_history"
	"$HOME/.rnd"
	"$HOME/.slqite_history"
	"$HOME/.sudo_as_admin_successful"
	"$HOME/.testcontainers.properties"
	"$HOME/.tig_history"
	"$HOME/.viminfo"
	"$HOME/.wget-hsts"
	"$HOME/.xsession_errors*"
	"$HOME/.yarnrc"
)

for j in ${junk[@]}; do
	if [ -n "$j" ] && [ -e "$j" ]; then
		rm -v "$j"
	fi
done


