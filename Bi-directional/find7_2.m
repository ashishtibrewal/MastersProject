function   ReqNum=find7(row,column,a,b,NumSlots)
x=zeros(1,6);
ReqNum=zeros(1,6);
if row==1
   x(1)=NumSlots(2,column,a,b);
   x(2)=NumSlots(3,column,a,b);
   x(3)=NumSlots(4,column,a,b);
   x(4)=NumSlots(5,column,a,b);
   x(5)=NumSlots(6,column,a,b);
   x(6)=NumSlots(7,column,a,b);

    for j=1:6
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==2
        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(3,column,a,b);
        x(3)=x(3)+NumSlots(7,column,a,b);
        
    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==3

        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(2,column,a,b);
        x(3)=x(3)+NumSlots(4,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==4
        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(3,column,a,b);
        x(3)=x(3)+NumSlots(5,column,a,b);

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==5

        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(4,column,a,b);
        x(3)=x(3)+NumSlots(6,column,a,b);
       

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==6

        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(5,column,a,b);
        x(3)=x(3)+NumSlots(7,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==7

        x(1)=x(1)+NumSlots(1,column,a,b);
        x(2)=x(2)+NumSlots(2,column,a,b);
        x(3)=x(3)+NumSlots(6,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==8
   x(1)=NumSlots(9,column,a,b);
   x(2)=NumSlots(10,column,a,b);
   x(3)=NumSlots(11,column,a,b);
   x(4)=NumSlots(12,column,a,b);
   x(5)=NumSlots(13,column,a,b);
   x(6)=NumSlots(14,column,a,b);

    for j=1:6
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==9
        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(10,column,a,b);
        x(3)=x(3)+NumSlots(14,column,a,b);
        
    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==10

        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(9,column,a,b);
        x(3)=x(3)+NumSlots(11,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==11
        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(10,column,a,b);
        x(3)=x(3)+NumSlots(12,column,a,b);

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==12

        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(11,column,a,b);
        x(3)=x(3)+NumSlots(13,column,a,b);
       

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==13

        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(12,column,a,b);
        x(3)=x(3)+NumSlots(14,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end
if row==14

        x(1)=x(1)+NumSlots(8,column,a,b);
        x(2)=x(2)+NumSlots(9,column,a,b);
        x(3)=x(3)+NumSlots(13,column,a,b);
        

    for j=1:3
        if x(j)~=0;
            ReqNum(j)=x(j);
        end
    end
end