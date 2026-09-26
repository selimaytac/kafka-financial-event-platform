# Shared, non-secret S3 backend settings for every remote-state stack (ADR 0025).
# The endpoint, key and credentials are supplied at run time by scripts/tofu.sh.
bucket                      = "opentofu-state"
region                      = "us-east-1"
use_path_style              = true
use_lockfile                = true
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
skip_requesting_account_id  = true
