function [  ] = digElectrodes( brainPath, electrodePath )
%DIG_ELECTRODES serves as a post-processing step in the coregistration
%process, unburying any electrodes that are hidden underneath brain tissue
%in the output segmentation. The original electrode nifti file is
%overwritten with the new electrode locations.
%
% INPUTS
%        brainPath:  filepath to brainMask.nii.gz output from skull
%                    stripping step of coregister
%
%        electrodePath: filepath to aligned electrode segmentation (electrodes
%                    only)
%
% OUTPUTS
%        none, but original electrode file is overwritten
%
% EXTERNAL FILE REQUIREMENTS
%
%       Nifti toolbox for MATLAB: 
%           http://www.mathworks.com/matlabcentral/fileexchange/8797
%
% KNOWN INCOMPATIBILITES
%
%       None
%
% CONTRIBUTORS
%
%        Created by:
%            Allison Pearce
%            July 2012
%        Translational Neuroengineering Lab, University of Pennsylvania
%



%%-------------------------------------------------------------------------
% INIT
%-------------------------------------------------------------------------

% unzip files and load image matrices
str = sprintf(['! gunzip ' brainPath]);
eval(str);
str = sprintf(['! gunzip ' electrodePath]);
eval(str);
fn_brain = char(regexp(brainPath,'(\w+).nii.gz','tokens','once')); 
bImg = load_untouch_nii([fn_brain '.nii']);
bImg = bImg.img;
fn_elec = char(regexp(electrodePath,'(\w+).nii.gz','tokens','once')); 
e_nii = load_untouch_nii([fn_elec '.nii']);
eImg = e_nii.img;
if sum(size(bImg) == size(eImg)) ~= 3
    error(['size of brain mask not equal to size of electrode segmentation' ...
        ' >>> exiting']);
end  

eImg_out = zeros(size(eImg));
%-------------------------------------------------------------------------

%% -------------------------------------------------------------------------
% MAIN
%------------------------------------------------------------------------

% separate individual electrodes
econn = bwconncomp(eImg);
eCell = cell(econn.NumObjects,1);
for i=1:econn.NumObjects
    [Xi, Yi, Zi] = ind2sub(size(eImg),econn.PixelIdxList{i});
    eCell{i} = [Xi Yi Zi];
end

bInds = find(bImg ~= 0);
[BX BY BZ] = ind2sub(size(bImg),bInds);
com = [ median(BX) median(BY) median(BZ) ];
for e=1:econn.NumObjects
    coords = eCell{e};
    e_com = round([median(coords(:,1)) median(coords(:,2)) ...
        median(coords(:,3))]); % shouldn't have to round this, but getting decimals
    
    dir = e_com - com;
    dir = dir./gcd(gcd(dir(1),dir(2)),dir(3)); % reduce while preserving direction
    dist = round(sqrt(sum((e_com - dir).^2))); % euclidean distance
    path = round([linspace(e_com(1),e_com(1) + dir(1),dist)' ...
        linspace(e_com(2),e_com(2) + dir(2),dist)' ...
        linspace(e_com(3),e_com(3) + dir(3),dist)']);
    for d=1:length(path)
        pt = path(d,:);
        if bImg(pt(1),pt(2),pt(3)) == 0
            break
        end
    end
    % shift old electrode by difference between exterior point and center
    % of mass
    new_xyz = coords + repmat(pt - e_com,size(coords,1),1);
    % there has to be a better way to do this
    for i = 1:size(new_xyz,1)
        eImg_out(new_xyz(i,1), new_xyz(i,2), new_xyz(i,3)) = 1;
    end
   
end    


% save and rezip files             
e_nii.img = eImg_out;
save_untouch_nii(e_nii,[fn_elec '.nii']);
str = sprintf('! gzip %s.nii', fn_brain);
eval(str);
str = sprintf('! gzip %s.nii', fn_elec);
eval(str);


end

