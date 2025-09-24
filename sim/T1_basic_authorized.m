function T1_basic_authorized()
%T1_BASIC_AUTHORIZED  Baseline: all ops authorized; replicas converge.
names = {'NodeA','NodeB'};
net = Network(2, names, 4242);

% Initial grants (Alice, Bob)
net.localGrant(1, 'Alice', 'Alice', 0.5);
net.localGrant(1, 'Alice', 'Bob',   0.6);

% Writes
net.localWrite(1, 'Alice', +1, 1.0);
net.localWrite(2, 'Bob',   +1, 1.2);

net.run();

disp('--- T1 BASIC AUTHORIZED LOGS ---');
for i=1:numel(net.replicas), fprintf('--- %s ---\n', net.replicas(i).name); disp(net.replicas(i).log'); end
fprintf('Final values: '); disp(arrayfun(@(r) r.dataValue, net.replicas));

assignin('base','NET_T1',net);
end
