#!/bin/bash

PROVIDER_URI="http://user:password@localhost:8332"
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
purge_data() {
  rm transactions.json blocks.json enriched_transactions.json
}

ps aux | pgrep start_bitcoind | grep -q -v grep
BITCOIND_STATUS=$?
if [ $BITCOIND_STATUS -ne 0 ]; then
  echo "Starting bitcoin daemon..."
  ./start_bitcoind.sh -D
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start bitcoin-etl process: $status"
    exit $status
  fi
fi

export last_block=0
while sleep 1; do
  block_count="$(bitcoin-cli -rpcuser=user -rpcpassword=password -rpcport=8332 getblockcount)"
  if ((block_count > ((last_block + 15)))); then
    echo "Processing start for block range $((last_block + 1))-$((last_block + 10))"
    bitcoinetl export_blocks_and_transactions --start-block "$((last_block + 1))" --end-block "$((last_block + 10))" \
      --provider-uri $PROVIDER_URI --chain bitcoin --blocks-output blocks.json --transactions-output transactions.json &&
    bitcoinetl enrich_transactions --provider-uri $PROVIDER_URI --transactions-input transactions.json \
      --transactions-output enriched_transactions.json &&
    python3 bitcoin_to_rabbitmq_exporter.py &&
    purge_data &&
    export last_block=$((last_block + 10))
  fi
done
