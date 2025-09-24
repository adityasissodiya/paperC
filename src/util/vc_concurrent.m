function tf = vc_concurrent(a, b)
%VC_CONCURRENT  True if a and b are concurrent (neither <= the other).
tf = ~(vc_leq(a,b) || vc_leq(b,a));
end
