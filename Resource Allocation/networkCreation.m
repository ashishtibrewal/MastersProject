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
  numInterRackChannels = dataCenterConfig.channels.interRack;    % Number of inter-rack channels
  numInterBladeChannels = dataCenterConfig.channels.interBlade;   % Number of inter-blade channels
  numInterSlotChannels = dataCenterConfig.channels.interSlot;    % Number of inter-slot channels
  maxChannelBandwidth = dataCenterConfig.bounds.maxChannelBandwidth; % Maximum bandwidth available on a link connecting any two "nodes" in the network (i.e 400 Gb/s)
  minChannelLatency = dataCenterConfig.bounds.minChannelLatency;  % Minimum latency between two connected (adjacent) nodes is 5 ns (Assuming they are 1 meter apart)
  % Note that the latency is 5 ns/m - Higher the distance, higher the latency
  
  % TODO Swicthes for all categoires (Take a constant - Different for TOR and TOB)
  TOD_delay = dataCenterConfig.switchDelay.TOD;   % TOD switch delay
  TOR_delay = dataCenterConfig.switchDelay.TOR;   % TOR switch delay
  TOB_delay = dataCenterConfig.switchDelay.TOB;   % TOB switch delay
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK CONNECTIVITY/TOPOLOGY MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS
  % 0 = Disconnected
  % 1 = Connected
  
  % Compelte/total connectivity map in a single 2D matrix of size 
  % [(nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks)]
  completeConnectivityMatrixSize = ((nTOR * nRacks) + (nTOB * nBlades * nRacks) + (nSlots * nBlades * nRacks));
  completeConnectivity = zeros(completeConnectivityMatrixSize);
  
  % RACK CONNECTIVITY - Fully-connected data-center (All racks are connected to all other racks)
  switch (rackTopology)
    case 'Fully-connected'
      rackConnectivity = ones(nTOR * nRacks);
      for rackNoDim1 = 1:(nTOR * nRacks)
        for rackNoDim2 = (rackNoDim1 + 1):(nTOR * nRacks)
          completeConnectivity(rackNoDim1,rackNoDim2) = 1;
        end
      end
    
    case 'Ring'
      
    %case 'Star'   % Make the first rack (i.e. first TOR in the first rack) the center of the star
      
    case 'Line'
      
    case 'Disconnected'
      rackConnectivity = zeros(nTOR * nRacks);
      % Do nothing to completeConnectivity since it's already zeroed
      
    %TODO Need to handle other cases/topologies
    otherwise
      error('Check configuration file for rack topology. Cases other than Fully-connected haven''t been handled yet.');
  end
  
  % TORs - TOBs CONNECTIVITY (i.e. rack to blade topology)
  % Note: When TOR > 1 => Star = Spineleaf
  switch (rack_bladeTopology)
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
  
  % BLADE CONNECTIVITY - All blades in a rack are connected - A fully-
  % connected rack (Note to get from a blade on one rack to a blade on 
  % another, you'd need to check the rackConnectivity matrix)
  % 1st & 2nd dimensions = Connectivity of blades in a rack
  % 3rd dimension = Rack number
  switch (bladeTopology)
    case 'Fully-connected'
      bladeConnectivity = ones(nBlades, nBlades, nRacks);
      
    case 'Ring'
      
    %case 'Star'   % Make the first blade (i.e. first TOB in the first blade) in each rack the center of the star
      
    case 'Line'
    
    case 'Disconnected'
      bladeConnectivity = zeros(nBlades, nBlades, nRacks);
      % Do nothing to completeConnectivity since it's already zeroed
      
    %TODO Need to handle other cases/topologies  
    otherwise
      error('Check configuration file for blade topology. Cases other than Fully-connected haven''t been handled yet.');
  end
  
  % TOBs - slots CONNECTIVITY (i.e. blade to slot topology)
  % Note: When TOB > 1 => Star = Spineleaf)
  switch (blade_slotTopology)
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
  
  % SLOT CONNECTIVITY - All slots on a blade are connected - A
  % fully-connected blade
  % 1st & 2nd dimensions = Connectivity of slots on a blade
  % 3rd dimension = Blade number
  % 4th dimension = Rack number
  switch (slotTopology)
    case 'Fully-connected'
      slotConnectivity = ones(nSlots, nSlots, nBlades, nRacks);
      
    case 'Ring'
      
    %case 'Star'   % Make the first slot in every blade in every rack the center of the star
      
    case 'Line'
      
    case 'Disconnected'
      slotConnectivity = zeros(nSlots, nSlots, nBlades, nRacks);
      
    %TODO Need to handle other cases/topologies
    otherwise
      error('Check configuration file for slot topology. Cases other than Fully-connected haven''t been handled yet.');
  end
      
  % Network map/connectivity struct containing the rack, blade and slot
  % connectivity maps
  connectivityMap.rackConnectivity = rackConnectivity;
  connectivityMap.bladeConnectivity = bladeConnectivity;
  connectivityMap.slotConnectivity = slotConnectivity;
  connectivityMap.completeConnectivity = completeConnectivity + completeConnectivity.';
  % Transposing completeConnectivity matrix and adding to fill in remaining
  % elements. Since only the upper half is filled as specified by the
  % topology and an adjacency matrix is symmetric, this works perfectly.

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

  % Network distance map struct containing the rack, blade and slot distance
  % maps
  distanceMap.rackDistance = rackDistance;
  distanceMap.bladeDistance = bladeDistance;
  distanceMap.slotDistance = slotDistance;
  
  % Network latency map struct containing the inter-rack, inter-blade and
  % inter-slot latency maps
  latencyMap.rackLatency = rackLatency;
  latencyMap.bladeLatency = bladeLatency;
  latencyMap.slotLatency = slotLatency;
  
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
  % NETWORK/RESOURCE OCCUPIED & TYPE MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS (OCCUPIED)
  %  0 = Resource unavailable (i.e. the particular slot has no free unit)
  % >0 = Resource available (i.e. the particular slot has at least one free unit)

  % All slots in all blades in all racks are unoccupied at the start
  % 1st dimension = Slot number
  % 2nd dimension = Blade number
  % 3rd dimension = Rack number
  occupiedMap = zeros(nSlots, nBlades, nRacks);
  
  % VALUE MEANINGS (TYPE)
  % CPU = 1
  % 
  
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
            occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeCPU; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'CPU';                % Store the type of resource
          % Check for homogeneous MEM blades
          case dataCenterConfig.setupTypes.homogenMEM
            occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeMEM; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'MEM';                % Store the type of resource
          % Check for homogeneous STO blades
          case dataCenterConfig.setupTypes.homogenSTO
            occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeSTO; % Updated occupied map
            resourceMap{slotNo,bladeNo,rackNo} = 'STO';                % Store the type of resource
          % Check for heterogeneous CPU & MEM blades
          case dataCenterConfig.setupTypes.heterogenCPU_MEM
            % Check for % of CPUs and % of MEMs
            switch (dataCenterConfig.heterogenSplit.heterogenCPU_MEM)
              % 50-50 CPU-MEM
              case 50
                % Even slots are CPUs
                if (mod(slotNo,2) == 0)
                  occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeCPU; % Updated occupied map
                  resourceMap{slotNo,bladeNo,rackNo} = 'CPU';                % Store the type of resource
                % Odd slots are MEMs
                else
                  occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeMEM; % Updated occupied map
                  resourceMap{slotNo,bladeNo,rackNo} = 'MEM';                % Store the type of resource
                end
              % Add cases to handle other percentages
              otherwise
                error('Check configuration file for CPU-MEM distribution percentage. Cases other than 50-50 haven''t been handled yet.');
            end
        end
      end
    end
  end

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
          rackBandwidth(rackNoDim1,rackNoDim2) = maxChannelBandwidth * numInterRackChannels;
        else
          rackBandwidth(rackNoDim1,rackNoDim2) = 0;
        end
      else
        rackBandwidth(rackNoDim1,rackNoDim2) = -1;
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
            bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = maxChannelBandwidth * numInterBladeChannels;
          else
            bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = 0;
          end
        else
          bladeBandwidth(bladeNoDim1,bladeNoDim2,rackNo) = -1;
        end
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
              slotBandwidth(slotNoDim1,slotNoDim2,bladeNo,rackNo) = maxChannelBandwidth * numInterSlotChannels;
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
  
  % Network distance map struct containing the rack, blade and slot distance
  % maps
  bandwidthMap.rackBandwidth = rackBandwidth;
  bandwidthMap.bladeBandwidth = bladeBandwidth;
  bandwidthMap.slotBandwidth = slotBandwidth;
  
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
  
  % THIS NEEDS TO BE CHANGED TO CONSIDER DIFFERENT UNITS INSIDE A SLOT
  holdTimeMap = zeros(nSlots, nBlades, nRacks);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Pack all maps into a single struct
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  dataCenterMap.connectivityMap = connectivityMap;
  dataCenterMap.occupiedMap = occupiedMap;
  dataCenterMap.resourceMap = resourceMap;
  dataCenterMap.distanceMap = distanceMap;
  dataCenterMap.latencyMap = latencyMap;
  dataCenterMap.latencyMapLinear = latencyMapLinear;
  dataCenterMap.bandwidthMap = bandwidthMap;
  dataCenterMap.holdTimeMap = holdTimeMap;
  
end