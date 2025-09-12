
function disp_map(m)
%DISP_MAP Print containers.Map contents in a stable order.
k = m.keys;
k = sort(k);
for i = 1:numel(k)
    v = m(k{i});
    if isstruct(v)
        fprintf('%s -> ', k{i});
        disp(v);
    else
        fprintf('%s -> %s\n', k{i}, mat2str(v));
    end
end
end
