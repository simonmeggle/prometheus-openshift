#!/usr/bin/env bash
# inspired by https://github.com/he1nh/openshift-prometheus


. .customvars.env

echo "Project: $PROJECTNAME ($PROJECTDESC)"
OSENV="$HOME/apps/oc/data/$CLUSTERNAME"

function main() {
  echo "Please choose a cluster action: "
  select ans in "Create" "Remove" "Rebuild" "Abort"; do
      case $ans in
          Create ) createCluster
                   exit;;
          Remove ) removeCluster
                   exit;;
          Rebuild) removeCluster
                   createCluster
                   exit;;
          Abort)   exit;;
          *)       exit;;
      esac
  done
}

function waitForURL() {
  URL=$1
  for x in $(seq 120); do
    curl --silent $URL | grep -q "Found" && echo "OK" && return
    printf "."
    sleep 1
  done
  echo "URL did not respond within 120 seconds. Aborting."
  exit 1
}


function removeCluster() {
  echo "Shutting down cluster..."
  oc cluster down
  echo "Removing local data dirs..."
  rm -rf "$OSENV"
  docker stop $(docker ps -qa | grep -v `docker ps --filter=ancestor=registry:2 -q`)
  docker rm $(docker ps -qa | grep -v `docker ps --filter=ancestor=registry:2 -q`)
}

function createCluster() {

  [ -x $(which oc) ] || { echo "oc client not found." 1>&2 ; exit 1; }

  oc project $PROJECTNAME 2>&1 > /dev/null
  if [ "$?" != "0" ]; then
    echo "Project $PROJECTNAME does not yet exist."
    echo "Using openshift data space 'OSENV': $OSENV"
    mkdir -p $OSENV/config
    mkdir -p $OSENV/data
    mkdir -p $OSENV/vol

    echo "+ create oc cluster for $OSENV"
    oc cluster up \
       --use-existing-config=true \
       --host-config-dir=$OSENV/config \
       --host-data-dir=$OSENV/data \
       --host-pv-dir=$OSENV/vol
      #   \
      #  --public-hostname=$(hostname)

    # create the project:
    echo "+ creating project $PROJECTNAME"
    oc new-project $PROJECTNAME --display-name="$PROJECTDESC"
  fi

  echo "+ creating serviceaccounts"
  oc create serviceaccount prometheus
  oc create serviceaccount kube-state-metrics
  oc create serviceaccount grafana
  oc create serviceaccount node-exporter

  oc login -u system:admin

  oc adm policy add-cluster-role-to-user cluster-admin admin


  echo "+ assigning security context constraints to service accounts"
  oc adm policy add-scc-to-user anyuid -z prometheus
  oc adm policy add-scc-to-user anyuid -z grafana
  oc adm policy add-scc-to-user privileged -z node-exporter
  echo "+ reading HAproxy stats auth credentials"
  # HAPROXY_PORT=$(oc set env dc router -n default --list | grep STATS_PORT | awk -F"=" '{print $2}')
  HAPROXY_STATS_USERNAME=$(oc set env dc router -n default --list | grep STATS_USERNAME | awk -F"=" '{print $2}'  )
  HAPROXY_STATS_PASSWORD=$(oc set env dc router -n default --list | grep STATS_PASSWORD | awk -F"=" '{print $2}'  )

  echo "+ adding cluster-role 'cluster-reader' to user prometheus in namespace 'default'"
  oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:prometheus
  oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:kube-state-metrics
  oc login -u developer -u developer -n $PROJECTNAME

  echo "+ deploying Prometheus..."
  oc process -f obj/01-prometheus.yaml -p HAPROXY_STATS_USERNAME=$HAPROXY_STATS_USERNAME -p HAPROXY_STATS_PASSWORD=$HAPROXY_STATS_PASSWORD | oc apply -f -

  echo "+ deploying Grafana..."
  oc apply -f obj/02-grafana.yaml

  echo "+ deploying Node-Exporter..."
  oc login -u system:admin
  oc apply -f obj/04-node-exporter.yaml



  PROMETHEUS_URL="http://"$(oc get route prometheus --template='{{ .spec.host }}')
  echo "Waiting for the Prometheus URL coming available: ${PROMETHEUS_URL}"
  waitForURL $PROMETHEUS_URL

  GRAFANA_URL="http://"$(oc get route grafana --template='{{ .spec.host }}')
  echo "Waiting for the Grafana URL coming available: ${GRAFANA_URL}"
  waitForURL $GRAFANA_URL

  echo "Importing Prometheus-datasource for Grafana"
  DATASOURCE=$(cat <<EOF
  {
    "name":"prometheus",
    "type":"prometheus",
    "url":"${PROMETHEUS_URL}",
    "access":"direct",
    "basicAuth": false
  }
EOF
)

  curl -u admin:admin --silent --fail --show-error \
    --request POST ${GRAFANA_URL}/api/datasources \
    --header "Content-Type: application/json" \
    --data-binary "${DATASOURCE}"

  # DASHBOARDS=( 22 737 )
  # for D in ${DASHBOARDS[@]}; do
  # echo "Importing Dashboard https://grafana.com/dashboards/${D}"
  # curl -u admin:admin --silent --fail --show-error \
  #   --request POST ${GRAFANA_URL}/api/dashboards/db \
  #   --header "Content-Type: application/json" \
  #   --data-binary "@./grafana_dashboards/${D}.json"
  # done

}

main

# until kctl get customresourcedefinitions servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
