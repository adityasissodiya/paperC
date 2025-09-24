classdef Replica < handle
%REPLICA  A simulated replica with CRDT state, ACL events, and an inbox.
    properties
        id
        name
        nReplicas
        vc           % local vector clock (1 x n)
        dataValue    % simple counter for demo
        aclEvents    % struct array: (type, principal, clock)
        inbox        % received ops (structs)
        appliedNow   % map op.id -> true/false at arrival
        finalApplied % map op.id -> true/false after quiescence
        log          % textual log lines
    end
    methods
        function obj = Replica(id, nReplicas, name)
            obj.id = id;
            obj.nReplicas = nReplicas;
            if nargin < 3, name = sprintf('Node%d', id); end
            obj.name = name;
            obj.vc = vc_init(nReplicas);
            obj.dataValue = 0;
            obj.aclEvents = struct('type',{},'principal',{},'clock',{});
            obj.inbox = struct('id',{},'author',{},'action',{},'target',{},'payload',{},'clock',{},'sigValid',{});
            obj.appliedNow = containers.Map('KeyType','char','ValueType','logical');
            obj.finalApplied = containers.Map('KeyType','char','ValueType','logical');
            obj.log = {};
        end
        
        function tick(obj)
            obj.vc = vc_increment(obj.vc, obj.id);
        end
        
        function clk = currentClock(obj)
            clk = obj.vc;
        end
        
        function addAclEvent(obj, type, principal, clock)
            e = struct('type',type,'principal',principal,'clock',clock);
            obj.aclEvents(end+1) = e;
        end
        
        function applyData(obj, op)
            % Simple demo: 'write' means increment by payload (for counter)
            if strcmp(op.target, 'counter')
                obj.dataValue = obj.dataValue + op.payload;
            end
        end
        
        function appendLog(obj, t, msg)
            obj.log{end+1} = sprintf('[t=%.2f] %s: %s', t, obj.name, msg);
        end
        
        function receiveOp(obj, tnow, op)
            % Merge clocks on receive
            obj.vc = vc_merge(obj.vc, op.clock);
            % Store op
            obj.inbox(end+1) = op;
            
            % Signature check
            if ~op.sigValid
                obj.appliedNow(op.id) = false;
                obj.appendLog(tnow, sprintf('DROP %s: invalid signature (author=%s)', op.id, op.author));
                return;
            end
            
            % If ACL event, record and done
            if strcmp(op.action, 'grant')
                obj.addAclEvent('grant', op.payload.principal, op.clock);
                obj.appendLog(tnow, sprintf('grant(%s) recorded (op=%s)', op.payload.principal, op.id));
                obj.appliedNow(op.id) = true; % meta-apply (policy)
                return;
            elseif strcmp(op.action, 'revoke')
                obj.addAclEvent('revoke', op.payload.principal, op.clock);
                obj.appendLog(tnow, sprintf('revoke(%s) recorded (op=%s)', op.payload.principal, op.id));
                obj.appliedNow(op.id) = true;
                return;
            end
            
            % Data op: check authorization at current knowledge (causal cut)
            tf = authorized_at_cut(obj.aclEvents, op, @vc_leq, @vc_concurrent);
            if tf
                obj.applyData(op);
                obj.appliedNow(op.id) = true;
                obj.appendLog(tnow, sprintf('%s %s %+g (✔ applied)', op.author, op.action, op.payload));
            else
                obj.appliedNow(op.id) = false;
                obj.appendLog(tnow, sprintf('%s %s %+g (pending or ✖ unauthorized)', op.author, op.action, op.payload));
            end
        end
        
        function recomputeFinal(obj)
            % Materialize from scratch using all known ops and ACL events at final knowledge.
            obj.dataValue = 0;
            writes = obj.inbox(arrayfun(@(o) strcmp(o.action,'write'), obj.inbox));
            for k = 1:numel(writes)
                op = writes(k);
                tf = authorized_at_cut(obj.aclEvents, op, @vc_leq, @vc_concurrent);
                if tf
                    obj.applyData(op);
                    obj.finalApplied(op.id) = true;
                else
                    obj.finalApplied(op.id) = false;
                end
            end
        end
    end
end
