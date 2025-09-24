function T4_backdating_attack()
%T4_BACKDATING_ATTACK  Edge case: simulate a crafted concurrent write around a revoke.
names = {'NodeA','NodeB'};
net = Network(2, names, 999);

% Initial: Alice and Bob
net.localGrant(1, 'Alice', 'Alice', 0.5);
net.localGrant(1, 'Alice', 'Bob',   0.6);

% Revoke Bob at A
net.localRevoke(1, 'Alice', 'Bob', 2.0);

% Partition
net.schedulePartition(2.5, [1]);
% Bob writes on B (appearing concurrent)
net.localWrite(2, 'Bob', +1, 2.6);
% Heal
net.schedulePartitionEnd(5.0, [1]);

net.run();

disp('--- T4 BACKDATING ATTACK LOGS ---');
for i=1:numel(net.replicas), fprintf('--- %s ---\n', net.replicas(i).name); disp(net.replicas(i).log'); end
fprintf('Final values: '); disp(arrayfun(@(r) r.dataValue, net.replicas));

assignin('base','NET_T4',net);
end
