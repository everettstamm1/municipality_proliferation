%{
project: LocGovFrag
title: maps.m
purpose: maps
input: panel_a_data.csv
output: 
author: DS
created: 2023.10.16

% DESCRIPTION OF PROCESS

1. load boundaries and block data
2. prepare segregation data

%}

clear
clc

addpath ~/Dropbox/Documents/matlab

cd '~/Dropbox/Research/municipality_proliferation'

%% load data

% state abbreviations

filename = 'data/raw/bls/state_abbrev_fips.csv';
statefips = readtable(filename);

statefips = renamevars(statefips, 'fips', 'stfips');

% state boundaries

state = shaperead('usastatehi', 'UseGeoCoords', true);

for k = 1:length(state)
    stateidx = strcmp(statefips.name, state(k).Name);
    state(k).abbr = statefips.abbr{stateidx};
    state(k).stid = statefips.stfips(stateidx);
end

%%
% load counties

zipfilename = 'data/raw/census/tl_2020_us_county.zip';
unzip(zipfilename);

county = shaperead('tl_2020_us_county.shp', 'UseGeoCoords', true);

delete('tl_2020_us_county.*');

countytbl = struct2table(county);

countytbl.stfips = cellfun(@str2double, {county.STATEFP}');
countytbl.fips = cellfun(@str2double, {county.COUNTYFP}');

countytbl.origin_fips = countytbl.stfips*1e3 + countytbl.fips;


%%
% migration data

migdata = readtable('data/clean/panel_a_data.csv');

% sum decades of migrants between origins and destinations

years = 1950:10:1970;

migdata.act_outmig(:) = 0;
migdata.pred_outmig(:) = 0;

for t = 1:length(years)
    migdata.act_outmig = migdata.act_outmig + ...
        migdata.(['origin_fips_act_outmig' num2str(years(t))]);
    
    migdata.pred_outmig = migdata.pred_outmig + ...
        migdata.(['origin_fips_pred_outmig' num2str(years(t))]);
end

migdata = join(migdata, grpstats( ...
    migdata(:,{'dest_cz_name','cz_recent_black_migrants'}), ...
    {'dest_cz_name'}, '@sum'));

migdata.shblackmig = migdata.cz_recent_black_migrants ...
    ./migdata.Fun1_cz_recent_black_migrants;


%% find five largest recent origins for each destination

dests = unique(migdata.dest_cz_name);
keep = false(height(migdata),1);

for i = 1:length(dests)
    idx = strcmp(migdata.dest_cz_name, dests(i));
    fivehighest = maxk(migdata.cz_recent_black_migrants(idx), 5);
    keep(idx) = ...
        ismember(migdata.cz_recent_black_migrants(idx), fivehighest);
end

migdata = migdata(keep, :);

origs = unique(migdata.origin_fips_name);

% prepare origin county shapefile
countytbl = innerjoin(countytbl, migdata);
migcounty = table2struct(countytbl);


%% geocode destinations and origins

desttbl = table(dests, 'VariableNames', {'Name'});
origtbl = table(origs, 'VariableNames', {'Name'});

for i = 1:length(dests)
    coords = geoCode(dests{i}, 'osm');
    
    desttbl.lat(i) = coords(1);
    desttbl.lon(i) = coords(2);
end

for i = 1:length(origs)
    coords = geoCode(origs{i}, 'osm');
    
    origtbl.lat(i) = coords(1);
    origtbl.lon(i) = coords(2);
    
    idx = strcmp(migdata.origin_fips_name, origs(i));
    migdata.orig_lat(idx) = coords(1);
    migdata.orig_lon(idx) = coords(2);
end
%%
% drop origins with missing location
origtbl = origtbl(~isnan(origtbl.lat),:);
migdata = migdata(~isnan(migdata.orig_lat),:);

% assign colors
migdata.clr(migdata.dest_cz_name == "Cleveland, OH") = {[1 .8 0]};
migdata.clr(migdata.dest_cz_name == "Columbus, OH") = {[0 .5 0]};

%% define spatial network

g = digraph(migdata.origin_fips_name, migdata.dest_cz_name, ...
    migdata.shblackmig);

for i = 1:height(g.Nodes)
    if any(strcmp(g.Nodes.Name(i), dests))
        idx = strcmp(desttbl.Name, g.Nodes.Name(i));
        
        g.Nodes.Lat(i) = desttbl.lat(idx);
        g.Nodes.Lon(i) = desttbl.lon(idx);
    else
        idx = strcmp(origtbl.Name, g.Nodes.Name(i));
        
        g.Nodes.Lat(i) = origtbl.lat(idx);
        g.Nodes.Lon(i) = origtbl.lon(idx);
    end
end

%% map

states = shaperead('usastatelo', 'UseGeoCoords', true);

figure('Position', [10 10 500 650])
axis([-90 -80 32 42])

hold on;
geoshow(states, 'FaceColor', [.95 .95 .95], ...
    'EdgeColor', [.7 .7 .7], 'FaceAlpha', .5);

symspec = makesymbolspec("Polygon", ...
    {'pred_outmig', [-250000 40000], 'FaceColor', gray});
geoshow(migcounty, 'SymbolSpec', symspec, 'EdgeAlpha', .2)

p = plot(g, 'LineWidth', migdata.shblackmig*50, ...
    'EdgeColor', cell2mat(migdata.clr), ...
    'ArrowSize', 15, 'ArrowPosition', .98, 'NodeFontSize', 11);

p.XData = g.Nodes.Lon;
p.YData = g.Nodes.Lat;

dest_idx = ismember(p.NodeLabel, {'Columbus, OH', 'Cleveland, OH'});

p.Marker = repmat({'.'}, length(p.NodeLabel), 1);
p.Marker(dest_idx) = {'o'};
p.MarkerSize = repmat(10, length(p.NodeLabel), 1);
p.MarkerSize(dest_idx) = [13 13];
p.NodeColor = repmat([.5 .5 .5], length(p.NodeLabel), 1);
p.NodeColor(p.NodeLabel == "Cleveland, OH",:) = [.9 .7 0];
p.NodeColor(p.NodeLabel == "Columbus, OH",:) = [0 .4 0];

colormap(flipud(gray))
c = colorbar('SouthOutside');
c.Position = [.18 .84 .15 .02];

c.Label.String = 'Predicted out-migration';
c.Ticks = [.1 .9];
c.TickLabels = {'Small', 'Large'};

box on
set(gca,'XTickLabel',[]);
set(gca,'YTickLabel',[]);
set(gca,'XTick',[])
set(gca,'YTick',[])
set(gcf,'color','w');

print('-bestfit', '-dpdf', '-r300', 'exhibits/figures/map_example.pdf');

close all


%% Municipality maps

% load data

% municipality shapefile with year of incorporation
fname = 'data/clean/other/municipal_shapefile/municipal_shapefile.shp';
munis = shaperead(fname, 'UseGeoCoords', true, ...
    'Selector', {@(x1,x2) strcmp(x1, '39') && contains(x2, 'C'), ...
    'STATEFP', 'CLASSFP'});

munis = keepfield(munis, {'Geometry' , 'BoundingBox', 'Lat', 'Lon', ...
    'GEOID', 'yr_ncrp', 'cz', 'cz_name'});

munis = munis( ...
    ismember({munis.cz_name}, {'Cleveland, OH', 'Columbus, OH'}));

%%
% race data for munis
fname = 'data/raw/census/nhgis0043_csv/nhgis0043_ds258_2020_place.csv';
race = readtable(fname);

race = renamevars(race, {'U7J001', 'U7J002'}, {'pop', 'white'});

keep = {'GEOID', 'pop', 'white'};
race = removevars(race, ~ismember(race.Properties.VariableNames, keep));

race.GEOID = cellfun(@(x) regexprep(x, '\w*US', ''), ...
    race.GEOID, 'UniformOutput', false);

race.shwhite = race.white./race.pop;

munistbl = join(struct2table(munis), race);

munistbl.clat = cellfun(@nanmean, munistbl.Lat);
munistbl.clon = cellfun(@nanmean, munistbl.Lon);

munis = table2struct(munistbl);

%% prepare figure

newincorp = [munis.yr_ncrp] >= 1940 & [munis.yr_ncrp] <= 1970;

symspec = makesymbolspec("Polygon", ...
    {'shwhite', [0 1], 'FaceColor', parula});


%% compile figure

f = figure('Position', [10 10 500 650]);

tiledlayout(2,1, 'TileSpacing', 'tight')

% Columbus, OH
nexttile

axis([-83.5 -82.5 39.7 40.3])
geoshow(munis, 'SymbolSpec', symspec)
hold on;

box on
set(gca,'XTickLabel',[]);
set(gca,'YTickLabel',[]);
set(gca,'XTick',[])
set(gca,'YTick',[])
set(gcf,'color','w');

g1 = scatter([munis(newincorp).clon], [munis(newincorp).clat], 100, ...
    [1 0 0]);
g1.MarkerFaceColor = [1 0 0];
g1.MarkerFaceAlpha = .2;
g1.LineWidth = 1;

text(-83.46, 39.74, 'Columbus, OH', 'FontSize', 24)


% Cleveland, OH
nexttile

axis([-82.15 -81.15 41.2 41.8])
geoshow(munis, 'SymbolSpec', symspec)
hold on;

box on
set(gca,'XTickLabel',[]);
set(gca,'YTickLabel',[]);
set(gca,'XTick',[])
set(gca,'YTick',[])
set(gcf,'color','w');

g1 = scatter([munis(newincorp).clon], [munis(newincorp).clat], 100, ...
    [1 0 0]);
g1.MarkerFaceColor = [1 0 0];
g1.MarkerFaceAlpha = .2;
g1.LineWidth = 1;

text(-82.11, 41.24, 'Cleveland, OH', 'FontSize', 24)

colormap(parula)
c = colorbar('SouthOutside');
c.Position = [.23 .37 .15 .02];

c.Label.String = 'Share White in Municipality';
c.Ticks = [0 .5 1];
c.TickLabels = [0 .5 1] ;

legend(g1, 'Incorporated between 1940-1970', 'Location', 'NorthWest')
legend boxoff
%%
print('-bestfit', '-dpdf', '-r300', 'exhibits/figures/map_frag.pdf');

%close all

%%

%{
%% Detroit example


f = figure;
f.Position = [500 500 1600 1200];


colormap(flipud(parula))
c = colorbar('SouthOutside');
c.FontSize = 15;
c.Position = [.2 .25 .12 .01];  
c.Label.String = ['Share ' races_lbl{r} ' in municipality'];
c.Ticks = 0:.25:1;

axis tight
axis off
set(gcf,'color','w');

% ensure PDF print preserves size of figure
f.Units = 'centimeters';
f.PaperUnits = 'centimeters';
f.PaperSize = f.Position(3:4);
%%
print('-bestfit', '-dpdf', '-r300', ...
    ['../figures/geoshow_map_' races{r} '_New York_2020.pdf']);
close all

%}