% main program for getting coastline for each ArcticDEM tile
% Requirements: gdal software;ogr2ogr
% %%%% inputs needed
currentdir=pwd;
addpath(genpath(currentdir));

% %%%% control parameters
codedir=['/data/chunli/coastline/codec2/'];
addpath(genpath(codedir));
constant
width0=width+1e3; %buffer width of the a priori coastline, e.g., 2km. need to be slightly larger than width in Coastline.m

%Preparation: building folders
if ~exist(orthworkdir,'dir')
  mkdir(orthworkdir)
end
if ~exist(tiledirnew,'dir')
  mkdir(tiledirnew)
end
if ~exist('output','dir')
  mkdir('output')
end

if 0
macdir=[];
%General directory that contains the mosaic tile DEM files, such as /elev/dem/setsm/ArcticDEM/mosaic/v2.0/
tiledir=[macdir,'/data/chunli/coastline/'];%ArcticDEM mosaic tile directory. 
stripdir='/*/ArcticDEM/region*/strips/2m/'; %directory of strip files
multidir=[macdir,'/data1/pgc_projects/dai_aleutians_multi_mono/imagery/WV*/']; % directory of mono multispectral images
end

%addpath(genpath(multidir));
[status , cmdout ]=system(['find ',codedir,' -name GSHHS_f_L1.shp']);
shpname=deblank(cmdout);

filename='tilelist';
fid = fopen(filename);
n = linecount(fid);
fid = fopen(filename);
ftile=cell(n,1);
for i=1:n
   ftile{i}=fgetl(fid);
end

parpool(1)
%parfor xyid=1:n*m*ns*ms
parfor xyid=1:n
%for xid=7:8 %5:8 %6:7  %1:80
%   for yid=53:55 %1:80
%       for xids=1:2
%           for yids=1:2
                % 54_06_2_2_5m_v2 yid_xid_xids_yids %name convention
%   xid=X(xyid);yid=Y(xyid);
%   xids=XS(xyid);yids=YS(xyid);
%   xid=6;yid=55;xids=2;yids=1;%
%   tilefile=sprintf('%02d_%02d_%01d_%01d_5m_v2.0_reg_dem.tif',yid,xid,xids,yids);  %'54_06_2_2_5m_v2.0_reg_dem.tif';

    tilefile=ftile{xyid};
    [dir,ifile,ext] =fileparts(tilefile);
    r=1;
    xid= sscanf(ifile(r+3:(r+4)), '%g', 1);
    yid= sscanf(ifile(r:(r+1)), '%g', 1);
    xids= sscanf(ifile(r+6), '%g', 1);
    yids= sscanf(ifile(r+8), '%g', 1);

    % get the data boundary, rang0, of this DEM tile 
    dx=100e3;x0=-4000e3;y0=-4000e3;%xe=3400e3;ye=4000e3; %ArcticDEM Mosaic tiles coordinate reference;
    x=x0+(xid-1)*dx+(xids-1)*dx/2;y=y0+(yid-1)*dx+(yids-1)*dx/2;
%   rang0=[x x+dx/2 y y+dx/2];
    
    % Find whether this tile contains any coastline.
    % Buffer the tile boundary by width;
    rang0=[x-width0 x+dx/2+width0 y-width0 y+dx/2+width0];
    x0=[rang0(1) rang0(2) rang0(2) rang0(1) rang0(1) ];y0=[rang0(4) rang0(4) rang0(3) rang0(3) rang0(4) ];
    [lat0,lon0]=polarstereo_inv(x0,y0,[], [],70,-45);
    bb = geoshape(lat0,lon0,'Geometry','Polygon');
    tileshape=sprintf('output/%02d_%02d_%01d_%01d_tile.shp',yid,xid,xids,yids);
    tilecoastname=sprintf('output/%02d_%02d_%01d_%01d_tilegshhs.shp',yid,xid,xids,yids);
    shapewrite(bb,tileshape);
    system(['rm ',tilecoastname])
    system(['time ogr2ogr -overwrite -clipsrc ',tileshape,' ',tilecoastname,' ',shpname]);
    %ogr2ogr -overwrite -clipsrc tile.shp tilegshhs.shp GSHHS/GSHHS_f_L1.shp
    S = shaperead(tilecoastname);
    cnt=length(S); %figure;mapshow(S);
    if cnt==0; continue;end
    
fprintf (['\n Working on tile:',tilefile,'; \n'])

        tic

    [Co]=CoastTileMonoProb(tilefile,S);
    tileshape=sprintf('output/%02d_%02d_%01d_%01d_tile*',yid,xid,xids,yids);
        toc
            system(['rm ',tileshape]);


%           end %yids
%      end%xids
%   end % yid
%end %xid
end 


