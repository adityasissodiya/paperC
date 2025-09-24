function T2_partition_unauthorized()
%T2_PARTITION_UNAUTHORIZED  Revoke on A; Bob writes on B during partition.
names = {'NodeA','NodeB'};
net = Network(2, names, 4242);

% Initial grants: Alice admin, Bob member
net.localGrant(1, 'Alice', 'Alice', 0.5);
net.localGrant(1, 'Alice', 'Bob',   0.6);

% Baseline write
net.localWrite(2, 'Bob', +1, 1.0);

% Revoke Bob on A
net.localRevoke(1, 'Alice', 'Bob', 2.0);

% Partition A | B
net.schedulePartition(2.5, [1]);    % isolate A from the rest
% Bob writes while partitioned (on B)
net.localWrite(2, 'Bob', +1, 3.0);
% Heal
net.schedulePartitionEnd(5.0, [1]);

net.run();

disp('--- T2 PARTITION UNAUTHORIZED LOGS ---');
for i=1:numel(net.replicas), fprintf('--- %s ---\n', net.replicas(i).name); disp(net.replicas(i).log'); end
fprintf('Final values: '); disp(arrayfun(@(r) r.dataValue, net.replicas));

assignin('base','NET_T2',net);
end
