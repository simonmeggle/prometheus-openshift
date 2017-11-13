TODO:

* Grafana Dashboards anpassen
*
* ifconfig-Hack von Robo
eingerschränkter RAM innerhalb Limit
* https://github.com/rbo/oc-cluster/blob/master/up
* Mysql Beispiel-Pod?
*  Dashboard: https://github.com/rfrail3/grafana-dashboards/tree/master/prometheus






## Monitoring-Targets:
* Node exporter: GRAFANA https://grafana.com/dashboards/405
  Node exporter is a Prometheus exporter for hardware and OS metrics expose UNIX kernels.

* Cadvisor sind schon drin

* DeploymentConfig mit kube-state-metrics: (Metriken: https://github.com/kubernetes/kube-state-metrics/tree/master/Documentation)
  kube-state-metrics is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects.
  Stellt alle API-Objekte als Prom. Metriken dar.

  "Der automatisierte Weg, beim debuggen mit kubectl oder oc get deployment den Status der Deplyments abzufragen. "
 https://github.com/kubernetes/kube-state-metrics, (II: https://www.weave.works/blog/monitoring-kubernetes-infrastructure/) Dashboard: https://grafana.com/dashboards/741
  Benutzt https://github.com/kubernetes/autoscaler/tree/master/addon-resizer

Container-Restarts: http://akrambenaissi.com/2017/08/monitoring-openshift-pod-restarts-with-prometheusalertmanager-and-kube-state-metrics

* Config diff mit kubediff: https://www.weave.works/blog/monitoring-kubernetes-infrastructure/

* Routers
Router laufen im default namespace!
der router-exporter wird nicht mehr benötigt; /metrics spuckt gleich Prometheus-Daten aus




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


Damit der admin alles sehen darf:
oc adm policy add-cluster-role-to-user cluster-admin admin
