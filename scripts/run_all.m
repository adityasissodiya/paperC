function run_all()
%RUN_ALL  Run all scenarios T1..T4 deterministically.
clc;
fprintf('=== Running T1 ===\n'); sim/T1_basic_authorized;
fprintf('\n=== Running T2 ===\n'); sim/T2_partition_unauthorized;
fprintf('\n=== Running T3 ===\n'); sim/T3_concurrent_acl_conflict;
fprintf('\n=== Running T4 ===\n'); sim/T4_backdating_attack;
fprintf('\nAll scenarios complete.\n');
end
