#!/usr/bin/env sh

junk=(
	"$HOME/.NERDTreeBookmarks"
	"$HOME/.angular-config.json"
	"$HOME/.bash_history"
	"$HOME/.dbshell"
	"$HOME/.dir_colors"
	"$HOME/.install4j"
	"$HOME/.lesshst"
	"$HOME/.mongorc.json"
	"$HOME/.mysql_history"
	"$HOME/.node_repl_history"
	"$HOME/.psql_history"
	"$HOME/.python_history"
	"$HOME/.rnd"
	"$HOME/.sudo_as_admin_successful"
	"$HOME/.testcontainers.properties"
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


