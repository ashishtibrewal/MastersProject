% Comparision of all new algorithms
% 7cores 
% Typical 5spine 20leaf topology

clear all;
link=mapspine();

node=length(link)-5;
sta=zeros(1,20000);
dst=zeros(1,20000);
BW=zeros(1,20000);
[coreseq1  coreseq2] = prioritymap7core_start2(  );


for y=1:5
    % y=1  '2di priority core switch spectrum soft split'
    % y=2  '2di priority core switch slot split spectrum soft split 3 paths '
    % y=3  '2di priority core switch spectrum hard split 3 paths(0.001)'
    % y=4  '2di priority core switch spectrum hard split 3 paths(0.01)'
    % y=5  '2di priority core switch spectrum hard split 3 paths(0.1)'
    pathmemory=zeros(20000,10);
    linkblock=linkBlock20spineleaf();
    LXPR=LXPR20spineleaf;
    NumSlots=NS20spineleaf7cores();
    xtavg=zeros(1,50);
    probabilitya=zeros(1,50);
    probabilityb=zeros(1,50);
    probabilityc=zeros(1,50);
    count=zeros(1,20000);
    XTblockcount=zeros(1,20000);
    EXTblockcount=zeros(1,20000);
    core=zeros(14,50);
    sum1=zeros(60,50);
    xtmin=zeros(1,50);
    xtmax=zeros(1,50);
    Bcauses=zeros(20000,3);
    XTcondition=zeros(2,4);
    %%%% change%%%%
    %LXPR=LXPR6nodes();
    
    resource=res20spineleaf();
    resource1=res20spineleaf();
    seq=1;
    dis=zeros(1,20000);
    XT=zeros(1,20000);
    no=0;%no crosstalk number(0XT and blcok number)
    
    
    slot_index3=0;
    slot_index4=0;
    K1=0;
    K2=0;
    
    %XT=crosstalk();
    for x=1:20000%request(x)
        if y==1
            sta(x)=randi([1,node],1,1); %generate random start node
            dst(x)=randi([1,node],1,1); %generate random destination node
            BW(x)=2*randi([1,4],1,1);   %generate random BW (2 4 6 8)
            while sta(x)==dst(x)
                dst(x)=randi([1,node],1,1); %if the two random number are same, regenerate one.
            end
        end
        
        [distance,path]=dijkstra(link,sta(x),dst(x));  %use the dijkstra code to find the shortest path
        
        
        if y==4
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
             
             
            if blocking~=0
                K1=K1+1;
            end
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1/x>=0.05
%                 K1/x
%                 slot_index3=100;
%             end
            if K1/x>=0.01
                slot_index4=100;
                slot_index3=100;
             
%             if T1~=0
%                 K1=K1+1;
%             end
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1==600
%                 slot_index3=100;
%             end
%             if K2==600
%                 slot_index4=100;
            end
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
            
            %use pathmemory to remember all paths for each request
            
         
        end
        
        if y==2
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
              [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:)]=ff1XTnewcoreswitchKpaths2di_ss_(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,coreseq1,coreseq2);
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
        end
        
         if y==3
             k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
             
             
            if blocking~=0
                K1=K1+1;
            end
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1/x>=0.05
%                 K1/x
%                 slot_index3=100;
%             end
            if K1/x>=0.001
                slot_index4=100;
                slot_index3=100;
             
%             if T1~=0
%                 K1=K1+1;
%             end
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1==600
%                 slot_index3=100;
%             end
%             if K2==600
%                 slot_index4=100;
            end
            for i=1:length(shortestpaths{k_index})
                pathmemory(x,i)=shortestpaths{k_index}(i);
            end
         end
         
         
         if y==1
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
           [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,XTeach,k_index,Bcauses(x,:)]=ff1XTnewcoreswitchsplitKpaths2di_ss(BW,shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,coreseq1,coreseq2);
           Bcauses(x,:) 
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
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1/x>=0.05
%                 K1/x
%                 slot_index3=100;
%             end
            if K1/x>=0.1
                slot_index4=100;
                slot_index3=100;
             
