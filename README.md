## 1. Abstract

* Problem: CRDTs excel at **availability & merge**, but **they don’t reject**—which clashes with access control.
* Gap: No central arbiter; permissions change under partitions; revocations race with writes.
* Idea: A **replicated ACL/capability layer** + **signed ops** + a simple **causal rule** (“revocation wins”) that guarantees: **no unauthorized write survives convergence**.
* Method: Formalize acceptance/merge rules; simulate distributed executions in **MATLAB**; show convergence & safety under partitions/rejoins; quantify overhead.
* Results: Zero unauthorized post‑merge, deterministic resolution of grant/revoke vs. writes, low verification overhead.
* Scope: Authorization only (not confidentiality), eventually consistent model, non‑Byzantine baseline; security extensions discussed.

---

## 2. Introduction

**Goal:** Motivate *why CRDT + AC matters* outside centralized platforms; define the one big promise and one big constraint.

* **Motivation:** Multi‑stakeholder, intermittently connected collaboration (local‑first docs; federated knowledge entries; DPP‑style product logs). Centralized auth doesn’t exist / isn’t trusted / isn’t online.
* **Tension:** CRDTs merge everything; access control wants to **reject** unauthorized ops.
* **Claim (precise):** We provide a convergent rule set so that **any operation not authorized in the causal history** will be **ignored by all honest replicas** after synchronization.
* **Contributions :**

  1. **Auth‑CRDT layer**: a small set of CRDTs (Map\<LWW/OR‑Set>) + **ACL‑CRDT** (remove‑wins) + **signed operations**.
  2. **Causal authorization semantics**: accept op **iff** (a) signature valid, (b) ACL at op’s causal time permits it; **revocation wins** on concurrency.
  3. **MATLAB simulation framework** + figure grammar to visualize permission windows, partitions, merges, and dropped ops.
  4. **Evaluation**: safety, convergence, cost; ablations (no ACL‑check, add‑wins vs remove‑wins).
* **Scope & non‑claims, upfront:** No BFT adversary proofs; no confidentiality; not production PKI; eventual consistency only.

---

## 3. Background & Related Work

* **CRDT essentials** relevant to our design (LWW registers, OR‑Set/OR‑Map, add‑wins vs remove‑wins; strong eventual consistency).
* **Access control in distributed settings:** ACLs vs. capabilities; revocation pain; DID / VCs (only what we use).
* **Prior attempts** at local‑first/CRDT access control; file‑system permission CRDTs; delegation chains; why those don’t fully solve causal revocation vs. writes.
* **Positioning:** We target **authorization safety under eventual consistency**, with a minimal rule set and empirical validation.

---

## 4. System & Threat Model

**Reviewers will hunt for hidden assumptions.**

* **Actors:** users/devices; optional agents.
* **State:** Application data `D` as a **CRDT Map\<key → value‑CRDT>**; policy `A` as an **ACL‑CRDT** (set/dictionary of ⟨principal, permission, scope⟩ with remove‑wins).
* **Network:** async, partitions, reordering, loss; eventual delivery.
* **Identity:** each principal has a keypair; ops are **signed**.
* **Adversary (baseline):** honest‑but‑curious / misconfigured nodes; **not** Byzantine (no key theft, no signature forgery).
* **Security property (authorization safety):** *After quiescence*, no state reflects an operation by a principal that lacked the required permission in the op’s **causal past**.
* **Liveness:** ops are locally accepted optimistically and converge; revocations eventually take effect globally.

---

## 5. Data & Policy Model

* **Application CRDTs:**

  * Single‑valued fields → **LWW‑Register**.
  * Sets/lists (e.g., certifications) → **OR‑Set**; choose **remove‑wins** for security‑sensitive elements.
  * Top‑level → **OR‑Map** containing field CRDTs.
* **Policy CRDT (ACL‑CRDT):**

  * Elements: ⟨principal, action, scope, ver⟩ with unique IDs; **grant = add**, **revoke = remove** (remove‑wins).
  * Optional **capability tokens** (delegations) as CRDT elements.
* **Operation format:** ⟨opID, principal, action, target, payload, **sig**, **clock**⟩; clock = vector or dotted version vector carried by the op.
* **Causal view:** each replica maintains a version of `A` to evaluate authorization **at op’s clock**.

---

## 6. Authorization Semantics & Algorithms

Spell out the rules; keep them small enough to reason about.

