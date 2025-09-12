
function events = scenario_T2()
%SCENARIO_T2 Partitioned revoke; later write by revoked user must be dropped.
% Timeline:
% t0: GRANT(B)
% t1: B WRITE v1
% (partition; admin revokes elsewhere)
% t2: REVOKE(B)
% t3: B WRITE v2 (didn't see revoke)
% Expect: v1 may remain (authorized at t1); v2 dropped.

events = struct('id',{},'type',{},'principal',{},'action',{},'scope',{},'key',{},'value',{},'time',{});
function push(e), events(end+1) = e; end

push(struct('id','f0','type','GRANT','principal','B','action','write','scope','*','key','','value',[],'time',0));
push(struct('id','f1','type','WRITE','principal','B','action','','scope','*','key','asset.state','value','v1','time',1));
push(struct('id','f2','type','REVOKE','principal','B','action','write','scope','*','key','','value',[],'time',2));
push(struct('id','f3','type','WRITE','principal','B','action','','scope','*','key','asset.state','value','v2','time',3));

end
