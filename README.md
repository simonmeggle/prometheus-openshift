OPENSHIFT 3.6.1 
Prometheus 2.1.0  
Grafana 4.6.3
Kube-state-metrics 1.2.0
Node-Exporter 0.15.2


# Firewall 9100 (all nodes)
# https://github.com/wkulhanek/openshift-prometheus/tree/master/node-exporter


oc login -u system:admin
oc new-project monitoring

### ignore the project limits
# oc export limits default-limits -o yaml > default_limits.yaml
oc delete limitrange default-limits
# oc export quota default-quota -o yaml > deault_quota.yaml
oc delete quota default-quota

### create service accounts
oc create serviceaccount prometheus
oc create serviceaccount kube-state-metrics
oc create serviceaccount grafana
oc create serviceaccount node-exporter

### optional
oc adm policy add-cluster-role-to-user cluster-admin admin

### allow containers to run with root user
oc adm policy add-scc-to-user anyuid -z prometheus
oc adm policy add-scc-to-user anyuid -z grafana

### allow privileged execution of node-exporter
oc adm policy add-scc-to-user privileged -z node-exporter

### allow Prometheus and k-s-m to read cluster metrics
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:prometheus
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:monitoring:kube-state-metrics

### ignore the default node selector so that node-exporters can run on _every_ node
oc annotate ns monitoring openshift.io/node-selector= --overwrite

### ROLLOUT ###
oc apply -f obj/01-prometheus.yaml
oc apply -f obj/02-grafana.yaml
oc apply -f obj/03-node-exporter.yaml
oc apply -f obj/04-kube-state-metrics.yaml

#------
NOTES: 
oc get events --sort-by='.lastTimestamp'
oc get ds --all-namespaces
oc get pods -o wide
watch -n 1 "echo '###pods';oc get pods; echo '###dc'; oc get dc; echo '###ds'; oc get ds; echo '###svc'; oc get svc; echo '###configmap'; oc get configmap; echo '###routes'; oc get routes"

#-----
ISSUES:
- k-s-m does not seem to export deployment metrics on openshift

#-----
Dashboards: 
X Kubernetes Pod Metrics (#747)
  - kube_pod_status_phase wird nicht richtig ausgewertet
  - Templating Namespace
X Kubernetes Deployment (#3137)
  - kube-state-metrics liest keine deployment-Metriken aus

O Prometheus Stats 2.0 (direkt von Grafana-Projekt)
O Kubernetes Pod Resources (#737)
  - Detaillierter als 3146, aber kein Templating auf Pods-Ebene
O Kubernetes Pods (#3146)
  - nicht sehr detailliert, aber Templating auf Pod-Ebene
  - bietet keinen Mehrwert zu K.Pod Resources
O K8 Cluster Overview (#3870)
  - Labels angepasst 
O Project Metrics with Limits (basierend auf 1471)
O Kubernetes Netstat  (#3259)
  - sehr umfangreiche Netzwerkstatistiken
O Kubernetes Nodes (#3140)
O Kubernetes requested vs. allocated Ressources (#3149)
  - CPU/Memory allocation im Cluster 
