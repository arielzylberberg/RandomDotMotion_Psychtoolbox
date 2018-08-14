
function inside = isInsideRegion(pos, region)

% function in = isInsideRegion(pos, region)
% 
% checks is pos, defined as [x y] or an n*2 matrix, is inside a specified
% region 
% 
% Input
%     pos       [x, y] or an n*2 matrix in screen coordinates 
%     region is a structure with two fields 
%       type    can be 'rect', 'circ', 'area'
%       spec    if type is 'rect', spec defines a rectangle [xmin ymin xmax ymax]
%               if type is 'ellipse', spec defines an ellipse. in this case spec is
%               a structure with these fields
%                   center      the center of the circle in screen coordinates [x y]
%                   radius      the x and y radius of the ellipse [rx ry]
%               if type is 'area', spec defines a bitmap mask. in this case
%               spec is a structure with these fields
%                   center      the center of the mask in screen coordinate [x y]
%                   mask        a 2D array with positive values corresponding
%                               to regions that are considered inside and zero
%                               or negative values for regions considered
%                               outside
%
% Output
%   inside      1 if pos is inside the region, 0 otherwise
% 

% 
% 09/26/07  Developed by RK
% 

inside = 0;

switch region.type,
    case 'rect',
        inside = pos(:,1)>=region.spec(1) && pos(:,1)<region.spec(3) && ...
                 pos(:,2)>=region.spec(2) && pos(:,2)<region.spec(4);
    case 'ellipse',
        n = size(pos,1);
        d = ((pos-repmat(region.spec.center,n,1))./repmat(region.spec.radius,n,1));
        inside = sqrt(sum(d.^2,2))<=1;
    case 'area',
        mask_size = fliplr(size(region.spec.mask));
        ind = floor(pos-region.spec.center+mask_size/2) + 1;
        if ind(1)>=1 && ind(1)<=mask_size(1) && ind(2)>=1 && ind(2)<=mask_size(2),
            if region.spec.mask(ind(2),ind(1)) > 0,
                inside = 1;
            end;
        end;
    otherwise,
        error('region type is not recognized');
end;





