#!/bin/sh

# Kill the current process group on relevant signals, unbinding the TERM signal to prevent recursion
trap "trap - TERM && kill 0" INT EXIT TERM

if [ "$(id -u weechat)" -ne "$UID" ] || [ "$(id -g weechat)" -ne "$GID" ]; then
	echo "Updating weechat UID and GID" >&2

	deluser weechat
	addgroup -g "$GID" -S weechat
	adduser -u "$UID" -D -S -h /var/lib/weechat -s /bin/sh -G weechat weechat
	passwd -d weechat

	chown weechat:weechat /run/weechat_stderr.fifo
	chown weechat:weechat /var/lib/weechat
fi

# Generate ssh host keys if needed
for keyType in rsa dsa ecdsa ed25519; do
	if [ ! -f /etc/ssh/keys/ssh_host_${keyType}_key ]; then
		ssh-keygen -t ${keyType} -f /etc/ssh/keys/ssh_host_${keyType}_key -N ''
	fi
done

# Start services in the background, and kill this process group if one of them exits
{ su -c 'cat /run/weechat_stderr.fifo' weechat; kill 0; } &
{ su -c '/usr/local/bin/weechat-tmux.sh' weechat; kill 0; } &
{ /usr/sbin/sshd -D -e; kill 0; } &

# Wait for all processes to exit, allowing traps to be handled
wait
