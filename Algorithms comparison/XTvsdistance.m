h=3e-6;
n1=3;
n2=3; total_n = n1+n2;

L=[0.001 0.01 0.025 0.05 0.1 0.2 0.5 1];
 
for i =1:length(L)            
XT(i)=(n1+0.5*n2-n1*exp(-(total_n+1)*h*L(i)*1000)- n2*exp(-(total_n+1)*h*L(i)*1000)*0.5)/(1+n1*exp(-(total_n+1)*h*L(i)*1000)+n2*exp(-(total_n+1)*h*L(i)*1000));
XT2(i)=10*log10(XT(i));

end


plot(L,XT2,'+r-');
grid on;
              