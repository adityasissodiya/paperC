
function tf = is_authorized_at_time(acl_events, principal, action, scope, t)
%IS_AUTHORIZED_AT_TIME Return true if principal has (action, scope) at time t.
% acl_events: struct array with fields: type ('GRANT'|'REVOKE'), principal, action, scope, time
% Matching is exact on principal, action, and scope, with fallback to wildcard '*' scope.
%
% Rule: LWW-element-set with remove-wins bias: at time t, the latest event <= t decides;
% if tie, REVOKE wins.
%
% Returns logical scalar.
tf = false;
% First try exact scope match, then wildcard
scopes = {scope, '*'};
for si = 1:numel(scopes)
    s = scopes{si};
    idx = arrayfun(@(e) strcmp(e.principal, principal) && strcmp(e.action, action) && strcmp(e.scope, s) && e.time <= t, acl_events);
    if any(idx)
        evs = acl_events(idx);
        % find latest time
        times = [evs.time];
        maxT = max(times);
        % among events with maxT, apply remove-wins: REVOKE overrides GRANT
        idxMax = find(times == maxT);
        lastTypes = {evs(idxMax).type};
        if any(strcmp(lastTypes, 'REVOKE'))
            tf = false;
        else
            tf = true;
        end
        return;
    end
end
% if nothing found, not authorized
tf = false;
end