%             if T1~=0
%                 K1=K1+1;
%             end
%             if T2~=0
%                 K2=K2+1;
%             end
%             if K1==600
%                 slot_index3=100;
%             end
%             if K2==600
%                 slot_index4=100;
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
        

            if mod(x,400)==0
                %x==200/2||x==400/2||x==600/2||x==800/2||x==1000/2||x==1200/2||x==1400/2||x==1600/2||x==1800/2||x==2000/2||x==2200/2||x==2400/2||x==2600/2||x==2800/2||x==3000/2||x==3200/2||x==3400/2||x==3600/2||x==3800/2||x==4000/2
%                 XTsum=0;
                x

                
                  resource1=resource;
                
          for i=1:14
                for j=1:200
                    
      %core function is used to get how many slots are still
      %empty for whole links. In the last, it shows the ultilization
      % in whole links of each core.
          resource1(resource1<0)=0;
           core(i,x/400)=core(i,x/400)+(resource1(i,j,1,21)+resource1(i,j,2,21)+resource1(i,j,3,21)+resource1(i,j,4,21)+resource1(i,j,5,21)+resource1(i,j,6,21)+resource1(i,j,7,21)+resource1(i,j,8,21)+resource1(i,j,9,21)+resource1(i,j,10,21)+resource1(i,j,11,21)+resource1(i,j,12,21)+resource1(i,j,13,21)+resource1(i,j,14,21)+resource1(i,j,15,21)+resource1(i,j,16,21)+resource1(i,j,17,21)+resource1(i,j,18,21)+resource1(i,j,19,21)+resource1(i,j,20,21));
            core(i,x/400)=core(i,x/400)+(resource1(i,j,1,22)+resource1(i,j,2,22)+resource1(i,j,3,22)+resource1(i,j,4,22)+resource1(i,j,5,22)+resource1(i,j,6,22)+resource1(i,j,7,22)+resource1(i,j,8,22)+resource1(i,j,9,22)+resource1(i,j,10,22)+resource1(i,j,11,22)+resource1(i,j,12,22)+resource1(i,j,13,22)+resource1(i,j,14,22)+resource1(i,j,15,22)+resource1(i,j,16,22)+resource1(i,j,17,22)+resource1(i,j,18,22)+resource1(i,j,19,22)+resource1(i,j,20,22));
            core(i,x/400)=core(i,x/400)+(resource1(i,j,1,23)+resource1(i,j,2,23)+resource1(i,j,3,23)+resource1(i,j,4,23)+resource1(i,j,5,23)+resource1(i,j,6,23)+resource1(i,j,7,23)+resource1(i,j,8,23)+resource1(i,j,9,23)+resource1(i,j,10,23)+resource1(i,j,11,23)+resource1(i,j,12,23)+resource1(i,j,13,23)+resource1(i,j,14,23)+resource1(i,j,15,23)+resource1(i,j,16,23)+resource1(i,j,17,23)+resource1(i,j,18,23)+resource1(i,j,19,23)+resource1(i,j,20,23));
