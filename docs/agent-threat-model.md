# Agent threat model — the coding agent as a non-human actor

> Required by the capstone: reason about the agent's blast radius inside our delivery loop.

**Where the agent sits.** A coding agent can author code and manifests and open pull requests
against **both** repositories. The configuration repository is reconciled by Argo CD, so any
change merged there is, within the sync interval, applied to the cluster. That places the agent
**inside the control loop**: a bad merged change is a bad deployment.

**Credentials / least privilege.**
- The agent operates only through Git (proposing branches / PRs). It holds **no** cluster
  credentials and **no** kubeconfig — same principle as CI.
- It does **not** hold the registry push credentials (`ACR_*`) or the `CONFIG_REPO_PAT`; those
  live only in GitHub Actions secrets, used by CI after a human-reviewed merge.
- It cannot push to `main` directly; branch protection requires review.

**Review gates (human + policy-as-code).**
- Every agent PR requires human review before merge (branch protection on `main` in both repos).
- Policy-as-code in CI on the configuration repo: `helm lint` + `kubeconform`/OPA checks reject
  privileged pods, `:latest` on the critical path, missing probes/PDBs, or plaintext Secrets
  (only SealedSecrets allowed). These run on the PR, before merge.

**Worst case if it proposes a bad change.**
- A subtly wrong manifest (e.g. liveness probing a downstream, an over-permissive
  ServiceAccount, a non-idempotent handler, dropping `min.insync.replicas`) could degrade or
  outage the critical path after merge.
- Containment: review + policy checks catch the common classes pre-merge; Argo CD history +
  `git revert` give a fast rollback; PDBs/topology spread/HPA limit blast radius; SLO burn-rate
  alerts surface user-visible impact quickly. The agent never has a direct write path to the
  cluster, so the *only* way its change ships is through a gate we control.

See `agent-log.md` for concrete mistakes already caught.
