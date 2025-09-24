function tf = vc_leq(a, b)
%VC_LEQ  True iff vector clock a <= b component-wise.
tf = all(a <= b);
end
