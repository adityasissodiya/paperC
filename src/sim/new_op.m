function op = new_op(id, author, action, target, payload, clock, sigValid)
%NEW_OP  Construct an operation struct.
if nargin < 7, sigValid = true; end
op = struct();
op.id = id;
op.author = author;
op.action = action;     % 'write' | 'grant' | 'revoke'
op.target = target;     % e.g., 'counter'
op.payload = payload;   % e.g., +1
op.clock = clock;       % vector clock (1 x n)
op.sigValid = sigValid; % signature simulation
end
