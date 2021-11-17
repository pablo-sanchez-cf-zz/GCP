#!/usr/bin/env bash
export PATH=$PATH:/usr/local/bin/:/usr/bin

# CREATE DAILY SNAPSHOT

DEVICE_NAME="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/disks/0/device-name" -H "Metadata-Flavor: Google")"
DEVICE_ID="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/id" -H "Metadata-Flavor: Google")"
INSTANCE_ZONE="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")"
INSTANCE_ZONE="${INSTANCE_ZONE##*/}"
DATE_TIME="$(date "+%s")"
echo "$(gcloud compute disks snapshot ${DEVICE_NAME} --snapshot-names gcs-${DEVICE_NAME}-${DEVICE_ID}-${DATE_TIME} --zone ${INSTANCE_ZONE})"


# DELETE OLD SNAPSHOTS (OLDER THAN 7 DAYS)

SNAPSHOT_LIST="$(gcloud compute snapshots list --regexp "(.*gcs-.*)|(.*-${DEVICE_ID}-.*)" --uri)"

echo "${SNAPSHOT_LIST}" | while read line ; do

   SNAPSHOT_NAME="${line##*/}"
   SNAPSHOT_DATETIME="$(gcloud compute snapshots describe ${SNAPSHOT_NAME} | grep "creationTimestamp" | cut -d " " -f 2 | tr -d \')"
   SNAPSHOT_DATETIME="$(date -d ${SNAPSHOT_DATETIME} +%Y%m%d)"
   SNAPSHOT_EXPIRY="$(date -d "-7 days" +"%Y%m%d")"
if [ $SNAPSHOT_EXPIRY -ge $SNAPSHOT_DATETIME ];
        then
         echo "$(gcloud compute snapshots delete ${SNAPSHOT_NAME} --quiet)"
   fi
done