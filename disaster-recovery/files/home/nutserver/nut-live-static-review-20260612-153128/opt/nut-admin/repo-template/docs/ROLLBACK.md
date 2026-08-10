# NUT Server Rollback Procedure

## Purpose
This document explains how to restore the known-good NUT server configuration captured on 2026-03-23 before additional testing.

## Known-Good Freeze Location
- `/root/nut-freeze-2026-03-23/`

## Frozen Items
- `/etc/nut/`
- `/usr/local/bin/nut-test-logic.sh`

## Rollback Use Case
Use this rollback if:
- NUT services fail after testing
- UPS devices do not report correctly
- Dashboard behavior becomes incorrect
- `upsmon` / `upssched` event handling stops working
- Custom test logic changes need to be reverted

## Rollback Steps

### 1. Stop NUT services

```bash
sudo systemctl stop nut-monitor
sudo systemctl stop nut-server
