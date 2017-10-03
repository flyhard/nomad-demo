job "logging-elk" {
  datacenters = ["dc1"]
  type = "service"

//  constraint {
//    attribute = "${attr.kernel.name}"
//    value = "linux"
//  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  # - logging-elk - #
  group "logging-elk" {
  count = 1
    # - elasticsearch - #
    task "elasticsearch" {
      driver = "docker"

      config {
        image = "elasticsearch"
        hostname = "elasticsearch.service.local"
//        network_mode = "external"
//        dns_servers = ["172.17.0.1"]
//        dns_search_domains = ["weave.local."]
        logging {
          type = "json-file"
        }
        port_map {
          elasticsearch = 9200
        }
      }

      resources {
        memory = 3000
        network {
          mbits = 50
          port "elasticsearch" {}
        }
      }
      service {
        name="elasticsearch"
        tags=["urlprefix-elasticsearch.service.consul:9999/"]
        port = "elasticsearch"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    # - end elasticsearch - #

    # - kibana - #
    task "kibana" {
      driver = "docker"

      env{
        SERVER_NAME="kibana.local:9999"
        ELASTICSEARCH_URL="http://elasticsearch.service.consul:9999/"
      }
      config {
        image = "kibana"
        hostname = "elasticsearch.service.consul"
//        network_mode = "external"
//        dns_servers = ["127.0.0.1:8600"]
//        dns_search_domains = ["service.consul."]
        extra_hosts= ["elasticsearch.local:10.144.245.243"]
        logging {
          type = "json-file"
        }
        port_map {
          kibana = 5601
        }
      }

      resources {
        memory = 2000
        network {
          mbits = 50
          port "kibana" {}
        }
      }
      service {
        name="kibana"
        tags=["urlprefix-kibana.service.consul:9999/"]
        port = "kibana"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    # - end kibana - #

  } # - end logging-elk - #

}