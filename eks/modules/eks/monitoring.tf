resource "aws_cloudwatch_metric_alarm" "cluster_failed_node_count" {
  count               = var.metrics_type == "cloudwatch" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Kubernetes-Cluster-Failed-Node"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "This alarm triggers when a node is suffering from any node conditions."
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"
  tags                = var.tags

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_cpu_utilization" {
  count               = var.metrics_type == "cloudwatch" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Kubernetes-Cluster-High-Worker-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "This alarm triggers when there is high CPU usage by worker nodes"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "node_filesystem_utilization" {
  count               = var.metrics_type == "cloudwatch" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Kubernetes-Cluster-High-Worker-Disk-Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_filesystem_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Maximum"
  threshold           = 90
  alarm_description   = "This alarm triggers when there is high disk usage on worker nodes"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"
  tags                = var.tags

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_memory_utilization" {
  count               = var.metrics_type == "cloudwatch" ? 1 : 0
  alarm_name          = "${var.cluster_name}-Kubernetes-Cluster-High-Worker-Memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "This alarm triggers when there is high memory usage by worker nodes"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"
  tags                = var.tags

  dimensions = {
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_dashboard" "dash" {
  count          = var.metrics_type == "cloudwatch" ? 1 : 0
  dashboard_name = "${var.cluster_name}-kubernetes-cluster"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "period" : 60,
            "metrics" : [
              ["ContainerInsights", "cluster_failed_node_count", "ClusterName", "${var.cluster_name}"]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
            "title" : "Cluster Failed Node Count"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "view" : "singleValue",
            "sparkline" : true,
            "period" : 60,
            "metrics" : [
              ["ContainerInsights", "cluster_node_count", "ClusterName", "${var.cluster_name}"]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
            "title" : "Cluster Node Count"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, Namespace} MetricName=\"namespace_number_of_running_pods\" ClusterName=\"${var.cluster_name}\"', 'Maximum')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 60,
            "stat" : "Maximum",
            "title" : "Running Pods",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 6,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName,InstanceId, NodeName} MetricName=\"node_cpu_utilization\" ClusterName=\"${var.cluster_name}\"', 'Average')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "cpu_usage",
                  "value" : 90
                }
              ]
            },
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 60,
            "title" : "Node CPU Usage",
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 6,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, NodeName, InstanceId} MetricName=\"node_filesystem_utilization\" ClusterName=\"${var.cluster_name}\"', 'Maximum')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "disk_usage",
                  "value" : 90
                }
              ]
            },
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 300,
            "title" : "Node Disk Usage",
            "stat" : "Maximum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 6,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, NodeName, InstanceId} MetricName=\"node_memory_utilization\" ClusterName=\"${var.cluster_name}\"', 'Average')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "memory_usage",
                  "value" : 90
                }
              ]
            },
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 60,
            "title" : "Node Memory Usage",
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, NodeName, InstanceId} MetricName=\"node_number_of_running_pods\" ClusterName=\"${var.cluster_name}\"', 'Maximum')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 60,
            "title" : "Node Running Pods",
            "stat" : "Maximum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 6,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, PodName, Namespace} MetricName=\"pod_number_of_container_restarts\" ClusterName=\"${var.cluster_name}\"', 'Sum')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 300,
            "title" : "Container Restarts",
            "stat" : "Sum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 12,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SEARCH('{ContainerInsights, ClusterName, Service, Namespace} MetricName=\"service_number_of_running_pods\" ClusterName=\"${var.cluster_name}\"', 'Maximum')", "label" : "", "id" : "e1", "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "period" : 60,
            "title" : "Service Running Pods",
            "stat" : "Maximum"
          }
        }
      ]
    }
  )
}
#
