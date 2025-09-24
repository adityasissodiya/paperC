function plot_all()
%PLOT_ALL  Create simple timeline/state plots for T1..T4.
figdir = 'docs';
if ~exist(figdir,'dir'), mkdir(figdir); end

plots = { 'NET_T1','F1_T1.png'; 'NET_T2','F2_T2.png'; 'NET_T3','F3_T3.png'; 'NET_T4','F4_T4.png' };

for i = 1:size(plots,1)
    var = plots{i,1}; out = fullfile(figdir, plots{i,2});
    if ~evalin('base', sprintf('exist(''%s'',''var'')', var))
        fprintf('Variable %s not found in base workspace. Run scripts/run_all first.\n', var);
        continue;
    end
    net = evalin('base', var);
    plot_timeline(net, out);
end

% A simple summary bar (F5): final values per replica (by scenario)
F5 = figure('Name','F5 Summary','Color','w');
vals = [];
for i = 1:size(plots,1)
    var = plots{i,1};
    if evalin('base', sprintf('exist(''%s'',''var'')', var))
        net = evalin('base', var);
        vals = [vals; arrayfun(@(r) r.dataValue, net.replicas)];
    end
end
if ~isempty(vals)
    bar(vals);
    title('Final data values per replica (by scenario)');
    xlabel('Replica'); ylabel('Value');
    saveas(F5, fullfile(figdir,'F5_summary.png'));
end
end

function plot_timeline(net, outFile)
% Simple per-node scatter of events; ✔ (applied) green circle; ✖ red x.
T = [net.timeline.time]';
N = numel(net.replicas);
Y = [net.timeline.node]';
isWrite = arrayfun(@(e) strcmp(e.action,'write'), net.timeline);
applied = arrayfun(@(e) strcmp(e.outcome,'applied'), net.timeline);
rejected = arrayfun(@(e) strcmp(e.outcome,'rejected'), net.timeline);
isGrant = arrayfun(@(e) strcmp(e.action,'grant'), net.timeline);
isRevoke = arrayfun(@(e) strcmp(e.action,'revoke'), net.timeline);

F = figure('Name','Timeline','Color','w'); hold on;
plot(T(isWrite & applied), Y(isWrite & applied), 'o', 'MarkerFaceColor',[0.2 0.7 0.2], 'MarkerEdgeColor','k');
plot(T(isWrite & rejected), Y(isWrite & rejected), 'x', 'Color',[0.85 0.2 0.2], 'LineWidth',1.5);
plot(T(isGrant), Y(isGrant), 's', 'MarkerFaceColor',[0.2 0.4 0.9], 'MarkerEdgeColor','k');
plot(T(isRevoke), Y(isRevoke), '^', 'MarkerFaceColor',[0.9 0.5 0.2], 'MarkerEdgeColor','k');

yticks(1:N); yticklabels(arrayfun(@(r) r.name, net.replicas, 'UniformOutput', false));
xlabel('Time'); ylabel('Replica');
title('Timeline: ✔ applied writes, ✖ rejected; squares=grant; triangles=revoke');
grid on;
saveas(F, outFile);
end
