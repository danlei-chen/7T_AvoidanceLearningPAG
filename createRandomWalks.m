clear;clc
n=(24*4); %number of steps
clf;
hold on;
c = ['r','g','b','c','m','y','k'];

for l=1:2

x = randn(n,1); % normal
%jumps are +-1
% x = (rand(n,1) - 0.5*ones(n,1));
indP = find(x>0);
indM = find(x<=0);
sc=abs(10*rand(size(x)));

x(indP) = sc(indP);
x(indM) = -1*sc(indM);
z = 50+(randi(10)-5)*ones(n,1);
for i=2:n
    if (z(i-1)+ x(i))>80 | (z(i-1)+ x(i))<20
    else
        z(i) = z(i-1)+ x(i);
        
    end
end
plot(z,'Color', c(mod(l,7)+1),'LineWidth',2);
set(gca,'YLim',[0 100])
X(:,l)=z;
end
