function [resource,blocking,XTtotal,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,k_index,Bcauses]=ff1XTnewcoreswitchKpaths2di_ss_(BW,kshortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XTtotal)

k_index=0;

XTblock=0;
EXTblock=0;

Bcauses=zeros(1,3);
slot_index1=0;
slot_index2=100;
coreseq1=[4 2 8 6 ];
coreseq2=[1 3 5 7 ];

for y=1:length(kshortestpaths)
k_index=k_index+1;
blocking=0; 
n=length(kshortestpaths{y});
a=zeros(1,n-1);
b=zeros(1,n-1);
%-------------------------------NEW h-----------------------------------
k=6e-2;
R=50e-3;
p=4e6;
cp=30e-6;

h= (2*k^2 *R)/(p * cp);







out=0;
rowcs=zeros(1,n-1);
columncs=zeros(1,n-1);


for i=1:(n-1)
 a(i)=kshortestpaths{y}(i);
    b(i)=kshortestpaths{y}(i+1);
    if a(i)>b(i)
        k=a(i);
        a(i)=b(i);
        b(i)=k;
    end
end


for i=1:(n-1)
    linkblock(1,a(i),b(i))=linkblock(1,a(i),b(i))+1;
end


%Find the minimum xt connection not matter it satisfies xt threshold
for ln=1:n-1 %linknumber
    
    si1=slot_index1;
    si2=slot_index2;
    
   % coreseq=[7 3 5 10 12 14]; for both 1 and 2 start
   coreseq=coreseq1;
  
    XTtemp=inf;
    
    a(ln)=kshortestpaths{y}(ln);
    b(ln)=kshortestpaths{y}(ln+1);
    if a(ln)>b(ln)
       k=a(ln);
        a(ln)=b(ln);
        b(ln)=k;
      %  coreseq=[4 6 2 13 9 11]; for 1 start
      %  coreseq=[13 9 11 4 6 2]; for 2 start
      coreseq=coreseq2;
        si1=slot_index2;
        si2=slot_index1;
        
    end
    
    
    for v=1:2   %spectrum splits (2 division 1 for each direction)
        
        if v==2   %(change to another division when not enough resource in this division )
            r=si1;
            si1=si2;
            si2=r;
        end
          
    for time=1:length(coreseq)
        corenum=coreseq(time);
         up=0;
            down=0;
        for i=1+(corenum-1)*200+si1:corenum*200+1-BW-si2
            
            sum=0;
            XT=0;
            out=0;
            upblocking=0;
            %upblocking value notes down how many
            %previous requests are blocked due to
            %new request.
            ReqNum=zeros(1,6);
            ReqNums=0;
            XTperLink=zeros(1,n-1);
            
            for k=i:i+BW-1
                column=mod(k,200);
                if column==0
                    column=200;
                end
                row=ceil(k/200);
                
                sum=sum+resource(row,column,a(ln),b(ln));
                
            end
            
            if sum==BW
                
                col=mod(i,200);
               % num=count7(resource,row,col,BW,a(ln),b(ln));
              %  XTperLink(ln)=(num-num*exp(-(num+1)*h*link(a(ln),b(ln))*1000))/(1+num*exp(-(num+1)*h*link(a(ln),b(ln))*1000));
              
              [n1,n2]=count7(resource,row,col,BW,a(ln),b(ln));  
                total_n = n1+n2;
              if total_n~=0
                 [n3,n4]=count7_(resource,row,col,BW,a(ln),b(ln)); %same direc n3--cp  n4--cp1
                 
                 up=up+ n3*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000));
                 down=down+ n3*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                 
                 if n4~=0
                     cp= sqrt(2)*cp;
                     k=4e-4;
                     h= (2*k^2 *R)/(p * cp);
                     up=up+ n4*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000));
                     down=down+ n4*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                     
                     cp=30e-6;
                     k=6e-2;

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 [n3,n4]=count7__(resource,row,col,BW,a(ln),b(ln)); %opp direc
                    up=up+ n3*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000))*0.5;
                    down=down+ n3*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                 if n4~=0
                     cp= sqrt(2)*cp;
                     k=4e-4;
                     h= (2*k^2 *R)/(p * cp);
                     up=up+ n4*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000))*0.5;
                     down=down+ n4*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                     
                     cp=30e-6;
                     k=6e-2;

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 %cp= sqrt(2)*cp;
                 %h1= (2*k^2 *R)/(p * cp);
                
                 
                 XTperLink(ln)=up/(1+down);
              end  
                if XTperLink(ln)==0
                    XTtemp=0;
                    rowcs(ln)=row;
                    columncs(ln)=col;
                    out=1;
                    break
                else
                    if XTperLink(ln)<XTtemp
                        XTtemp=XTperLink(ln);
                        rowcs(ln)=row;
                        columncs(ln)=col;
                    end
                end
            end
            
        end
        if out==1
            break
        end
        
    end
   
    if out==1    %enough resource ---> out loop
       break
    end
    
    end
    
    XTperLink(ln)=XTtemp;
    XT=XT+XTperLink(ln);
end

%Find the minimum XT slots
XT2=10*log10(XT);



if (any(XTperLink==inf)==1)||(any(rowcs==0)==1)||(any(columncs==0)==1)
    blocking=1;%Blocking by resource congestion.
    Bcauses(k_index)=2;
         
    
else
    if XT2>-24
       
        XTblock=1;
         Bcauses(k_index)=1;
        blocking=1;%Blocking by XT.
        
    end
    
    if XT2<=-24
        for ln=1:n-1
            
            for j=1:BW
               if kshortestpaths{y}(ln)<kshortestpaths{y}(ln+1)
                resource(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=0;
                end
                if kshortestpaths{y}(ln)>kshortestpaths{y}(ln+1)
                resource(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=-1;
                end
                LXPR(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=XTperLink(ln);
                NumSlots(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=x;
                
                if XTperLink(ln)~=0
                    
                    ReqNum=find7(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln),NumSlots);
                end
            
            % ReqNum is the request number affected by this XT
            % ReqNums is the array to store all affected requests
            for l=1:6
                if isempty(find(ReqNums==ReqNum(l), 1))==1
                    ReqNums=[ReqNums ReqNum(l)];
                end
            end
            end
        end
        
        
        if length(ReqNums)~=1
            
            for k=2:length(ReqNums)%ReqNums(1)=0;
                [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory(ReqNums(k),:),link,ReqNums(k),NumSlots);
                % up_blocking=up_blocking+upblocking;
                if upblocking~=0
                    break
                end
            end
            
            if upblocking~=0
                EXTblock=EXTblock+1;
                Bcauses(k_index)=1;
                %Then we need to convert resource of new request back to 1
                %and add one block number
                [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitch(kshortestpaths{y},resource,x,LXPR,NumSlots,linkblock);
                XTtotal(x)=0;
                blocking=1;
                x
            else
                
                for k=2:length(ReqNums) %ReqNums(1)=0;
                    
                    [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(ReqNums(k),:),link,ReqNums(k),LXPR,NumSlots);
                    XTtotal(ReqNums(k))=upXT1;
                end
            end
        end
    end
end

if blocking~=1
        XTtotal(x)=XT;
        XTblock=0;
        EXTblock=0;
        Bcauses(k_index)=0;
        break
        
else
    XTtotal(x)=0;
    
    for m=1:(n-1)
        linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
    end
end


end




