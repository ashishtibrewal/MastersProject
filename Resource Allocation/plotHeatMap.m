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
  
  % Find factors (multiples) of nNodes to be able to create a scalable heatmap
  nNodesFactors = [];
  for i = 1:nNodes
    if (mod(nNodes,i) == 0)
      nNodesFactors = [nNodesFactors,i];
    end
  end
  
  nNodesFactorsSize = size(nNodesFactors,2);
  if (mod(nNodesFactorsSize,2) == 0)
    hmSize = [nNodesFactors(nNodesFactorsSize/2), nNodesFactors((nNodesFactorsSize/2) + 1)];
  else
    hmSize = [nNodesFactors(ceil(nNodesFactorsSize/2)), nNodesFactors(ceil(nNodesFactorsSize/2))];
  end

  scaleFactor = 8;

  rmap = zeros([hmSize,3]);
  rmapScaled = zeros([(hmSize * scaleFactor),3]);
  
  hmap = zeros([hmSize,3]);
  hmapScaled = zeros([(hmSize * scaleFactor),3]);
  
  switch (updateType)
    case 'locationMap'
      for r = 1:hmSize(1)
        for c = 1:hmSize(2)
          nodeType = dataCenterMap.completeResourceMap(startNode + ((r - 1) * hmSize(2)) + c);
          if (strcmp(nodeType, 'CPU') == 1)
              rmap(r,c,:) = [0,0,0];
          elseif (strcmp(nodeType, 'MEM') == 1)
              rmap(r,c,:) = [1,1,1];
          elseif (strcmp(nodeType, 'STO') == 1)
              rmap(r,c,:) = [0.5,0.5,0.5];
          end
        end
      end

      for r = 1:hmSize(1)
        for c = 1:hmSize(2)
          rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),1) = rmap(r,c,1);
          rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),2) = rmap(r,c,2);
          rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),3) = rmap(r,c,3);
        end
      end

      % Open new figure
      figure ('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
      subplot(1,2,1);
      imshow(rmapScaled);
      title('Resource type - CPUs = Black, MEMs = While, STOs = Grey');
      
    case 'heatMap'
      for r = 1:hmSize(1)
        for c = 1:hmSize(2)
          nodeVal = dataCenterMap.completeUnitAvailableMap(startNode + ((r - 1) * hmSize(2)) + c);
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

      for r = 1:hmSize(1)
        for c = 1:hmSize(2)
          hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),1) = hmap(r,c,1);
          hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),2) = hmap(r,c,2);
          hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),3) = hmap(r,c,3);
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