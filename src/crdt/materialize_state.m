
function [finalState, appliedOps, prunedOps] = materialize_state(all_events)
%MATERIALIZE_STATE Materialize final data state from union of events.
% Events include GRANT/REVOKE (policy) and WRITE (data).
% Policy is interpreted as LWW-element-set with remove-wins.
% Data is LWW-register per key, but only writes authorized at their time are considered.
%
% Returns:
%  finalState : containers.Map from key -> struct('value', v, 'time', t, 'principal', p, 'opID', id)
%  appliedOps : array of opIDs that were applied
%  prunedOps  : array of opIDs that were dropped as unauthorized
%
% Note: time is scalar Lamport timestamp in this harness.

% Separate policy and writes
isWrite = arrayfun(@(e) strcmp(e.type, 'WRITE'), all_events);
write_events = all_events(isWrite);
policy_events = all_events(~isWrite);

% Build final state via filtering + LWW
finalState = containers.Map('KeyType','char','ValueType','any');
appliedOps = strings(0);
prunedOps  = strings(0);

for i = 1:numel(write_events)
    w = write_events(i);
    % Check authorization at op time
    if is_authorized_at_time(policy_events, w.principal, 'write', w.scope, w.time)
        % authorized -> consider for LWW on the key
        if isKey(finalState, w.key)
            cur = finalState(w.key);
            if w.time > cur.time
                finalState(w.key) = struct('value', w.value, 'time', w.time, 'principal', w.principal, 'opID', w.id);
            end
        else
            finalState(w.key) = struct('value', w.value, 'time', w.time, 'principal', w.principal, 'opID', w.id);
        end
        appliedOps(end+1) = string(w.id);
    else
        prunedOps(end+1) = string(w.id);
    end
end

end
