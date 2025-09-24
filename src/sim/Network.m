classdef Network < handle
%NETWORK  Discrete-event sim of replicas with partitions and message delivery.
    properties
        t
        events        % array of structs: time, kind, payload
        replicas      % array of Replica
        connected     % adjacency matrix (NxN logical)
        pending       % queued messages when disconnected: struct (from,to,op)
        timeline      % struct array of {time, node, opid, author, action, outcome}
        rngSeed
    end
    methods
        function obj = Network(nReplicas, names, rngSeed)
            if nargin < 2 || isempty(names)
                names = arrayfun(@(i) sprintf('Node%d',i), 1:nReplicas, 'UniformOutput', false);
            end
            if nargin < 3, rngSeed = 12345; end
            obj.rngSeed = rngSeed;
            rng(rngSeed);
            obj.t = 0;
            obj.events = struct('time',{},'kind',{},'payload',{});
            obj.replicas = repmat(Replica(1,nReplicas,'tmp'), 1, 0);
            for i = 1:nReplicas
                obj.replicas(i) = Replica(i, nReplicas, names{i});
            end
            obj.connected = true(nReplicas);  % fully connected
            obj.pending = struct('from',{},'to',{},'op',{});
            obj.timeline = struct('time',{},'node',{},'opid',{},'author',{},'action',{},'outcome',{});
        end
        
        function scheduleEvent(obj, time, kind, payload)
            ev = struct('time', time, 'kind', kind, 'payload', payload);
            obj.events(end+1) = ev;
            [~, idx] = sort([obj.events.time]);
            obj.events = obj.events(idx);
        end
        
        function schedulePartition(obj, tstart, nodes)
            obj.scheduleEvent(tstart, 'partition_start', nodes);
        end
        
        function schedulePartitionEnd(obj, tend, nodes)
            obj.scheduleEvent(tend, 'partition_end', nodes);
        end
        
        function localGrant(obj, nodeId, admin, principal, time)
            r = obj.replicas(nodeId);
            r.tick();
            opid = sprintf('opG_%d_%d', nodeId, numel(r.inbox)+1);
            op = new_op(opid, admin, 'grant', 'acl', struct('principal',principal), r.currentClock(), true);
            obj.scheduleEvent(time, 'local_op', struct('node', nodeId, 'op', op));
        end
        
        function localRevoke(obj, nodeId, admin, principal, time)
            r = obj.replicas(nodeId);
            r.tick();
            opid = sprintf('opR_%d_%d', nodeId, numel(r.inbox)+1);
            op = new_op(opid, admin, 'revoke', 'acl', struct('principal',principal), r.currentClock(), true);
            obj.scheduleEvent(time, 'local_op', struct('node', nodeId, 'op', op));
        end
        
        function localWrite(obj, nodeId, author, delta, time)
            r = obj.replicas(nodeId);
            r.tick();
            opid = sprintf('opW_%d_%d', nodeId, numel(r.inbox)+1);
            op = new_op(opid, author, 'write', 'counter', delta, r.currentClock(), true);
            obj.scheduleEvent(time, 'local_op', struct('node', nodeId, 'op', op));
        end
        
        function run(obj)
            while ~isempty(obj.events)
                ev = obj.events(1); obj.events(1) = [];
                obj.t = ev.time;
                switch ev.kind
                    case 'partition_start'
                        nodes = ev.payload;
                        obj.applyPartition(nodes, true);
                        obj.logAll(sprintf('--- PARTITION START: isolate {%s} ---', strjoin(arrayfun(@num2str,nodes,'UniformOutput',false),',')));
                    case 'partition_end'
                        nodes = ev.payload;
                        obj.applyPartition(nodes, false);
                        obj.logAll(sprintf('--- PARTITION END: reconnect {%s} ---', strjoin(arrayfun(@num2str,nodes,'UniformOutput',false),',')));
                        obj.flushPending();
                    case 'local_op'
                        node = ev.payload.node; op = ev.payload.op;
                        for j = 1:numel(obj.replicas)
                            if obj.connected(node, j)
                                obj.deliver(node, j, op);
                            else
                                obj.pending(end+1) = struct('from',node,'to',j,'op',op);
                            end
                        end
                    otherwise
                        error('Unknown event kind: %s', ev.kind);
                end
            end
            for i = 1:numel(obj.replicas)
                obj.replicas(i).recomputeFinal();
            end
        end
        
        function deliver(obj, from, to, op)
            r = obj.replicas(to);
            r.receiveOp(obj.t, op);
            outcome = 'meta';
            if strcmp(op.action,'write')
                if isKey(r.appliedNow, op.id) && r.appliedNow(op.id)
                    outcome = 'applied';
                else
                    outcome = 'rejected';
                end
            elseif any(strcmp(op.action,{'grant','revoke'}))
                outcome = op.action;
            end
            obj.timeline(end+1) = struct('time',obj.t,'node',to,'opid',op.id,'author',op.author,'action',op.action,'outcome',outcome);
        end
        
        function flushPending(obj)
            still = struct('from',{},'to',{},'op',{});
            for k = 1:numel(obj.pending)
                m = obj.pending(k);
                if obj.connected(m.from, m.to)
                    obj.deliver(m.from, m.to, m.op);
                else
                    still(end+1) = m; %#ok<AGROW>
                end
            end
            obj.pending = still;
        end
        
        function applyPartition(obj, nodes, startFlag)
            % If starting, sever edges between 'nodes' and the rest.
            % If ending, reconnect everything.
            N = numel(obj.replicas);
            M = obj.connected;
            if startFlag
                for i = 1:N
                    for j = 1:N
                        if (ismember(i,nodes) && ~ismember(j,nodes)) || (~ismember(i,nodes) && ismember(j,nodes))
                            M(i,j) = false;
                        end
                    end
                end
            else
                M(:,:) = true;
            end
            obj.connected = M;
        end
        
        function ok = convergeEqual(obj)
            vals = arrayfun(@(r) r.dataValue, obj.replicas);
            ok = all(vals == vals(1));
        end
        
        function ok = noUnauthorizedPostMerge(obj)
            % After recomputeFinal, ensure each replica's data equals the sum of its finalApplied writes.
            for i = 1:numel(obj.replicas)
                r = obj.replicas(i);
                writes = r.inbox(arrayfun(@(o) strcmp(o.action,'write'), r.inbox));
                s = 0;
                for k = 1:numel(writes)
                    if isKey(r.finalApplied, writes(k).id) && r.finalApplied(writes(k).id)
                        s = s + writes(k).payload;
                    end
                end
                if r.dataValue ~= s
                    ok = false; return;
                end
            end
            ok = true;
        end
        
        function logAll(obj, msg)
            for i = 1:numel(obj.replicas)
                obj.replicas(i).appendLog(obj.t, msg);
            end
        end
    end
end
