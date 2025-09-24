function tests = test_invariants
%TEST_INVARIANTS  Basic safety & convergence tests for T1..T4.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
addpath(genpath('.'));
end

function test_T1(tc)
sim/T1_basic_authorized;
net = evalin('base','NET_T1');
verifyTrue(tc, net.convergeEqual(), 'Replicas did not converge in T1');
verifyTrue(tc, net.noUnauthorizedPostMerge(), 'Unauthorized effect detected in T1');
end

function test_T2(tc)
sim/T2_partition_unauthorized;
net = evalin('base','NET_T2');
verifyTrue(tc, net.convergeEqual(), 'Replicas did not converge in T2');
verifyTrue(tc, net.noUnauthorizedPostMerge(), 'Unauthorized effect detected in T2');
end

function test_T3(tc)
sim/T3_concurrent_acl_conflict;
net = evalin('base','NET_T3');
verifyTrue(tc, net.convergeEqual(), 'Replicas did not converge in T3');
verifyTrue(tc, net.noUnauthorizedPostMerge(), 'Unauthorized effect detected in T3');
end

function test_T4(tc)
sim/T4_backdating_attack;
net = evalin('base','NET_T4');
verifyTrue(tc, net.convergeEqual(), 'Replicas did not converge in T4');
verifyTrue(tc, net.noUnauthorizedPostMerge(), 'Unauthorized effect detected in T4');
end