* **Accept rule (per replica):**

  ```
  verify(sig, principal, op);
  if authorized(A, op, op.clock) then apply(D, op) else buffer/drop;
  ```

  * `authorized` queries ACL‑CRDT **as of op.clock** (causal cut).
* **Merge rule:** standard CRDT merges for `D` and `A` (idempotent, commutative, associative).
* **Concurrency resolution:** If **grant/revoke** and **write** are concurrent:

  * **Revocation wins:** deny the write (do not materialize in `D` after merge).
  * Determinism via remove‑wins in ACL and causal check at apply‑time.
* **Properties (informal proofs / invariants):**

  * **Convergence:** `D` and `A` are CRDTs ⇒ converge.
  * **Authorization safety:** sketch: any path that materializes an unauthorized write requires `authorized` to be true at some replica; show contradiction under remove‑wins + causal check.
  * **Monotonic revocation:** once revoke observed, no future writes by that principal on that scope will be accepted.
* **Complexity:** per‑op verification O(1) signature + O(|P|) or O(log|P|) ACL lookup; merge costs standard.

---

## 7. Implementation

**A clean harness that reviewers could reproduce.**

* **Event model:** scripted traces of `grant`, `write`, `revoke`, partitions, delays; random seeds for reproducibility.
* **Replica state structs:** `D`, `A`, event log, delivery queues; vector‑clock utilities.
* **Scenarios (canonical):**

  1. **Grant → writes → revoke || write** (revocation concurrent with a write).
  2. **Partitioned writes** by authorized user, **revocation in other partition**, then merge.
  3. **Membership churn:** grant‑revoke‑regrant with stale replicas.
  4. **No‑ACL ablation** (to show why we need the rule), **add‑wins vs remove‑wins** ablation.
* **Metrics:** unauthorized‑write rate (should be 0 post‑merge), time/merges‑to‑safety, op suppression count, signature verify cost, memory overhead (ACL size), staleness window for reads.
* **Validation hooks:** invariants checked at quiescence; randomized permutations to kill accidental sequencing assumptions.

---

## 8. Figures & Visual Grammar

* **F1 Timeline (hero):** permission intervals vs. user writes; ✔ applied, ✖ dropped; partitions shaded; merge points marked.
* **F2 Before/After tables:** `D` state per replica pre‑merge → converged state; highlight which ops vanished.
* **F3 Convergence plot:** unauthorized‑writes over time (should drop to 0).
* **F4 Ablation:** compare add‑wins vs remove‑wins on same trace; bar chart of residual unauthorized ops (add‑wins fails).
* **F5 Cost:** per‑op verification latency vs. ACL size.
* **Appendix figs:** vector‑clock causality diagrams for tricky interleavings.

---

## 9. Evaluation

**Hit the questions a skeptical reviewer will ask.**

* **RQ‑style checks:**

  * *Safety:* Does any unauthorized write persist after convergence? (No.)
  * *Ordering corner cases:* With concurrent revoke/write, do all replicas make the same decision? (Yes, by construction.)
  * *Availability:* Are authorized writes always locally accepted (optimistic) and eventually preserved? (Yes.)
  * *Overhead:* Signature verification and ACL lookup cost within sane bounds? (Show microbenchmarks.)
* **Baselines:**

  * **Naïve CRDT (no AC)** → shows why “CRDT alone” is unsafe.
  * **Central gate (ideal)** → upper bound on safety/latency (not available offline).
  * **Add‑wins ACL** → demonstrates wrong semantics under revoke races.
* **Sensitivity:** ACL size, partition length, churn rate, op fan‑out.
* **Negative tests:** late backdated op; grant after write (concurrent) vs. before (causal).

---

## 10. Discussion

* **What this buys you:** authorization safety under eventual consistency; no central arbiter; deterministic conflict handling.
* **What it does not:** confidentiality, audit immutability, Byzantine resistance, legal compliance.
* **Integration:** how this would plug into a local‑first app or a federated store; DID/VC optional; key distribution realities.
* **Design alternatives:** capability chains vs. ACL; epoch‑based revocation; per‑field scopes; why we chose remove‑wins.
* **User impact:** admins need templates; developers get a small, predictable rule set.

---

## 11. Threats to Validity & Limitations

* **Internal:** simulation ≠ deployment; limited op patterns; simplified identity model.
* **External:** workloads may have confidentiality needs; some domains require global ordering.
* **Construct:** vector‑clock precision; mis‑specification of scopes; revocation semantics might be too conservative for some apps.

