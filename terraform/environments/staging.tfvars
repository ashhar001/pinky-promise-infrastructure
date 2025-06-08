# Staging Environment Configuration

# Project Configuration
project_id  = "pinky-promise-staging"
region      = "us-central1"
environment = "staging"

# Cluster Configuration
cluster_name = "pinky-promise-cluster"

# Database Configuration (Smaller for staging)
database_tier       = "db-custom-1-3840" # 1 vCPU, 3.75GB RAM
database_name       = "pinky_promise"
enable_read_replica = false # No replica for staging
replica_tier        = "db-custom-1-3840"

# Networking Configuration
vpc_cidr             = "10.10.0.0/16"
public_subnet_cidr   = "10.10.1.0/24"
private_subnet_cidr  = "10.10.2.0/24"
database_subnet_cidr = "10.10.3.0/24"
pods_cidr            = "10.11.0.0/16"
services_cidr        = "10.12.0.0/16"

# Security Configuration
enable_private_nodes   = true
master_ipv4_cidr_block = "172.16.1.0/28"

# Authorized networks for cluster access
authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All networks (staging)"
  }
]

# Monitoring Configuration
enable_monitoring     = true
enable_backup         = true
backup_retention_days = 7 # Shorter retention for staging
backup_location       = "us"

# Scaling Configuration
min_node_count = 1
max_node_count = 5

# Deletion Protection (Disabled for staging)
enable_deletion_protection = false

# High Availability (Disabled for cost savings)
enable_high_availability = false

# Common Labels
common_labels = {
  environment = "staging"
  project     = "pinky-promise"
  managed_by  = "terraform"
  team        = "platform"
  cost_center = "engineering"
}

