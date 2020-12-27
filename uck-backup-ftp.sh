#!/bin/sh

# =============================================================================
# Unifi Cloud Key Backup to FTP
# https://github.com/aessing/uck-backup-ftp
# -----------------------------------------------------------------------------
# Developer.......: Andre Essing (https://www.andre-essing.de/)
#                                (https://github.com/aessing)
#                                (https://twitter.com/aessing)
#                                (https://www.linkedin.com/in/aessing/)
# -----------------------------------------------------------------------------
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
# =============================================================================

FTP_SERVER={SERVERNAME}
FTP_PATH={BACKUPPATH}
FTP_USER={FTPUSER}
FTP_PASSWORD={FTPPASSWORD}

###############################################################################
############### Magic Line - Normally no changes below necessary ##############
###############################################################################

echo ""
echo "============================================================================="
echo "$(date)"
echo "Starting backtup to:"
echo " - FTP Server: ${FTP_SERVER}"
echo " - FTP Path: ${FTP_PATH}"
echo " - FTP User: ${FTP_USER}"
echo "-----------------------------------------------------------------------------"

###############################################################################
#
# Setup some stuff
#
echo ""
echo " - Setup some stuff"
BACKUP_ROOT=/uck-backup-ftp
CRON_FILE=/etc/cron.d/uck-backup-ftp
PROTECT_BACKUP_FOLDER=/srv/unifi-protect/backups
PROTECT_BACKUP_LINK=$BACKUP_ROOT/protect
SCRIPT_FILE=`basename $0`
SCRIPT_PATH=$(dirname $(readlink -f $0))
UNIFI_BACKUP_FOLDER=/srv/unifi/data/backup/autobackup
UNIFI_BACKUP_LINK=$BACKUP_ROOT/unifi

###############################################################################
#
# Install lftp
#
dpkg -s lftp >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
    echo ""
    echo " - Installing lftp with apt-get"
    apt-get update
    apt-get install --no-install-recommends -y lftp
fi

###############################################################################
#
# Create backup folder
#
if [ ! -d $BACKUP_ROOT ]; then
    echo ""
    echo " - Creating backup folder ($BACKUP_ROOT)"
    mkdir -p $BACKUP_ROOT
fi
if [ ! -L $UNIFI_BACKUP_LINK ]; then
    echo ""
    echo " - Linking UNIFI backups ($UNIFI_BACKUP_FOLDER) to backup folder ($UNIFI_BACKUP_LINK)"
    ln -s $UNIFI_BACKUP_FOLDER $UNIFI_BACKUP_LINK
fi
if [ ! -L $PROTECT_BACKUP_LINK ]; then
    echo ""
    echo " - Linking UNIFI backups ($PROTECT_BACKUP_FOLDER) to backup folder ($PROTECT_BACKUP_LINK)"
    ln -s $PROTECT_BACKUP_FOLDER $PROTECT_BACKUP_LINK
fi

###############################################################################
#
# Create CRON file
# 
if [ ! -f "$CRON_FILE" ]; then
    echo ""
    echo " - Setting up CRON job that runs every hour ($CRON_FILE)"
    echo "30 * * * * root $SCRIPT_PATH/$SCRIPT_FILE" > $CRON_FILE
    chmod 644 $CRON_FILE
    systemctl restart cron.service
fi

###############################################################################
#
# Copy backup files to FTP server
#
echo ""
echo " - Copy backups to FTP server ($FTP_SERVER)"
/usr/bin/lftp -e "set ssl:verify-certificate no;mirror --overwrite --no-perms --no-umask -RL $BACKUP_ROOT $FTP_PATH;exit" -u $FTP_USER,$FTP_PASSWORD $FTP_SERVER
echo ""
echo " - done"
echo ""
echo "============================================================================="
echo ""

###############################################################################
#EOF