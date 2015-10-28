function [ coreseq1  coreseq2] = prioritymap7core_uni(  )
  
    coreseq1=zeros(1,7);
    coreseq2=zeros(1,7);
    
    corecost=zeros(1,7);
    corecost(7)=inf;
       
  %  coreseq1=[7 3 5 10 12 14];
    for time=1:7
        if time==1
            [~,corenum]=max(corecost);
        else
            [~,corenum]=min(corecost);
         
        end
        coreseq1(time)=corenum;
        coreseq2(time)=corenum+7;
        corecost=cost7_2(corecost,corenum);
   
    end
    
    
    
         
     
     
     




