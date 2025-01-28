resource "kubectl_manifest" "high_priority_apps" {
  count     = var.cluster_created ? 1 : 0
  yaml_body = <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority-apps
value: 100
globalDefault: true
preemptionPolicy: PreemptLowerPriority
description: "Priority class for high priority applications."
EOF
}

resource "kubectl_manifest" "low_priority_apps" {
  count     = var.cluster_created ? 1 : 0
  yaml_body = <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority-apps
value: 50
globalDefault: false
preemptionPolicy: Never
description: "Priority class for low priority applications."
EOF
}

resource "kubectl_manifest" "extra_capacity_deployment" {
  yaml_body = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: extra-capacity
  labels:
    app: extra-capacity
spec:
  replicas: ${var.placeholder_pods}
  selector:
    matchLabels:
      app: extra-capacity
  template:
    metadata:
      labels:
        app: extra-capacity
    spec:
      priorityClassName: low-priority-apps
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 500m
            memory: 2000Mi
EOF
}
