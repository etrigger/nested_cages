% Script to run on Imac

% [V0,F0] = load_mesh('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-300k_varap/octopus-300k.ply');
% levels = floor(2.^((-20:2:-2)/3)*size(F0,1));
% [cages_V,cages_F,~,~,~,timing] = ...
% multires_per_layer( ...
% V0,F0, ...
% levels, ...
% 'QuadratureOrder',2, ...
% 'ExpansionEnergy','surface_arap', ...
% 'FinalEnergy','none', ...
% 'BetaInit',1e-2, ...
% 'Eps',1e-3,...
% 'PartialPath','partial_01_13.mat');
% write_cages('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-300k_varap/octopus',cages_V,cages_F);
% save('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-300k_varap/timing.mat','timing')
% % Obs.: Error
% % Removing 1 skinny facets...
% % ^[OD^[OC  /private/tmp/tp9d214703_7304_49e2_bb4f_604a63ba06fb.offError using meshfix (line 22)
% % /bin/bash: ^[OD^[OC: command not found
% % ^[OD^[OC

% [V0,F0] = load_mesh('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_478k_varap/max-clean-478k.ply');
% V0 = V0/max(max(abs(V0)));
% levels = floor(2.^((-22:2:-2)/3)*size(F0,1));
% [cages_V,cages_F,~,~,~,timing] = ...
%   multires_per_layer( ...
%   V0,F0, ...
%   levels, ...
%   'QuadratureOrder',2, ...
%   'ExpansionEnergy','displacement_path', ...
%   'FinalEnergy','volume', ...
%   'BetaInit',1e-2, ...
%   'EpsFinal',5e-4,...
%   'EpsExpansion',5e-3,...
%   'PartialPath','partial_01_13.mat',...
%   'NewFlow',true);
% write_cages('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_478k_volume_new_test/max-478',cages_V,cages_F);
% save('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_478k_colume_new_test/timing.mat','timing')
% % Obs.: Stuck with the simulation. Canceled to try new flow ideas

% [V0,F0] = load_mesh('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/horse_volume/horse_0.obj');
% levels = 1000:500:25000; % 50 layers
% [cages_V,cages_F,~,~,~,timing] = ...
%   multires_per_layer( ...
%   V0,F0, ...
%   levels, ...
%   'QuadratureOrder',2, ...
%   'ExpansionEnergy','surface_arap', ...
%   'FinalEnergy','none', ...
%   'BetaInit',1e-2, ...
%   'EpsFinal',1e-3,...
%   'EpsExpansion',1e-3,...
%   'PartialPath','partial_01_13.mat');
% write_cages('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/horse_arap50_final/maxplank',cages_V,cages_F);
% save('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/horse_arap50_final/timing.mat','timing');
% % Obs.: Recovered weird tale (OK)

% [V0,F0] = load_mesh('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_small_1doll/maxplank_small.obj');
% levels = 750:250:13000; %50 layers
% [cages_V,cages_F,~,~,~,timing] = ...
%   multires_per_layer( ...
%   V0,F0, ...
%   levels, ...
%   'QuadratureOrder',2, ...
%   'ExpansionEnergy','volumetric_arap', ...
%   'FinalEnergy','none', ...
%   'BetaInit',1e-2, ...
%   'EpsFinal',1e-3,...
%   'EpsExpansion',1e-3,...
%   'PartialPath','partial_01_13.mat');
% write_cages('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_varap50_final/maxplank',cages_V,cages_F);
% save('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/maxplank_varap50_final/timing.mat','timing');
% % Obs.: ARAP:Stuck in the last step for the 2nd layer

[V0,F0] = load_mesh('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-500k-disppath/octopus-500k.ply');
V0 = V0/max(max(abs(V0)));
levels = floor(2.^((-22:2:-2)/3)*size(F0,1));
[cages_V,cages_F,~,~,~,timing] = ...
  multires_per_layer( ...
  V0,F0, ...
  levels, ...
  'QuadratureOrder',2, ...
  'ExpansionEnergy','surface_arap', ...
  'FinalEnergy','none', ...
  'BetaInit',1e-2, ...
  'EpsFinal',1e-3,...
  'EpsExpansion',1e-3,...
  'PartialPath','partial_01_13.mat');
write_cages('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-500k-varap_final/octopus',cages_V,cages_F);
save('/Users/leokollersacht/Documents/nested_cages/Meshes/Results/octopus-500k-varap_final/timing.mat','timing')
% Obs.: VARAP: Eltopo stuck at the last step of first layer.
% Try ARAP now