
function ensure_dir(d)
%ENSURE_DIR Create directory if it does not exist.
if ~exist(d, 'dir')
    mkdir(d);
end
end
