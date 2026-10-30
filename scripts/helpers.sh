get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

set_tmux_option() {
	local option="$1"
	local value="$2"
	tmux set-option -gq "$option" "$value"
}

# multiple tmux server detection helpers

current_tmux_server_pid() {
	echo "$TMUX" |
		cut -f2 -d","
}

current_tmux_server_socket() {
	echo "$TMUX" |
		cut -f1 -d","
}

# A server is another live socket next to ours. Counting `tmux` processes
# cannot tell servers from clients: every plugin, status job and `run-shell`
# that calls tmux while the config loads is a short-lived `tmux` process too.
another_tmux_server_running() {
	local current_socket="$(current_tmux_server_socket)"
	local socket
	for socket in "$(dirname "$current_socket")"/*; do
		[ -S "$socket" ] && [ "$socket" != "$current_socket" ] || continue
		# A refused connection is a stale socket; a hung server still exists.
		timeout 2 tmux -S "$socket" list-sessions >/dev/null 2>&1
		case $? in
			0|124) return 0 ;;
		esac
	done
	return 1
}
