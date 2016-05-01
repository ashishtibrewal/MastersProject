% Script to extract all data for creating graphs

% Total types
% Type 1 = Homogeneous racks (Homogeneous blades)
% Type 2 = Heterogeneous racks (Homogeneous blades)
% Type 3 = Heterogeneous racks (Heterogeneous blades)
types = 3;

% Total requests
req = 1000;

% Spacing for graphs that don't need values for every request
spacing = 50; 

% Request vector
request = 1:req;
requestWithZero = 0:req;
requestSpacedFifty = 0:spacing:req;
requestSpacedHundred = 0:(spacing * 2):req;

% Extract allocation times
R_allocTime(:,1) = cell2mat(requestDB_T1(:,18));    % Type 1
R_allocTime(:,2) = cell2mat(requestDB_T2(:,18));    % Type 2
R_allocTime(:,3) = cell2mat(requestDB_T3(:,18));    % Type 3

% Extract utilisation
R_netUtilisation(:,1) = NETutilization_T1;          % Type 1
R_netUtilisation(:,2) = NETutilization_T2;          % Type 2
R_netUtilisation(:,3) = NETutilization_T3;          % Type 3

R_cpuUtilisation(:,1) = CPUutilization_T1;          % Type 1
R_cpuUtilisation(:,2) = CPUutilization_T2;          % Type 2
R_cpuUtilisation(:,3) = CPUutilization_T3;          % Type 3

R_memUtilisation(:,1) = MEMutilization_T1;          % Type 1
R_memUtilisation(:,2) = MEMutilization_T2;          % Type 2
R_memUtilisation(:,3) = MEMutilization_T3;          % Type 3

R_stoUtilisation(:,1) = STOutilization_T1;          % Type 1
R_stoUtilisation(:,2) = STOutilization_T2;          % Type 2
R_stoUtilisation(:,3) = STOutilization_T3;          % Type 3

% Extract blocking probability
R_bp(1,:) = 0;
for i = 2:(req + 1)
  R_bp(i,1) = nBlocked_T1(i-1)/(i-1);               % Type 1
  R_bp(i,2) = nBlocked_T2(i-1)/(i-1);               % Type 2
  R_bp(i,3) = nBlocked_T3(i-1)/(i-1);               % Type 3
end

% Extract failure cause
R_failureCause(1,1) = size(cell2mat(strfind(requestDB_T1(:,14),'CPU')),1);    % Failed due to CPU
R_failureCause(1,2) = size(cell2mat(strfind(requestDB_T2(:,14),'CPU')),1);    % Failed due to CPU
R_failureCause(1,3) = size(cell2mat(strfind(requestDB_T3(:,14),'CPU')),1);    % Failed due to CPU

R_failureCause(2,1) = size(cell2mat(strfind(requestDB_T1(:,14),'MEM')),1);    % Failed due to MEM
R_failureCause(2,2) = size(cell2mat(strfind(requestDB_T2(:,14),'MEM')),1);    % Failed due to MEM
R_failureCause(2,3) = size(cell2mat(strfind(requestDB_T3(:,14),'MEM')),1);    % Failed due to MEM

R_failureCause(3,1) = size(cell2mat(strfind(requestDB_T1(:,14),'STO')),1);    % Failed due to STO
R_failureCause(3,2) = size(cell2mat(strfind(requestDB_T2(:,14),'STO')),1);    % Failed due to STO
R_failureCause(3,3) = size(cell2mat(strfind(requestDB_T3(:,14),'STO')),1);    % Failed due to STO

R_failureCause(4,1) = size(cell2mat(strfind(requestDB_T1(:,15),'BAN')),1);    % Failed due to BAN
R_failureCause(4,2) = size(cell2mat(strfind(requestDB_T2(:,15),'BAN')),1);    % Failed due to BAN
R_failureCause(4,3) = size(cell2mat(strfind(requestDB_T3(:,15),'BAN')),1);    % Failed due to BAN

