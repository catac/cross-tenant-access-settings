variable "defaults_file_path" {
  description = "Path to the defaults YAML configuration file"
  type        = string
  default     = "config/defaults.yaml"
}

variable "peers_file_path" {
  description = "Path to the peers YAML configuration file"
  type        = string
  default     = "config/peers.yaml"
}
