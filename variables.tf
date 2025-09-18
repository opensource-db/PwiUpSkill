
variable "instance_count" {
  description = "Number of Instance's"
  type        = number
}



# Giveing Instance Types as Variables
variable "instance_type" {
  description = " EC2 instance type"
  type        = string  
}


variable "os_distribution" {
  description = "Target OS distribution (redhat, rocky, amazonlinux, ubuntu, debian, suse, almalinux)"
  type        = string
}

variable "architecture" {
  description = "CPU architecture to use (x86_64 or arm64)"
  type        = string
  #default     = "x86_64"
}

variable "postgres_version" {
  description = "The Version of the Postgres to Install(Eg:-15,16,17)"
  type = string
  # default = "15"  
}

variable "replica_count" {
  # default = 1
  type = number
}

variable "replication_user" {
  # default = "replicator"
  type = string
}

variable "replication_password" {
  # default = "krishna"  # Replace with a strong password
  type = string
}

# Defineing the variable to control pgbench execution
variable "run_pgbench" {
  description = "Set to 'yes' to run pgbench, otherwise 'no'."
  type        = string
  #default     = "no"
}

# This Part is Now Updated
variable "cleanup_pgbench" {
  description = "Set to 'yes' to clean up pgbench data, otherwise 'no'."
  type        = string
  default     = "no"  # You can set this to 'yes' for cleanup.
}
