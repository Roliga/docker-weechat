FROM alpine:latest

RUN apk add --update --no-cache \
	gnutls ncurses libgcrypt python perl curl aspell aspell-en ca-certificates openssh tmux rxvt-unicode-terminfo
RUN apk add --no-cache --virtual build-dependencies \
	cmake make gcc g++ libcurl libintl zlib-dev curl-dev perl-dev gnutls-dev python2-dev ncurses-dev libgcrypt-dev jq tar aspell-dev ca-certificates
RUN WEECHAT_TARBALL="$(curl -sS https://api.github.com/repos/weechat/weechat/releases/latest | jq .tarball_url -r)" \
	&& curl -sSL $WEECHAT_TARBALL -o /tmp/weechat.tar.gz \
	&& mkdir -p /tmp/weechat/build \
	&& tar xzf /tmp/weechat.tar.gz --strip 1 -C /tmp/weechat \
	&& cd /tmp/weechat/build \
	&& cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
	&& make \
	&& make install

RUN curl https://ftp.gnu.org/gnu/aspell/dict/sv/aspell-sv-0.51-0.tar.bz2 -o /tmp/aspell-sv.tar.bz2 \
	&& mkdir /tmp/aspell-sv \
	&& tar xjf /tmp/aspell-sv.tar.bz2 --strip 1 -C /tmp/aspell-sv \
	&& cd /tmp/aspell-sv \
	&& ./configure \
	&& make \
	&& make install

RUN apk del build-dependencies \
	&& rm -rf /tmp/*

COPY weechat-tmux.sh entrypoint.sh /usr/local/bin/
COPY sshd_config /etc/ssh
COPY tmux.conf /etc

ENV UID=1495
ENV GID=1495

RUN  addgroup -g "$GID" -S weechat \
	&& adduser -u "$UID" -D -S -h /var/lib/weechat -s /bin/sh -G weechat weechat \
	&& passwd -d weechat \
	&& chown weechat:weechat /var/lib/weechat

RUN mkfifo /run/weechat_stderr.fifo \
	&& chown weechat:weechat /run/weechat_stderr.fifo

VOLUME /var/lib/weechat
VOLUME /etc/ssh/keys

ENTRYPOINT [ "entrypoint.sh" ]
