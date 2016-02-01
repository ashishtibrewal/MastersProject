function plotUsage(occupiedMap, dataCenterConfig)
% Function to plot data center usage

tRacks = dataCenterConfig.tRacks;
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

% Plot axes limits
limits = [0, nBlades, 0, nSlots, 0, nUnits];
i = 0;
% Create a 3D bar plots
for rackNo = 1:(nRacks/tRacks):nRacks
  i = i + 1;
  subplot(1,3,i);
  
  if (racksCPU(racksCPU == rackNo))
    bar3(abs(occupiedMap(:,:,rackNo) - (nUnits * unitSizeCPU)));
  end
  
  if (racksMEM(racksMEM == rackNo))
    bar3(abs(occupiedMap(:,:,rackNo) - (nUnits * unitSizeMEM)));
  end
  
  if (racksSTO(racksSTO == rackNo))
    bar3(abs(occupiedMap(:,:,rackNo) - (nUnits * unitSizeSTO)));
  end
  
  str = sprintf('Rack %i', rackNo);
  if (racksCPU(racksCPU == rackNo)) str = strcat(str, ' (CPUs)');
  elseif (racksMEM(racksMEM == rackNo)) str = strcat(str, ' (MEMs)');
  elseif (racksSTO(racksSTO == rackNo)) str = strcat(str, ' (STOs)');
  end
  title(str);
  xlabel('Blade');
  ylabel('Slot');
  zlabel('Unit');
  axis(limits);
end

% Pause to be able to complete plotting
pause(0.01);
end

