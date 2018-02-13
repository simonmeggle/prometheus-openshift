Monitoring OpenShift with Prometheus, Node-Exporter, Kube-State-Metrics / visualization by Grafana

# Version overview
This project was build upon the following components:
* OpenShift 3.6.1 
* Prometheus 2.1.0  
* Grafana 4.6.3
* Kube-state-metrics 1.2.0
* Node-Exporter 0.15.2

# Deployment steps

## Firewall 
see https://github.com/wkulhanek/openshift-prometheus/tree/master/node-exporter

## setup project 
```
oc login -u system:admin
oc new-project monitoring
```
## optional: ignore the project limits
```
# oc export limits default-limits -o yaml > default_limits.yaml
oc delete limitrange default-limits
# oc export quota default-quota -o yaml > deault_quota.yaml
oc delete quota default-quota
```
## create service accounts
```
oc create serviceaccount prometheus
oc create serviceaccount kube-state-metrics
oc create serviceaccount grafana
oc create serviceaccount node-exporter
```
## optional: make admin the cluster admin for a full overview with `oc get`
```
oc adm policy add-cluster-role-to-user cluster-admin admin
```
## allow containers to run with root user
```
oc adm policy add-scc-to-user anyuid -z prometheus
oc adm policy add-scc-to-user anyuid -z grafana
```
## allow privileged execution of node-exporter
```
oc adm policy add-scc-to-user privileged -z node-exporter
```
## allow Prometheus and k-s-m to read cluster metrics
```
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:prometheus
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:kube-state-metrics
```
## ignore the default node selector so that node-exporters can run on _every_ node
```
oc annotate ns monitoring openshift.io/node-selector= --overwrite
```
## ROLLOUT ###
```
oc apply -f obj/01-prometheus.yaml
oc apply -f obj/02-grafana.yaml
oc apply -f obj/03-node-exporter.yaml
oc apply -f obj/04-kube-state-metrics.yaml
```

# Grafana dashboards
## import dashboards
To import the project's dashboards (see list below): 
* Grafana-Button
* "Dashboards"
* "import"
* "Paste JSON"

## save dashboard adaptions
Any change in the Grafana dashboards should be saved in Grafana as well as JSON: 
* "Share Dashboard"
* "Export"
* "Save to file" (do *not* use "View JSON", because the data will contain all cluster internal data like node names, IP addresses, pod names etc. as well)
* save to the file in `/dashboards`

# some notes: 
```
# show events sorted
oc get events --sort-by='.lastTimestamp'
# show cluster wide objects
oc get ds --all-namespaces
# wide output
oc get pods -o wide
# poor man's oc dashboard
watch -n 1 "echo '###pods';oc get pods; echo '###dc'; oc get dc; echo '###ds'; oc get ds; echo '###svc'; oc get svc; echo '###configmap'; oc get configmap; echo '###routes'; oc get routes"
```
# Issues
* k-s-m does not seem to export deployment metrics on openshift

# Dashboard notes
(X = not used, O = used)

O `prometheus_20_stats.json` - Prometheus Stats 2.0 (from the Grafana-Project)

O `kubernetes_pod_resources.json` - Kubernetes Pod Resources (#737)
  - more detailled than #3146, but without Templating for pods 
  
O `kubernetes_openshift_cluster_overview_edited.json` - K8 Cluster Overview (#3870)
  - adapted labels
  
O `kubernetes_project_metrics_w_limits.json` - Project Metrics with Limits (based on #1471)

O `kubernetes_netstat.json` - Kubernetes Netstat  (#3259)
  - very detailled
  
O `kubernetes_nodes.json` - Kubernetes Nodes (#3140)

O `kubernetes_req_vs_all_resources.json` - Kubernetes requested vs. allocated Ressources (#3149)
  - CPU/Memory allocation within Cluster 

X Kubernetes Pod Metrics (#747)
  - kube_pod_status_phase not evaluated correctly
  - Templating Namespace
  
X Kubernetes Deployment (#3137)
  - useless without deployment metrics from k-s-m
  
X Kubernetes Pods (#3146)
  - not very detailled, but Templating for pods
