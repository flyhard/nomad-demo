job "hashiui" {

  datacenters = [ "dc1" ]

  type        = "service"

  update {

    max_parallel     = 1

    min_healthy_time = "10s"

    healthy_deadline = "3m"

    auto_revert      = false

    canary           = 1
  }

  group "ui" {
    count = 3

    restart {

      attempts = 10
      interval = "5m"

      delay    = "25s"

      mode     = "delay"
    }

    ephemeral_disk {

      size = 300
    }


    task "ui" {

      driver = "raw_exec"

      config {
        command = "hashi-ui-darwin-amd64"
        args    = [
          "--nomad-enable",
          "--consul-enable",
          "-listen-address",
          "${NOMAD_ADDR_UI}"]
      }

      artifact {
        source = "https://github.com/jippi/hashi-ui/releases/download/v0.14.0/hashi-ui-darwin-amd64"
      }

      resources {
        cpu    = 100
        # 500 MHz
        memory = 70
        # 256MB
        network {
          mbits = 10
          port "UI" {}
        }
      }

      service {
        name = "hashi-ui"
        tags = [ "global", "ui", "web","urlprefix-localhost:8080/"  ]
        port = "UI"
        check {
          name     = "tcp alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
        check {
          name     = "http check ok"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        data        = "---\nkey: {{ with secret \"secret/hello\" }}{{ .Data.value }}{{ end }}\n"
        destination = "local/file.yml"
        change_mode = "noop"
      }

      vault {
        policies    = [ "default", "secret" ]
        change_mode = "noop"
      }

      # Controls the timeout between signalling a task it will be killed
      # and killing the task. If not set a default is used.
      # kill_timeout = "20s"
    }
  }
}
