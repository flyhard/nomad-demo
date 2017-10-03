bind_addr = "0.0.0.0"
data_dir = "/tmp/nomad-data"
log_level = "INFO"
enable_debug = true

server {
  enabled = true
  bootstrap_expect = 1
  rejoin_after_leave = false
}

# these settings allow Nomad to automatically find its peers through Consul
consul {
  server_service_name = "nomad"
  server_auto_join = true
  client_service_name = "nomad-client"
  client_auto_join = true
  auto_advertise = true
}

vault {
  enabled = true
  address = "http://localhost:8200"
}

client {
  enabled = true
  options {
    "driver.raw_exec.enable" = "1"
  }
}

