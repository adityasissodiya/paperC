
function metrics = evaluate_events(events, name)
%EVALUATE_EVENTS Evaluate scenario events; returns metrics struct and saves outputs.
%
% Metrics:
%   unauthorized_final_count  - number of WRITE ops dropped as unauthorized
%   applied_count             - number of WRITE ops applied
%   pruned_ids                - ids of dropped writes
%   final_state               - map (key->value) summary

if nargin < 2, name = 'scenario'; end

[out_dir_ok] = true;
if exist('src/util/ensure_dir.m','file')
    ensure_dir('out');
else
    out_dir_ok = false;
end

[finalState, appliedOps, prunedOps] = materialize_state(events);

% Summarize
keys = finalState.keys;
vals = strings(1, numel(keys));
for i = 1:numel(keys)
    entry = finalState(keys{i});
    if ischar(entry.value) || isstring(entry.value)
        vals(i) = string(entry.value);
    else
        vals(i) = string(mat2str(entry.value));
    end
end

metrics = struct();
metrics.name = name;
metrics.unauthorized_final_count = numel(prunedOps);
metrics.applied_count = numel(appliedOps);
metrics.pruned_ids = prunedOps;
metrics.applied_ids = appliedOps;
metrics.final_state_keys = keys;
metrics.final_state_vals = vals;

fprintf('\n[%s] applied=%d, unauthorized_after_merge=%d\n', name, metrics.applied_count, metrics.unauthorized_final_count);
if ~isempty(keys)
    fprintf('Final state:\n');
    for i = 0:numel(keys)-1
        fprintf('  %s = %s\n', keys{i+1}, metrics.final_state_vals(i+1));
    end
else
    fprintf('Final state: (empty)\n');
end
if ~isempty(prunedOps)
    fprintf('Pruned ops: %s\n', strjoin(cellstr(prunedOps), ', '));
end

% Save MAT output
if out_dir_ok
    save(fullfile('out', sprintf('%s_metrics.mat', name)), 'metrics');
end

end
