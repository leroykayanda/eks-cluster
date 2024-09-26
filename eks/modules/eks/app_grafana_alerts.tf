resource "grafana_folder" "rule_folder" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  title = var.env
}

resource "grafana_rule_group" "node_memory" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "node_memory"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Node Memory Usage"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"PBFA97CFB590B2093\"},\"editorMode\":\"code\",\"expr\":\"(sum(container_memory_working_set_bytes{id=\\\"/\\\"}) by (instance) / sum(machine_memory_bytes) by (instance)) * 100\",\"interval\":\"10s\",\"intervalFactor\":1,\"intervalMs\":30000,\"legendFormat\":\"{{instance}}\",\"maxDataPoints\":100,\"range\":true,\"refId\":\"A\",\"step\":10}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"mean\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[90],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "4"
      description      = ""
      runbook_url      = ""
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "node_cpu" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "node_cpu"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Node CPU Usage"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"PBFA97CFB590B2093\"},\"editorMode\":\"code\",\"expr\":\"100 * (1 - avg(rate(node_cpu_seconds_total{mode=\\\"idle\\\"}[5m])) by (node))\",\"interval\":\"10s\",\"intervalFactor\":1,\"intervalMs\":15000,\"legendFormat\":\"{{node}}\",\"maxDataPoints\":100,\"range\":true,\"refId\":\"A\",\"step\":10}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"mean\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[90],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "6"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "node_disk" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "node_disk"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Node Disk Usage"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"PBFA97CFB590B2093\"},\"editorMode\":\"code\",\"exemplar\":false,\"expr\":\"100 - (\\n  node_filesystem_avail_bytes{mountpoint=\\\"/\\\", fstype!~\\\"tmpfs|nfs|rpc_pipefs\\\"}\\n    / node_filesystem_size_bytes{mountpoint=\\\"/\\\", fstype!~\\\"tmpfs|nfs|rpc_pipefs\\\"} * 100\\n)\",\"instant\":false,\"interval\":\"10s\",\"intervalFactor\":1,\"intervalMs\":15000,\"legendFormat\":\"{{node}}\",\"maxDataPoints\":100,\"metric\":\"\",\"range\":true,\"refId\":\"A\",\"step\":10}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[90],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "7"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "node_condition" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "node_condition"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Failed Worker Nodes"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"datasource\":{\"type\":\"prometheus\",\"uid\":\"PBFA97CFB590B2093\"},\"editorMode\":\"code\",\"exemplar\":true,\"expr\":\"sum(kube_node_status_condition{condition=\\\"Ready\\\",status!=\\\"true\\\"})\",\"instant\":false,\"interval\":\"\",\"intervalMs\":15000,\"legendFormat\":\"\",\"maxDataPoints\":43200,\"range\":true,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"max\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"

    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "2m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "63"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "container_mem_limit_use" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "container_mem_limit_use"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "High Container Memory Limit Usage"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"sum(container_memory_working_set_bytes{image!=\\\"\\\"})  by (container) / sum(kube_pod_container_resource_limits{resource=\\\"memory\\\"})  by (container)\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"mean\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0.9],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "52"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "container_cpu_limit_use" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "container_cpu_limit_use"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "High Container CPU Limit Usage"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"sum(rate(container_cpu_usage_seconds_total{image!=\\\"\\\"}[5m])) by (container) / sum(kube_pod_container_resource_limits{resource=\\\"cpu\\\"}) by (container)\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"mean\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0.9],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "51"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "container_oom" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "container_oom"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Container OutOfMemory"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"sum(increase(container_oom_events_total[5m])) by (namespace, pod) \",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "1m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "42"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "container_restarts" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "container_restarts"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Container Restarting"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"sum(increase(kube_pod_container_status_restarts_total[5m])) by (namespace, pod)\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "1m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "44"
      description      = ""
      runbook_url      = ""
    }
    labels = {

    }
    is_paused = false
  }
}


resource "grafana_rule_group" "pv_almost_full" {
  count = var.cluster_created && var.create_pv_full_alert && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "pv_almost_full"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 300

  rule {
    name      = "Persistent Volume Almost Full"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"sum by (persistentvolumeclaim) (kubelet_volume_stats_used_bytes/kubelet_volume_stats_capacity_bytes * 100)\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[70],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "36"
    }
    labels = {

    }
    is_paused = false
  }
}

resource "grafana_rule_group" "pod_not_ready" {
  count = var.cluster_created && var.metrics_type == "prometheus-grafana" ? 1 : 0
  depends_on = [
    helm_release.grafana
  ]
  org_id           = 1
  name             = "pod_not_ready"
  folder_uid       = grafana_folder.rule_folder[0].uid
  interval_seconds = 60

  rule {
    name      = "Pod not ready"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "PBFA97CFB590B2093"
      model          = "{\"editorMode\":\"code\",\"expr\":\"kube_pod_status_phase{phase=~\\\"(Pending|Failed|Unknown)\\\"} > 0\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"max\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "cdlpol5hdssg0c"
      __panelId__      = "45"
    }
    labels    = {}
    is_paused = false
  }
}
