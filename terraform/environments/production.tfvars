# Production Environment Configuration

# Project Configuration
project_id  = "pinky-promise-app"
region      = "us-central1"
environment = "production"

# Cluster Configuration
cluster_name = "pinky-promise-cluster"

# Database Configuration
database_tier       = "db-custom-2-4096" # 2 vCPU, 4GB RAM
database_name       = "pinky_promise"
enable_read_replica = true
replica_tier        = "db-custom-1-3840" # 1 vCPU, 3.75GB RAM

# Networking Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
private_subnet_cidr  = "10.0.2.0/24"
database_subnet_cidr = "10.0.3.0/24"
pods_cidr            = "10.1.0.0/16"
services_cidr        = "10.2.0.0/16"

# Security Configuration
enable_private_nodes   = true
master_ipv4_cidr_block = "172.16.0.0/28"

# Authorized networks for cluster access
authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All networks (update for production)"
  }
]

# Monitoring Configuration
enable_monitoring     = true
enable_backup         = true
backup_retention_days = 30
backup_location       = "us"

# Scaling Configuration
min_node_count = 1
max_node_count = 10

# Deletion Protection (IMPORTANT for Production)
enable_deletion_protection = true

# High Availability
enable_high_availability = true

# Common Labels
common_labels = {
  environment = "production"
  project     = "pinky-promise"
  managed_by  = "terraform"
  team        = "platform"
  cost_center = "engineering"
}

