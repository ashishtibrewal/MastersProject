function plotHeatMap(dataCenterConfig, dataCenterMap, updateType)
% Function to plot the heatmap that represents the resource utilisation on
% each node (a node is a slot in this context)

  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;
  nTOR = dataCenterConfig.nTOR;
  nTOB = dataCenterConfig.nTOB;
  
  nTORs = nTOR * nRacks;
  nTOBs = nTOB * nBlades * nRacks;
  nNodes = nSlots * nBlades * nRacks;
  
  startNode = (nTORs + nTOBs);
  endNode = startNode + nNodes;

  hmap = zeros(64,64,3);
  hmapScaled = zeros(64*8,64*8,3);

  rhmap = zeros(64,64,3);
  rhmapScaled = zeros(64 * 8,64 * 8,3);
  
  switch (updateType)
    case 'locationMap'
      for r = 1:64
        for c = 1:64
          nodeType = dataCenterMap.completeResourceMap(startNode + ((r - 1) * 64) + c);
          if (strcmp(nodeType, 'CPU') == 1)
              rhmap(r,c,:) = [0,0,0];
          elseif (strcmp(nodeType, 'MEM') == 1)
              rhmap(r,c,:) = [1,1,1];
          elseif (strcmp(nodeType, 'STO') == 1)
              rhmap(r,c,:) = [0.5,0.5,0.5];
          end
        end
      end

      for r = 1:64
        for c = 1:64
          rhmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),1) = rhmap(r,c,1);
          rhmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),2) = rhmap(r,c,2);
          rhmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),3) = rhmap(r,c,3);
        end
      end

      % Open new figure
      figure ('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
      subplot(1,2,1);
      imshow(rhmapScaled);
      title('Resource type - CPUs = Black, MEMs = While, STOs = Grey');
      
    case 'heatMap'
      for r = 1:64
        for c = 1:64
          nodeVal = dataCenterMap.completeUnitAvailableMap(startNode + ((r - 1) * 64) + c);
          switch (nodeVal)
            case 0
              hmap(r,c,:) = [1,0,0];
            case 1
              hmap(r,c,:) = [1,1,0];
            case 2
              hmap(r,c,:) = [0,1,0];
          end
        end
      end

      for r = 1:64
        for c = 1:64
          hmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),1) = hmap(r,c,1);
          hmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),2) = hmap(r,c,2);
          hmapScaled((((r - 1) * 8) + 1):(r * 8),(((c - 1) * 8) + 1):(c * 8),3) = hmap(r,c,3);
        end
      end

      subplot(1,2,2);
      imshow(hmapScaled);
      title('Resource Utilization - Green = Max free, Yellow = Min free, Red = None free');
      
      %blocked = find(cell2mat(requestDB(1:t,9)) == 0);
      %nBlocked = [nBlocked,size(blocked,1)];
      %subplot(1,3,3);
      %plot(nBlocked,t);
      %title('Blocking probability');
      
      pause(0.01);      % Pause to update the plot/figure
  end

end