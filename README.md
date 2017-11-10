TODO:
* NodeExporter
* Grafana Dashboard Import
* shellscript aufräumen
* cadvisor (https://www.robustperception.io/openshift-and-prometheus/) vs kube-state-metrics


https://github.com/rbo/oc-cluster/blob/master/up


FRAGEN:
* Warum keine Service URL wenn offline?
* HAPROXY kann nicht angesprochen werden


Vortrag:
  * https://blog.openshift.com/wp-content/uploads/Prometheus-OpenShift-Commons-Briefing-1.pdf
  * Sakuli

## NodeExporter
Node Exporter als Daemon Set



## Routers
Router laufen im default namespace!


Damit der admin alles sehen darf: 
oc adm policy add-cluster-role-to-user cluster-admin admin
