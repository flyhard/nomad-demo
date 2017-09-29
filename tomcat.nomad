job "tomcat" {
  datacenters = [ "dc1" ]

  meta {
    tomcat_version = "8.5.16"
  }

  type        = "service"
  # constraint {
  #   attribute = "${attr.kernel.name}"
  #   value     = "linux"
  # }

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert      = false
    canary           = 1
  }

  group "tomcat" {

    count = 2

    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    ephemeral_disk {
      # When sticky is true and the task group is updated, the scheduler
      # will prefer to place the updated allocation on the same node and
      # will migrate the data. This is useful for tasks that store data
      # that should persist across allocation updates.
      # sticky = true
      #
      # Setting migrate to true results in the allocation directory of a
      # sticky allocation directory to be migrated.
      # migrate = true

      # The "size" parameter specifies the size in MB of shared ephemeral disk
      # between tasks in the group.
      size = 300
    }

      task "tomcat" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "raw_exec"

      # The "config" stanza specifies the driver configuration, which is passed
      # directly to the driver to start the task. The details of configurations
      # are specific to each driver, so please see specific driver
      # documentation for more information.
      config {
        command = "apache-tomcat-8.5.16/bin/catalina.sh"
        args    = [ "run" ]
      }


      artifact {
        source = "http://apache.mirror.anlx.net/tomcat/tomcat-8/v8.5.16/bin/apache-tomcat-8.5.16.tar.gz"
        options {
          checksum = "sha1:6ae7b007fc17eb2821585e2651edaca90708a75b"
        }
      }

    artifact {
      source      = "https://s3-eu-west-1.amazonaws.com/web-bucket-pabich/server.xml.tpl"
      mode        = "file"
      destination = "local/server.xml.tpl"
    }

    artifact {
      source      = "https://github.com/bdclark/docker-tomcat-consul/raw/master/tomcat/conf/tomcat-users.xml.ctmpl"
      mode        = "file"
      destination = "local/tomcat-users.xml.ctmpl"
    }


    # logs {
      #   max_files     = 10
      #   max_file_size = 15
      # }


      resources {
        cpu    = 500
        # 500 MHz
        memory = 300
        # 256MB
        network {
          mbits = 10
          port "shutdown" {}
          port "http" {}
          port "https" {}
          port "ajp" {}
        }
      }


      service {
        name = "tomcat-test"
        tags = [ "tomcat","web" ]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
        check {
          name     = "HTTP UP"
          type     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "2s"
        }
      }

      # The "template" stanza instructs Nomad to manage a template, such as
      # a configuration file or script. This template can optionally pull data
      # from Consul or Vault to populate runtime configuration data.
      #
      # For more information and examples on the "template" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/template.html
      #
      template {
        source      = "local/server.xml.tpl"
        destination = "local/apache-tomcat-8.5.16/conf/server.xml"
      }

      # The "template" stanza can also be used to create environment variables
      # for tasks that prefer those to config files. The task will be restarted
      # when data pulled from Consul or Vault changes.
      #
      # template {
      #   data        = "KEY={{ key \"service/my-key\" }}"
      #   destination = "local/file.env"
      #   env         = true
      # }

      # The "vault" stanza instructs the Nomad client to acquire a token from
      # a HashiCorp Vault server. The Nomad servers must be configured and
      # authorized to communicate with Vault. By default, Nomad will inject
      # The token into the job via an environment variable and make the token
      # available to the "template" stanza. The Nomad client handles the renewal
      # and revocation of the Vault token.
      #
      # For more information and examples on the "vault" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/vault.html
      #
      # vault {
      #   policies      = ["cdn", "frontend"]
      #   change_mode   = "signal"
      #   change_signal = "SIGHUP"
      # }

      # Controls the timeout between signalling a task it will be killed
      # and killing the task. If not set a default is used.
      # kill_timeout = "20s"
    }
  }
}
