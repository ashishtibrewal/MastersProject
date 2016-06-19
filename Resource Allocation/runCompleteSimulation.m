%%+++++++++++++++++++++++++++++++++++++%%
%%% Script that runs all simualtions  %%%
%%+++++++++++++++++++++++++++++++++++++%%

% Script to automate/run the complete simulation with different
% data-center, resource pool setups.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up clean environment and logging functionality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;                      % Clear all variables in the workspace
close all;                      % Close all open figures
clc;                            % Clear console/command prompt
addpath(genpath('../MATLAB Custom Imports/'));  % Add path to utility library (Using genpath recursively adds subdirectories)
diaryDir = 'log/';              % Log directory
diaryFileName = strcat(diaryDir, 'log.txt');  % Log file name/path
% Create log (i.e. diary) directory if it doesn't already exist
if(exist(diaryDir,'dir') ~= 7)
  mkdir(diaryDir);
end
diary(diaryFileName);           % Create new diary with the specified file name
diary on;                       % Turn diary (i.e. logging functionality) on
str = sprintf('\n+-------- SIMULATION STARTED --------+\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Miscellaneous simulation "variables" (including macros)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Macro definitions
global SUCCESS;       % Declare macro as global
global FAILURE;       % Declare macro as global
global DROPPED;       % Declare macro as global
global HT_COMPLETE;   % Declare macro as global
SUCCESS = 1;          % Assign a value to global macro
FAILURE = 0;          % Assign a value to global macro
DROPPED = 2;          % Assign a value to global macro
HT_COMPLETE = 3;      % Assign a value to global macro

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluate constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numRequests = 1000;         % Total number of requests to generate
numTypes = 3;               % Total number of configuration types
generateNewRequestDB = 0;   % Flag that is used to generate a new request database
plotFigures = 1;            % Flag that is used to control figures/plots
displayFigures = 0;         % Flag that is used to control whether figures are visible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import configuration files (YAML config files)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import Type 1 configuration file
yaml_configFile_T1 = 'config/configType1.yaml';    % File to import (File path)
dataCenterConfig_T1 = ReadYaml(yaml_configFile_T1);   % Read file and store it into a struct called dataCenterConfig

% Import Type 2 configuration file
yaml_configFile_T2 = 'config/configType2.yaml';    % File to import (File path)
dataCenterConfig_T2 = ReadYaml(yaml_configFile_T2);   % Read file and store it into a struct called dataCenterConfig

% Import Type 3 configuration file
yaml_configFile_T3 = 'config/configType3.yaml';    % File to import (File path)
dataCenterConfig_T3 = ReadYaml(yaml_configFile_T3);   % Read file and store it into a struct called dataCenterConfig

% Type independent configuration file
dataCenterConfig = dataCenterConfig_T1;         % Store it as a separate variable to be able to extract common elements for all configuration types

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (generateNewRequestDB == 1)
  % Inputs generated here to keep it consistent across all simulations
  str = sprintf('Input generation started ...');
  disp(str);

  requestDB = inputGeneration(numRequests);    % Pre-generating randomised requests - Note that the resource allocation is only allowed to look at the request for the current iteration
  save('requestDB.mat','requestDB');

  str = sprintf('Input generation complete.\n');
  disp(str);
else
  % Inputs generated here to keep it consistent across all simulations
  str = sprintf('Loading input database ...');
  disp(str);

  load('requestDB');            % Load the same requestDB to keep it consistent across all simulations

  str = sprintf('Loading input database complete.\n');
  disp(str);
end

% Start MATLAB parallel pool (Using default cluster, i.e. 'local')
threadPool = gcp();     % Get current parallel pool, i.e. check if a parallel pool is open, if not open a new one
%threadPool = parpool();    % Open a new parpool with default cluster, i.e. 'local'

% Start timer
tic;

% Initialize variables to be able to use in the main parallel loop (parfor)
requestDB_T1 = [];
dataCenterMap_T1 = [];
requestDB_T2 = [];
dataCenterMap_T2 = [];
requestDB_T3 = [];
dataCenterMap_T3 = [];
nBlocked_T1 = [];
CPUutilization_T1 = [];
MEMutilization_T1 = [];
STOutilization_T1 = [];
NETutilization_T1 = [];
minLatency_T1 = [];
maxLatency_T1 = [];
averageLatency_T1 = [];
nBlocked_T2 = [];
CPUutilization_T2 = [];
MEMutilization_T2 = [];
STOutilization_T2 = [];
NETutilization_T2 = [];
minLatency_T2 = [];
maxLatency_T2 = [];
averageLatency_T2 = [];
nBlocked_T3 = [];
CPUutilization_T3 = [];
MEMutilization_T3 = [];
STOutilization_T3 = [];
NETutilization_T3 = [];
minLatency_T3 = [];
maxLatency_T3 = [];
averageLatency_T3 = [];
requests = 1:numRequests;
reqLatencyCM = cell2mat(requestDB(1:numRequests,6));
reqLatencyMS = cell2mat(requestDB(1:numRequests,7));

% Start parallel for loop to run multiple threads
parfor i = 1:numTypes
  type = i;     % Type of configuration/setup
  switch (i)
    case 1
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 1
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 1 ...\n');
      disp(str);

      [requestDB_T1_L, dataCenterMap_T1_L, nBlocked_T1_L, CPUutilization_T1_L, MEMutilization_T1_L, STOutilization_T1_L, NETutilization_T1_L, minLatency_T1_L, maxLatency_T1_L, averageLatency_T1_L] = simStart(dataCenterConfig_T1, numRequests, requestDB, type);
      requestDB_T1 = [requestDB_T1, requestDB_T1_L];
      dataCenterMap_T1 = [dataCenterMap_T1, dataCenterMap_T1_L];
      nBlocked_T1 = [nBlocked_T1, nBlocked_T1_L];
      CPUutilization_T1 = [CPUutilization_T1, CPUutilization_T1_L];
      MEMutilization_T1 = [MEMutilization_T1, MEMutilization_T1_L];
      STOutilization_T1 = [STOutilization_T1, STOutilization_T1_L];
      NETutilization_T1 = [NETutilization_T1, NETutilization_T1_L];
      minLatency_T1 = [minLatency_T1, minLatency_T1_L];
      maxLatency_T1 = [maxLatency_T1, maxLatency_T1_L];
      averageLatency_T1 = [averageLatency_T1, averageLatency_T1_L];

    case 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 2 ...\n');
      disp(str);

      [requestDB_T2_L, dataCenterMap_T2_L, nBlocked_T2_L, CPUutilization_T2_L, MEMutilization_T2_L, STOutilization_T2_L, NETutilization_T2_L, minLatency_T2_L, maxLatency_T2_L, averageLatency_T2_L] = simStart(dataCenterConfig_T2, numRequests, requestDB, type);
      requestDB_T2 = [requestDB_T2, requestDB_T2_L];
      dataCenterMap_T2 = [dataCenterMap_T2, dataCenterMap_T2_L];
      nBlocked_T2 = [nBlocked_T2, nBlocked_T2_L];
      CPUutilization_T2 = [CPUutilization_T2, CPUutilization_T2_L];
      MEMutilization_T2 = [MEMutilization_T2, MEMutilization_T2_L];
      STOutilization_T2 = [STOutilization_T2, STOutilization_T2_L];
      NETutilization_T2 = [NETutilization_T2, NETutilization_T2_L];
      minLatency_T2 = [minLatency_T2, minLatency_T2_L];
      maxLatency_T2 = [maxLatency_T2, maxLatency_T2_L];
      averageLatency_T2 = [averageLatency_T2, averageLatency_T2_L];

    case 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 3 ...\n');
      disp(str);

      [requestDB_T3_L, dataCenterMap_T3_L, nBlocked_T3_L, CPUutilization_T3_L, MEMutilization_T3_L, STOutilization_T3_L, NETutilization_T3_L, minLatency_T3_L, maxLatency_T3_L, averageLatency_T3_L] = simStart(dataCenterConfig_T3, numRequests, requestDB, type);
      requestDB_T3 = [requestDB_T3, requestDB_T3_L];
      dataCenterMap_T3 = [dataCenterMap_T3, dataCenterMap_T3_L];
      nBlocked_T3 = [nBlocked_T3, nBlocked_T3_L];
      CPUutilization_T3 = [CPUutilization_T3, CPUutilization_T3_L];
      MEMutilization_T3 = [MEMutilization_T3, MEMutilization_T3_L];
      STOutilization_T3 = [STOutilization_T3, STOutilization_T3_L];
      NETutilization_T3 = [NETutilization_T3, NETutilization_T3_L];
      minLatency_T3 = [minLatency_T3, minLatency_T3_L];
      maxLatency_T3 = [maxLatency_T3, maxLatency_T3_L];
      averageLatency_T3 = [averageLatency_T3, averageLatency_T3_L];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and plot results (Analysis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Displaying results (Type 1) ...');
disp(str);

displayResults(dataCenterMap_T1, requestDB_T1, numRequests, dataCenterConfig_T1);

str = sprintf('\nDisplaying results (Type 2) ...');
disp(str);

displayResults(dataCenterMap_T2, requestDB_T2, numRequests, dataCenterConfig_T2);

str = sprintf('\nDisplaying results (Type 3) ...');
disp(str);

displayResults(dataCenterMap_T3, requestDB_T3, numRequests, dataCenterConfig_T3);

% Stop timer and print its value
toc

% Close parpool
delete(threadPool);
%delete(gcp('nocreate'));   % The 'nocreate' option prevents opening a new one

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results/graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

if(plotFigures == 1)
  % HEAT MAPS (Type 1, Type 2 & Type 3)
  plotHeatMap(dataCenterConfig_T1, dataCenterMap_T1, 'allMapsSetup', displayFigures);
  plotHeatMap(dataCenterConfig_T2, dataCenterMap_T2, 'allMapsSetup', displayFigures);
  plotHeatMap(dataCenterConfig_T3, dataCenterMap_T3, 'allMapsSetup', displayFigures);

  % BLOCKING PROBABILITY (Request vs BP, IT utilisation vs BP, NET utilisation vs BP, etc.)
  %yFactor = eps;               % Set to epsilon to avoid going to -inf
  %yFactor = 1/(2 * nRequests);  % Set to half the maximum blocking probability to avoid going to -inf
  yFactor = 0;
  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(requests,max(yFactor,(nBlocked_T1)),'x-');
  hold on;
  semilogy(requests,max(yFactor,(nBlocked_T2)),'x-');
  semilogy(requests,max(yFactor,(nBlocked_T3)),'x-');
  xlabel('Request no.');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Blocking probability');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(CPUutilization_T1,nBlocked_T1,'x-');
  hold on;
  semilogy(CPUutilization_T2,nBlocked_T2,'x-');
  semilogy(CPUutilization_T3,nBlocked_T3,'x-');
  xlabel('CPU utilization (%)');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('CPU utilization vs Blocking probability');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(MEMutilization_T1,nBlocked_T1,'x-');
  hold on;
  semilogy(MEMutilization_T2,nBlocked_T2,'x-');
  semilogy(MEMutilization_T3,nBlocked_T3,'x-');
  xlabel('Memory utilization (%)');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Memory utilization vs Blocking probability');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(STOutilization_T1,nBlocked_T1,'x-');
  hold on;
  semilogy(STOutilization_T2,nBlocked_T2,'x-');
  semilogy(STOutilization_T3,nBlocked_T3,'x-');
  xlabel('Storage utilization (%)');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Storage utilization vs Blocking probability');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(CPUutilization_T1,nBlocked_T1,'x-');
  hold on;
  semilogy(MEMutilization_T1,nBlocked_T1,'x-');
  semilogy(STOutilization_T1,nBlocked_T1,'x-');
  xlabel('IT resource utilization (%)');
  ylabel('Blocking probability');
  legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
  title('IT Resource utilization vs Blocking probability - Homogenous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(CPUutilization_T2,nBlocked_T2,'x-');
  hold on;
  semilogy(MEMutilization_T2,nBlocked_T2,'x-');
  semilogy(STOutilization_T2,nBlocked_T2,'x-');
  xlabel('IT resource utilization (%)');
  ylabel('Blocking probability');
  legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
  title('IT Resource utilization vs Blocking probability - Heterogeneous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(CPUutilization_T3,nBlocked_T3,'x-');
  hold on;
  semilogy(MEMutilization_T3,nBlocked_T3,'x-');
  semilogy(STOutilization_T3,nBlocked_T3,'x-');
  xlabel('IT resource utilization (%)');
  ylabel('Blocking probability');
  legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
  title('IT Resource utilization vs Blocking probability - Heterogeneous racks (Heterogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(NETutilization_T1,nBlocked_T1,'x-');
  hold on;
  semilogy(NETutilization_T2,nBlocked_T2,'x-');
  semilogy(NETutilization_T3,nBlocked_T3,'x-');
  xlabel('Network utilization (%)');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Network utilization vs Blocking probability');

  % UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilization) - Log (Semi-log) scale
  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(requests,CPUutilization_T1,'-');
  hold on;
  semilogy(requests,MEMutilization_T1,'-');
  semilogy(requests,STOutilization_T1,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(requests,CPUutilization_T2,'-');
  hold on;
  semilogy(requests,MEMutilization_T2,'-');
  semilogy(requests,STOutilization_T2,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(requests,CPUutilization_T3,'-');
  hold on;
  semilogy(requests,MEMutilization_T3,'-');
  semilogy(requests,STOutilization_T3,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  semilogy(requests,NETutilization_T1,'-');
  hold on;
  semilogy(requests,NETutilization_T2,'-');
  semilogy(requests,NETutilization_T3,'-');
  xlabel('Request no.');
  ylabel('Network utilization');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Network utilization');

  % UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilization) - Linear scale
  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  plot(requests,CPUutilization_T1,'-');
  hold on;
  plot(requests,MEMutilization_T1,'-');
  plot(requests,STOutilization_T1,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  plot(requests,CPUutilization_T2,'-');
  hold on;
  plot(requests,MEMutilization_T2,'-');
  plot(requests,STOutilization_T2,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  plot(requests,CPUutilization_T3,'-');
  hold on;
  plot(requests,MEMutilization_T3,'-');
  plot(requests,STOutilization_T3,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

  if (displayFigures == 1)
    figure('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  plot(requests,NETutilization_T1,'-');
  hold on;
  plot(requests,NETutilization_T2,'-');
  plot(requests,NETutilization_T3,'-');
  xlabel('Request no.');
  ylabel('Network utilization');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Network utilization');

  % LATENCY ALLOCATION (REQUEST group vs LATENCY ALLOCATED - min, average, max graph)
  if (displayFigures == 1)
    figure('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  else
    figure('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
  end
  plot(requests,reqLatencyCM,'+','color', 'c');
  hold on;
  plot(requests,reqLatencyMS,'*','color', 'm');
  plot(requests,averageLatency_T1,'s','color', 'r');
  plot(requests,minLatency_T1,'o','color', 'r');
  plot(requests,maxLatency_T1,'x','color', 'r');
  plot(requests,averageLatency_T2,'s','color', 'g');
  plot(requests,minLatency_T2,'o','color', 'g');
  plot(requests,maxLatency_T2,'x','color', 'g');
  plot(requests,averageLatency_T3,'s','color', 'b');
  plot(requests,minLatency_T3,'o','color', 'b');
  plot(requests,maxLatency_T3,'x','color', 'b');
  xlabel('Request no.');
  ylabel('Latency (ns)');
  legend('Requested CPU-MEM latency', 'Requested MEM-STO latency', ...
         'Average latency - Homogenous racks (Homogeneous blades)', 'Minimum latency - Homogenous racks (Homogeneous blades)', 'Maximum latency - Homogenous racks (Homogeneous blades)', ...
         'Average latency - Heterogeneous racks (Homogeneous blades)', 'Minimum latency - Heterogeneous racks (Homogeneous blades)', 'Maximum latency - Heterogeneous racks (Homogeneous blades)', ...
         'Average latency - Heterogeneous racks (Heterogeneous blades)', 'Minimum latency - Heterogeneous racks (Heterogeneous blades)', 'Maximum latency - Heterogeneous racks (Heterogeneous blades)', ...
         'location','northwest');
  title('Request no. vs Latency allocated');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save figures and entire workspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outputFormats = {'png', 'fig'};
dateTime = datestr(datetime,'dd-mmm-yyyy--HH-MM-SS/');
relativePath = '../../';
simResultsDir = 'simResults/';
simResultsDirPath = strcat(relativePath, simResultsDir);
savePath = strcat(simResultsDirPath, dateTime);
simWorkspace = 'sim_workspace';
simWorkspacePath = strcat(simResultsDirPath, dateTime, simWorkspace);
% Create parent simulation results directory if it doesn't already exist
if(exist(simResultsDirPath,'dir') ~= 7)
  mkdir(simResultsDirPath);
end
% Save all "open" figures in the specified formats (Note: The saveFigs function creates a new directory for the current simulation under the parent directory if one doesn't already exist)
for i = 1:size(outputFormats,2)
  saveFigs(savePath, 'format', outputFormats{i});
end
% Save entire workspace
save(simWorkspacePath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up & display log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('\n+------- SIMULATION COMPLETE --------+\n');
disp(str);
diary off;                       % Turn diary (i.e. logging functionality) off
if(displayFigures == 0)
  close all;   % Manually close all figures (i.e. clear/release memory( since they are not being displayed
end
%clear;
%str = sprintf('Opening simulation log ...');
%disp(str);
%open('log/log.txt');
