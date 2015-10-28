function index=check7(resource,i,j,a,b)
total=0; %#ok<NASGU>
index=0;
if i==1
    total=resource(2,j,a,b)+resource(3,j,a,b)+resource(4,j,a,b)+resource(5,j,a,b)+resource(6,j,a,b)+resource(7,j,a,b);
    if total<6
        index=1;
    end
end
if i==2
    total=resource(1,j,a,b)+resource(3,j,a,b)+resource(7,j,a,b);
    if total<3
        index=1;
    end
end
if i==3
    total=resource(1,j,a,b)+resource(2,j,a,b)+resource(4,j,a,b);
    if total<3
        index=1;
    end
end
if i==4
    total=resource(1,j,a,b)+resource(3,j,a,b)+resource(5,j,a,b);
    if total<3
        index=1;
    end
end
if i==5
    total=resource(1,j,a,b)+resource(4,j,a,b)+resource(6,j,a,b);
    if total<3
        index=1;
    end
end
if i==6
    total=resource(1,j,a,b)+resource(5,j,a,b)+resource(7,j,a,b);
    if total<3
        index=1;
    end
end
if i==7
    total=resource(1,j,a,b)+resource(2,j,a,b)+resource(6,j,a,b);
    if total<3
        index=1;
    end
end
