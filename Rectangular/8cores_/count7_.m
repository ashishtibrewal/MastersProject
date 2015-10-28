
%CHONG NEW!!!!!!!!!

function [n3,n4]=count7_(resource,row,column,BW,a,b)
x=zeros(1,6);
n3=0;
n4=0;
if row==1
    for i=column:column+BW-1
        x(1)=x(1)+resource(2,i,a,b);
        x(2)=x(2)+resource(8,i,a,b);
        x(3)=x(3)+resource(7,i,a,b);
       % x(4)=x(4)+resource(5,i,a,b);
       % x(5)=x(5)+resource(6,i,a,b);
       % x(6)=x(6)+resource(7,i,a,b);
    end
   
        if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
    
end
if row==2
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(7,i,a,b);
        x(4)=x(4)+resource(8,i,a,b);
        x(5)=x(5)+resource(6,i,a,b);
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(5)>=0 && x(5)<BW 
            n4=n4+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
end
if row==3
    for i=column:column+BW-1
        x(1)=x(1)+resource(2,i,a,b);
        x(2)=x(2)+resource(4,i,a,b);
        x(3)=x(3)+resource(6,i,a,b);
        x(4)=x(4)+resource(7,i,a,b);
        x(5)=x(5)+resource(5,i,a,b);
        
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
        if x(5)>=0 && x(5)<BW 
            n4=n4+1;
        end
end
if row==4
    for i=column:column+BW-1
        x(1)=x(1)+resource(5,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(6,i,a,b);
        
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
end
if row==5
    for i=column:column+BW-1
        x(1)=x(1)+resource(3,i,a,b);
        x(2)=x(2)+resource(4,i,a,b);
        x(3)=x(3)+resource(6,i,a,b);
       
    end
    if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
end
if row==6
    for i=column:column+BW-1
        x(1)=x(1)+resource(2,i,a,b);
        x(2)=x(2)+resource(3,i,a,b);
        x(3)=x(3)+resource(4,i,a,b);
        x(4)=x(4)+resource(5,i,a,b);
        x(5)=x(5)+resource(7,i,a,b);
    end
    if x(4)>=0 && x(4)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
         if x(5)>=0 && x(5)<BW 
            n3=n3+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
end
if row==7
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(2,i,a,b);
        x(3)=x(3)+resource(3,i,a,b);
        x(4)=x(4)+resource(6,i,a,b);
        x(5)=x(5)+resource(8,i,a,b);
        
    end
    if x(4)>=0 && x(4)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
        if x(5)>=0 && x(5)<BW 
            n3=n3+1;
        end
        if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
end
if row==8
    for i=column:column+BW-1
        x(1)=x(1)+resource(1,i,a,b);
        x(2)=x(2)+resource(2,i,a,b);
        x(3)=x(3)+resource(7,i,a,b);
        
    end
   if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n4=n4+1;
        end
end
if row==9
    for i=column:column+BW-1
        x(1)=x(1)+resource(10,i,a,b);
        x(2)=x(2)+resource(16,i,a,b);
        x(3)=x(3)+resource(15,i,a,b);
       % x(4)=x(4)+resource(5,i,a,b);
       % x(5)=x(5)+resource(6,i,a,b);
       % x(6)=x(6)+resource(7,i,a,b);
    end
   
        if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
    
end
if row==10
    for i=column:column+BW-1
        x(1)=x(1)+resource(9,i,a,b);
        x(2)=x(2)+resource(11,i,a,b);
        x(3)=x(3)+resource(15,i,a,b);
        x(4)=x(4)+resource(16,i,a,b);
        x(5)=x(5)+resource(14,i,a,b);
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(5)>=0 && x(5)<BW 
            n4=n4+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
end
if row==11
    for i=column:column+BW-1
        x(1)=x(1)+resource(10,i,a,b);
        x(2)=x(2)+resource(12,i,a,b);
        x(3)=x(3)+resource(14,i,a,b);
        x(4)=x(4)+resource(15,i,a,b);
        x(5)=x(5)+resource(13,i,a,b);
        
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
        if x(5)>=0 && x(5)<BW 
            n4=n4+1;
        end
end
if row==12
    for i=column:column+BW-1
        x(1)=x(1)+resource(13,i,a,b);
        x(2)=x(2)+resource(11,i,a,b);
        x(3)=x(3)+resource(14,i,a,b);
        
    end
    if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
end
if row==13
    for i=column:column+BW-1
        x(1)=x(1)+resource(11,i,a,b);
        x(2)=x(2)+resource(12,i,a,b);
        x(3)=x(3)+resource(14,i,a,b);
       
    end
    if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
end
if row==14
    for i=column:column+BW-1
        x(1)=x(1)+resource(10,i,a,b);
        x(2)=x(2)+resource(11,i,a,b);
        x(3)=x(3)+resource(12,i,a,b);
        x(4)=x(4)+resource(13,i,a,b);
        x(5)=x(5)+resource(15,i,a,b);
    end
    if x(4)>=0 && x(4)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
         if x(5)>=0 && x(5)<BW 
            n3=n3+1;
        end
        if x(4)>=0 && x(4)<BW 
            n4=n4+1;
        end
end
if row==15
    for i=column:column+BW-1
        x(1)=x(1)+resource(9,i,a,b);
        x(2)=x(2)+resource(10,i,a,b);
        x(3)=x(3)+resource(11,i,a,b);
        x(4)=x(4)+resource(14,i,a,b);
        x(5)=x(5)+resource(16,i,a,b);
        
    end
    if x(4)>=0 && x(4)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n4=n4+1;
        end
        if x(5)>=0 && x(5)<BW 
            n3=n3+1;
        end
        if x(1)>=0 && x(1)<BW 
            n4=n4+1;
        end
end
if row==16
    for i=column:column+BW-1
        x(1)=x(1)+resource(9,i,a,b);
        x(2)=x(2)+resource(10,i,a,b);
        x(3)=x(3)+resource(15,i,a,b);
        
    end
   if x(1)>=0 && x(1)<BW 
            n3=n3+1;
        end
        if x(3)>=0 && x(3)<BW 
            n3=n3+1;
        end
        if x(2)>=0 && x(2)<BW 
            n4=n4+1;
        end
end