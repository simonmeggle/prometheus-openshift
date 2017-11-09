#!/usr/bin/env bash


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

    echo "create oc cluster for $OSENV"
    oc cluster up \
       --use-existing-config=true \
       --host-config-dir=$OSENV/config \
       --host-data-dir=$OSENV/data \
       --host-pv-dir=$OSENV/vol
      #   \
      #  --public-hostname=$(hostname)

    # create the project:
    echo "creating project $PROJECTNAME"
    oc new-project $PROJECTNAME --display-name="$PROJECTDESC"
  fi


  echo "creating serviceaccounts"
  oc create serviceaccount prometheus
  oc create serviceaccount grafana
  oc login -u system:admin
  echo "assigning sccs"
  oc adm policy add-scc-to-user anyuid -z prometheus
  oc adm policy add-scc-to-user anyuid -z grafana

  echo "adding cluster-role 'cluster-reader' to user prometheus in namespace 'default'"
  oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:prometheus
  oc login -u developer -u developer -n $PROJECTNAME

  echo "Deploying prometheus..."
  oc apply -f obj/01-prometheus.yaml

  #
  #
  #
  #
  # exit
  # oc secrets new-sshauth gitlab-ssh --ssh-privatekey=$(pwd)/.ssh/id_rsa
  #
  # oc login -u system:admin
  # # allows to list nodes
  # oc policy add-role-to-user cluster-admin system
  # # label the local node
  # oc label node localhost region="local"
  #
  # # any UID allowed for OMD-Container (needs root)
  # oc create sa rootcontainer
  # oc adm policy add-scc-to-user anyuid -z rootcontainer
  #
  # oc login -u developer -u developer
  #
  # # to allow OMD as sa "rootcontainer" to process tempates
  # oc policy add-role-to-user edit -z rootcontainer
  #
  # omd-nagios/create_omd_volumes.sh
  # omd-nagios/deploy_omd.sh
  #
  # sakuli-tests/trigger_sakuli_image_build.sh
}

main
