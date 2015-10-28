% Comparision of all new algorithms
% 7cores 
% Typical 6 nodes topology

clear all;
link=map6nodesDATA();

node=length(link);
sta=zeros(1,10000);
dst=zeros(1,10000);
BW=zeros(1,10000);
[coreseq1  coreseq2] = prioritymap7core_start2(  );


for y=1:5
    % y=1  '2di priority core switch spectrum soft split'
    % y=2  '2di priority core switch slot split spectrum soft split 3 paths '
    % y=3  '2di priority core switch spectrum hard split 3 paths(0.001)'
    % y=4  '2di priority core switch spectrum hard split 3 paths(0.01)'
    % y=5  '2di priority core switch spectrum hard split 3 paths(0.1)'
    pathmemory=zeros(10000,10);
    linkblock=linkBlock();
    LXPR=LXPR6nodes();
    NumSlots=NS6nodes7cores();
    xtavg=zeros(1,100);
    probabilitya=zeros(1,100);
    probabilityb=zeros(1,100);
    probabilityc=zeros(1,100);
    count=zeros(1,10000);
    XTblockcount=zeros(1,10000);
    EXTblockcount=zeros(1,10000);
    core=zeros(14,100);
    sum1=zeros(9,100);
    xtmin=zeros(1,100);
    xtmax=zeros(1,100);
    Bcauses=zeros(10000,3);
    XTcondition=zeros(2,4);
    time=zeros(1,100);
    
    resource=res6nodes();
    resource1=res6nodes();
    seq=1;
    dis=zeros(1,10000);
    XT=zeros(1,10000);
    no=0;%no crosstalk number(0XT and blcok number)
    
    
    slot_index3=0;
    slot_index4=0;
    K1=0;
    K2=0;
    
    %XT=crosstalk();
    for x=1:10000%request(x)
        tic;
        if y==1
            sta(x)=randi([1,node],1,1); %generate random start node
            dst(x)=randi([1,node],1,1); %generate random destination node
            BW(x)=2*randi([1,4],1,1);   %generate random BW (2 4 6 8)
            while sta(x)==dst(x)
                dst(x)=randi([1,node],1,1); %if the two random number are same, regenerate one.
            end
        end
        
        [distance,path]=dijkstra(link,sta(x),dst(x));  %use the dijkstra code to find the shortest path
        
        
        if y==3
           k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
             
             if blocking~=0
                K1=K1+1;
             end            
            if K1/x>=0.001
                slot_index4=100;
                slot_index3=100;
                     
            end
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
            
            %use pathmemory to remember all paths for each request
            
         
        end
        
        if y==1
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
              [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:)]=ff1XTnewcoreswitchKpaths2di_ss_(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,coreseq1,coreseq2);
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
        end
        
         if y==4
           k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
             
             if blocking~=0
                K1=K1+1;
             end            
            if K1/x>=0.01
                slot_index4=100;
                slot_index3=100;
                     
            end
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
         end
         
         
         if y==2
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
           [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,XTeach,k_index,Bcauses(x,:)]=ff1XTnewcoreswitchsplitKpaths2di_ss(BW,shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,coreseq1,coreseq2);
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
         end
         
         if y==5
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
             
             if blocking~=0
                K1=K1+1;
             end            
            if K1/x>=0.1
                slot_index4=100;
                slot_index3=100;
                     
            end
            
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
         end
        
         
        seq=seq+1;
        if seq==8
            seq=1;
        end
        
        
        dis(x)=distance;
        count(x)=blocking;
         XTblockcount(x)=XTblock;
         EXTblockcount(x)=EXTblock;
        

            if mod(x,100)==0
                %x==200/2||x==400/2||x==600/2||x==800/2||x==1000/2||x==1200/2||x==1400/2||x==1600/2||x==1800/2||x==2000/2||x==2200/2||x==2400/2||x==2600/2||x==2800/2||x==3000/2||x==3200/2||x==3400/2||x==3600/2||x==3800/2||x==4000/2
                XTsum=0;
                x
                time(x/100)=toc/100;
                for k=1:x
                    
                    XTsum=XTsum+XT(k);
                end
                xtavg(x/100)=10*log10(XTsum/(x-sum(count)));
                
                xtmax(x/100)=10*log10(max(XT));
                
                count1=count(1:x);
                XTmin1=XT(1:x);
                % First x elememts of count and XT
                %Then they are used to calculate min successful XT 
                xtmin(x/100)=10*log10(min(XTmin1(count1==0)));
                if xtmin(x/100)==-inf
                    xtmin(x/100)=-40;
                end   
                
                  resource1=resource;
                
                            for i=1:14
                for j=1:200
                    
      %core function is used to get how many slots are still
      %empty for whole links. In the last, it shows the ultilization
      % in whole links of each core.
          resource1(resource1<0)=0;
            core(i,x/100)=core(i,x/100)+(resource1(i,j,1,2)+resource1(i,j,1,6)+resource1(i,j,2,3)+resource1(i,j,2,6)+resource1(i,j,3,4)+resource1(i,j,3,5)+resource1(i,j,3,6)+resource1(i,j,4,5)+resource1(i,j,5,6));
      
            %The sum function is used to get how many slots are still
            %empty in each link.   
            
            sum1(1,x/100)=sum1(1,x/100)+resource1(i,j,1,2);
            sum1(2,x/100)=sum1(2,x/100)+resource1(i,j,1,6);
            sum1(3,x/100)=sum1(3,x/100)+resource1(i,j,2,3);
            sum1(4,x/100)=sum1(4,x/100)+resource1(i,j,2,6);
            sum1(5,x/100)=sum1(5,x/100)+resource1(i,j,3,4);
            sum1(6,x/100)=sum1(6,x/100)+resource1(i,j,3,5);
            sum1(7,x/100)=sum1(7,x/100)+resource1(i,j,3,6);
            sum1(8,x/100)=sum1(8,x/100)+resource1(i,j,4,5);
            sum1(9,x/100)=sum1(9,x/100)+resource1(i,j,5,6);
            
                end
                core(i,x/100)=(1800-core(i,x/100))/1800;
                            end
            
                                           
            end
      
        
        %linkblocksum 4 is four different counting place for x=1k 2k 3k 4k
        % 2 -> request numbers and block numbers in this link
        %9 -> nine different links
        if x==2500
            %             linkblocksum=zeros(4,2,9);
            linkblockratio=zeros(9,4); %Link block ratio
            
            %             linkblocksum(1,1,1)=linkblock(1,1,2);
            %             linkblocksum(1,2,1)=linkblock(2,1,2);
            linkblockratio(1,1)=linkblock(2,1,2)/linkblock(1,1,2);
            
            %             linkblocksum(1,1,2)=linkblock(1,1,6);
            %             linkblocksum(1,2,2)=linkblock(2,1,6);
            linkblockratio(2,1)=linkblock(2,1,6)/linkblock(1,1,6);
            
            %             linkblocksum(1,1,3)=linkblock(1,2,3);
            %             linkblocksum(1,2,3)=linkblock(2,2,3);
            linkblockratio(3,1)=linkblock(2,2,3)/linkblock(1,2,3);
            
            %             linkblocksum(1,1,4)=linkblock(1,2,6);
            %             linkblocksum(1,2,4)=linkblock(2,2,6);
            linkblockratio(4,1)=linkblock(2,2,6)/linkblock(1,2,6);
            
            %             linkblocksum(1,1,5)=linkblock(1,3,4);
            %             linkblocksum(1,2,5)=linkblock(2,3,4);
            linkblockratio(5,1)=linkblock(2,3,4)/linkblock(1,3,4);
            
            %             linkblocksum(1,1,6)=linkblock(1,3,5);
            %             linkblocksum(1,2,6)=linkblock(2,3,5);
            linkblockratio(6,1)=linkblock(2,3,5)/linkblock(1,3,5);
            
            %             linkblocksum(1,1,7)=linkblock(1,3,6);
            %             linkblocksum(1,2,7)=linkblock(2,3,6);
            linkblockratio(7,1)=linkblock(2,3,6)/linkblock(1,3,6);
            
            %             linkblocksum(1,1,8)=linkblock(1,4,5);
            %             linkblocksum(1,2,8)=linkblock(2,4,5);
            linkblockratio(8,1)=linkblock(2,4,5)/linkblock(1,4,5);
            
            %             linkblocksum(1,1,9)=linkblock(1,5,6);
            %             linkblocksum(1,2,9)=linkblock(2,5,6);
            linkblockratio(9,1)=linkblock(2,5,6)/linkblock(1,5,6);
            
        end
        
        if x==5000
            
            %             linkblocksum(2,1,1)=linkblock(1,1,2);
            %             linkblocksum(2,2,1)=linkblock(2,1,2);
            linkblockratio(1,2)=linkblock(2,1,2)/linkblock(1,1,2);
            
            %             linkblocksum(2,1,2)=linkblock(1,1,6);
            %             linkblocksum(2,2,2)=linkblock(2,1,6);
            linkblockratio(2,2)=linkblock(2,1,6)/linkblock(1,1,6);
            
            %             linkblocksum(2,1,3)=linkblock(1,2,3);
            %             linkblocksum(2,2,3)=linkblock(2,2,3);
            linkblockratio(3,2)=linkblock(2,2,3)/linkblock(1,2,3);
            
            %             linkblocksum(2,1,4)=linkblock(1,2,6);
            %             linkblocksum(2,2,4)=linkblock(2,2,6);
            linkblockratio(4,2)=linkblock(2,2,6)/linkblock(1,2,6);
            
            %             linkblocksum(2,1,5)=linkblock(1,3,4);
            %             linkblocksum(2,2,5)=linkblock(2,3,4);
            linkblockratio(5,2)=linkblock(2,3,4)/linkblock(1,3,4);
            
            %             linkblocksum(2,1,6)=linkblock(1,3,5);
            %             linkblocksum(2,2,6)=linkblock(2,3,5);
            linkblockratio(6,2)=linkblock(2,3,5)/linkblock(1,3,5);
            
            %             linkblocksum(2,1,7)=linkblock(1,3,6);
            %             linkblocksum(2,2,7)=linkblock(2,3,6);
            linkblockratio(7,2)=linkblock(2,3,6)/linkblock(1,3,6);
            
            %             linkblocksum(2,1,8)=linkblock(1,4,5);
            %             linkblocksum(2,2,8)=linkblock(2,4,5);
            linkblockratio(8,2)=linkblock(2,4,5)/linkblock(1,4,5);
            
            %             linkblocksum(2,1,9)=linkblock(1,5,6);
            %             linkblocksum(2,2,9)=linkblock(2,5,6);
            linkblockratio(9,2)=linkblock(2,5,6)/linkblock(1,5,6);
            
        end
        if x==7500
            
            %             linkblocksum(3,1,1)=linkblock(1,1,2);
            %             linkblocksum(3,2,1)=linkblock(2,1,2);
            linkblockratio(1,3)=linkblock(2,1,2)/linkblock(1,1,2);
            
            %             linkblocksum(3,1,2)=linkblock(1,1,6);
            %             linkblocksum(3,2,2)=linkblock(2,1,6);
            linkblockratio(2,3)=linkblock(2,1,6)/linkblock(1,1,6);
            
            %             linkblocksum(3,1,3)=linkblock(1,2,3);
            %             linkblocksum(3,2,3)=linkblock(2,2,3);
            linkblockratio(3,3)=linkblock(2,2,3)/linkblock(1,2,3);
            
            %             linkblocksum(3,1,4)=linkblock(1,2,6);
            %             linkblocksum(3,2,4)=linkblock(2,2,6);
            linkblockratio(4,3)=linkblock(2,2,6)/linkblock(1,2,6);
            
            %             linkblocksum(3,1,5)=linkblock(1,3,4);
            %             linkblocksum(3,2,5)=linkblock(2,3,4);
            linkblockratio(5,3)=linkblock(2,3,4)/linkblock(1,3,4);
            
            %             linkblocksum(3,1,6)=linkblock(1,3,5);
            %             linkblocksum(3,2,6)=linkblock(2,3,5);
            linkblockratio(6,3)=linkblock(2,3,5)/linkblock(1,3,5);
            
            %             linkblocksum(3,1,7)=linkblock(1,3,6);
            %             linkblocksum(3,2,7)=linkblock(2,3,6);
            linkblockratio(7,3)=linkblock(2,3,6)/linkblock(1,3,6);
            
            %             linkblocksum(3,1,8)=linkblock(1,4,5);
            %             linkblocksum(3,2,8)=linkblock(2,4,5);
            linkblockratio(8,3)=linkblock(2,4,5)/linkblock(1,4,5);
            
            %             linkblocksum(3,1,9)=linkblock(1,5,6);
            %             linkblocksum(3,2,9)=linkblock(2,5,6);
            linkblockratio(9,3)=linkblock(2,5,6)/linkblock(1,5,6);
            
        end
        if x==10000
            
            %             linkblocksum(4,1,1)=linkblock(1,1,2);
            %             linkblocksum(4,2,1)=linkblock(2,1,2);
            linkblockratio(1,4)=linkblock(2,1,2)/linkblock(1,1,2);
            
            %             linkblocksum(4,1,2)=linkblock(1,1,6);
            %             linkblocksum(4,2,2)=linkblock(2,1,6);
            linkblockratio(2,4)=linkblock(2,1,6)/linkblock(1,1,6);
            
            %             linkblocksum(4,1,3)=linkblock(1,2,3);
            %             linkblocksum(4,2,3)=linkblock(2,2,3);
            linkblockratio(3,4)=linkblock(2,2,3)/linkblock(1,2,3);
            
            %             linkblocksum(4,1,4)=linkblock(1,2,6);
            %             linkblocksum(4,2,4)=linkblock(2,2,6);
            linkblockratio(4,4)=linkblock(2,2,6)/linkblock(1,2,6);
            %
            %             linkblocksum(4,1,5)=linkblock(1,3,4);
            %             linkblocksum(4,2,5)=linkblock(2,3,4);
            linkblockratio(5,4)=linkblock(2,3,4)/linkblock(1,3,4);
            
            %             linkblocksum(4,1,6)=linkblock(1,3,5);
            %             linkblocksum(4,2,6)=linkblock(2,3,5);
            linkblockratio(6,4)=linkblock(2,3,5)/linkblock(1,3,5);
            
            %             linkblocksum(4,1,7)=linkblock(1,3,6);
            %             linkblocksum(4,2,7)=linkblock(2,3,6);
            linkblockratio(7,4)=linkblock(2,3,6)/linkblock(1,3,6);
            
            %             linkblocksum(4,1,8)=linkblock(1,4,5);
            %             linkblocksum(4,2,8)=linkblock(2,4,5);
            linkblockratio(8,4)=linkblock(2,4,5)/linkblock(1,4,5);
            
            %             linkblocksum(4,1,9)=linkblock(1,5,6);
            %             linkblocksum(4,2,9)=linkblock(2,5,6);
            linkblockratio(9,4)=linkblock(2,5,6)/linkblock(1,5,6);
            
        end
        
    end
    
    
        sum1=(2800-sum1)/2800;
    asum=zeros(1,100);
    for t=1:100
        for i=1:9
            asum(t)=asum(t)+sum1(i,t);
        end
    end
    asum=asum/9;
    
    a=0;%Total block number
    a1=0;%Total block number(Kpaths)
    b=0;%Block number due to XT
    c=0;%Block number due to resource
    
    XTsum=0;
   for i=100:100:10000
        for j=(i-99):i
            a=a+count(j);
            
            a1=a1+sum(Bcauses(j,:)~=0);
            b=b+sum(Bcauses(j,:)==1);
            
        end
            
   
    
         c=a1-b;
         probabilitya(i/100)=a/i;
