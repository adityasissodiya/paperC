
function events = scenario_T1()
%SCENARIO_T1 Revoke vs concurrent write; revoke must win.
% Timeline:
% t0: Admin GRANT write to B on scope '*'
% t1: B WRITE key='D.title' value='X'
% t2: Admin REVOKE write from B  ||  t2': B WRITE key='D.title' value='Y' (concurrent)
%
% Expect: final title ~= 'Y' (Y write pruned as concurrent with revoke)

events = struct('id',{},'type',{},'principal',{},'action',{},'scope',{},'key',{},'value',{},'time',{});

% Helper to append
function push(e), events(end+1) = e; end

push(struct('id','e0','type','GRANT','principal','B','action','write','scope','*','key','','value',[],'time',0));
push(struct('id','e1','type','WRITE','principal','B','action','','scope','*','key','D.title','value','X','time',1));
% concurrent revoke and write at same time 2
push(struct('id','e2','type','REVOKE','principal','B','action','write','scope','*','key','','value',[],'time',2));
push(struct('id','e3','type','WRITE','principal','B','action','','scope','*','key','D.title','value','Y','time',2));

end
