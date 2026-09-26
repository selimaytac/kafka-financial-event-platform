# Profile dev (ADR 0003, ADR 0004)
node_image        = "kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f"
workers           = 1
gateway_host_port = 8443
cpu_caps          = { control_plane = 2, worker = 2 }
