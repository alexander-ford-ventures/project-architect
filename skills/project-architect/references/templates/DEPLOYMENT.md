---
template_name: DEPLOYMENT
generate_when: "decisions.hosting.frontend != null OR decisions.hosting.backend != null"
required_decisions: [hosting.frontend, hosting.backend]
optional_decisions: [hosting.cdn, deployment.environments, deployment.iac, deployment.preview_deploys, deployment.rollback]
depends_on: []
revision_triggers: [hosting.frontend, hosting.backend, hosting.cdn, deployment.iac]
---

# Deployment: {{project_name}}

## Environments
Table: environment | URL | branch | purpose | data isolation. Typically dev / preview / staging / production with their promotion rules.

## Infrastructure
One subsection per service (frontend, backend, edge, database, cache, queue, CDN, object storage). Each captures: provider, configuration, scaling policy, and region(s).

## Domain & DNS
Domains owned, DNS provider, record layout (apex, www, api, status), and certificate strategy (ACME / managed).

## Environment Variables
Table: name | scope | description. Names and descriptions only — never values.

## Deployment Process
Step-by-step how a change reaches production: trigger (git push / tag / manual), build, test, deploy, smoke. Reference the CI/CD platform without duplicating CI_CD.md detail.

## Rollback Strategy
How to revert to a known-good state (atomic deploys / instant rollback / blue-green / canary), expected RTO, and the rehearsal cadence.

## Preview Deployments
How preview / per-PR environments are created and torn down, data-scrubbing rules, and access controls.

## Revision Log
(none yet)
