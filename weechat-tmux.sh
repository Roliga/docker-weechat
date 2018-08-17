#!/bin/sh

trap 'trap - TERM && kill $weechatPID' INT TERM

weechatPID="$(tmux -u new-session -d -P -F '#{pid}' -s weechat "weechat -d '/var/lib/weechat' 2>/run/weechat_stderr.fifo")"

while [ -d "/proc/$weechatPID" ]; do sleep 5; done
