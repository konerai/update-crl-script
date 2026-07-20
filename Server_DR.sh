#!/bin/bash

#---- Settings ----#

CRL_URL=(  
          "http://example1"                     # URL CRL
          "http://example1"
          "http://example1"
          "http://example1"                     

)                     
CRL_PATH="/tmp/crl.der"                         # tmp file
STORE_NAME="mca"                                # srotage CryptoPro (mca/uca)
CERTMGR_CMD="/opt/cprocsp/bin/amd64/certmgr"    # path to certmgr (usually /opt/cprocsp/bin/amd64/certmgr or /opt/cprocsp/bin/i386/certmgr)
NGINX_RELOAD_CMD="systemctl reload nginx"       # or /etc/init.d/nginx reload 
LOG_FILE="/var/log/update_crl.log"              # logfile/change directory if you want
                                                # not critical
#---- Settings ----#

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "=== Update CRL ==="

rm -f "$CRL_PATH"
log "Old temporary file removed"

# 1. Download CRL
log "Loading from CRL $CRL_URL ..."
if ! wget -q --timeout=30 --tries=3 -O "$CRL_PATH" "$CRL_URL"; then
    log "ERROR: failed to load CRL"
    exit 1
fi

# 2. check NULL 
if [ ! -s "$CRL_PATH" ]; then
    log "ERROR: downloaded file is empty"
    exit 1
fi

# 3. Import CryptoPro
log "Import in store CRL '$STORE_NAME'..."
if ! $CERTMGR_CMD -inst -store "$STORE_NAME" -file "$CRL_PATH" -crl >> "$LOG_FILE" 2>&1; then
    log "ERROR: failed import CRL in CryptoPro"
    exit 1
fi

# 4. Clear tmp file
rm -f "$CRL_PATH"
log "Import CRL"

# 5. Reload nginx
log "Reload nginx..."
if $NGINX_RELOAD_CMD; then
    log "nginx reloas succsesfully"
else
    log "ERORR: faild reload nginx"
    exit 1
fi

log "=== Update CRL done ==="

#---------------------------------------------------------------------------------#

                            #    Guide for daemon cron     #
                            #       sudo crontabe -e       #
                            #   0*/6*** /path/to/file.sh   #
                            #  sudo systemctl restart cron #