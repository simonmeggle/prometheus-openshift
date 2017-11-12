TODO:
* NodeExporter
* Grafana Dashboard Import
* shellscript aufräumen
* cadvisor (https://www.robustperception.io/openshift-and-prometheus/) vs kube-state-metrics
* node exporter
* ifconfig-Hack von Robo
eingerschränkter RAM innerhalb Limit

Michael:
  * haproxy (1/1 up) vs. kubernetes-service-endpoints (0/1 up) -  ist das der gleiche Router?
  * Welche FS in den node-exporter reinhängen 




https://github.com/rbo/oc-cluster/blob/master/up



Vortrag:
  * https://blog.openshift.com/wp-content/uploads/Prometheus-OpenShift-Commons-Briefing-1.pdf
  * Sakuli
  * keine Prozessüberwachungen


## Kubernetes Servicediscovery:

https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config

Automatisches Ermitteln von Scrape targets über die Kubernetes REST API

Rollentypen:
  * node: ein Target pro Clusternode
    * Adresse -> Kubelet HTTP port
  * service: ein Target pro Service (="Blackbox Exporter")
    * Adresse -> Service DNS name
  * pod: ein Target pro Pod
  * endpoint:
  * ingress
  *



## NodeExporter
Node Exporter als Daemon Set



## Routers
Router laufen im default namespace!

der router-exporter wird nicht mehr benötigt; /metrics spuckt gleich Prometheus-Daten aus


Damit der admin alles sehen darf:
oc adm policy add-cluster-role-to-user cluster-admin admin
