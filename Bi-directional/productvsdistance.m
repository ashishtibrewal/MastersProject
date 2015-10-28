x1=[2 10 20 446 500 600 1400 2000];
pro1=[0.003		0.015	0.024	0.670	0.598		0.718		1.053		1.505];
x2=[2 10 20 500 588 600 1400 2000];
pro2=[0.003		0.015	0.030		0.755	0.888	0.789		1.842		2.631];
x3=[2 10 20 500 588 600 1400 2000];
pro3=[0.004		0.021	0.041		1.032	1.213	0.845		1.972		2.817];
x4=[2 10 20 500 588 600 1400 2000];
pro4=[0.005		0.024	0.048		1.201	1.412	1.074		2.505		3.579];
x5=[2 3.6 10 20 500 600 1400 2000];
pro5=[0.006	0.010	0.024	0.036		0.910		1.092		2.549		3.641];
x6=[2 10 20 500 600 1400 1760 2000];
pro6=[0.002		0.010	0.020		0.501		0.601		1.403	1.764	1.585];
x7=[2 10 20 500 600 1326 1400 2000];
pro7=[0.003		0.015	0.030		0.760		0.912	1.694	1.788		2.109];


figure(1)

hold on;
plot (x1,pro1,'or-');
plot (x2,pro2,'xb-');
plot (x3,pro3,'*g-');
plot (x4,pro4,'kd-');
plot (x5,pro5,'sm-');
plot (x6,pro6,'cv-');
plot (x7,pro7,'y+-');
xlabel('Path distance (meter) (2*link distance)');
ylabel('Spatial Efficiency distance product(Gb/s/um^2*Km)');
title('Spatial Efficiency distance product vs distance ');
legend('7-core hex MCF in uni-directional benchmark(446m path distance)','7-core hexagonal MCF(588m path distance)','19-core hexagonal MCF(588m path distance)','37-core hexagonal MCF(588m path distance)','61-core hexagonal MCF(3.6m path distance)','8-core rectangular MCF (1760 path distance)','12-core rectangular MCF (1326m path distance)');