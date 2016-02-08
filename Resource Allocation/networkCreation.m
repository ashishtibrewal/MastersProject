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
  
  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;
  
  unitSizeCPU = dataCenterConfig.unitSizeCPU;
  unitSizeMEM = dataCenterConfig.unitSizeMEM;
  unitSizeSTO = dataCenterConfig.unitSizeSTO;

  racksCPU = dataCenterConfig.racksCPU;
  racksMEM = dataCenterConfig.racksMEM;
  racksSTO = dataCenterConfig.racksSTO;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK CONSTANTS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Optical fiber channels between each node
  numInterRackChannels = 10;    % Number of inter-rack channels
  numInterBladeChannels = 20;   % Number of inter-blade channels
  numInterSlotChannels = 20;    % Number of inter-slot channels
  maxChannelBandwidth = 25; % Maximum bandwidth available on a link connecting any two "nodes" in the network (i.e 400 Gb/s)
  minChannelLatency = 5;  % Minimum latency between two connected (adjacent) nodes is 5 ns (Assuming they are 1 meter apart)
  % Note that the latency is 5 ns/m - Higher the distance, higher the latency
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK CONNECTIVITY/TOPOLOGY MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS
  % 0 = Disconnected
  % 1 = Connected

  % RACK CONNECTIVITY - Fully-connected data-center (All racks are connected to all other racks)
  rackConnectivity = ones(nRacks);

  % BLADE CONNECTIVITY - All blades in a rack are connected - A fully-
  % connected rack (Note to get from a blade on one rack to a blade on 
  % another, you'd need to check the rackConnectivity matrix)
  % 1st & 2nd dimensions = Connectivity of blades in a rack
  % 3rd dimension = Rack number
  bladeConnectivity = ones(nBlades, nBlades, nRacks);

  % SLOT CONNECTIVITY - All slots on a blade are connected - A
  % fully-connected blade
  % 1st & 2nd dimensions = Connectivity of slots on a blade
  % 3rd dimension = Blade number
  % 4th dimension = Rack number
  slotConnectivity = ones(nSlots, nSlots, nBlades, nRacks);

  % Network map/connectivity struct containing the rack, blade and slot
  % connectivity maps
  networkMap.rackConnectivity = rackConnectivity;
  networkMap.bladeConnectivity = bladeConnectivity;
  networkMap.slotConnectivity = slotConnectivity;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NETWORK DISTANCE & LATENCY MAP
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
          % Distance between a slot and itself is 0
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
  % NETWORK/RESOURCE OCCUPIED MAP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % VALUE MEANINGS
  %  0 = Resource unavailable (i.e. the particular slot has no free unit)
  % >0 = Resource available (i.e. the particular slot has at least one free unit)

  % All slots in all blades in all racks are unoccupied at the start
  % 1st dimension = Slot number
  % 2nd dimension = Blade number
  % 3rd dimension = Rack number
  occupiedMap = zeros(nSlots, nBlades, nRacks);

  % Set the value for each slot to the number of units available in it
  for rackNo = 1:nRacks
    for bladeNo = 1:nBlades
      for slotNo = 1:nSlots
        % Check for CPU racks
        if (racksCPU(racksCPU == rackNo))
          %str = sprintf('Here !!! %i', rackNo);
          %disp(str);
          occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeCPU;
        end
        
        % Check for MEM racks
        if (racksMEM(racksMEM == rackNo))
          occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeMEM;
        end
        
        % Check for STO racks
        if (racksSTO(racksSTO == rackNo))
          occupiedMap(slotNo,bladeNo,rackNo) = nUnits * unitSizeSTO;
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
  dataCenterMap.networkMap = networkMap;
  dataCenterMap.occupiedMap = occupiedMap;
  dataCenterMap.distanceMap = distanceMap;
  dataCenterMap.latencyMap = latencyMap;
  dataCenterMap.bandwidthMap = bandwidthMap;
  dataCenterMap.holdTimeMap = holdTimeMap;
  
end