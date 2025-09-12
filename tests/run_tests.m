
addpath(genpath('src'));
fail = false;

% T1
e1 = scenario_T1();
m1 = evaluate_events(e1, 'T1');
if m1.unauthorized_final_count ~= 1
    warning('T1 expected 1 unauthorized pruned write; got %d', m1.unauthorized_final_count);
    fail = true;
end
% Final title should be 'X' (write at t=1), not 'Y'
if ~any(strcmp(m1.final_state_keys, 'D.title')) || ~any(strcmp(m1.final_state_vals, 'X'))
    warning('T1 expected D.title = X after merge.');
    fail = true;
end

% T2
e2 = scenario_T2();
m2 = evaluate_events(e2, 'T2');
if m2.unauthorized_final_count ~= 1
    warning('T2 expected 1 unauthorized pruned write; got %d', m2.unauthorized_final_count);
    fail = true;
end
if ~any(strcmp(m2.final_state_keys, 'asset.state')) || ~any(strcmp(m2.final_state_vals, 'v1'))
    warning('T2 expected asset.state = v1 after merge.');
    fail = true;
end

% T3
e3 = scenario_T3();
m3 = evaluate_events(e3, 'T3');
if m3.unauthorized_final_count ~= 1
    warning('T3 expected 1 unauthorized pruned write; got %d', m3.unauthorized_final_count);
    fail = true;
end
% No final value expected (grant happened after write; no later authorized write)
if numel(m3.final_state_keys) ~= 0
    warning('T3 expected empty final state; got %d keys', numel(m3.final_state_keys));
    fail = true;
end

if fail
    error('Some tests failed. See warnings above.');
else
    disp('All tests passed.');
end