%             core(i,x/400)=core(i,x/400)+(resource1(i,j,1,24)+resource1(i,j,2,24)+resource1(i,j,3,24)+resource1(i,j,4,24)+resource1(i,j,5,24)+resource1(i,j,6,24)+resource1(i,j,7,24)+resource1(i,j,8,24)+resource1(i,j,9,24)+resource1(i,j,10,24)+resource1(i,j,11,24)+resource1(i,j,12,24)+resource1(i,j,13,24)+resource1(i,j,14,24)+resource1(i,j,15,24)+resource1(i,j,16,24)+resource1(i,j,17,24)+resource1(i,j,18,24)+resource1(i,j,19,24)+resource1(i,j,20,24));
%             core(i,x/400)=core(i,x/400)+(resource1(i,j,1,25)+resource1(i,j,2,25)+resource1(i,j,3,25)+resource1(i,j,4,25)+resource1(i,j,5,25)+resource1(i,j,6,25)+resource1(i,j,7,25)+resource1(i,j,8,25)+resource1(i,j,9,25)+resource1(i,j,10,25)+resource1(i,j,11,25)+resource1(i,j,12,25)+resource1(i,j,13,25)+resource1(i,j,14,25)+resource1(i,j,15,25)+resource1(i,j,16,25)+resource1(i,j,17,25)+resource1(i,j,18,25)+resource1(i,j,19,25)+resource1(i,j,20,25));

            %The sum function is used to get how many slots are still
            %empty in each link.   
            
            sum1(1,x/400)=sum1(1,x/400)+resource1(i,j,1,21);
            sum1(2,x/400)=sum1(2,x/400)+resource1(i,j,2,21);
            sum1(3,x/400)=sum1(3,x/400)+resource1(i,j,3,21);
            sum1(4,x/400)=sum1(4,x/400)+resource1(i,j,4,21);
            sum1(5,x/400)=sum1(5,x/400)+resource1(i,j,5,21);
            sum1(6,x/400)=sum1(6,x/400)+resource1(i,j,6,21);
            sum1(7,x/400)=sum1(7,x/400)+resource1(i,j,7,21);
            sum1(8,x/400)=sum1(8,x/400)+resource1(i,j,8,21);
            sum1(9,x/400)=sum1(9,x/400)+resource1(i,j,9,21);
            sum1(10,x/400)=sum1(10,x/400)+resource1(i,j,10,21);
            
            sum1(11,x/400)=sum1(11,x/400)+resource1(i,j,11,21);
            sum1(12,x/400)=sum1(12,x/400)+resource1(i,j,12,21);
            sum1(13,x/400)=sum1(13,x/400)+resource1(i,j,13,21);
            sum1(14,x/400)=sum1(14,x/400)+resource1(i,j,14,21);
            sum1(15,x/400)=sum1(15,x/400)+resource1(i,j,15,21);
            sum1(16,x/400)=sum1(16,x/400)+resource1(i,j,16,21);
            sum1(17,x/400)=sum1(17,x/400)+resource1(i,j,17,21);
            sum1(18,x/400)=sum1(18,x/400)+resource1(i,j,18,21);
            sum1(19,x/400)=sum1(19,x/400)+resource1(i,j,19,21);
            sum1(20,x/400)=sum1(20,x/400)+resource1(i,j,20,21);
            
            sum1(21,x/400)=sum1(21,x/400)+resource1(i,j,1,22);
            sum1(22,x/400)=sum1(22,x/400)+resource1(i,j,2,22);
            sum1(23,x/400)=sum1(23,x/400)+resource1(i,j,3,22);
            sum1(24,x/400)=sum1(24,x/400)+resource1(i,j,4,22);
            sum1(25,x/400)=sum1(25,x/400)+resource1(i,j,5,22);
            sum1(26,x/400)=sum1(26,x/400)+resource1(i,j,6,22);
            sum1(27,x/400)=sum1(27,x/400)+resource1(i,j,7,22);
            sum1(28,x/400)=sum1(28,x/400)+resource1(i,j,8,22);
            sum1(29,x/400)=sum1(29,x/400)+resource1(i,j,9,22);
            sum1(30,x/400)=sum1(30,x/400)+resource1(i,j,10,22);

            sum1(31,x/400)=sum1(31,x/400)+resource1(i,j,11,22);
            sum1(32,x/400)=sum1(32,x/400)+resource1(i,j,12,22);
            sum1(33,x/400)=sum1(33,x/400)+resource1(i,j,13,22);
            sum1(34,x/400)=sum1(34,x/400)+resource1(i,j,14,22);
            sum1(35,x/400)=sum1(35,x/400)+resource1(i,j,15,22);
            sum1(36,x/400)=sum1(36,x/400)+resource1(i,j,16,22);
            sum1(37,x/400)=sum1(37,x/400)+resource1(i,j,17,22);
            sum1(38,x/400)=sum1(38,x/400)+resource1(i,j,18,22);
            sum1(39,x/400)=sum1(39,x/400)+resource1(i,j,19,22);
            sum1(40,x/400)=sum1(40,x/400)+resource1(i,j,20,22);

            sum1(41,x/400)=sum1(41,x/400)+resource1(i,j,1,23);
            sum1(42,x/400)=sum1(42,x/400)+resource1(i,j,2,23);
            sum1(43,x/400)=sum1(43,x/400)+resource1(i,j,3,23);
            sum1(44,x/400)=sum1(44,x/400)+resource1(i,j,4,23);
            sum1(45,x/400)=sum1(45,x/400)+resource1(i,j,5,23);
            sum1(46,x/400)=sum1(46,x/400)+resource1(i,j,6,23);
            sum1(47,x/400)=sum1(47,x/400)+resource1(i,j,7,23);
            sum1(48,x/400)=sum1(48,x/400)+resource1(i,j,8,23);
            sum1(49,x/400)=sum1(49,x/400)+resource1(i,j,9,23);
            sum1(50,x/400)=sum1(50,x/400)+resource1(i,j,10,23);

            sum1(51,x/400)=sum1(51,x/400)+resource1(i,j,11,23);
            sum1(52,x/400)=sum1(52,x/400)+resource1(i,j,12,23);
            sum1(53,x/400)=sum1(53,x/400)+resource1(i,j,13,23);
            sum1(54,x/400)=sum1(54,x/400)+resource1(i,j,14,23);
            sum1(55,x/400)=sum1(55,x/400)+resource1(i,j,15,23);
            sum1(56,x/400)=sum1(56,x/400)+resource1(i,j,16,23);
            sum1(57,x/400)=sum1(57,x/400)+resource1(i,j,17,23);
            sum1(58,x/400)=sum1(58,x/400)+resource1(i,j,18,23);
            sum1(59,x/400)=sum1(59,x/400)+resource1(i,j,19,23);
            sum1(60,x/400)=sum1(60,x/400)+resource1(i,j,20,23);
            


            
                end
                core(i,x/400)=(80000-core(i,x/400))/80000;
            end
            
                                           
            end
      
    end  
        %linkblocksum 4 is four different counting place for x=1k 2k 3k 4k
        % 2 -> request numbers and block numbers in this link
        %9 -> nine different links
      
    
    
        sum1=(2800-sum1)/2800;
    asum=zeros(1,50);
    for t=1:50
        for i=1:60
            asum(t)=asum(t)+sum1(i,t);
        end
    end
    asum=asum/60;
    
    a=0;%Total block number
    a1=0;%Total block number(Kpaths)
    b=0;%Block number due to XT
    c=0;%Block number due to resource
    
    XTsum=0;
   for i=400:400:20000
        for j=(i-399):i
            a=a+count(j);
            
            a1=a1+sum(Bcauses(j,:)~=0);
            b=b+sum(Bcauses(j,:)==1);
            
        end
            
   
    
         c=a1-b;
         probabilitya(i/400)=a/i;
%          probabilityb(i/100)=b/i;
%          probabilityc(i/100)=c/i;
        
        if (xtavg(i/400))==-inf
            xtavg(i/400)=-90;
        end
        
    end
    
     d=b/a1; %percentage of block due to XT
     e=c/a1; %percentage of block due to resource
    
       for k=2500:2500:20000
            
            
        XTcondition(1,k/2500)=sum(EXTblockcount(1:k))/(sum(XTblockcount(1:k))+sum(EXTblockcount(1:k)));
        XTcondition(2,k/2500)=1-XTcondition(1,k/2500);
          
      
      end
     
     
    x=400:400:20000;
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
        semilogy(asum,probabilitya,'ps-');
    end
   
    
    
    hold on;
    legend('2di priority core switch spectrum soft split 3 paths ','2di priority core switch slot split spectrum soft split 3 paths ','2di priority core switch spectrum hard split 3 paths (0.001)','2di priority core switch spectrum hard split 3 paths (0.01)','2di priority core switch spectrum hard split 3 paths (0.1)',5);
    axis([0,1,0,1]);
    title('Blocking Probability for Random Source and Destination');
    xlabel('Network Utilization');
    ylabel('Blocking Probability');
    grid on;
    
    

end
