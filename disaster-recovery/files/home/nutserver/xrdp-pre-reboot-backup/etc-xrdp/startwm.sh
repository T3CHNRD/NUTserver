#!/bin/sh

# XRDP Ubuntu GNOME session startup
# Restores Ubuntu GNOME shell mode instead of XFCE fallback.

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export DESKTOP_SESSION=ubuntu
export GDMSESSION=ubuntu
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export XDG_SESSION_TYPE=x11
export LIBGL_ALWAYS_SOFTWARE=1
export GSK_RENDERER=cairo

if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi

test -x /etc/X11/Xsession && exec /etc/X11/Xsession
exec /bin/sh /etc/X11/Xsession
