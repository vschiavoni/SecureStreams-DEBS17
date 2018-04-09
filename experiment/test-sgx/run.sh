#!/usr/bin/env bash

export NETWORK=xp
export DOCKER_HOST=:2381

echo "Check if network exist..."
docker network ls | grep -e "\s$NETWORK\s"

case "$?" in
  0)
    echo "So cool!"
    ;;
  1)
    echo "Network does not exist, we gonna make it appear..."
    docker network create $NETWORK
    ;;
  *)
    echo "WTF...?!"
    ;;
esac

echo "Update docker images"
docker-compose pull

function slack_notify {
  ../../slack-notifier/notifier.sh $1
}

function clean {
  echo "Remove containers from a previous XP if exist..."
  docker-compose stop
  docker-compose rm -f
}

function run_xp {
  clean;

  mkdir -p output
  mkdir -p logs
  echo 'Clean routing logs...'
  rm -f logs/*

  echo 'Run store_stats.rb'
  ../../store_stats/store_stats.rb &> store-stats.log &
  store_stats_pid=$!

  WORKERS=${WORKERS:-1}
  SGX_FACTOR=${SGX_FACTOR:-1}
  echo "Use $WORKERS regular worker(s) and $((WORKERS * SGX_FACTOR)) sgx worker(s)"

  echo 'Let’s experiment!'
  docker-compose scale routerdatamapper=1 routermapperfilter=1 routerfilterreduce=1 routerreduceprinter=1
  docker-compose scale mappersgx=$((WORKERS * SGX_FACTOR)) filter=$WORKERS reduce=$WORKERS

  docker-compose scale data1=1 data2=1 data3=1 data4=1
  #docker-compose scale data=1

  slack_notify "Run XP $i/$N with $WORKERS regular worker(s) and $((WORKERS * SGX_FACTOR)) SGX worker(s)\n\`\`\`$(docker ps | sed 's/$/\\n/')\`\`\`"
  docker-compose up printer
  slack_notify "XP $i/$N done!"

  echo 'Stop store_stats.rb'
  kill $store_stats_pid 2>> store-stats.log || echo "Failed at $(date)"
}

for WORKERS in 1 2 4
do
  export RESULT_OUTPUT=results-$WORKERS-workers.dat
  echo "Run XPs with $WORKERS worker(s), output: $RESULT_OUTPUT"

  for i in `seq 1 ${N:-5}`
  do
    echo "Run XP #$i/$N..."
    run_xp;
  done
done

clean;

slack_notify "All XPs have been done! :party:"
