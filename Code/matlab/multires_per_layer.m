function [cages_V,cages_F,Pall,V_coarse,F_coarse,timing] = multires_per_layer(V0,F0,levels,varargin)
  % MULTIRES_PER_LAYER
  % [cages_V,cages_F,Pall,V_coarse,F_coarse] = multires_per_layer(V0,F0,levels,varargin)
  %
  % Given a fine traingle mesh (V0,F0) and an output numeber of faces
  % (for each level), obtains nested cages based on specified method
  %
  % Input:
  %   V0  (#vertices)x3 list of mesh vertex positions of the initial fine mesh
  %   F0  (#faces)x3 list of vertex indices that form each face of the
  %   initial mesh
  %   levels  (#levels)x1 vector specifying the number of faces for each
  %   output mesh. We assume level(j)<level(j+1)
  %   Optional: 
  %    'flow_type': 'signed_distance_direction' is the default and we have
  %    been using only this one
  %     'energy': followed by either 'displacement_step' or
  %       'displacement_initial' or 'symmetry_x' or 
  %       'volume' or 'displacement_step_and_volume' (default)
  %     'quadrature_order': 1, 2 or 3 (default=1)
  %     'simulation_steps': quantity of (linear) simulation steps for each
  %     flow step. Default = 1
  %     ('V_coarse','F_coarse'): previously computed initial coarse layers
  %     'Pall': previously computed flow (single layer only for now)
  %     'method': can be either 'shrink_fine_and_expand', 
  %       'shrink_coarse_refining' or 'expand_coarse_and_shrink' 
  %       or 'shrink_fine_and_expand_coarse' (default)
  % Output:
  %   cages_V   array with (#levels) matrices with vertices positions. 
  %             cages_V{k} corresponds to levels(k)-output mesh
  %   cages_F   array with (#levels) matrices with face indices. 
  %             cages_F{k} corresponds to levels(k)-output mesh
  %   Pall      sequence of meshes from the flow
  %   V_coarse  initial coarse mesh for each level
  %   F_coarse  initial coarse mesh for each level
  %   timing:   struct with timing.decim, timing.flow and 
  %             timing.simulation, timing.etienne
  
  flow_type = 'signed_distance_direction';
  simulation_steps = 1;
  energy = 'displacement_step_and_volume';
  quadrature_order = 1;
  V_coarse = [];
  F_coarse = [];
  Pall = [];
  method = 'shrink_fine_and_expand_coarse';
  % below parameter only used for ElTopo
  eps_distance = 1e-3; %( obs.: 1e-3 worked very well for bunny and pelvis)
  beta_init = 5e-3;
  
  % save timings
  timing.decimation = 0.0;
  timing.flow = 0.0;
  timing.simulation = 0.0;
  timing.etienne = 0; % not exactly timing, but let's put in this struct
  
  % Parsing arguments
  ii = 1;
  while ii < numel(varargin)
      switch varargin{ii}
          case 'flow_type'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              flow_type = varargin{ii};
          case 'simulation_steps'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              simulation_steps = varargin{ii};
          case 'energy'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              energy = varargin{ii};
          case 'quadrature_order'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              quadrature_order = varargin{ii};
          case 'Pall'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              Pall = varargin{ii};
          case 'V_coarse'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              V_coarse = varargin{ii};
          case 'F_coarse'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              F_coarse = varargin{ii};
          case 'method'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              method = varargin{ii};
          case 'eps_distance'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              eps_distance = varargin{ii};
          case 'beta_init'
              assert(ii+1<=numel(varargin));
              ii = ii+1;
              beta_init = varargin{ii};
          otherwise
              error('Unsupported parameter: %s',varargin{ii});
      end
      ii = ii+1;
  end
  
  % number of levels
  num_levels = size(levels,2);
  
  if (isempty(V_coarse)&&isempty(F_coarse))
      % coarsen the mesh with Qslim with different levels
      
      for k=1:num_levels
          % if energy is symmetry_x, perform special decimation to produce
          % symmetric initial coarse meshes
          if strcmp(energy,'symmetry_x')

              % I have migrated the symmetric decimation to a separate
              % function. Requires tests
              [V_coarse{k},F_coarse{k}] = symmetry_x_decimation(V0,F0,levels(k));

          end
          
      end
      
  end
  
  figure;
  
  switch method
      
      case 'shrink_fine_and_expand'
  
          % Define last level as input mesh
          V_coarse{num_levels+1} = V0;
          F_coarse{num_levels+1} = F0;

          % loop over different levels
          for k=num_levels+1:-1:2
              
              % save partial result
              save('partial.mat','Pall','V_coarse','F_coarse','V0','F0');

              % for all other energies but 'symmetry_x', decimate with 
              % CGAL + meshfix
              if ~strcmp(energy,'symmetry_x')
                tic
                [V_coarse{k-1},F_coarse{k-1}] = cgal_simplification(V_coarse{k},F_coarse{k},levels(k-1));
                [V_coarse{k-1},F_coarse{k-1}] = meshfix(V_coarse{k-1},F_coarse{k-1});
                timing.decimation = timing.decimation + toc; 
              end

            if (isempty(Pall) || size(Pall,2)~=num_levels)
                tic
                [Pall,F_refined] = shrink_fine_to_inside_coarse_3D(V_coarse{k},F_coarse{k},...
                    V_coarse{k-1},F_coarse{k-1},'flow_type',flow_type,...
                    'V_to_intersect',V_coarse{k-1},'F_to_intersect',F_coarse{k-1},...
                    'quadrature_order',quadrature_order);
                Pall_all_times{k-1} = Pall;
                timing.flow = timing.flow + toc; 
            end

            % push coarse mesh with physical simulation to obtain the cages
            tic
            [V_coarse_new,~,~] = combined_step_project(Pall,F_refined,...
                V_coarse{k-1},F_coarse{k-1},'simulation_steps',simulation_steps,'energy',energy);
            timing.simulation = timing.simulation + toc;

            % The input for the next level is the output of this level
            V_coarse{k-1} = V_coarse_new;

            cla;

          end

          % output all flow meshes for all levels
          Pall = Pall_all_times;

          % output all cages
          for k=1:num_levels

              cages_F{k} = F_coarse{k};
              cages_V{k} = V_coarse{k};

          end
          
      case 'shrink_coarse_refining'
          
          % Define last level as input mesh
          V_coarse{num_levels+1} = V0;
          F_coarse{num_levels+1} = F0;
          
          % loop over different levels
          for k=num_levels:-1:1
              
              V0 = V_coarse{k+1};
              F0 = F_coarse{k+1};
              iter = 1;
          
              min_x = min(V0(:,1))-1e-2;
              min_y = min(V0(:,2))-1e-2;
              min_z = min(V0(:,3))-1e-2;
              max_x = max(V0(:,1))+1e-2;
              max_y = max(V0(:,2))+1e-2;
              max_z = max(V0(:,3))+1e-2;

              % initial coarse mesh: cube around the input fine mesh
              V_coarse_ = [min_x min_y min_z; min_x max_y min_z; min_x min_y max_z; ...
                  min_x max_y max_z; max_x min_y min_z; max_x max_y min_z; ...
                  max_x min_y max_z; max_x max_y max_z];
              F_coarse_ = [1 3 2; 2 3 4; 1 5 3; 3 5 7; 1 2 5; 2 6 5;...
                  5 6 7; 7 6 8; 2 8 6; 2 4 8; 3 7 4; 7 8 4];

              
              % next: correct output levels for this while
              while( (size(F_coarse_,1)<levels(k)) || (iter==1))
                  % Define 2 steps of the flow as the initial mesh
                  Pall(:,:,1) = V0;
                  Pall(:,:,2) = V0;
                  % minimize energy on the coarse mesh
                  [V_coarse_new,~,F_to_refine] = combined_step_project(Pall,F0,...
                      V_coarse_,F_coarse_,'simulation_steps',simulation_steps,'energy',energy,'min_progress',1e-3,'method','shrink_coarse_refining');
                                    
                  % claer Pall so we can overwrite Pall(:,:,1) and Pall(:,:,2)
                  P_all_times{k} = Pall; 
                  clear Pall;
                  
                  if ~isempty(F_to_refine)
                    [V_coarse_,F_coarse_] = upsample(V_coarse_new,F_coarse_,'OnlySelected',F_to_refine);

                    % attract newly created points
                    V_coarse_att = V_coarse_;
                    [~,~,att,~] = signed_distance(V_coarse_(size(V_coarse_new,1)+1:size(V_coarse_,1),:),V0,F0);
                    V_coarse_att(size(V_coarse_new,1)+1:size(V_coarse_,1),:) = V_coarse_att(size(V_coarse_new,1)+1:size(V_coarse_,1),:) +...
                        0.0*(att-V_coarse_att(size(V_coarse_new,1)+1:size(V_coarse_,1),:));
                    [V_eltopo,~] = collide_eltopo_mex([V0;V_coarse_],[F0;size(V0,1)+F_coarse_],[V0;V_coarse_att],size(V0,1),1e-4,1e-10);
                    V_coarse_ = V_eltopo(size(V0,1)+1:end,:);

                  else
                      V_coarse_ = V_coarse_new;
                  end
                  
                  % if refinement exceeds number of faces, output previous
                  % mesh and leave loop
                  if (size(F_coarse_,1)>levels(k))
                      V_coarse_ = V_coarse_prev;
                      F_coarse_ = F_coarse_prev;
                      break;
                  end
                  
              end
              
              V_coarse{k} = V_coarse_;
              F_coarse{k} = F_coarse_;
              % output level
              cages_F{k} = F_coarse{k};
              cages_V{k} = V_coarse{k};
              
          end
          
          Pall = P_all_times;
          
      case 'expand_coarse_and_shrink'
          
          % Define last level as input mesh
          V_coarse{num_levels+1} = V0;
          F_coarse{num_levels+1} = F0;
          
          % loop over different levels
          for k=num_levels:-1:1
              
              [V_coarse{k},F_coarse{k}] = cgal_simplification(V_coarse{k+1},F_coarse{k+1},levels(k));
              [V_coarse{k},F_coarse{k}] = meshfix(V_coarse{k},F_coarse{k});
              
              % expand coarse mesh
              Pall = expand_coarse_to_outside_fine_3D(V_coarse{k},F_coarse{k},...
                  V_coarse{k+1},F_coarse{k+1},'quadrature_order',quadrature_order);
              
              Pall_all_times{k} = Pall;
              
              % shrink coarse mesh
              
              % output level
              cages_F{k} = F_coarse{k};
              cages_V{k} = V_coarse{k};
              
          end
          
          Pall = Pall_all_times;
          
      case 'shrink_fine_and_expand_coarse'
          
          % Define last level as input mesh
          V_coarse{num_levels+1} = V0;
          F_coarse{num_levels+1} = F0;
          
          cages_V{num_levels+1} = V0;
          cages_F{num_levels+1} = F0;
          
          % loop over different levels
          for k=num_levels:-1:1
              
%               % only generate coarse layers if they were not prescribed
%               if (isempty(V_coarse) && isempty(F_coarse))
                  tic
                  [V_coarse{k},F_coarse{k}] = cgal_simplification(cages_V{k+1},cages_F{k+1},levels(k));
                  [V_coarse{k},F_coarse{k}] = meshfix(V_coarse{k},F_coarse{k});
                  timing.decimation = timing.decimation + toc;
%               end
              
              % save partial result
              save('partial.mat','Pall','V_coarse','F_coarse','V0','F0');
              
              % shirnk fine mesh, expand coarse mesh
              tic
              [Pall,Pall_coarse,F_exp,F_shrink] = shrink_fine_expand_coarse_3D(cages_V{k+1},cages_F{k+1},...
                  V_coarse{k},F_coarse{k},'quadrature_order',quadrature_order,'eps_distance',eps_distance);
              timing.flow = timing.flow + toc;
              
              Pall_all_times{k} = Pall;
              
              % save partial result
              save('partial.mat','Pall','Pall_coarse','V_coarse','F_coarse','V0','F0');
              
              % push coarse mesh with physical simulation to obtain the cages
              tic
              [V_coarse_new,~,~,etienne_called] = combined_step_project(Pall,F_shrink,...
                  Pall_coarse(:,:,end),F_exp,'simulation_steps',simulation_steps,...
                  'energy',energy,'eps_distance',eps_distance,'beta_init',beta_init);
              timing.simulation = timing.simulation + toc;
              
              timing.etienne = timing.etienne+etienne_called;
              
              % output level
              cages_F{k} = F_exp;
              cages_V{k} = V_coarse_new;
              V_coarse{k} = cages_V{k};
              F_coarse{k} = cages_F{k};
              
          end
          
          Pall = Pall_all_times;
          
  end
  
  
end
