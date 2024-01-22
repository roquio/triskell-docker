#!/bin/bash
set -e


# Public host
PUBLIC_HOST=${PUBLIC_HOST}

# Nuxeo conf
NUXEO_CONF=/home/nuxeo/nuxeo.conf

# Data
NUXEO_DATA=${NUXEO_DATA:-/data/nuxeo}
# Logs
NUXEO_LOGS=${NUXEO_LOGS:-/var/log/nuxeo}
# PID
NUXEO_PID=${NUXEO_PID:-/var/run/nuxeo}


if [ "$1" = "start" ]; then
    if [ ! -f $NUXEO_HOME/configured ]; then
        echo "Configuration..."

        # Properties
        sed -i s\\PUBLIC_HOST\\$PUBLIC_HOST\\g $NUXEO_CONF

        # Data
        mkdir -p $NUXEO_DATA
        chown -R $NUXEO_USER: $NUXEO_DATA
        # Logs
        mkdir -p $NUXEO_LOGS
        touch $NUXEO_LOGS/server.log        
        chown -R $NUXEO_USER: $NUXEO_LOGS
        # PID
        mkdir -p $NUXEO_PID
        chown -R $NUXEO_USER: $NUXEO_PID

        # Wizard
        touch $NUXEO_HOME/configured
    fi

	# Command
	NUXEO_CMD="NUXEO_CONF=$NUXEO_CONF $NUXEO_HOME/bin/nuxeoctl startbg"
	echo "NUXEO_CMD = $NUXEO_CMD"
	su - $NUXEO_USER -c "$NUXEO_CMD 2>&1" &
	
	tail -f $NUXEO_LOGS/server.log

else
    exec "$@"
fi



