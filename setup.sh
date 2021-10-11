#!/bin/sh
# Software-specific stuff

set -eu

do_as_user() {
	user="$1"
	shift

	su - "$user" -c "$*"
}

appservice_discord() {
	[ -d /services/appservice_discord/.git ] ||
		do_as_user appservice_discord \
			git clone --depth=1 \
				https://github.com/git-bruh/matrix-discord-bridge /services/appservice_discord

	(
		cd /services/appservice_discord

		git pull

		[ -d env ] || do_as_user appservice_discord python -m venv "$PWD/env"
		do_as_user appservice_discord "cd $PWD; . env/bin/activate; pip install -r appservice/requirements.txt"
	)
}

caddy() {
	kiss list libcap # For setcap

	[ -f /services/caddy/caddy ] ||
		curl -L "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fduckdns" \
			> /services/caddy/caddy
	chmod +x /services/caddy/caddy

	chown caddy:caddy /services/caddy/caddy
	setcap "cap_net_bind_service=+ep" /services/caddy/caddy

	[ -f /services/caddy/Caddyfile ] || cp -f Caddyfile /services/caddy/Caddyfile
}

umurmur() {
	[ -f /etc/umurmur.conf ] && {
		chown umurmur:umurmur /etc/umurmur.conf

		sed 's|/etc/|/services/umurmur|' /etc/umurmur.conf > _
		mv -f _ /etc/umurmur.conf
	}

	printf "umurmur certificates must be placed at '%s' and '%s'.\n" \
		/services/umurmur/cert.crt \
		/services/umurmur/key.key
}

synapse() {
	(
		cd /services/synapse

		: "${SYNAPSE_USER:=synapse_user}"
		: "${SYNAPSE_DB:=synapse}"

		kiss list libjpeg-turbo libxslt rust # Required by the Python packages

		[ -d env ] || do_as_user synapse python -m venv "$PWD/env"
		. env/bin/activate

		do_as_user synapse ". $PWD/env/bin/activate; pip install -U matrix-synapse[postgres]"

		[ -f homeserver.yaml ] || do_as_user synapse \
			"cd $PWD; . env/bin/activate; python -m synapse.app.homeserver \
				--server-name $SYNAPSE_SERVER \
				--config-path $PWD/homeserver.yaml \
				--generate-config \
				--report-stats=no"

		# Make sure that we use the same password in-case the previous run failed.
		[ -f pg_pass ] || tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 20 | head -n1 > pg_pass

		pg_pass="$(cat pg_pass)"

		# Create the user if it doesn't exist.
		[ "$(do_as_user postgres psql -tAc "\"SELECT 1 FROM pg_roles WHERE rolname='$SYNAPSE_USER'\"")" = "1" ] ||
				do_as_user postgres psql -c "\"CREATE USER $SYNAPSE_USER WITH PASSWORD '$pg_pass'\""

		# Create the database if it doesn't exist.
		[ "$(do_as_user postgres psql -tAc "\"SELECT 1 FROM pg_database WHERE datname='$SYNAPSE_DB'"\")" = "1" ] ||
			do_as_user postgres \
				createdb \
					--encoding=UTF8 --locale=C --template=template0 \
					--owner="$SYNAPSE_USER" "$SYNAPSE_DB"

		cat << EOF
NOTE: The postgres password is stored in "/services/synapse/pg_pass" for reference.

The following lines must be added to homeserver.yaml to replace the default sqlite3 database:
database:
  name: psycopg2
  args:
    user: $SYNAPSE_USER
    password: $pg_pass
    database: $SYNAPSE_DB
    host: localhost
    cp_min: 5
    cp_max: 10
EOF
	)
}

stagit() {
	mkdir -p "/etc/stagit" "/services/stagit/repos" "/services/stagit/home"

	cat > /etc/stagit/stagit.conf << EOF
GIT_HOME="/services/stagit/repos"
WWW_HOME="/services/stagit/home"
CLONE_URI="git://git.git-bruh.duckdns.org"
DEFAULT_OWNER="git-bruh"
DEFAULT_DESCRIPTION="description"
GIT_USER="stagit"
EOF
}
