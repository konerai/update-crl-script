# CRL Update Script for CryptoPro and Nginx Reload

This bash script automatically downloads a Certificate Revocation List (CRL) from a specified URL, imports it into a CryptoPro storage (`mca` or `uca`), and reloads Nginx to apply the changes. It is designed for Linux environments with CryptoPro CSP installed.

## Features

- Download CRL from multiple fallback URLs (tries them in order).
- Validates that the downloaded file is not empty.
- Imports the CRL into a CryptoPro certificate store (`mca`/`uca`).
- Automatically reloads Nginx after successful import.
- Logs every action with timestamps for easy auditing.
- All settings are configurable via variables at the top of the script.

## Requirements

- **Operating System**: Linux (tested on CentOS 7/8, Ubuntu 18.04/20.04).
- **CryptoPro CSP** (version 5.0 or higher) installed and properly configured.
- **Utilities**: `wget` (for downloading).
- **Permissions**: Root or sudo privileges to run `certmgr` and reload Nginx.
- **Nginx** (or any web server – the reload command can be changed).

## Installation

1. Clone this repository (or download the script manually):
   ```bash
   git clone https://github.com/your_username/Server_DR.git
   cd Server_DR
   ```

2. Make the script executable:
   ```bash
   chmod +x update_crl.sh
   ```

3. (Optional) Edit the configuration variables inside the script to match your environment:
   - `CRL_URL` – an array of URLs (the script tries each until one succeeds).
   - `CRL_PATH` – temporary location to save the downloaded CRL (default: `/tmp/crl.der`).
   - `STORE_NAME` – CryptoPro store name (`mca` or `uca`).
   - `CERTMGR_CMD` – full path to the `certmgr` binary (default: `/opt/cprocsp/bin/amd64/certmgr`).
   - `NGINX_RELOAD_CMD` – command to reload Nginx (default: `systemctl reload nginx`).
   - `LOG_FILE` – path to the log file (default: `/var/log/Server_DR.log`).

## Usage

### Manual Run

Run the script with root privileges:
```bash
sudo ./Server_DR.sh
```

Check the log output to confirm success:
```bash
tail -f /var/log/Server_DR.log
```

### Automated Execution via Cron

To run the script every 6 hours, add a cron job:

1. Open the root crontab:
   ```bash
   sudo crontab -e
   ```

2. Add the following line (adjust the path to your script):
   ```
   0 */6 * * * /full/path/to/Server_DR.sh
   ```

3. Save and restart the cron daemon (if needed):
   ```bash
   sudo systemctl restart cron   # on Debian/Ubuntu
   sudo systemctl restart crond  # on RHEL/CentOS
   ```

Now the CRL will be updated automatically every 6 hours.

## Configuration Variables Explained

| Variable            | Description                                                                                  |
|---------------------|----------------------------------------------------------------------------------------------|
| `CRL_URL`           | Array of URLs. The script tries each URL sequentially until a successful download occurs.    |
| `CRL_PATH`          | Temporary file path where the downloaded CRL is stored (e.g., `/tmp/crl.der`).               |
| `STORE_NAME`        | CryptoPro store name – either `mca` (default) or `uca`.                                      |
| `CERTMGR_CMD`       | Full path to the `certmgr` executable (typically `/opt/cprocsp/bin/amd64/certmgr`).          |
| `NGINX_RELOAD_CMD`  | Command to reload Nginx (e.g., `systemctl reload nginx` or `/etc/init.d/nginx reload`).      |
| `LOG_FILE`          | Path to the log file where all operations are recorded.                                      |

## Logging

All actions and errors are written to the log file specified by `LOG_FILE`. Each entry includes a timestamp:

```
2026-07-20 10:15:30 - === Update CRL ===
2026-07-20 10:15:30 - Old temporary file removed
2026-07-20 10:15:31 - Loading from CRL http://example1 ...
2026-07-20 10:15:32 - Import in store CRL 'mca'...
2026-07-20 10:15:33 - Import CRL
2026-07-20 10:15:33 - Reload nginx...
2026-07-20 10:15:34 - nginx reload successfully
2026-07-20 10:15:34 - === Update CRL done ===
```

## Detailed Step‑by‑Step Guide for First‑Time Setup

1. **Verify your CryptoPro installation**  
   Ensure `certmgr` is available and functional:
   ```bash
   /opt/cprocsp/bin/amd64/certmgr -list -store mca
   ```
   If you get a list of certificates, the tool works.

2. **Test the script manually**  
   - Run it with `sudo ./Server_DR.sh`.  
   - Watch the log with `tail -f /var/log/Server_DR.log` in another terminal.  
   - If something fails, check:
     - Network connectivity to the CRL URL.
     - Write permissions to `CRL_PATH` (usually `/tmp` is writable).
     - That `certmgr` can write to the CryptoPro store (requires root).
     - That the Nginx reload command works (try `sudo systemctl reload nginx` separately).

3. **Tune the configuration**  
   - If your CRL comes in a different format (e.g., PEM), you may need to convert it. This script expects a DER‑encoded CRL, but you can adapt it.
   - If you have multiple URLs, put them in the array. The script will stop at the first successful download.

4. **Set up cron** (as described above)  
   - Choose an appropriate interval (e.g., every 6 hours, daily).  
   - Make sure the script path is absolute and that cron has the correct environment (you may need to set `PATH` in the crontab).

5. **Monitor the logs**  
   - Check the log file periodically to ensure updates are happening.  
   - You can also set up log rotation (e.g., with `logrotate`) to prevent the log file from growing indefinitely.

## Troubleshooting

| Problem                     | Likely Cause & Solution                                                                                   |
|-----------------------------|-----------------------------------------------------------------------------------------------------------|
| **Download fails**          | URL unreachable, network down, or `wget` missing. Check internet and URL.                                 |
| **Downloaded file is empty**| The server returned an empty response. Verify the CRL URL and try manually with `wget`.                   |
| **Import fails**            | `certmgr` path is wrong, store name incorrect, or CryptoPro is not installed. Check paths and run `certmgr -list -store mca`. |
| **Nginx reload fails**      | Nginx service not running, or the reload command is wrong. Try `sudo systemctl status nginx` and adjust the `NGINX_RELOAD_CMD`. |
| **Permission denied**       | Run the script with `sudo` or ensure the user has appropriate sudo rights for `certmgr` and Nginx reload. |
