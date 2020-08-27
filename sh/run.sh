#!/bin/bash

#deploy shell script 2020-09

############################################ Start of configuration 

# jar name
JAR_NAME=app.jar

#self File name
PROG_NAME=$0

#args
ACTION=$1

# Time to wait for the application to start
APP_START_TIMEOUT=100

APP_PORT=8080

#run directory
APP_HOME=/app

#Absolute path to jar
JAR_PATH=${APP_HOME}/${JAR_NAME}

#Absolute path to start log
LOG_FILE_PATH=${APP_HOME}/logs/start.log

PID_FILE=${APP_HOME}/pid

HEALTH_CHECK_URL=http://127.0.0.1:${APP_PORT}/app/status

INSTANCE_NAME=${SERVER_NAME}
DOMAIN_NAME=${SERVER_DOMAIN}

########################################### End of configuration 

# Create non-existent directory
mkdir -p ${APP_HOME}/
mkdir -p ${APP_HOME}/logs

usage() {
  echo "Usage: $PROG_NAME {start|stop|restart|log|deploy|debug}"
  exit 2
}

health_check() {
  exptime=0
  echo "checking ${HEALTH_CHECK_URL}"
  while true; do
    status_code=$(/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w %{http_code} ${HEALTH_CHECK_URL})
    if [[ "$?" != "0" ]]; then
      echo -n -e "-------application not started"
      echo -n -e "\nThe log is as follows:\n"
      tail -n30 ${LOG_FILE_PATH}
    else

      echo "Log: "
      tail -n30 ${LOG_FILE_PATH}

      echo "code is $status_code"

      break
      if [[ "$status_code" == "200" ]]; then
        break
      fi
    fi
    sleep 2
    ((exptime++))

    echo -e "-------Wait app to pass health check: $exptime..."

    if [[ ${exptime} -gt ${APP_START_TIMEOUT} ]]; then
      echo 'app start failed'
      exit 1
    fi
  done
  echo "check ${HEALTH_CHECK_URL} success"
}
start_application() {
  echo "starting java process ${JAR_NAME}"
  echo "instance name: ${INSTANCE_NAME}"
  echo "domain name: ${DOMAIN_NAME}"
  nohup java -jar ${JAR_PATH} >${LOG_FILE_PATH} 2>&1 &
  echo $! >${PID_FILE}
  echo "started java process ${JAR_NAME}"
}

debug() {
  echo "starting java process ${JAR_NAME}"
  echo "instance name: ${INSTANCE_NAME}"
  echo "domain name: ${DOMAIN_NAME}"
  nohup java -jar ${JAR_PATH} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 >${LOG_FILE_PATH} 2>&1 &
  echo $! >${PID_FILE}
  echo "started java process ${JAR_NAME}"
}

stop_application() {
  checkjavapid=$(ps -ef | grep java | grep ${JAR_NAME} | grep -v grep | grep -v $0 | awk '{print$2}')

#  if [ ! -f "$PID_FILE" ]; then
 #   echo -e "-------Application is already stopped"
 #   return
 # fi
  if [[ ! ${checkjavapid} ]]; then
    echo -e "------- Application is already stopped"
    return
  fi
 
  echo "stoping java process"
  times=60
  for e in $(seq 60); do
    sleep 1
    COSTTIME=$(($times - $e))
    checkjavapid=$(ps -ef | grep java | grep ${JAR_NAME} | grep -v grep | grep -v 'deploy.sh' | awk '{print$2}')
    if [[ ${checkjavapid} ]]; then
      kill -9 ${checkjavapid}
      echo -e "------- stopping java lasts $(expr $COSTTIME) seconds."
    else
      echo -e "------- Application  stopped"
      break
    fi
  done
  echo ""
}
start() {
  start_application
}
starttest() {
  echo "starting test ${JAR_NAME}"
  echo "instance name: ${INSTANCE_NAME}"
  echo "domain name: ${DOMAIN_NAME}"
  nohup java -jar ${JAR_PATH} >${LOG_FILE_PATH} 2>&1 &
 # echo $! >${PID_FILE}
  echo "started java process ${JAR_NAME}"
}
stop() {
  stop_application
}

log() {
  tail -f -n3000 ${LOG_FILE_PATH} | perl -pe's/(INFO)|(DEBUG)|(WARN)|(ERROR)|(^[0-9-:.\s]{10,23})|((?<=[OGNR]\s)[0-9]{1,5})|((?<=\[.{15}\]\s).{1,40}(?=\s(:\s)|\s))/\e[1;32m$1\e[0m\e[1;36m$2\e[0m\e[1;33m$3\e[0m\e[1;31m$4\e[0m\e[1;34m$5\e[0m\e[1;35m$6\e[0m\e[1;36m$7\e[0m/g'
}

deploy() {
  echo "Starting deployment========"

}
case "$ACTION" in
start)
  start
  ;;
starttest)
  starttest
  ;;
debug)
  debug
  ;;  
stop)
  stop
  ;;
restart)
  stop
  start
  ;;
log)
  log

  ;;
deploy)
  deploy
  ;;
*)
  usage
  ;;
esac
