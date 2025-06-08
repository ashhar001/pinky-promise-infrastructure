# Development Environment Configuration

# Project Configuration
project_id  = "pinky-promise-dev"
region      = "us-central1"
environment = "development"

# Cluster Configuration
cluster_name = "pinky-promise-cluster"

# Database Configuration (Minimal for dev)
database_tier       = "db-custom-1-3840" # Small instance for testing v1
database_name       = "pinky_promise"
enable_read_replica = false # No replica for dev
replica_tier        = "db-f1-micro"

# Networking Configuration
vpc_cidr             = "10.20.0.0/16"
public_subnet_cidr   = "10.20.1.0/24"
private_subnet_cidr  = "10.20.2.0/24"
database_subnet_cidr = "10.20.3.0/24"
pods_cidr            = "10.21.0.0/16"
services_cidr        = "10.22.0.0/16"

# Security Configuration
enable_private_nodes   = true
master_ipv4_cidr_block = "172.16.2.0/28"

# Authorized networks for cluster access
authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All networks (development)"
  }
]

# Monitoring Configuration
enable_monitoring     = false # Disabled for cost savings
enable_backup         = false # Disabled for dev
backup_retention_days = 1
backup_location       = "us"

# Scaling Configuration
min_node_count = 0
max_node_count = 3

# Deletion Protection (Disabled for dev)
enable_deletion_protection = false

# High Availability (Disabled for cost savings)
enable_high_availability = false

# Common Labels
common_labels = {
  environment = "development"
  project     = "pinky-promise"
  managed_by  = "terraform"
  team        = "platform"
  cost_center = "engineering"
}

