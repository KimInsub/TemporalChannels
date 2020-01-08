
%%
figure()
for endpoint = 1:3
    subplot(1,3,endpoint)
    a1=[0:0.01:endpoint];
    plot(sin(2*pi*a1)); hold on
    plot(a1);
    xlim([0 500])
    ylim([-1 5])
    size(a1)
end
%%

figure()
pp=[0.001 0.01 0.1];
for midpoint = 1:3
    subplot(1,3,midpoint)
    a1=[0:pp(midpoint):1];
    plot(sin(2*pi*a1)); hold on
    plot(a1);
    % xlim([0 500])
    % ylim([-1 5])
    size(a1)
end


%%
figure()
for ls = 1:5
    
    subplot(1,5,ls)
   
    tp=linspace(1,ls);
    plot(sin(2*pi*tp)); hold on
    plot(tp);
    ylim([-1 5])
end
%%
figure()
for ls = 1:5
    
    subplot(1,5,ls)
    tp=linspace(1,2);
    freq=1*ls;
    plot(sin(2*pi*tp*freq)); hold on
    plot(tp); 
    ylim([-1 5])
end

%%
Fs = 1000;            % Sampling frequency
Ts = 1/Fs;             % Sampling period or time step
dt = 0:Ts:3-Ts;       % signal duration 1 sec in this case
f1=10;% 10 hz
f2=30;
f3=70;

% y=A*sin(2*pi*ft+theta)

y1=10*sin(2*pi*f1*dt)
y2=10*sin(2*pi*f2*dt)
y3=10*sin(2*pi*f3*dt)
y4=y1+y2+y3;

figure()

subplot(4,1,1);
plot(y1); hold on;
subplot(4,1,2);
plot(y2); hold on;
subplot(4,1,3);
plot(y3); hold on;
subplot(4,1,4);
plot(y4); hold on;

%%
figure()
nfft=length(y4); % length of time domain signal
nfft2=2^nextpow2(nfft); %lengh of sinal in power of 2
ff=fft(y4,nfft2);
fff=ff(1:nfft2/2);
xfft=Fs*(0:nfft2/2-1)/nfft2;
plot(xfft,abs(fff))
%%
figure()
plot(abs(fff))

%%
figure()
subplot(2,1,1);
plot(dt,y4);
subplot(2,1,2);
plot(xfft,abs(fff));

%%

y4=model.irfs.hrf{1};

hrfs{1}=model.irfs.hrf{1};
hrfs{2}=model.irfs.nrfT{1};
hrfs{3}=model.irfs.nrfS{1};

for i =1: 3
  y4=hrfs{i}
Fs=length(y4);
nfft=length(y4); % length of time domain signal
nfft2=2^nextpow2(nfft); %lengh of sinal in power of 2
ff =fft(y4,nfft2);
fff=ff(1:nfft2/2);
xfft=Fs*(0:nfft2/2-1)/nfft2;

plot(xfft,abs(fff));
hold on;

% findpeaks(abs(fff));
xlim([0 20])
end