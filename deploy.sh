#!/bin/sh
# Incremental setup script, can be resumed at any time.

set -eu # Make sure that all params are set.

. "$(dirname "$0")/setup.sh"

: "${SERVICES:=caddy appservice_discord synapse stagit umurmur}" # Services that I run.

grep "^$MAIN_USER:" /etc/group || {
	adduser "$MAIN_USER"
	addgroup "$MAIN_USER" wheel
}

[ -f "/home/$MAIN_USER/.profile" ] || cp -f profile "/home/$MAIN_USER/.profile"

(
	cd "/home/$MAIN_USER"

	mkdir -p kiss
	cd kiss

	for repo in kisslinux/repo kiss-community/community git-bruh/kiss-repo; do
		[ -d "${repo##*/}" ] || git clone --depth=1 "https://github.com/$repo"
	done
)

# Make sure that all the required packages like Python and Postgres are installed.
# Installation of the meta package is left as a manual task as I usually copy
# over the binaries from my PC to the VPS.
kiss list server-meta

mkdir -p /etc/rc.d
cp -f ./iptables.boot /etc/rc.d/ # Must reboot once.

[ -L /var/service/postgresql ] || {
	printf "Postgresql must be running!"
	return 1
}

for service in $SERVICES; do
	grep "^$service:" /etc/group || adduser "$service" -HD # No home / pass

	[ -d "/services/$service" ] || mkdir -p "/services/$service"
	chown -R "$service:$service" "/services/$service"

	[ -d "/etc/sv/$service" ] || {
		mkdir -p "/etc/sv/$service"

		cp -f "./sv/$service.run" "/etc/sv/$service/run"
		ln -sf "/run/runit/supervise.$service" "/etc/sv/$service/supervise"
	}

	# Check if the setup function exists (Making sure not to call the system binary with the same name) and call it.
	case "$(type "$service" 2>/dev/null)" in
		# "$service is a function."
		*function*) "$service" ;;
	esac

	sleep 1 # Give some time to read the printed warnings (If any).
done
