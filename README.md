# Causal Authorization over CRDTs — Interactive MATLAB Repo

> **Goal:** Keep it simple and reproducible. **Signed ops + remove‑wins ACL + causal‑cut check** ⇒ after convergence, **no unauthorized write survives**.

This is an **interactive, clone‑and‑run** MATLAB project. You’ll simulate a few replicas, flip network partitions on/off, and watch how revocations race writes—and why **revocation wins** under our rule set.

**You get:**
- Clean MATLAB code (no toolboxes), heavy comments.
- Four scenarios (T1–T4) with **timelines** (✔ applied, ✖ dropped), partition shading, and state evolution.
- Reproducible runs (fixed seeds) + tests that assert **safety** and **convergence**.
- Human‑level explanations; assumes you know distributed systems, not CRDT arcana.

---

## Quick start

```matlab
% In MATLAB, from the repo root:
scripts/run_all     % run all scenarios
scripts/plot_all    % generate figures into docs/
runtests tests      % run safety + convergence tests
```

---

## The idea in three rules

1) **Signed operations** — every op carries `author` and (mock) signature; replicas ignore unsigned/invalid ops.  
2) **Remove‑wins ACL‑CRDT** — the membership list is a replicated set: concurrent **remove** beats **add** (safer default).  
3) **Causal‑cut authorization** — apply an op only if the **ACL as of the op’s causal past** authorizes it. Revoke concurrent with a grant ⇒ deny.

**Outcome:** After quiescence (all messages delivered), the final state contains **no effects** from causally unauthorized ops.

---

## Layout

```
src/                % core logic
  util/             % vector clocks (vc_*)
  crdt/             % (placeholder) LWW register
  acl/              % ACL check at an op's causal cut (remove-wins)
  sim/              % Replica + Network simulation
sim/                % scenarios T1..T4
scripts/            % run_all.m, plot_all.m
tests/              % invariants (safety & convergence)
docs/               % figures F1..F5 (generated)
.github/workflows/  % optional MATLAB CI
```

---

## Scenarios

- **T1** baseline — all authorized, converge with ✔ everywhere.  
- **T2** partition + revoke vs write — post‑revoke write becomes ✖ on merge.  
- **T3** concurrent grant vs revoke — remove‑wins; writes in that window are ✖.  
- **T4** “backdating” edge — crafted concurrent write; filtered at materialization.

Logs call out key moments; plots show ✔/✖, grants/revokes, partitions, and final agreement.

---

## Guarantees we check

- **Safety (post‑quiescence):** no unauthorized effect remains.  
- **Convergence:** all replicas end identical (data + ACL).  
- **Determinism:** concurrent revoke/write decisions match across replicas.

We do **not** claim confidentiality or BFT here. This is the non‑Byzantine baseline.

---

## License

MIT.
