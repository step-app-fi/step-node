#!/bin/sh
TMPFILE_RELAXED=$(mktemp)
TMPFILE_RESTRICTED=$(mktemp)
cp /root/.avalanchego/configs/chains-relaxed/$BLOCKCHAIN_ID_ENV/config.json ${TMPFILE_RELAXED}
cp /root/.avalanchego/configs/chains-restricted/$BLOCKCHAIN_ID_ENV/config.json ${TMPFILE_RESTRICTED}
cat ${TMPFILE_RELAXED} | envsubst > /root/.avalanchego/configs/chains-relaxed/$BLOCKCHAIN_ID_ENV/config.json
cat ${TMPFILE_RESTRICTED} | envsubst > /root/.avalanchego/configs/chains-restricted/$BLOCKCHAIN_ID_ENV/config.json
avalanchego $* 
