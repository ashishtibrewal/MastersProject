function dataCenterMap =  networkCreation(dataCenterConfig)
% Function to create the data center network

  % Note that the latency map should have an almost linear relationship
  % with the distance map (i.e. If the distance increase, the latency has to
  % increase)

  % Adjacency matrix for connectivity

  % Could also think of inter-datacenter topology - After I've got the basic
  % simulation working

  % Assumptions on inter-blade (i.e. intra-node) need to be made - latency,
  % connectivity (i.e. the topology) and the bandwidth capabilities of these
  % links need to be set
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK CONSTANTS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;
  nTOR = dataCenterConfig.nTOR;
  nTOB = dataCenterConfig.nTOB;
  
  unitSizeCPU = dataCenterConfig.unitSize.CPU;
  unitSizeMEM = dataCenterConfig.unitSize.MEM;
  unitSizeSTO = dataCenterConfig.unitSize.STO;
  
  rackTopology = dataCenterConfig.topology.rack;
  rack_bladeTopology = dataCenterConfig.topology.rack_blade;
  bladeTopology = dataCenterConfig.topology.blade;
  blade_slotTopology = dataCenterConfig.topology.blade_slot;
  slotTopology = dataCenterConfig.topology.slot;
  
  % Optical fiber channels between each node
  nChannelsTOR_TOR = dataCenterConfig.channels.TOR_TOR;
  nChannelsTOR_TOB = dataCenterConfig.channels.TOR_TOB;
  nChannelsTOB_TOB = dataCenterConfig.channels.TOB_TOB;
  nChannelsTOB_SLOT = dataCenterConfig.channels.TOB_slot;
  nChannelsSLOT_SLOT = dataCenterConfig.channels.slot;
  
  % Network limits/constraints
  maxChannelBandwidth = dataCenterConfig.bounds.maxChannelBandwidth; % Maximum bandwidth available on a link connecting any two "nodes" in the network (i.e 400 Gb/s)
  minChannelLatency = dataCenterConfig.bounds.minChannelLatency;  % Minimum latency between two connected (adjacent) nodes is 5 ns (Assuming they are 1 meter apart)
  % Note that the latency is 5 ns/m - Higher the distance, higher the latency
  
  % TODO Swicthes for all categoires (Take a constant - Different for TOR and TOB)
  TOD_delay = dataCenterConfig.switchDelay.TOD;   % TOD switch delay
  TOR_delay = dataCenterConfig.switchDelay.TOR;   % TOR switch delay
  TOB_delay = dataCenterConfig.switchDelay.TOB;   % TOB switch delay
  
  % Compelte/total matrix map in a single 2D matrix of size [(nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks)]
  completeMatrixSize = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks));
  
  % Flag to choose whether the distance between TORs-TOBs (in a rack) and TOBs-SLOTs (in a blade) are equal (i.e. independent of the node number)
  equalSwitchDistances = 0;   % Switch equal distances flag
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK CONNECTIVITY/TOPOLOGY MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS
  % 0 = Disconnected
  % 1 = Connected
  % IMPORTANT NOTE: All units inside a slot are assumed to be
  % fully-connected
  
  completeConnectivityMatrixSize = completeMatrixSize;          % Complete connectivity map size
  completeConnectivity = zeros(completeConnectivityMatrixSize); % Initialize with zeros
  
  %%%%%% RACK (TOR) CONNECTIVITY %%%%%%
  switch (rackTopology)
    case 'Fully-connected'
      rackConnectivity = ones(nTOR * nRacks);   % Need to remove since it's unused
      for TOR_NoDim1 = 1:(nTOR * nRacks)
        for TOR_NoDim2 = (TOR_NoDim1 + 1):(nTOR * nRacks)
          completeConnectivity(TOR_NoDim1,TOR_NoDim2) = 1;
        end
      end
      
    case 'Line'    % Adjacent nodes (i.e.TORs) are connected to each other
      rackConnectivity = zeros(nTOR * nRacks);    % Need to remove since it's unused
      for TOR_NoDim1 = 1:((nTOR * nRacks) - 1)
        completeConnectivity(TOR_NoDim1,(TOR_NoDim1 + 1)) = 1;
        %completeConnectivity(TOR_NoDim1,(TOR_NoDim1 - 1)) = 1; % Don't need to do this since we only care about the upper half of the matrix
      end
    
    case 'Ring'    % Similar to the line topology but with end nodes connected to each other too (i.e. node 1 and node n have to be connected)
      rackConnectivity = zeros(nTOR * nRacks);    % Need to remove since it's unused
      for TOR_NoDim1 = 1:((nTOR * nRacks) - 1)
        completeConnectivity(TOR_NoDim1,(TOR_NoDim1 + 1)) = 1;
        % Also need to connect it around since it's a ring topology
        if (TOR_NoDim1 == 1)
          completeConnectivity(TOR_NoDim1,(nTOR * nRacks)) = 1;
        end
      end
      
    %case 'Star'   % Make the first/middle rack (i.e. first TOR in the first rack) the center of the star
      
    case 'Disconnected'
      rackConnectivity = zeros(nTOR * nRacks);
      % Do nothing to completeConnectivity since it's already zeroed
      
    %TODO Need to handle other cases/topologies
    otherwise
      error('Check configuration file for rack topology. Cases other than Fully-connected haven''t been handled yet.');
  end
  
  %%%%%% TORs - TOBs CONNECTIVITY (i.e. rack to blade topology) %%%%%%
  switch (rack_bladeTopology)
    % Note: When TOR > 1 => Star = Spineleaf
    case 'Star'   % Note when TOR > 1 => Star = Spineleaf
      TOB_offset = 0;   % Initialize TOB offset outside/before the outer loop
      TOR_counter = 0;  % Initialize TOR counter outside/before the outer loop
      for TOR = 1:(nTOR * nRacks)
        TOB_counter = 0;
        TOR_counter = TOR_counter + 1;
        TOB_start = ((nTOR * nRacks) + (nTOB * nBlades * TOB_offset) + 1); 
        for TOB = TOB_start:((nTOR * nRacks) + (nTOB * nBlades * nRacks)) 
          TOB_counter = TOB_counter + 1;
          completeConnectivity(TOR,TOB) = 1;
          if (TOB_counter == (nTOB * nBlades))
            break;      % Break out of inner loop once all TOBs and been connected to/for a specific TOR
          end
        end
        if (mod(TOR_counter,nTOR) == 0)
          TOB_offset = TOB_offset + 1;    % Increment the offset once all TORs for a rack have been covered
          TOR_counter = 0;                % Reset TOR counter back to zero
        end
      end
      % Check number of TORs to issue warning when configured with the wrong topology
      if (nTOR > 1)
        warning(['TORs > 1, hence, rack-blade star topology is invalid - using spine-leaf ', ...
                 'topology setup instead.']);
      end
      
    case 'Spine-leaf'   % Note when TOR > 1 => Star = Spineleaf
      TOB_offset = 0;   % Initialize TOB offset outside/before the outer loop
      TOR_counter = 0;  % Initialize TOR counter outside/before the outer loop
      for TOR = 1:(nTOR * nRacks)
        TOB_counter = 0;
        TOR_counter = TOR_counter + 1;
        TOB_start = ((nTOR * nRacks) + (nTOB * nBlades * TOB_offset) + 1); 
        for TOB = TOB_start:((nTOR * nRacks) + (nTOB * nBlades * nRacks)) 
          TOB_counter = TOB_counter + 1;
          completeConnectivity(TOR,TOB) = 1;
          if (TOB_counter == (nTOB * nBlades))
            break;      % Break out of inner loop once all TOBs and been connected to/for a specific TOR
          end
        end
        if (mod(TOR_counter,nTOR) == 0)
          TOB_offset = TOB_offset + 1;    % Increment the offset once all TORs for a rack have been covered
          TOR_counter = 0;                % Reset TOR counter back to zero
        end
      end
      % Check number of TORs to issue warning when configured with the wrong topology
      if (nTOR == 1)
        warning(['TORs = 1, hence, rack-blade spine-leaf topology is invalid - using star ', ...
                 'topology setup instead.']);
      end
      
    case 'Disconnected'
      warning(['Rack-blade (i.e.TORs-TOBs) is disconnected. Check configuration file ', ... 
               '(Also check if blades between racks are connected - If this is true, it could ', ...
               'still work without requiring any rack-blade connectivity to be present).']);
      % Do nothing to completeConnectivity since it's already zeroed
      
    otherwise
      error('Check configuration file for rack-blade topology. Cases other than Star/Spine-leaf is not allowed for rack-blade topology.');
  end
  
  %%%%%% BLADE (TOB) CONNECTIVITY %%%%%%
  switch (bladeTopology)
    case 'Fully-connected'
      % IMPORTANT NOTE: Fully-connected within a rack (No inter-rack blades
      % are connected directly and all traffic has to go through the TOR
      % switch)
      bladeConnectivity = ones(nBlades, nBlades, nRacks);     % Need to remove since it's unused
      mod_offset = 0;       % Initialize mod offset outside/before the outer loop
      for TOB_NoDim1 = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
        TOB_counter = 0;  % Reset TOB counter for every source TOB node
        for TOB_NoDim2 = (TOB_NoDim1 + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
          TOB_counter = TOB_counter + 1;    % Increment TOB coutner
          if (mod((TOB_counter + mod_offset), (nTOB * nBlades)) == 0)    % If all TOBs (within the same rack) have been covered for source TOB
            break;
          end
          completeConnectivity(TOB_NoDim1,TOB_NoDim2) = 1;
        end
        mod_offset = mod_offset + 1;    % Increment mod offset for every source TOB node (Note don't need to reset mod offset since it's value is being added and modded)
      end
      
    case 'Line'    % Adjacent nodes (i.e.TOBs) are connected to each other
      bladeConnectivity = zeros(nBlades, nBlades, nRacks);     % Need to remove since it's unused
      TOB_counter = 0;
      for TOB_NoDim1 = ((nTOR * nRacks) + 1):(((nTOR * nRacks) + (nTOB * nBlades * nRacks)) - 1)
        TOB_counter = TOB_counter + 1;
        if (TOB_counter == (nTOB * nBlades))    % Check if all TOBs in a rack have been covered
          TOB_counter = 0;    % Reset TOB counter when moving to a new rack
        else
          completeConnectivity(TOB_NoDim1,(TOB_NoDim1 + 1)) = 1;
        end
      end
    
    case 'Ring'    % Similar to the line topology but with end nodes connected to each other too (i.e. node 1 and node n have to be connected)
      bladeConnectivity = zeros(nBlades, nBlades, nRacks);     % Need to remove since it's unused
      TOB_counter = 0;
      for TOB_NoDim1 = ((nTOR * nRacks) + 1):(((nTOR * nRacks) + (nTOB * nBlades * nRacks)) - 1)
        TOB_counter = TOB_counter + 1;
        if (TOB_counter == (nTOB * nBlades))    % Check if all TOBs in a rack have been covered
          TOB_counter = 0;    % Reset TOB counter when moving to a new rack
        else
          completeConnectivity(TOB_NoDim1,(TOB_NoDim1 + 1)) = 1;
          % Also need to connect it around since it's a ring topology
          if (TOB_counter == 1)   % Check if the current node is the first TOB in the rack
            completeConnectivity(TOB_NoDim1,((TOB_NoDim1 + (nTOB * nBlades)) - 1)) = 1;
          end
        end
      end
      
    %case 'Star'   % Make the first/middle blade (i.e. first TOB in the first blade) in each rack the center of the star
    
    case 'Disconnected'
      bladeConnectivity = zeros(nBlades, nBlades, nRacks);
      % Do nothing to completeConnectivity since it's already zeroed
      
    %TODO Need to handle other cases/topologies  
    otherwise
      error('Check configuration file for blade topology. Cases other than Fully-connected haven''t been handled yet.');
  end
  
  %%%%%% TOBs - SLOTS CONNECTIVITY (i.e. blade to slot topology) %%%%%%
  switch (blade_slotTopology)
    % Note: When TOB > 1 => Star = Spineleaf)
    case 'Star'   % Note when TOB > 1 => Star = Spineleaf
      slot_offset = 0;   % Initialize slot offset outside/before the outer loop
      TOB_counter = 0;   % Initialize TOB counter outside/before the outer loop
      for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
        slot_counter = 0;
        TOB_counter = TOB_counter + 1;
        slot_start = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * slot_offset) + 1); 
        for slot = slot_start:((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
          slot_counter = slot_counter + 1;
          completeConnectivity(TOB,slot) = 1;
          if (slot_counter == nSlots)
            break;      % Break out of inner loop once all slots and been connected to/for a specific TOB
          end
        end
        if (mod(TOB_counter,nTOB) == 0)
          slot_offset = slot_offset + 1;    % Increment the offset once all TORs for a rack have been covered
          TOB_counter = 0;                  % Reset TOB counter back to zero
        end
      end
      % Check number of TOBs to issue warning when configured with the wrong topology
      if (nTOB > 1)
        warning(['TOBs > 1, hence, blade-slot star topology is invalid - using spine-leaf ', ...
                 'topology setup instead.']);
      end
      
    case 'Spine-leaf'   % Note when TOB > 1 => Star = Spineleaf
      slot_offset = 0;   % Initialize slot offset outside/before the outer loop
      TOB_counter = 0;   % Initialize TOB counter outside/before the outer loop
      for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
        slot_counter = 0;
        TOB_counter = TOB_counter + 1;
        slot_start = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * slot_offset) + 1); 
        for slot = slot_start:((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
          slot_counter = slot_counter + 1;
          completeConnectivity(TOB,slot) = 1;
          if (slot_counter == nSlots)
            break;      % Break out of inner loop once all slots and been connected to/for a specific TOB
          end
        end
        if (mod(TOB_counter,nTOB) == 0)
          slot_offset = slot_offset + 1;    % Increment the offset once all TORs for a rack have been covered
          TOB_counter = 0;                  % Reset TOB counter back to zero
        end
      end
      % Check number of TOBs to issue warning when configured with the wrong topology
      if (nTOB == 1)
        warning(['TOBs = 1, hence, blade-slot spine-leaf topology is invalid - using star ', ...
                 'topology setup instead.']);
      end
      
    case 'Disconnected'
      warning(['Blade-slot (i.e.TOBs-slots) is disconnected. Check configuration file ', ... 
              '(Also check if slots between blades are connected - If this is true, it could ', ...
              'still work without requiring any blade-slot connectivity to be present).']);
      % Do nothing to completeConnectivity since it's already zeroed
      
    otherwise
      error('Check configuration file for rack-blade topology. Cases other than Star/Spine-leaf is not allowed for blade-slot topology.');
  end
  
  %%%%%% SLOT CONNECTIVITY %%%%%%
  switch (slotTopology)
    % IMPORTANT NOTE: Fully-connected within a balde (No inter-blade slots
    % are connected directly and all traffic has to go through the TOB
    % switch)
    case 'Fully-connected'
      slotConnectivity = ones(nSlots, nSlots, nBlades, nRacks);   % Need to remove since it's unused
      
      slotsLimit = nSlots - 1;
      slotCounter = 0;
      for slotNoDim1 = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
        for slotNoDim2 = (slotNoDim1 + 1):(slotNoDim1 + slotsLimit)
          completeConnectivity(slotNoDim1,slotNoDim2) = 1;
        end
        slotsLimit = slotsLimit - 1;    % Decrement slots limit
        slotCounter = slotCounter + 1;  % Increment slot counter
        if (slotCounter == nSlots)
          slotCounter = 0;            % Reset slot counter
          slotsLimit = nSlots - 1;    % Reset slots limit
        end
      end
      
    case 'Line'    % Adjacent nodes (i.e.SLOTs) are connected to each other
      slotConnectivity = zeros(nSlots, nSlots, nBlades, nRacks);   % Need to remove since it's unused
      slotCounter = 0;
      for slotNoDim1 = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + 1):(((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks)) - 1)
        slotCounter = slotCounter + 1;
        if (slotCounter == nSlots)          % Check if all slots in a blade have been covered
          slotCounter = 0;    % Reset slot counter when moving to a new blade
        else
          completeConnectivity(slotNoDim1,(slotNoDim1 + 1)) = 1;
        end
      end

    case 'Ring'    % Similar to the line topology but with end nodes connected to each other too (i.e. node 1 and node n have to be connected)
      slotConnectivity = zeros(nSlots, nSlots, nBlades, nRacks);   % Need to remove since it's unused
      slotCounter = 0;
      for slotNoDim1 = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + 1):(((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks)) - 1)
        slotCounter = slotCounter + 1;
        if (slotCounter == nSlots)          % Check if all slots in a blade have been covered
          slotCounter = 0;    % Reset slot counter when moving to a new blade
        else
          completeConnectivity(slotNoDim1,(slotNoDim1 + 1)) = 1;
          % Also need to connect it around since it's a ring topology
          if (slotCounter == 1)
            completeConnectivity(slotNoDim1,((slotNoDim1 + nSlots) - 1)) = 1;
          end
        end
      end
      
    %case 'Star'   % Make the first/middle slot in every blade in every rack the center of the star
      
    case 'Disconnected'
      slotConnectivity = zeros(nSlots, nSlots, nBlades, nRacks);
      % Do nothing to completeConnectivity since it's already zeroed
      
    %TODO Need to handle other cases/topologies
    otherwise
      error('Check configuration file for slot topology. Cases other than Fully-connected haven''t been handled yet.');
  end
      
  % Transposing completeConnectivity matrix and adding to fill in remaining elements (i.e. the elements in the bottom half of the matrix).
  % Since only the upper triangle is filled as specified by the topology (and since an adjacency matrix is symmetric), this works perfectly.
  completeConnectivity = completeConnectivity + completeConnectivity.';
  
  % Network map/connectivity struct containing the rack, blade, slot and complete connectivity maps.
  connectivityMap.rackConnectivity = rackConnectivity;
  connectivityMap.bladeConnectivity = bladeConnectivity;
  connectivityMap.slotConnectivity = slotConnectivity;
  connectivityMap.completeConnectivity = completeConnectivity;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SWITCH DATABASE (TOB & TOB)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Stores indexes of TOR & TOB swithces in the connectivity matrix
  % IMPORTANT NOTE: This doesn't consider "slot-level" switching even if it exists.
  TOR_indexes = 1:(nTOR * nRacks);          % Top of rack switch indexes
  TOB_indexes = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks));  % Top of blade switch indexes
  
  % Switch map struct containing TOR & TOB switch indexes
  switchMap.TOR_indexes = TOR_indexes;
  switchMap.TOB_indexes = TOB_indexes;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK DISTANCE & LATENCY MAP (Hierarchial)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS (Distance)
  %  0  = Connected (i.e. Same rack/blade/slot)
  % >0  = Connected (i.e. Different rack/blade/slot)
  % inf =  Disconnected 
  % All values are in meters (m).
  
  % VALUE MEANINGS (Latency)
  % -1  = Connected (i.e. Same rack/blade/slot)
  % >0  = Connected (i.e. Different rack/blade/slot)
  % inf =  Disconnected 
  % All values are in nanoseconds (ns)
  % Note that the latency between two "nodes" is dependent on the distance
  % between them (i.e. minimum latency is 5 ns/m)
  
  % IMPORTANT NOTE: See equalSwitchDistances flag above
  
  % Complete distance map
  completeDistanceMatrixSize = completeMatrixSize;      % Complete distance map
  completeDistance = inf(completeDistanceMatrixSize);   % Initialize with infinity
  
  % Complete latency map
  completeLatencyMatrixSize = completeMatrixSize;       % Complete latency map
  completeLatency = inf(completeLatencyMatrixSize);     % Initialize with infinity
  
  % Make leading diagonal of a matrix zero (since distance between a node
  % an itself is zero)
  completeDistance(1:(completeDistanceMatrixSize+1):(completeDistanceMatrixSize ^ 2)) = 0;
  
  % Make leading diagonal of a matrix zero (since latency between a node
  % an itself is zero)
  completeLatency(1:(completeLatencyMatrixSize+1):(completeLatencyMatrixSize ^ 2)) = 0;
  
  % Extract distance values
  TOR_distIntraRack = dataCenterConfig.distances.TOR_IntraRack;
  TOR_distInterRack = dataCenterConfig.distances.TOR_InterRack;
  TOR_TOB_dist = dataCenterConfig.distances.TOR_TOB;
  TOB_distIntraBlade = dataCenterConfig.distances.TOB_IntraBlade;
  TOB_distInterBlade = dataCenterConfig.distances.TOB_InterBlade;
  TOB_slot_dist = dataCenterConfig.distances.TOB_slot;
  slot_dist = dataCenterConfig.distances.slot;

  % RACK DISTANCE - All racks are equidistant from each other (i.e. at a
  % distance of 25 meters from each other)
  rackDistance = ones(nRacks);
  rackLatency = ones(nRacks);
  for rackNoDim1 = 1:nRacks
    for rackNoDim2 = 1:nRacks
      % Distance between a rack and itself is 0
      if (rackNoDim1 ~= rackNoDim2)
        % If the racks are connected, they have a finite distance and latency 
        % else they are inifinite
        if (rackConnectivity(rackNoDim1,rackNoDim2) == 1)
          rackDistance(rackNoDim1,rackNoDim2) = 25;
          rackLatency(rackNoDim1,rackNoDim2) = rackDistance(rackNoDim1,rackNoDim2) * minChannelLatency;
        else
          rackDistance(rackNoDim1,rackNoDim2) = inf;
          rackLatency(rackNoDim1,rackNoDim2) = inf;
        end
      else
        rackDistance(rackNoDim1,rackNoDim2) = 0;
        rackLatency(rackNoDim1,rackNoDim2) = -1;
      end
    end
  end
  
  %%%%%% TOR DISTANCE %%%%%% 
  % IMPORTANT NOTE: Distance between TORs within the same rack is the same (constant across all TORs within a rack)
  for TOR_NoDim1 = 1:(nTOR * nRacks)
    for TOR_NoDim2 = (TOR_NoDim1 + 1):(nTOR * nRacks)
      if (completeConnectivity(TOR_NoDim1,TOR_NoDim2) == 1) % Only has a finite distance if two nodes are connected
        if (ceil(TOR_NoDim2/nTOR) == ceil(TOR_NoDim1/nTOR)) % If both TORs are on the same rack
          completeDistance(TOR_NoDim1,TOR_NoDim2) = TOR_distIntraRack;
        else
          completeDistance(TOR_NoDim1,TOR_NoDim2) = (ceil(TOR_NoDim2/nTOR) - ceil(TOR_NoDim1/nTOR)) * TOR_distInterRack;
        end
        completeLatency(TOR_NoDim1,TOR_NoDim2) = completeDistance(TOR_NoDim1, TOR_NoDim2) * minChannelLatency;   % Update complete latency map
      end
    end
  end
  
  %%%%%% TORs - TOBs DISTANCE %%%%%%
  for TOR = 1:(nTOR * nRacks)
    bladeCounter = 0;       % Reset blade counter when iterating for every TOR
    for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
      if (completeConnectivity(TOR,TOB) == 1) % Only has a finite distance if two nodes are connected
        if (equalSwitchDistances == 1)
          completeDistance(TOR,TOB) = TOR_TOB_dist;   % Distance independent of the blade counter/location
        else
          completeDistance(TOR,TOB) = TOR_TOB_dist + (bladeCounter * TOR_TOB_dist);   % Distance based on the blade counter/location
        end
        completeLatency(TOR,TOB) = completeDistance(TOR, TOB) * minChannelLatency;   % Update complete latency map
        if (mod(TOB, nTOB) == 0)          % Check if all TOBs have been covered for current blade
          bladeCounter = bladeCounter + 1;   % Increment blade counter
        end
      end
    end
  end

  % BLADE DISTANCE - Blades 1 to n are an increasing distance away from each
  % other. Adjacent nodes are 0.1 meters (i.e. 10 cm) away from each other.
  bladeDistance = ones(nBlades, nBlades, nRacks);
  bladeLatency = ones(nBlades, nBlades, nRacks);
  for rackNo = 1:nRacks
    for bladeNoDim1 = 1:nBlades
      for bladeNoDim2 = 1:nBlades
        % Distance between a blade and itself is 0
        if (bladeNoDim1 ~= bladeNoDim2)
          % If the blades are connected, they have a finite distance and 
          % latency else they are infinite
          if (bladeConnectivity(bladeNoDim1,bladeNoDim2,rackNo) == 1)
            bladeDistance(bladeNoDim1,bladeNoDim2,rackNo) = (abs(bladeNoDim1 - bladeNoDim2))/10;
            bladeLatency(bladeNoDim1,bladeNoDim2,rackNo) = bladeDistance(bladeNoDim1,bladeNoDim2,rackNo) * minChannelLatency;
          else
            bladeDistance(bladeNoDim1,bladeNoDim2,rackNo) = inf;
            bladeLatency(bladeNoDim1,bladeNoDim2,rackNo) = inf;
          end
        else
          bladeDistance(bladeNoDim1,bladeNoDim2,rackNo) = 0;
          bladeLatency(bladeNoDim1,bladeNoDim2,rackNo) = -1;
        end
      end
    end
  end
  
  %%%%%% TOB DISTANCE %%%%%%
  % IMPORTANT NOTE: Distance between TOBs within the same blade is the same (constant across all TOBs within a blade)
  TOB_num = 0;        % Initialize TOB num
  for TOB_NoDim1 = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
    TOB_counter = 0;
    for TOB_NoDim2 = (TOB_NoDim1 + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
      TOB_counter = TOB_counter + 1;
      if (completeConnectivity(TOB_NoDim1,TOB_NoDim2) == 1) % Only has a finite distance if two nodes are connected
        if (TOB_counter < (nTOB - TOB_num)) % If both TOBs are on the same blade
          completeDistance(TOB_NoDim1, TOB_NoDim2) = TOB_distIntraBlade;
        else
          %[TOB_NoDim1, TOB_NoDim2, ceil(TOB_NoDim1/(nTOB + (nTOR * nRacks))), ceil((TOB_NoDim2 - 1)/(nTOB + (nTOR * nRacks))), (nTOB * nBlades)]
          completeDistance(TOB_NoDim1,TOB_NoDim2) = abs(TOB_NoDim2 - TOB_NoDim1) * TOB_distInterBlade;
        end
        completeLatency(TOB_NoDim1,TOB_NoDim2) = completeDistance(TOB_NoDim1, TOB_NoDim2) * minChannelLatency;   % Update complete latency map
      end
    end
    TOB_num = TOB_num + 1;
    if (TOB_num == nTOB)
      TOB_num = 0;    % Reset TOB num counter
    end
  end
    
  %%%%%% TOBs - SLOTs DISTANCE %%%%%%
  for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
    slot_counter = 0;
    for slot = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
      slot_counter = slot_counter + 1;           % Increment slot counter
      slot_counter = mod(slot_counter, (nSlots + 1));  % Mod slot counter to keep its value in range of nSlots
      if (slot_counter == 0)   % Check to avoid the zero created by the mod operation
        slot_counter = 1;
      end
      if (completeConnectivity(TOB,slot) == 1)
        if (equalSwitchDistances == 1)
          completeDistance(TOB,slot) = TOB_slot_dist;   % Distance independent of the slot counter/location
        else
          completeDistance(TOB,slot) = slot_counter * TOB_slot_dist;  % Distance based on the slot counter/location
        end
        completeLatency(TOB,slot) = completeDistance(TOB,slot) * minChannelLatency;   % Update complete latency map
      end
    end
  end

  % SLOT DISTANCE - Slots 1 to n are an increasing distance away from each
  % other. Adjacent slots are 0.01 meters (i.e. 1 cm) away from each other.
  slotDistance = ones(nSlots, nSlots, nBlades, nRacks);
  slotLatency = ones(nSlots, nSlots, nBlades, nRacks);
  for rackNo = 1:nRacks
    for bladeNo = 1:nBlades
      for slotNoDim1 = 1:nSlots
        for slotNoDim2 = 1:nSlots
          % Distance bgietween a slot and itself is 0
          if (slotNoDim1 ~= slotNoDim2)
            % If the slots are connected, they have a finite distance and 
            % latency else they are infinite
            if (slotConnectivity(slotNoDim1,slotNoDim2,bladeNo,rackNo) == 1)
              slotDistance(slotNoDim1,slotNoDim2,bladeNo,rackNo) = (abs(slotNoDim1 - slotNoDim2))/100;
              slotLatency(slotNoDim1,slotNoDim2,bladeNo,rackNo) = slotDistance(slotNoDim1,slotNoDim2,bladeNo,rackNo) * minChannelLatency;
            else
              slotDistance(slotNoDim1,slotNoDim2,bladeNo,rackNo) = inf;
              slotLatency(slotNoDim1,slotNoDim2,bladeNo,rackNo) = inf;
            end
          else
            slotDistance(slotNoDim1,slotNoDim2,bladeNo,rackNo) = 0;
            slotLatency(slotNoDim1,slotNoDim2,bladeNo,rackNo) = -1;
          end
        end
      end
    end
  end
  
  %%%%%% SLOT DISTANCE %%%%%%
  for slotNoDim1 = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
    slotCounter = 0;
    for slotNoDim2 = (slotNoDim1 + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
      slotCounter = slotCounter + 1;
      if (completeConnectivity(slotNoDim1,slotNoDim2) == 1)
        completeDistance(slotNoDim1,slotNoDim2) = slot_dist * slotCounter;
      end
      completeLatency(slotNoDim1,slotNoDim2) = completeDistance(slotNoDim1,slotNoDim2) * minChannelLatency;   % Update complete latency map
    end
  end
  
  % Convert upper-triangular matrix to a full matrix (Doing this since the matrix should be complete and symmetric)
  nNodes = size(completeDistance, 1);
  for i = 1:nNodes
    for j = 1:nNodes
      completeDistance(j,i) = completeDistance(i,j);
      completeLatency(j,i) = completeLatency(i,j);
    end
  end
  
  % Network distance map struct containing the rack, blade, slot and complete distance maps
  distanceMap.rackDistance = rackDistance;
  distanceMap.bladeDistance = bladeDistance;
  distanceMap.slotDistance = slotDistance;
  distanceMap.completeDistance = completeDistance;
  
  % Network latency map struct containing the inter-rack, inter-blade and inter-slot latency maps
  latencyMap.rackLatency = rackLatency;
  latencyMap.bladeLatency = bladeLatency;
  latencyMap.slotLatency = slotLatency;
  latencyMap.completeLatency = completeLatency;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % HOPS MAP (i.e. Inter-node hops)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  hopsMap = connectivityMap.completeConnectivity;   % Extract complete connectivity matrix
	nNodes = size(hopsMap, 1);                        % Obtain size of the matrix
  
  % Check to make distance between disconnected nodes infinity
  for sourceNode = 1:nNodes
    for destNode = 1:nNodes
      if (sourceNode ~= destNode)    % Ignore diagonal
        if (hopsMap(sourceNode,destNode) == 0)  % If disconnected, make the 'distance' infinity
          hopsMap(sourceNode,destNode) = inf;
        end
      end
    end
  end
  
  % Implement Floyd-Warshall algorithm on the (boolean) connectivity/adjaceny matrix. 
  % This finds the shortest distance between between every node to every other node.
% 	for k = 1:nNodes
% 		i2k = repmat(hopsMap(:,k), 1, nNodes);
% 		k2j = repmat(hopsMap(k,:), nNodes, 1);
% 		hopsMap = min(hopsMap, (i2k + k2j));
%   end
   
   % Loop over hops matrix to reduce every element by one (since the Floyd-Warshall algorithm gives 
   % the shortest-path and not the number of hops). In general, nHops = nNodeTraversed - 1.
%   for sourceNode = 1:nNodes
%     for destNode = 1:nNodes
%       if (sourceNode ~= destNode)    % Ignore diagonal (since it's already zero)
%         hopsMap(sourceNode,destNode) = hopsMap(sourceNode,destNode) - 1;    % Subtract one from every non-diagonal element
%       end
%     end
%   end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SHORTEST PATH MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % IMPORTANT NOTE: Shortest paths simply based on link distances and doesn't account for switch delays
  
  %%%%%% Shortest path using Floyd-Warshall %%%%%%
  sPath = distanceMap.completeDistance;   % Extract complete distance matrix
	nNodes = size(sPath, 1);                % Obtain size of the matrix
  
  % Implement Floyd-Warshall algorithm (Shortest path between every node to
  % every other node)
% 	for k = 1:nNodes
% 		i2k = repmat(sPath(:,k), 1, nNodes);
% 		k2j = repmat(sPath(k,:), nNodes, 1);
% 		sPath = min(sPath, (i2k + k2j));
%   end
  
  %%%%%% K-shortest path %%%%%%
  weightedEdgeSparseGraph = sparse(distanceMap.completeDistance);   % Extract complete distance matrix and make it a sparse matrix
	nNodes = size(weightedEdgeSparseGraph, 1);                % Obtain size of the matrix
  kPaths = 1;     % Specify number of shortest paths to find
  
  ksPath_Dist = zeros(nNodes,nNodes,kPaths);   % Initialize k-shortest path distance matrix with it's 3rd dimension being of size kPaths
  ksPath_Paths = cell(nNodes,nNodes);    % Initialize k-shortest path paths cell
  
  ksPath_Latency = zeros(nNodes,nNodes,kPaths);   % Initialize k-shortest path latency matrix with it's 3rd dimension being of size kPaths 
  
  %profile on;         % Turn on profiler
  
  % Run k-shortest path for every node to every other node in the graph
%   for sourceNode = 1:nNodes
%     for destNode = 1:nNodes
%       if (sourceNode ~= destNode)    % Ignore diagonal (since distance between a node to itself if 0)
%         % Use the k-shortest paths algorithm
%         [ksPath_Dist(sourceNode,destNode,:),ksPath_Paths{sourceNode,destNode}] = graphkshortestpaths(weightedEdgeSparseGraph, sourceNode, destNode, kPaths);
%         % Store distance found for a specific set of source and destination nodes to the latency matrix
%         ksPath_Latency(sourceNode,destNode,:) = ksPath_Dist(sourceNode,destNode,:) * minChannelLatency;
%         % Find if the path found contains any switches for every k-th path
%         for k = 1:kPaths
%           % Extract k-th path for current source and destination nodes exluding the destination node (hence, the -1)
%           kth_Path = ksPath_Paths{sourceNode,destNode}{k}(1:numel(ksPath_Paths{sourceNode,destNode}{k}) - 1);
%           % Find TOR swithces
%           TOR_Switches = ismember(switchMap.TOR_indexes, kth_Path);
%           % Find TOB switches
%           TOB_Swithces = ismember(switchMap.TOB_indexes, kth_Path);
%           % If any switches exist in the shortest path
%           if (nnz(TOR_Switches) || nnz(TOB_Swithces))
%             % Find the total number of TOR swithces
%             nTOR_Switches = sum(histcounts(kth_Path,switchMap.TOR_indexes));
%             % Find the total number of TOB swithces
%             nTOB_Switches = sum(histcounts(kth_Path,switchMap.TOB_indexes));
%             % Find total switch delay on the path
%             totalSwitchDelay = (nTOR_Switches * TOR_delay) + (nTOB_Switches * TOB_delay);
%             % Update latency map
%             ksPath_Latency(sourceNode,destNode,k) = ksPath_Latency(sourceNode,destNode,k) + totalSwitchDelay;
%           end
%         end
%       end
%     end
%   end
  
  %profile viewer;     % View profiler results
  
  % K-shortest path struct containing the path distance and shortest paths
  ksPath.ksPath_Dist = ksPath_Dist;
  ksPath.ksPath_Paths = ksPath_Paths;
  
  % Shortest path struct containing the shortest path and k-shortest paths
  shortestPathMap.sPath = sPath;
  shortestPathMap.ksPath = ksPath;
  
  % Latency map struct (Shortest path latency map)
  shortestPathMap.shortestPathLatency = ksPath_Latency;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK LATENCY MAP (Linear indexing)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % This is used to find the latency between every slot (i.e. node) to
  % every other slot (i.e. node) in the network/graph. 
  % TODO Need to add switch delay factors (300ns for each switch) - Note
  % when doing this we might need to check the network connectivity map (or
  % the hierarchial latency map since nodes that are no connected have a
  % latency value of infinite)
  
  % TODO Switch delay value
  % TODO Connected value (check is latency is infinite) 
  
  % Latency map for each slot in the topology (Total number of slots in the
  % toplogy is equal to nRacks * nBlades * nSlots). Note that this is a 2D
  % matrix having a size of the total number of slots in each dimension
  latencyMapLinear = zeros(nRacks * nBlades * nSlots);
  
  for rackNoDim1 = 1:nRacks
    for bladeNoDim1 = 1:nBlades
      for slotNoDim1 = 1:nSlots
        for rackNoDim2 = 1:nRacks
          for bladeNoDim2 = 1:nBlades
            for slotNoDim2 = 1:nSlots
              % Evaluate row offsets
              rackOffsetRow = (nBlades * nSlots) * (rackNoDim1 - 1);
              bladeOffsetRow = nSlots * (bladeNoDim1 - 1);
              slotOffsetRow = slotNoDim1;
              rowOffset = rackOffsetRow + bladeOffsetRow + slotOffsetRow; % Total row offset
              % Evaluate column offset
              rackOffsetColumn = (nBlades * nSlots) * (rackNoDim2 - 1);
              bladeOffsetColumn = nSlots * (bladeNoDim2 - 1);
              slotOffsetColumn = slotNoDim2;
              columnOffset = rackOffsetColumn + bladeOffsetColumn + slotOffsetColumn; % Total column offset
              % Distance between a slot and itself is 0
              if (rowOffset == columnOffset)
                latencyMapLinear(rowOffset,columnOffset) = 0;
              else
                % TODO This needs to be changed
                latencyMapLinear(rowOffset,columnOffset) = rackNoDim1 * 10;
              end
            end
          end
        end
      end
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % IT RESOURCE OCCUPIED & TYPE MAP (Heirarchial)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS (OCCUPIED)
  %  0 = Resource unavailable (i.e. the particular slot has no free unit)
  % >0 = Resource available (i.e. the particular slot has at least one free unit)

  % All slots in all blades in all racks are unoccupied at the start
  % 1st dimension = Slot number
  % 2nd dimension = Blade number
  % 3rd dimension = Rack number
  availableMap = zeros(nSlots, nBlades, nRacks);
  
  % Map to keep track of the type of resource in each slot
  % 1st dimension = Slot number
  % 2nd dimension = Blade number
  % 3rd dimension = Rack number
  resourceMap = cell(nSlots, nBlades, nRacks);
  
  % Total number of racks specified in the configuration file
  racks = fieldnames(dataCenterConfig.racksConfig);
  
  % Set the value for each slot to the number of units available in it
  for rackNo = 1:nRacks
    rackConfigData = [dataCenterConfig.racksConfig.(racks{rackNo}){:}];
    for bladeNo = 1:nBlades
      for slotNo = 1:nSlots
        switch (rackConfigData(bladeNo))
          % Check for homogeneous CPU blades
          case dataCenterConfig.setupTypes.homogenCPU
            availableMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeCPU; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'CPU';                % Store the type of resource
          % Check for homogeneous MEM blades
          case dataCenterConfig.setupTypes.homogenMEM
            availableMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeMEM; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'MEM';                % Store the type of resource
          % Check for homogeneous STO blades
          case dataCenterConfig.setupTypes.homogenSTO
            availableMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeSTO; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'STO';                % Store the type of resource
          % Check for heterogeneous CPU & MEM blades
          case dataCenterConfig.setupTypes.heterogenCPU_MEM
            % Check for % of CPUs and % of MEMs
            switch (dataCenterConfig.heterogenSplit.heterogenCPU_MEM)
              % 50-50 CPU-MEM
              case 50
                % Odd slots are CPUs
                if (mod(slotNo,2) ~= 0)
                  availableMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeCPU; % Updated occupied map
                  resourceMap{slotNo,bladeNo,rackNo} = 'CPU';                % Store the type of resource
                % Even slots are CPUs
                else
                  availableMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeMEM; % Updated occupied map
                  resourceMap{slotNo,bladeNo,rackNo} = 'MEM';                % Store the type of resource
                end
              % TODO Add cases to handle other percentages
              otherwise
                error('Check configuration file for CPU-MEM distribution percentage. Cases other than 50-50 haven''t been handled yet.');
            end
          otherwise
            error('Check configuration file for racksConfig. Incorrect blade configurations have been specified for one or more racks.');
        end
      end
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % IT RESOURCE OCCUPIED & TYPE MAP (Linear)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Slot resource map (i.e. what type of resource does a slot contain)
  completeResourceMapCellArraySize = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks));     % Complete resource map size
  completeResourceMap = cell(1,completeResourceMapCellArraySize);   % Initialize cell
  
  % Slot resource occupied map (i.e. number of resources that have been occupied in a slot)
  completeResourceAvailableMapMatrixSize = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks));        % Complete resource occupied map size
  completeResourceAvailableMap = zeros(1,completeResourceAvailableMapMatrixSize);     % Initialize with zeros
  
  % Slot unit occupied map (i.e. number of slots that have been occupied in a slot)
  completeUnitAvailableMapMatrixSize = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks));        % Complete unit occupied map size
  completeUnitAvailableMap = zeros(1,completeUnitAvailableMapMatrixSize);     % Initialize with zeros

  % Total number of racks specified in the configuration file
  racks = fieldnames(dataCenterConfig.racksConfig);
  
  % Fill required matrices and cells with TOR & TOB content
  completeResourceMap(1,1:(nTOR * nRacks)) = {'TOR'};          % Top of rack switch nodes
  completeResourceMap(1,((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))) = {'TOB'};  % Top of blade switch nodes
  
  completeResourceAvailableMap(1,1:(nTOR * nRacks)) = inf;          % Top of rack switch resource avalibility (infinite availibility)
  completeResourceAvailableMap(1,((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))) = inf;  % Top of blade switch resource avalibility (infinite availibility)
  
  completeUnitAvailableMap(1,1:(nTOR * nRacks)) = inf;          % Top of rack switch unit avalibility (infinite availibility)
  completeUnitAvailableMap(1,((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))) = inf;  % Top of blade switch unit avalibility (infinite availibility)
  
  % Offset to ignore TOR & TOB switch indexes in the cell array
  switchOffset = (nTOR * nRacks) + (nTOB * nBlades * nRacks);
  
  % Set the value for each slot to the number of units available in it
  for rackNo = 1:nRacks
    rackConfigData = [dataCenterConfig.racksConfig.(racks{rackNo}){:}];
    for bladeNo = 1:nBlades
      slotCounter = 1;        % Initialize/Reset slot coutner to zero for every new blade
      for slotNo = ((nSlots * nBlades * (rackNo - 1)) + (nSlots * (bladeNo - 1) + 1) + switchOffset):((nSlots * bladeNo) + (nSlots * nBlades * (rackNo - 1)) + switchOffset)
        switch (rackConfigData(bladeNo))
          % Check for homogeneous CPU blades
          case dataCenterConfig.setupTypes.homogenCPU
            completeResourceAvailableMap(slotNo) = nUnits * unitSizeCPU; % Update resource occupied map
            completeUnitAvailableMap(slotNo) = nUnits;           % Update unit occupied map
            completeResourceMap{slotNo} = 'CPU';                % Store the type of resource
          % Check for homogeneous MEM blades
          case dataCenterConfig.setupTypes.homogenMEM
            completeResourceAvailableMap(slotNo) = nUnits * unitSizeMEM; % Update resource occupied map
            completeUnitAvailableMap(slotNo) = nUnits;           % Update unit occupied map
            completeResourceMap{slotNo} = 'MEM';                % Store the type of resource
          % Check for homogeneous STO blades
          case dataCenterConfig.setupTypes.homogenSTO
            completeResourceAvailableMap(slotNo) = nUnits * unitSizeSTO; % Update resource occupied map
            completeUnitAvailableMap(slotNo) = nUnits;           % Update unit occupied map
            completeResourceMap{slotNo} = 'STO';                % Store the type of resource
          % Check for heterogeneous CPU & MEM blades
          case dataCenterConfig.setupTypes.heterogenCPU_MEM
            % Check for % of CPUs and % of MEMs
            switch (dataCenterConfig.heterogenSplit.heterogenCPU_MEM)
              % 50-50 CPU-MEM
              case 50
                % Odd slots are CPUs
                if (mod(slotCounter,2) ~= 0)
                  completeResourceAvailableMap(slotNo) = nUnits * unitSizeCPU; % Updated occupied map
                  completeResourceMap{slotNo} = 'CPU';                % Store the type of resource
                % Even slots are MEMs
                else
                  completeResourceAvailableMap(slotNo) = nUnits * unitSizeMEM; % Updated occupied map
                  completeResourceMap{slotNo} = 'MEM';                % Store the type of resource
                end
              % Add cases to handle other percentages
              otherwise
                error('Check configuration file for CPU-MEM distribution percentage. Cases other than 50-50 haven''t been handled yet.');
            end
            completeUnitAvailableMap(slotNo) = nUnits;           % Update unit occupied map
        end
        slotCounter = slotCounter + 1;    % Increment slot counter
      end
    end
  end
  
  % Find matrix indexes for each type of resource (i.e. the node number in the graph)
  CPUlocations = find(strcmp(completeResourceMap, 'CPU'));
  MEMlocations = find(strcmp(completeResourceMap, 'MEM'));
  STOlocations = find(strcmp(completeResourceMap, 'STO'));
  
  % Pack the locations into the data center items struct
  locationMap.CPUs = CPUlocations;
  locationMap.MEMs = MEMlocations;
  locationMap.STOs = STOlocations;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK BANDWIDTH MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS
  % <0 = Bandwidth factor irrelevant (i.e. a value of -1 specifically)
  %  0 = Zero bandwidth (Resource not connected)
  % >0 = Finte bandwith between connected resources
  % All values are dependent on the distance map of the network (and
  % indirectly the network connectivity map)
  % Speeds are in Gb/s
  % ASSUMPTION IS THAT THE BANDWIDTH IS NOT AFFECTED BY THE DISTANCE IN
  % THIS SIMULATION - PRIMARILY BECAUSE OF THE REALLY SHORT DISTANCES
  % BETWEEN RESOURCES
  
  completeBandwidthMatrixSize = completeMatrixSize;           % Complete bandwidth map
  completeBandwidth = zeros(completeBandwidthMatrixSize);     % Initialize with zeros
  
  % INTER-RACK BANDWIDTH
  rackBandwidth = ones(nRacks);
  for rackNoDim1 = 1:nRacks
    for rackNoDim2 = 1:nRacks
      % Bandwidth between a rack and itself is irrelevant - Need to look at
      % inter-blade bandwidth for the specific rack.
      if (rackNoDim1 ~= rackNoDim2)
        % If the racks are connected, they have a finite bandwidth else
        % they are zero
        if (rackConnectivity(rackNoDim1,rackNoDim2) == 1)       
          rackBandwidth(rackNoDim1,rackNoDim2) = maxChannelBandwidth * nChannelsTOR_TOR;
        else
          rackBandwidth(rackNoDim1,rackNoDim2) = 0;
        end
      else
        rackBandwidth(rackNoDim1,rackNoDim2) = -1;
      end
    end
  end
  
  %%%%%% TOR-TOR BANDWIDTH %%%%%%
  for TOR_NoDim1 = 1:(nTOR * nRacks)
    for TOR_NoDim2 = (TOR_NoDim1 + 1):(nTOR * nRacks)
      % Check if the TORs are connected
      if (completeConnectivity(TOR_NoDim1,TOR_NoDim2) == 1)
        completeBandwidth(TOR_NoDim1,TOR_NoDim2) = maxChannelBandwidth * nChannelsTOR_TOR;
      end
    end
  end
  
  %%%%%% TOR-TOB BANDWIDTH %%%%%%
  for TOR = 1:(nTOR * nRacks)
    for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
      % Check if the TOR & TOB are connected
      if (completeConnectivity(TOR,TOB) == 1)
        completeBandwidth(TOR,TOB) = maxChannelBandwidth * nChannelsTOR_TOB;
      end
    end
  end

  % INTER-BLADE BANDWIDTH
  bladeBandwidth = ones(nBlades, nBlades, nRacks);
  for rackNo = 1:nRacks
    for bladeNoDim1 = 1:nBlades
      for bladeNoDim2 = 1:nBlades
        % Bandwidth between a blade and itself is irrelevant - Need to look at
        % inter-slot bandwidth for the specific blade.
        if (bladeNoDim1 ~= bladeNoDim2)
          % If the blades are connected, they have a finite bandwidth else
          % they are zero
          if (bladeConnectivity(bladeNoDim1,bladeNoDim2,rackNo) == 1)
            bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = maxChannelBandwidth * nChannelsTOB_TOB;
          else
            bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = 0;
          end
        else
          bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = -1;
        end
      end
    end
  end
  
  %%%%%% TOB-TOB BANDWIDTH %%%%%%
  for TOB_NoDim1 = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
    for TOB_NoDim2 = (TOB_NoDim1 + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
      % Check if the TOBs are connected
      if (completeConnectivity(TOB_NoDim1,TOB_NoDim2) == 1)
        completeBandwidth(TOB_NoDim1,TOB_NoDim2) = maxChannelBandwidth * nChannelsTOB_TOB;
      end
    end
  end
  
  
  %%%%%% TOB-SLOT BANDWIDTH %%%%%%
  for TOB = ((nTOR * nRacks) + 1):((nTOR * nRacks) + (nTOB * nBlades * nRacks))
    for slot = (((nTOR * nRacks) + (nTOB * nBlades * nRacks)) + 1): ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
      % Check if the TOB & SLOT are connected
      if (completeConnectivity(TOB,slot) == 1)
        completeBandwidth(TOB,slot) = maxChannelBandwidth * nChannelsTOB_SLOT;
      end
    end
  end

  % INTER-SLOT BANDWIDTH
  slotBandwidth = ones(nSlots, nSlots, nBlades, nRacks);
  for rackNo = 1:nRacks
    for bladeNo = 1:nBlades
      for slotNoDim1 = 1:nSlots
        for slotNoDim2 = 1:nSlots
          % Bandwidth between a slot and itself is irrelevant - Need to look 
          % at inter-unit bandwidth for the specific slot. Note that the
          % inter-unit bandwidth is assumed to be a constant and is not
          % explicitly set.
          if (slotNoDim1 ~= slotNoDim2)
            % If the slots are connected, they have a finite bandwidth else
            % they are zero
            if (slotConnectivity(slotNoDim1,slotNoDim2,bladeNo,rackNo) == 1)
              slotBandwidth(slotNoDim1,slotNoDim2,bladeNo,rackNo) = maxChannelBandwidth * nChannelsSLOT_SLOT;
            else
              slotBandwidth(slotNoDim1,slotNoDim2,bladeNo,rackNo) = 0;
            end
          else
            slotBandwidth(slotNoDim1,slotNoDim2,bladeNo,rackNo) = -1;
          end
        end
      end
    end
  end 
  
  %%%%%% SLOT-SLOT BANDWIDTH %%%%%%
  for slot_NoDim1 = (((nTOR * nRacks) + (nTOB * nBlades * nRacks)) + 1): ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
    for slot_NoDim2 = (slot_NoDim1 + 1): ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks))
      % Check if the SLOTs are connected
      if (completeConnectivity(slot_NoDim1,slot_NoDim2) == 1)
        completeBandwidth(slot_NoDim1,slot_NoDim2) = maxChannelBandwidth * nChannelsSLOT_SLOT;
      end
    end
  end
  
  % Transposing completeBandwidth matrix and adding to fill in remaining elements (i.e. the elements in the bottom half of the matrix).
  % Since only the upper triangle is filled as specified by the topology (and since an adjacency/connectivity matrix is symmetric), this works perfectly.
  completeBandwidth = completeBandwidth + completeBandwidth.';
  
  % Network distance map struct containing the rack, blade and slot distance
  % maps
  bandwidthMap.rackBandwidth = rackBandwidth;
  bandwidthMap.bladeBandwidth = bladeBandwidth;
  bandwidthMap.slotBandwidth = slotBandwidth;
  bandwidthMap.completeBandwidth = completeBandwidth;
  bandwidthMap.completeBandwidthOriginal = completeBandwidth;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % RESOURCE (i.e. BLADE) UTILIZED MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % VALUE MEANINGS
  % 0 = No resources (slots) have been allocated in this blade
  % 1 = At aleast a single resource (slot) has been allocated in this blade
  resourceUtilizedMap = zeros(1,(nBlades * nRacks));    % Initialize every blade's value with zero since no slots in it have been utilized
  % IMPORTANT NOTE: This map is used to optimize bin packing, i.e. need to
  % pack those bins (i.e. blades and therefore, racks) that have already
  % had some of their resources (i.e. slots) allocated to earlier requests.
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % HOLD TIME MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % VALUE MEANINGS
  %  0 = Zero holdtime (i.e. the particular slot is unoccupied/free)
  % >0 = Non-zero holdtime (i.e. the particular slot has at least one occupied unit)

  % All slots in all blades in all racks are unoccupied at the start,
  % therefore the holdtime is 0
  % 1st dimension = Slot number
  % 2nd dimension = Blade number
  % 3rd dimension = Rack number
  
  % TODO THIS NEEDS TO BE CHANGED TO CONSIDER DIFFERENT UNITS INSIDE A SLOT
  %holdTimeMap = zeros(nSlots, nBlades, nRacks);
  
  % IT resource hold time map
  holdTimeMapIT = cell(nSlots, nBlades, nRacks);
  for i = 1:size(holdTimeMapIT,3)
    for j = 1:size(holdTimeMapIT,2)
      for k = 1:size(holdTimeMapIT,1)
        holdTimeMapIT{k,j,i} = cell(1,nUnits);   % Initialize each cell with nUnits elements
      end
    end
  end
  
  % NET resource hold time map
  holdTimeMapNETSize = completeMatrixSize;
  holdTimeMapNET = cell(holdTimeMapNETSize);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Pack all maps into a single struct
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  dataCenterMap.connectivityMap = connectivityMap;
  dataCenterMap.hopsMap = hopsMap;
  dataCenterMap.switchMap = switchMap;
  dataCenterMap.completeUnitAvailableMap = completeUnitAvailableMap;
  dataCenterMap.availableMap = availableMap;
  dataCenterMap.completeResourceAvailableMap = completeResourceAvailableMap;
  dataCenterMap.resourceMap = resourceMap;
  dataCenterMap.completeResourceMap = completeResourceMap;
  dataCenterMap.locationMap = locationMap;
  dataCenterMap.resourceUtilizedMap = resourceUtilizedMap;
  dataCenterMap.distanceMap = distanceMap;
  dataCenterMap.latencyMap = latencyMap;
  dataCenterMap.latencyMapLinear = latencyMapLinear;
  dataCenterMap.bandwidthMap = bandwidthMap;
  dataCenterMap.holdTimeMapIT = holdTimeMapIT;
  dataCenterMap.holdTimeMapNET = holdTimeMapNET;
  dataCenterMap.shortestPathMap = shortestPathMap; 
  
end