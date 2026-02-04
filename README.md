# Nyukeit's Homelab
This is the official repository of my homelab. It consists of several self-hosted services as can be seen from the code above, which is mostly just Docker Compose files for each service.

## Documentation
Official private documentation of this homelab can be accessed at [Homelab Wiki](https://docs.nyukeit.com)
> Note: This documentation is private and is only accessible to authorised users.

## Caddy Cloudflare Image
This repo uses a custom built Caddy-Cloudflare DNS image that was built using a Dockerfile. The file can be accessed from `infra/caddy/Dockerfile`. Here is the simple Dockerfile used to be build the image:

```Dockerfile
FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

The image can be accessed from here:
`ghcr.io/nyukeit/caddy-cloudflare:latest`

## Backup
We use a combination of tools to ensure data integrity and availability. Here's an overview of our backup strategy:

### Database Backup
We use `pg_dump` to create a full backup of the PostgreSQL database used by Immich. The backup is then compressed using `zstd` to reduce storage requirements.

### File Backup
We use `restic` to create a backup of the Immich data directory and the compressed database dump. We exclude certain directories to reduce the backup size.

Restic requires a password prompt to initiate backup. This can be automated using a password file.

```bash
sudo install -m 600 /dev/null /etc/restic/immich-backup.pass
sudo nano /etc/restic/immich-backup.pass
```
Use a long and complex password to secure the backup. Make sure the owner of the file is root and the permissions are set to 600.

#### Using systemd to automate backup
Create a systemd service file to automate the backup process. Create a file named `/etc/systemd/system/immich-backup.service` with the following content:

```ini
[Unit]
Description=Immich Backup Service

[Service]
Type=oneshot
ExecStart=/path/to/immich-backup.sh
Environment=RESTIC_PASSWORD_FILE=/etc/restic/immich-backup.pass
Environment=RESTIC_REPOSITORY=/path/to/restic/repo
Environment=RCLONE_CONFIG=/home/youruser/.config/rclone/rclone.conf
Nice=15
IOSchedulingClass=best-effort
IOSchedulingPriority=7
```
Reload the systemd daemon and enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable immich-backup.service
```

### Notification
We use a custom script to send notifications when the backup completes successfully or fails. Notifications are sent using NTFY.
