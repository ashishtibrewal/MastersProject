function [coreseq1,coreseq2] = prioritymap7core_start2()
% prioritymap7core_start2 - Function to generate a priority map for a 7 
% core fibre.
%   Function return values:
%     coreseq1 - Core Sequence 1
%     coreseq2 - Core Sequence 2

  loop=3;
  coreseq1=zeros(1,6);
  coreseq2=zeros(1,6);

  corecost=zeros(1,7);
  corecost(7)=inf;

%  coreseq1=[7 3 5 10 12 14];
  for time=1:loop
      if time==1
          [~,corenum]=max(corecost);
      else
          [~,corenum]=min(corecost);
      end
      coreseq1(time)=corenum;
      corecost=cost7_2(corecost,corenum);
  end

  corecost=zeros(1,14);  
  corecost(10)=inf;  
  corecost(14)=0.1; 
  corecost(13)=0.2;

  for time=1:(6-loop)
    if time==1
       [~,corenum]=max(corecost);
    else
%      [~,corenum]=min(corecost);
      for i=8:14
        if corecost(i)<=corecost(corenum)
            corenum=i;
        end
      end
    end
    coreseq1(time+loop)=corenum;
    corecost=cost7_2(corecost,corenum);
  end

%  coreseq2=[4 6 2 13 9 11]; 
  corecost=zeros(1,7);
  corecost(4)=inf;
  corecost(2)=0.1;

  for time=1:loop
    if time==1
        [~,corenum]=max(corecost);
    else
       [~,corenum]=min(corecost);
    end
    coreseq2(time+loop)=corenum;
    corecost=cost7_2(corecost,corenum);
  end

  corecost=zeros(1,14);
  corecost(13)=inf;
  corecost(11)=0.15;
  corecost(9)=0.1;
  corecost(10)=0.2;
  for time=1:(6-loop)
    if time==1
      [~,corenum]=max(corecost);
    else
%      [~,corenum]=min(corecost);
      for i=8:14
        if corecost(i)<=corecost(corenum)
            corenum=i;
        end
      end
    end
    coreseq2(time)=corenum;
    corecost=cost7_2(corecost,corenum);
  end
  coreseq3=zeros(1,7);
  coreseq4=zeros(1,7);

  corecost=zeros(1,7);
  corecost(7)=inf;

%  coreseq1=[7 3 5 10 12 14];
  for time=1:7
    if time==1
      [~,corenum]=max(corecost);
    else
      [~,corenum]=min(corecost);
    end
      coreseq3(time)=corenum;
      coreseq4(time)=corenum+7;
      corecost=cost7_2(corecost,corenum);
  end
  coreseq1=[coreseq1 coreseq3(7)];
  coreseq2=[coreseq2 coreseq4(7)]; 
end


