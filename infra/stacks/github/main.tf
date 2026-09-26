# Repository settings and branch protection as code (ADR 0024 follow-up).
# They were first applied through the API; the import blocks below bring them under
# management without recreating anything, and re-adopt them if this state is ever lost.
provider "github" {
  owner = var.owner
}

import {
  to = github_repository.this
  id = var.repository
}

import {
  to = github_repository_ruleset.protect_main
  id = "${var.repository}:24025295"
}

resource "github_repository" "this" {
  name         = var.repository
  description  = "A hands-on learning project: designing an enterprise-style stock-exchange event platform on Kubernetes from scratch (Kafka/Strimzi, deterministic matching engine, GitOps, governance, HA/DR), with every decision explained."
  homepage_url = "https://selimaytac.github.io/kafka-financial-event-platform-docs/"
  visibility   = "public"
  topics = [
    "argocd", "clickhouse", "event-driven", "fintech", "gitops", "kafka", "kraft",
    "kubernetes", "matching-engine", "opentofu", "platform-engineering", "strimzi",
  ]

  has_issues      = true
  has_projects    = true
  has_wiki        = true
  has_discussions = false

  # Merge commits only; the PR title becomes the Conventional Commit subject (ADR 0024).
  allow_merge_commit          = true
  allow_squash_merge          = false
  allow_rebase_merge          = false
  allow_auto_merge            = false
  allow_update_branch         = false
  merge_commit_title          = "PR_TITLE"
  merge_commit_message        = "BLANK"
  delete_branch_on_merge      = true
  web_commit_signoff_required = false

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  # Deleting the repository would lose everything: refuse in code, and archive as a last line.
  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_ruleset" "protect_main" {
  name        = "protect-main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
      allowed_merge_methods             = ["merge"]
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      required_check {
        context        = "lint (pre-commit)"
        integration_id = 15368 # GitHub Actions
      }

      required_check {
        context        = "secrets (gitleaks, full history)"
        integration_id = 15368
      }
    }
  }
}