---

## 12. Related Work

* CRDT theory and maps/sets; local‑first collaboration; distributed file‑permission work; capability systems; DID/VC enforcement; SMT‑based policy checking (as orthogonal, centralized contrast).

---

## 13. Conclusion & Future Work

* **One‑liner:** We give a minimal rule set that makes **authorization and CRDTs coexist**: signed ops + replicated ACL + causal check + revoke‑wins ⇒ **no unauthorized write after convergence**.
* **Next:** BFT/forgery resistance; confidentiality overlays; production PKI; formal proofs (Coq/Isabelle); real app integration.

---

## 14. Artifacts & Reproducibility

* MATLAB repo: simulation harness + seeds + plotting scripts + data; deterministic runs; figure notebooks.
* Dataset: event traces; parameter files; instructions to regenerate all figures.

---



## What we can **safely claim** vs. **must not claim**

**Safe:**

* A convergent authorization semantics on top of standard CRDTs that **prevents unauthorized writes from surviving convergence**.
* Deterministic handling of grant/revoke vs. writes under partitions (revocation wins).
* Empirical evidence (MATLAB) that the rule set holds across adversarial interleavings and realistic partitions, with low runtime overhead.

**Do NOT claim:**

* Confidentiality guarantees; end‑to‑end legal compliance; Byzantine adversary resistance; production‑scale PKI/usability; universal performance at massive scale.

---

## Reviewer‑bait checklist (answer these explicitly in the text)

* How do you evaluate authorization *at op time* without a global view? (**Causal cut** from carried clock; replicated ACL snapshot.)
* Why remove‑wins in ACL? (Security: revocations must dominate concurrent writes; show add‑wins failure.)
* What happens if the authoring replica hasn’t seen a revoke yet? (It may accept locally, but the write will be **pruned on merge** at replicas that have the revoke; after quiescence it’s gone everywhere.)
* What if two admins concurrently grant and revoke? (Deterministic remove‑wins tie‑break; document rationale and impact.)
* What if keys are stolen / signatures forged? (Out of scope; discuss mitigations and BFT extensions in Future Work.)

---

# crdt-ac-sim — MATLAB simulation harness for CRDT + Access Control

A minimal, reproducible repository to **simulate authorization on top of CRDT-replicated data**.
It provides:
- An **ACL timeline** (remove-wins) and **signed-op placeholder**.
- A **materializer** that applies only **authorized** writes based on the ACL at the operation's causal time (here approximated by a scalar Lamport timestamp).
- Canonical scenarios (T1–T3) and metrics.
- Hooks to generate figures and extend with more CRDTs and scenarios.

> Goal: After quiescence (all events delivered), **no unauthorized write survives** in the converged state.

## Requirements
- MATLAB R2021b+ (tested features are basic: structs, containers.Map, plotting).
- No toolboxes required.

## Quick start
```bash
# In MATLAB:
scripts/run_all
# or from shell:
matlab -batch "scripts/run_all"
```

Outputs:
- Metrics printed to console.
- Final states saved to `out/` (create automatically).
- Figures will be saved to `figs/` by plotting helpers (placeholders included).

## Repository layout
```
src/
  acl/                 % ACL events, authorization checks
  crdt/                % Materialization rules for data (LWW registers etc.)
  sim/                 % Scenario generators (T1–T3)
  util/                % Helpers (Lamport clock, pretty printing)
scripts/
  run_all.m            % Run all scenarios, print metrics
tests/
  run_tests.m          % Basic assertions (unauthorized writes after convergence == 0)
docs/
  outline.md           % Paper outline + notes placeholders
.github/workflows/
  matlab.yml           % (Optional) CI template – requires MATLAB license token to run
```

## Scenarios included
- **T1** Revocation vs concurrent write (revocation wins).
- **T2** Partitioned revoke, later write by revoked user.
- **T3** Write before grant (concurrent) — drop unauthorized.

You can add more scenarios in `src/sim/` and register them in `scripts/run_all.m`.

## GitHub setup
```bash
git init
git add .
git commit -m "init: CRDT+AC MATLAB simulation harness"
git branch -M main
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## CI (optional)
This repo includes a GitHub Actions workflow (`.github/workflows/matlab.yml`) **commented out by default**.
To enable, you must supply MATLAB on runners (see MathWorks `matlab-actions`). If you don't have that,
run tests locally with:
```bash
matlab -batch "tests/run_tests"
