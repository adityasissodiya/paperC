function T3_concurrent_acl_conflict()
%T3_CONCURRENT_ACL_CONFLICT  Concurrent grant vs revoke; remove-wins; writes in the window are dropped.
names = {'NodeA','NodeB'};
net = Network(2, names, 777);

% Initial: only Alice
net.localGrant(1, 'Alice', 'Alice', 0.5);

% Concurrent admin ops: on A revoke Bob; on B grant Bob
net.localRevoke(1, 'Alice', 'Bob', 1.0);
net.localGrant(2, 'Alice', 'Bob',  1.0);

% Bob tries to write around the same time
net.localWrite(2, 'Bob', +1, 1.2);

net.run();

disp('--- T3 CONCURRENT ACL CONFLICT LOGS ---');
for i=1:numel(net.replicas), fprintf('--- %s ---\n', net.replicas(i).name); disp(net.replicas(i).log'); end
fprintf('Final values: '); disp(arrayfun(@(r) r.dataValue, net.replicas));

assignin('base','NET_T3',net);
end
