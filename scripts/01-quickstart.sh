#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/homeserver"
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/homeserver-install.log"

# Redirect output to log with fallback
if [ -w "$LOG_DIR" ]; then
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
else
    LOG_FILE="./homeserver-install.log"
    echo "WARNING: Cannot write to /var/log, logging to $LOG_FILE"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
fi

clear
cat << "EOF"
+===========================================================+
|                                                           |
|     HOMESERVER QUICKSTART INSTALLATION                    |
|                                                           |
+===========================================================+
EOF

echo ""
echo -e "${CYAN}Initialisiere Installation...${NC}"
echo ""

# Installation starten
bash "$INSTALL_DIR/install-homeserver.sh"
