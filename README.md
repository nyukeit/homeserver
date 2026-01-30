# This is my homelab repo
This repo serves as a backup for my homelab configuration and docker compose files

## Infrastructure
### AdGuard Home
Used for DNS filtering and blocking ads along with OpenWRT on a custom router that sits behind the ISP router for better security.

### FileBrowser
Used for browsing and managing files on the headless server using a web interface. Also provides access to my cloud storage, which is cloned onto the server.

### Immich
Used for managing and organizing photos and videos. It provides a web interface for browsing and searching through the media library.

### Portainer
Used for managing and monitoring Docker containers and services. It provides a web interface for managing and monitoring Docker containers and services.

### NTFY
Used for sending and receiving notifications. It provides a web interface for sending and receiving notifications.

### Caddy
Used for reverse proxying services. Remove reliance on port forwarding.

### Homepage
Used for consolidating information about the homelab infrastructure and services. Also provides running and health status of the services.

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
