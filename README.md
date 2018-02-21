Monitoring OpenShift with Prometheus, Node-Exporter, Kube-State-Metrics / visualization by Grafana

# Version overview
This project was build upon the following components:
* OpenShift 3.7.1 
* Prometheus 2.1.0  
* Grafana 5.0.0-beta4
* Kube-state-metrics 1.1.0
* Node-Exporter 0.15.2

# Testing on minishift
```
minishift start --memory 8GB --openshift-version v3.7.1
```
## Grant permissions for developer to see everything in minishift's console
```
oc adm policy add-cluster-role-to-user cluster-admin developer
```

# Deployment steps

## Firewall 
see https://github.com/wkulhanek/openshift-prometheus/tree/master/node-exporter

## Deploy base components
Because we set some cluster-reader role-bindings, we need to login as a cluster-admin:
```
oc login -u system:admin
```

In the next step we instantiate the project, in this case "monitoring". 
```
oc new-project monitoring
```

Next we import readymade Grafana-dashboards into a ConfigMap:
```
oc create configmap dashboards-grafana --from-file=dashboards/
```

In the next step we create the monitoring componentes based on a template:
```
oc new-app -p NAMESPACE=monitoring -f monitoring-template.yaml
```
Alternative command:
```
oc process -p NAMESPACE=monitoring -f monitoring-template.yaml | oc apply -f -
```

After this step, you'll have Prometheus, Grafana and kube-state-metrics running.

## Deploy node-exporter

The optional node-exporter component may be installed as a daemon set to gather host level metrics. It requires additional privileges to view the host and should only be run in administrator controlled namespaces.

### Optional: ignore the project limits
Without deleteing or changing the limits, sometimes not all nodes can be scheduled.
```
# oc export limits default-limits -o yaml > default_limits.yaml
oc delete limitrange default-limits
# oc export quota default-quota -o yaml > deault_quota.yaml
oc delete quota default-quota
```

### Ignore the default node selector so that node-exporters can run on _every_ node
```
oc annotate ns monitoring openshift.io/node-selector= --overwrite
```

### Deploy node-exporter DaemonSet
```
oc create -f node-exporter.yaml
```

### Allow privileged execution of node-exporter
```
oc adm policy add-scc-to-user -z prometheus-node-exporter -n monitoring hostaccess
```

# Notes: 
```
# show events sorted
oc get events --sort-by='.lastTimestamp'
# show cluster wide objects
oc get ds --all-namespaces
# wide output
oc get pods -o wide
# poor man's oc dashboard
watch -n 1 "echo '###pods';oc get pods; echo '###dc'; oc get dc; echo '###ds'; oc get ds; echo '###svc'; oc get svc; echo '###configmap'; oc get configmap; echo '###routes'; oc get routes"
# access minishift pv's
minishift ssh
sudo su -
cd /var/lib/minishift/openshift.local.pv
```

# FIXME
* k-s-m does not seem to export deployment metrics on openshift
* k-s-m does not provide kube_resourcequota used in dashboard "Cluster overview"
* check rule evaluation and its graph on the prometheus dashboard

# TODO
* use StatefulSet ?
* livenessProbe and/or readinessProbe
* Add rules from https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus/assets/prometheus/rules
* document template variables in readme
* add remote_write for prometheus?
* can storage limits/requests be calculated?
* add alertmanager or add parameter to specify an alertmanager url?
* parameters for grafana credentials?
* redeploy on configmap change (maybe https://github.com/aabed/kubernetes-configmap-rollouts)
  or https://github.com/coreos/prometheus-operator/tree/master/contrib/prometheus-config-reloader
  or https://github.com/jimmidyson/configmap-reload
* easier configmap changes
* oauth proxies for grafana/prometheus
