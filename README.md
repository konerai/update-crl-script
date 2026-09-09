# CRL Update Script for CryptoPro

This Bash script automatically downloads and imports Certificate Revocation Lists (CRL) from multiple distribution points into the CryptoPro CSP certificate storage.

## Features

- **Batch processing** – handles multiple CRL URLs in a single run
- **Error resilience** – continues processing remaining URLs even if one fails
- **Unique temporary files** – prevents collisions when downloading multiple CRLs
- **Detailed logging** – tracks all operations with timestamps
- **Zero downtime** – no service restart required (CRLs are updated live)

## Requirements

- **CryptoPro CSP** installed with `certmgr` utility
- **wget** for downloading CRL files
- **Bash** 4.0 or higher
- **Root privileges** (for log file access and certmgr execution)

## Installation

1. **Clone or download** this script to your server:
   ```bash
   sudo wget -O /usr/local/bin/update_crl.sh https://your-repo/update_crl.sh
