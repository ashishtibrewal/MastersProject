function [coreseq1,coreseq2] = prioritymap7core_uni()
% prioritymap7core_uni - Function to generate a priority map for a 7 core 
% fibre.
%   Function return values:
%     coreseq1 - Core Sequence 1
%     coreseq2 - Core Sequence 2

  coreseq1=zeros(1,7);    % Zero the values for core sequence 1
  coreseq2=zeros(1,7);    % Zero the values for core sequence 2

  corecost=zeros(1,7);    % Zero the value for core cost
  corecost(7)=inf;        % Set last element in core cost to infinity

  %coreseq1=[7 3 5 10 12 14];
  for time=1:7            % Loop from time 1 to 7
    if time==1            % Star time
      % Get the index of the highest value in the corecost array/matrix and store it in corenum. Initially returns 7 since corecost(7) is set to inifinity before entering the loop
        [~,corenum]=max(corecost);
    else
      % Get the index of the lowest value in the corecost array/matrix and store it in corenum.
        [~,corenum]=min(corecost);
    end
    % Set the values for each core sequence for each timestep.
    coreseq1(time)=corenum;
    coreseq2(time)=corenum+7;       % Question: Why adding 7 here ?
    corecost=cost7_2(corecost,corenum);
  end
  
end
    
    
    
         
     
     
     




