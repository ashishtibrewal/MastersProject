
%CHONG NEW!!!!!!!!!

function [n1,n2]=count7_2(resource,row,column,BW,a,b)
x=zeros(1,6);
n1=0;
n2=0;
if row==1
    for i=column:column+BW-1
        x(1)=x(1)+resource(2,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(4,i,a,b);
        x(4)=x(4)+resource(5,i,a,b);
        x(5)=x(5)+resource(6,i,a,b);
        x(6)=x(6)+resource(7,i,a,b);
    end
    for j=1:6
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==2
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(7,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==3
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(2,i,a,b);
        x(3)=x(3)+resource(4,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==4
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(5,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==5
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(4,i,a,b);
        x(3)=x(3)+resource(6,i,a,b);
       
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==6
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(5,i,a,b);
        x(3)=x(3)+resource(7,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==7
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(2,i,a,b);
        x(3)=x(3)+resource(6,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==8
    for i=column:column+BW-1
        x(1)=x(1)+resource(9,i,a,b);
        x(2)=x(2)+resource(10,i,a,b);
        x(3)=x(3)+resource(11,i,a,b);
        x(4)=x(4)+resource(12,i,a,b);
        x(5)=x(5)+resource(13,i,a,b);
        x(6)=x(6)+resource(14,i,a,b);
    end
    for j=1:6
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==9
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(10,i,a,b);
        x(3)=x(3)+resource(14,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==10
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(9,i,a,b);
        x(3)=x(3)+resource(11,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==11
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(10,i,a,b);
        x(3)=x(3)+resource(12,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==12
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(11,i,a,b);
        x(3)=x(3)+resource(13,i,a,b);
       
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==13
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(12,i,a,b);
        x(3)=x(3)+resource(14,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
if row==14
    for i=column:column+BW-1
        x(1)=x(1)+resource(8,i,a,b);
        x(2)=x(2)+resource(9,i,a,b);
        x(3)=x(3)+resource(13,i,a,b);
        
    end
    for j=1:3
        if x(j)<0
            n2=n2+1;
        end
        if x(j)>=0 && x(j)<BW 
            n1=n1+1;
        end
    end
end