%          probabilityb(i/100)=b/i;
%          probabilityc(i/100)=c/i;
        
        if (xtavg(i/100))==-inf
            xtavg(i/100)=-90;
        end
        
    end
    
     d=b/a1; %percentage of block due to XT
     e=c/a1; %percentage of block due to resource
    
       for k=2500:2500:10000
            
            
        XTcondition(1,k/2500)=sum(EXTblockcount(1:k))/(sum(XTblockcount(1:k))+sum(EXTblockcount(1:k)));
        XTcondition(2,k/2500)=1-XTcondition(1,k/2500);
          
      
      end
     
     
    x=100:100:10000;
    figure(1);
    if y==1
        semilogy(asum,probabilitya,'xb-');
    end
    if y==2
        semilogy(asum,probabilitya,'+g-');
    end
     if y==3
        semilogy(asum,probabilitya,'vr-');
    end
    if y==4
        semilogy(asum,probabilitya,'dk-');
    end
    if y==5
        semilogy(asum,probabilitya,'sm-');
    end
   
    
    
    hold on;
    legend('2di priority core switch spectrum soft split 3 paths ','2di priority core switch slot split spectrum soft split 3 paths ','2di priority core switch spectrum hard split 3 paths (0.001)','2di priority core switch spectrum hard split 3 paths (0.01)','2di priority core switch spectrum hard split 3 paths (0.1)',5);
    axis([0,1,0,1]);
    title('Blocking Probability for Random Source and Destination');
    xlabel('Network Utilization');
    ylabel('Blocking Probability');
   % grid on;
    
    

    
    
      
    

end
