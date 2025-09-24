function tf = authorized_at_cut(aclEvents, op, vc_leq_fn, vc_conc_fn)
%AUTHORIZED_AT_CUT  Is op authorized at its causal cut under remove-wins?
%   aclEvents: array of structs with fields: type ('grant'|'revoke'), principal, clock
%   op: struct with fields: author, clock
%   vc_leq_fn, vc_conc_fn: function handles to vector clock predicates

% Extract ACL events for op.author that are <= op.clock (in causal past)
P = op.author;
inCut = [];
for k = 1:numel(aclEvents)
    e = aclEvents(k);
    if strcmp(e.principal, P) && vc_leq_fn(e.clock, op.clock)
        inCut(end+1) = k; %#ok<AGROW>
    end
end

if isempty(inCut)
    tf = false; % no grants in the cut
    return;
end

% Partition into grants and revokes
Gidx = inCut(arrayfun(@(k) strcmp(aclEvents(k).type, 'grant'), inCut));
Ridx = inCut(arrayfun(@(k) strcmp(aclEvents(k).type, 'revoke'), inCut));

% If no grants at all, unauthorized
if isempty(Gidx)
    tf = false;
    return;
end

% Pick a maximal grant g* (no other grant strictly after it).
gstar = Gidx(1);
for gi = Gidx
    isMax = true;
    for gj = Gidx
        if gi ~= gj
            if vc_leq_fn(aclEvents(gi).clock, aclEvents(gj).clock) && ~vc_leq_fn(aclEvents(gj).clock, aclEvents(gi).clock)
                isMax = false; break;
            end
        end
    end
    if isMax
        gstar = gi; break;
    end
end

% Remove-wins: any revoke concurrent with or after g* kills authorization.
for ri = Ridx
    rclk = aclEvents(ri).clock;
    gclk = aclEvents(gstar).clock;
    if vc_conc_fn(rclk, gclk) || vc_leq_fn(gclk, rclk)
        tf = false;
        return;
    end
end

% Otherwise authorized
tf = true;
end