R_failureCause(5,1) = size(cell2mat(strfind(requestDB_T1(:,15),'LAT')),1);    % Failed due to LAT
R_failureCause(5,2) = size(cell2mat(strfind(requestDB_T2(:,15),'LAT')),1);    % Failed due to LAT
R_failureCause(5,3) = size(cell2mat(strfind(requestDB_T3(:,15),'LAT')),1);    % Failed due to LAT

% Extract spaced utilisation (Spacing = 50) -- Used for line graph
R_sF_netUtilisation(1,:) = 0;
R_sF_cpuUtilisation(1,:) = 0;
R_sF_memUtilisation(1,:) = 0;
R_sF_stoUtilisation(1,:) = 0;
index = 1;
for i = 1:req
  if (mod(i,spacing) == 0)
    index = index + 1;      % Increment index
    R_sF_netUtilisation(index,1) = NETutilization_T1(i);          % Type 1
    R_sF_netUtilisation(index,2) = NETutilization_T2(i);          % Type 2
    R_sF_netUtilisation(index,3) = NETutilization_T3(i);          % Type 3

    R_sF_cpuUtilisation(index,1) = CPUutilization_T1(i);          % Type 1
    R_sF_cpuUtilisation(index,2) = CPUutilization_T2(i);          % Type 2
    R_sF_cpuUtilisation(index,3) = CPUutilization_T3(i);          % Type 3

    R_sF_memUtilisation(index,1) = MEMutilization_T1(i);          % Type 1
    R_sF_memUtilisation(index,2) = MEMutilization_T2(i);          % Type 2
    R_sF_memUtilisation(index,3) = MEMutilization_T3(i);          % Type 3

    R_sF_stoUtilisation(index,1) = STOutilization_T1(i);          % Type 1
    R_sF_stoUtilisation(index,2) = STOutilization_T2(i);          % Type 2
    R_sF_stoUtilisation(index,3) = STOutilization_T3(i);          % Type 3
  end
end

% Put all data into a single matrix
R_sF_allUtilisation = [R_sF_netUtilisation,R_sF_cpuUtilisation,R_sF_memUtilisation,R_sF_stoUtilisation];

% Extract spaced utilisation (Spacing = 100) -- Used for bar graph
index = 0;
for i = 1:req
  if (mod(i,(spacing * 2)) == 0)
    index = index + 1;                                            % Increment index
    R_sH_netUtilisation(index,1) = NETutilization_T1(i);          % Type 1
    R_sH_netUtilisation(index,2) = NETutilization_T2(i);          % Type 2
    R_sH_netUtilisation(index,3) = NETutilization_T3(i);          % Type 3

    R_sH_cpuUtilisation(index,1) = CPUutilization_T1(i);          % Type 1
    R_sH_cpuUtilisation(index,2) = CPUutilization_T2(i);          % Type 2
    R_sH_cpuUtilisation(index,3) = CPUutilization_T3(i);          % Type 3

    R_sH_memUtilisation(index,1) = MEMutilization_T1(i);          % Type 1
    R_sH_memUtilisation(index,2) = MEMutilization_T2(i);          % Type 2
    R_sH_memUtilisation(index,3) = MEMutilization_T3(i);          % Type 3

    R_sH_stoUtilisation(index,1) = STOutilization_T1(i);          % Type 1
    R_sH_stoUtilisation(index,2) = STOutilization_T2(i);          % Type 2
    R_sH_stoUtilisation(index,3) = STOutilization_T3(i);          % Type 3
  end
end

% Put all data into a single matrix
R_sH_allUtilisation = [R_sH_netUtilisation,R_sH_cpuUtilisation,R_sH_memUtilisation,R_sH_stoUtilisation];

% Latency data
R_latency = [reqLatencyCM',reqLatencyMS',averageLatency_T1',minLatency_T1',maxLatency_T1',averageLatency_T2',minLatency_T2',maxLatency_T2',averageLatency_T3',minLatency_T3',maxLatency_T3'];