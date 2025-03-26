How to Use
Manual Run:
```bash
chmod +x /srv/affine-backups/backup-cronjob.sh
/srv/affine-backups/backup-cronjob.sh
```
Automatic Run (via GitHub Actions or cron):
GitHub Actions already runs this script nightly.

To add a local cron job, edit your crontab:
```bash
crontab -e
```
Add this line to run daily at midnight:
```bash
0 0 * * * /srv/affine-backups/backup-cronjob.sh >> /var/log/affine-backup.log 2>&1
```
✅ Done!
ubuntu@k3sworkerx86:/srv$ mkdir affine-postgres
mkdir: cannot create directory ‘affine-postgres’: Permission denied
ubuntu@k3sworkerx86:/srv$ sudo mkdir -p /srv/affine-postgres
ubuntu@k3sworkerx86:/srv$ sudo chown ubuntu:ubuntu /srv/affine-postgres