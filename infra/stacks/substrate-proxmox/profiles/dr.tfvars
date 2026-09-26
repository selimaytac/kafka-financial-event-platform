# Example: secondary site for DR drills (ADR 0003). Adjust to the real Proxmox network.
proxmox_node      = "pve"
gateway           = "10.20.0.1"
control_plane_ips = ["10.20.0.11"]
worker_ips        = ["10.20.0.21", "10.20.0.22"]
