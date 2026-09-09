#!/bin/bash

# ============================================================
# Settings
# ============================================================

# Array of CRL distribution point URLs to download
CRL_URL=(
    "http://example1"                     # CRL URL #1
    "http://example2"                     # CRL URL #2
    "http://example3"                     # CRL URL #3
    "http://example4"                     # CRL URL #4
)

# Temporary directory for storing downloaded CRL files
CRL_TMP_DIR="/tmp/crl_temp"

# CryptoPro certificate storage name (mca or uca)
STORE_NAME="mca"

# Path to CryptoPro certmgr utility
CERTMGR_CMD="/opt/cprocsp/bin/amd64/certmgr"

# Log file path
LOG_FILE="/var/log/update_crl.log"

# ============================================================
# Functions
# ============================================================

# Logging function: writes timestamped messages to log file
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# ============================================================
# Main execution
# ============================================================

# Create temporary directory if it doesn't exist
mkdir -p "$CRL_TMP_DIR"

# Start logging
log "=== Update CRL started ==="

# Initialize error counter
ERRORS=0

# Process each CRL URL from the array
for URL in "${CRL_URL[@]}"; do
    # Generate unique filename based on URL hash (first 8 chars of MD5)
    TMP_FILE="$CRL_TMP_DIR/crl_$(echo "$URL" | md5sum | cut -c1-8).der"
    
    log "Downloading CRL from $URL ..."
    
    # Download CRL with timeout and retry limits
    if ! wget -q --timeout=30 --tries=3 -O "$TMP_FILE" "$URL"; then
        log "ERROR: failed to download CRL from $URL"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Check if downloaded file is not empty
    if [ ! -s "$TMP_FILE" ]; then
        log "ERROR: downloaded CRL from $URL is empty"
        ERRORS=$((ERRORS + 1))
        rm -f "$TMP_FILE"
        continue
    fi

    # Import CRL into CryptoPro certificate store
    log "Importing CRL from $URL into store '$STORE_NAME'..."
    if ! $CERTMGR_CMD -inst -store "$STORE_NAME" -file "$TMP_FILE" -crl >> "$LOG_FILE" 2>&1; then
        log "ERROR: failed to import CRL from $URL"
        ERRORS=$((ERRORS + 1))
    else
        log "Successfully imported CRL from $URL"
    fi

    # Clean up temporary file after processing
    rm -f "$TMP_FILE"
done

# Remove temporary directory and all remaining files
rm -rf "$CRL_TMP_DIR"

# Report final status
if [ $ERRORS -eq 0 ]; then
    log "=== All CRL updated successfully ==="
    exit 0
else
    log "=== Update completed with $ERRORS error(s) ==="
    exit 1
fi
