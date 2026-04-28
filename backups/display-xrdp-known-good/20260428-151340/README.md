# Known-Good XRDP/GNOME Display Backup

Created: 20260428-151340

## Purpose

This backup captures the working XRDP + Ubuntu GNOME desktop configuration after XRDP was restored to the default Ubuntu GNOME-style UI.

## Known-good validation

Expected XRDP session values:

```bash
DESKTOP_SESSION=ubuntu
GDMSESSION=ubuntu
XDG_CURRENT_DESKTOP=ubuntu:GNOME
XDG_SESSION_DESKTOP=ubuntu
GNOME_SHELL_SESSION_MODE=ubuntu
XDG_SESSION_TYPE=x11
```

Expected process state:

```bash
gnome-session-binary --session=ubuntu
gnome-shell running as nutserver
xfce4-session not running in XRDP session
```

Expected GNOME extensions:

```bash
ubuntu-dock@ubuntu.com
ding@rastersoft.com
tiling-assistant@ubuntu.com
```

## Sensitive data intentionally excluded

- /etc/xrdp/key.pem
- /etc/xrdp/cert.pem
- ~/.vnc/passwd
- ~/.Xauthority
- ~/.ICEauthority
- /run/user/*
