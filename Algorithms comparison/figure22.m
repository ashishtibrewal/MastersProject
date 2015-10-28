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
 time =zeros(1,50);

for y=1:4
     % y=1  'benchmark'
    % y=2  '2di priority core switch spectrum soft split 3 paths '
    % y=3  '2di priority core switch slot split spectrum soft split 3 paths'
    % y=4  '2di priority core switch spectrum hard split 3 paths (0.1)'
    
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
   
    time1 =zeros(1,50);
    ratio =zeros(1,50);
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
        tic;
       x
        if y==2
            k_paths=3;
               
            
             [shortestpaths,kdistances]=kShortestPath(link,sta(x),dst(x),k_paths);
             
            % [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:),T1,T2]=ff1XTnewcoreswitchKpaths2di_ss(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT,slot_index3,slot_index4,coreseq1,coreseq2);
            
             [resource,blocking,XT,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses(x,:)]=ff1XTnewcoreswitchKpaths(BW(x),shortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XT);
             
             
            
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
         
         
         if y==3
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
              
           if y==1
              if x/400==1
                  time(x/400)=toc/400;
              else 
                time(x/400)=((time((x/400)-1)*400)+toc)/x;
              end
           else
               if x/400==1
                  time1(x/400)=(toc/400);
                  ratio(x/400)=time1(x/400)/time(x/400);
              else 
                time1(x/400)=(time1((x/400)-1)*400+toc)/x;
                ratio(x/400)=time1(x/400)/time(x/400);
               end
              
           end
%                 for k=1:x
%                     
%                     XTsum=XTsum+XT(k);
%                 end
%                 xtavg(x/100)=10*log10(XTsum/(x-sum(count)));
%                 
%                 xtmax(x/100)=10*log10(max(XT));
%                 
%                 count1=count(1:x);
%                 XTmin1=XT(1:x);
%                 % First x elememts of count and XT
%                 %Then they are used to calculate min successful XT 
%                 xtmin(x/100)=10*log10(min(XTmin1(count1==0)));
%                 if xtmin(x/100)==-inf
%                     xtmin(x/100)=-40;
%                 end   
                
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
            
%             sum1(61,x/400)=sum1(61,x/400)+resource1(i,j,1,24);
%             sum1(62,x/400)=sum1(62,x/400)+resource1(i,j,2,24);
%             sum1(63,x/400)=sum1(63,x/400)+resource1(i,j,3,24);
%             sum1(64,x/400)=sum1(64,x/400)+resource1(i,j,4,24);
%             sum1(65,x/400)=sum1(65,x/400)+resource1(i,j,5,24);
%             sum1(66,x/400)=sum1(66,x/400)+resource1(i,j,6,24);
%             sum1(67,x/400)=sum1(67,x/400)+resource1(i,j,7,24);
%             sum1(68,x/400)=sum1(68,x/400)+resource1(i,j,8,24);
%             sum1(69,x/400)=sum1(69,x/400)+resource1(i,j,9,24);
%             sum1(70,x/400)=sum1(70,x/400)+resource1(i,j,10,24);
%             
%             sum1(71,x/400)=sum1(71,x/400)+resource1(i,j,11,24);
%             sum1(72,x/400)=sum1(72,x/400)+resource1(i,j,12,24);
%             sum1(73,x/400)=sum1(73,x/400)+resource1(i,j,13,24);
%             sum1(74,x/400)=sum1(74,x/400)+resource1(i,j,14,24);
%             sum1(75,x/400)=sum1(75,x/400)+resource1(i,j,15,24);
%             sum1(76,x/400)=sum1(76,x/400)+resource1(i,j,16,24);
%             sum1(77,x/400)=sum1(77,x/400)+resource1(i,j,17,24);
%             sum1(78,x/400)=sum1(78,x/400)+resource1(i,j,18,24);
%             sum1(79,x/400)=sum1(79,x/400)+resource1(i,j,19,24);
%             sum1(80,x/400)=sum1(80,x/400)+resource1(i,j,20,24);
%             
%             sum1(81,x/400)=sum1(81,x/400)+resource1(i,j,1,25);
%             sum1(82,x/400)=sum1(82,x/400)+resource1(i,j,2,25);
%             sum1(83,x/400)=sum1(83,x/400)+resource1(i,j,3,25);
%             sum1(84,x/400)=sum1(84,x/400)+resource1(i,j,4,25);
%             sum1(85,x/400)=sum1(85,x/400)+resource1(i,j,5,25);
%             sum1(86,x/400)=sum1(86,x/400)+resource1(i,j,6,25);
%             sum1(87,x/400)=sum1(87,x/400)+resource1(i,j,7,25);
%             sum1(88,x/400)=sum1(88,x/400)+resource1(i,j,8,25);
%             sum1(89,x/400)=sum1(89,x/400)+resource1(i,j,9,25);
%             sum1(90,x/400)=sum1(90,x/400)+resource1(i,j,10,25);
%             
%             sum1(91,x/400)=sum1(91,x/400)+resource1(i,j,11,25);
%             sum1(92,x/400)=sum1(92,x/400)+resource1(i,j,12,25);
%             sum1(93,x/400)=sum1(93,x/400)+resource1(i,j,13,25);
%             sum1(94,x/400)=sum1(94,x/400)+resource1(i,j,14,25);
%             sum1(95,x/400)=sum1(95,x/400)+resource1(i,j,15,25);
%             sum1(96,x/400)=sum1(96,x/400)+resource1(i,j,16,25);
%             sum1(97,x/400)=sum1(97,x/400)+resource1(i,j,17,25);
%             sum1(98,x/400)=sum1(98,x/400)+resource1(i,j,18,25);
%             sum1(99,x/400)=sum1(99,x/400)+resource1(i,j,19,25);
%             sum1(100,x/400)=sum1(100,x/400)+resource1(i,j,20,25);


            
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
     
     
     
  

    
    
    
        figure(5)
    
    
    if y==5
        plot(asum,time,'xb-');
    end
    if y==2
        plot(asum,ratio,'+r-');
    end

    if y==3
        plot(asum,ratio,'vm-');
    end
    if y==4
        plot(asum,ratio,'kd-');
    end
    if y==5
        plot(x,asum,'ys-');
    end
    
    
    hold on;
    
    legend('2di priority core switch spectrum soft split 3 paths ','2di priority core switch slot split spectrum split 3 paths ','2di priority core switch spectrum hard split 3 paths (0.1)',3);
   
    title('Computational time ratio for each algorithms');
    xlabel('Network Utilization');
    ylabel('Computational time ratio to benchmark for each request');
    axis([0,0.9,0,10]);
    grid on;
    

    

end
