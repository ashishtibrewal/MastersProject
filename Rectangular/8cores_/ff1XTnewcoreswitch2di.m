
%CHONG NEW!!!!!!!!!

function [resource,blocking,XTtotal,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock]=ff1XTnewcoreswitch2di(BW,path,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XTtotal)
XTblock=0;
EXTblock=0;
blocking=0;
n=length(path);
a=zeros(1,n-1);
b=zeros(1,n-1);
coreseq1=[4 2 8 6 12 10 16 14];
coreseq2=[1 3 5 7 9 11 13 15];
%h=5e-5;

%-------------------------------NEW h-----------------------------------
k=6e-2;
R=50e-3;
p=4e6;
cp=30e-6;

h= (2*k^2 *R)/(p * cp);


rowcs=zeros(1,n-1);
columncs=zeros(1,n-1);

%--------------------Update the requrest number--------------------------

for i=1:(n-1)
    m(i)=path(i);
    t(i)=path(i+1);
    if m(i)>t(i)
        k=m(i);
        m(i)=t(i);
        t(i)=k;
    end
end

for i=1:(n-1)
    linkblock(1,m(i),t(i))=linkblock(1,m(i),t(i))+1;
end
%------------------------------------------------------------------------



%Find the minimum xt connection not matter it satisfies xt threshold
for ln=1:n-1 %linknumber
%---------------------------------------CHANGE-----------------------------------------------------------------------------      
     
    coreseq=coreseq1;
    XTtemp=inf;
    
    a(ln)=path(ln);
    b(ln)=path(ln+1);
    if a(ln)>b(ln)
       k=a(ln);
        a(ln)=b(ln);
        b(ln)=k;
       coreseq=coreseq2;
    end
    
   
    
    
    
    
    for time=1:length(coreseq)
            up=0;
            down=0;
            
       corenum=coreseq(time);
        for i=1+(corenum-1)*200:corenum*200+1-BW
            
            sum=0;
            XT=0;
            out=0;
            upblocking=0;
            %upblocking value notes down how many
            %previous requests are blocked due to
            %new request.
            ReqNum=zeros(1,7);
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
%---------------------------------------CHANGE-----------------------------------------------------------------------------                
                
               % num=count7(resource,row,col,BW,a(ln),b(ln));
                 % XTperLink(ln)=(num-num*exp(-(num+1)*h*link(a(ln),b(ln))*1000))/(1+num*exp(-(num+1)*h*link(a(ln),b(ln))*1000));
                 
                 
                 
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

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 [n5,n6]=count7__(resource,row,col,BW,a(ln),b(ln)); %opp direc
                    up=up+ n5*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000))*0.5;
                    down=down+ n5*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                    
                 if n6~=0
                     cp= sqrt(2)*cp;
                      k=4e-4;
                     h= (2*k^2 *R)/(p * cp);
                     up=up+ n6*(1-exp(-(total_n+1)*h*link(a(ln),b(ln))*1000))*0.5;
                     down=down+ n6*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000);
                     
                     cp=30e-6;

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 %cp= sqrt(2)*cp;
                 %h1= (2*k^2 *R)/(p * cp);
                
                 
                 XTperLink(ln)=up/(1+down);
              end 
                %XTperLink(ln)=(n1+0.5*n2-n1*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000)- n2*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000)*0.5)/(1+n1*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000)+n2*exp(-(total_n+1)*h*link(a(ln),b(ln))*1000));
                
                
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
    
    XTperLink(ln)=XTtemp;
    XT=XT+XTperLink(ln);
end

%Find the minimum XT slots
XT2=10*log10(XT);
%XT2
if (any(XTperLink==inf)==1)||(any(rowcs==0)==1)||(any(columncs==0)==1)
    blocking=1;%Blocking by resource congestion.

else
    if XT2>-24
    
        XTblock=1;
        blocking=1;%Blocking by resource congestion.
     
    end
    
    if XT2<=-24
        
        for ln=1:n-1
 %---------------------------------------CHANGE-----------------------------------------------------------------------------             
            for j=1:BW
                if path(ln)<path(ln+1)
                resource(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=0;
                end
                if path(ln)>path(ln+1)
                resource(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=-1;
                end
                LXPR(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=XTperLink(ln);
                NumSlots(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=x;
                
                if XTperLink(ln)~=0
                    
                    ReqNum=find7(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln),NumSlots);
                end
            
            % ReqNum is the request number affected by this XT
            % ReqNums is the array to store all affected requests
            for l=1:7
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
                EXTblock=1;
                XTblock=0;
                %Then we need to convert resource of new request back to 1
                %and add one block number
                [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitch(path,resource,x,LXPR,NumSlots,linkblock);
                XTtotal(x)=0;
                blocking=1;
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
        
else
    XTtotal(x)=0;
    
    for m=1:(n-1)
        linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
    end
end







