
addpath(genpath('src'));
ensure_dir('out'); ensure_dir('figs');

% T1
e1 = scenario_T1();
m1 = evaluate_events(e1, 'T1_revoke_vs_write');

% T2
e2 = scenario_T2();
m2 = evaluate_events(e2, 'T2_partitioned_revoke');

% T3
e3 = scenario_T3();
m3 = evaluate_events(e3, 'T3_write_before_grant');

disp('Done.');
