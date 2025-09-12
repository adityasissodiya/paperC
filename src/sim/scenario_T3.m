
function events = scenario_T3()
%SCENARIO_T3 Write before grant (concurrent); drop unauthorized write.
% Timeline:
% t0: B WRITE v1 (no grant yet)
% t1: GRANT(B) (concurrent-ish; but arrives after)
% Expect: v1 dropped.

events = struct('id',{},'type',{},'principal',{},'action',{},'scope',{},'key',{},'value',{},'time',{});
function push(e), events(end+1) = e; end

push(struct('id','g0','type','WRITE','principal','B','action','','scope','*','key','doc.title','value','v1','time',0));
push(struct('id','g1','type','GRANT','principal','B','action','write','scope','*','key','','value',[],'time',1));

end
