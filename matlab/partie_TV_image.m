clear variables
close all
clc

%% param
%xbar = rgb2gray(im2double(imread("flower.png")));
%sigma = 0.1;
%n = sigma*randn(size(xbar));
%z = rgb2gray(im2double(imread("gdb_benin.jpg")));
%z = rgb2gray(im2double(imread("color2.jpg")));
%z = z(2:end-1, 2:end-1);
%z = z(108-10:185+10,140-10:220+10); % boite englob du gdb sain
%z = z(58-10:144+10, 39-10:129+10); % boitr englob malsain
gdb = 'benin';
offset = 10;
switch gdb
    case 'benin'
        z_rgb = im2double(imread("gdb_benin.jpg"));
        z = rgb2gray(z_rgb);
        z = z(108-offset:185+offset,140-offset:220+offset); % boite englob du gdb sain
        z_rgb = z_rgb(108-offset:185+offset,140-offset:220+offset,:);
    case 'color'
        z = rgb2gray(im2double(imread("color.jpg")));
        z = z(63-offset:170+offset, 75-offset:165+offset);
    case 'color2'
        z = rgb2gray(im2double(imread("color2.jpg")));
        z = z(58-offset:144+offset, 39-offset:129+offset); % boitr englob malsain
    case 'color3'
        z = rgb2gray(im2double(imread("color3.jpg")));
        z = z(25-offset:142+offset, 33-offset:165);
end

[H,W] = size(z);
lambda = 15;
gamma = 0.005;
figure(12)
imshow(z_rgb)
figure(1)
imshow(z,[])
figure(44)
[Gx,Gy] = gradient(z);
NormCarreZ = Gx.^2 + Gy.^2;
imshow(NormCarreZ,[])

%% choix de l'opérateur de régularisation
gamma_choix = 'laplacien';
switch gamma_choix
    case 'id'
        G =@(x) x;
        Gt =@(x) x;
    case 'gradient'
        G = @(x) opD(x);
        Gt =@(x) opDt(x);
    case 'laplacien'
        G = @(x) opL(x);
        Gt =@(x) opLt(x);
end

%% calcul de la fonction à minimiser
f =@(x) norm(x(:),2);
g =@(x) lambda*norm(x(:),1);


%% calcul du prox_gamma_f(x)
prox_tau_g =@(x,tau) (x>tau).*(x) + (x<-tau).*(x); % psueod norm L0
%prox_tau_g =@(x,tau) (x>tau).*(x-tau) + (x<-tau).*(x+tau);
gradF =@(u) -G(-Gt(u)+z);

%% Méthode de descente
flag = true;
epsilon = 1e-6;
iteration = 1;
uk = G(z);
energie_init = 0.5*norm(-Gt(uk)+z+z, "fro")^2;% + lambda*norm(uk,1);
ENERGIE = [energie_init ];
while flag && (iteration < 1000)
    % Iteartion proximale
    uk1 = uk - gamma*gradF(uk) - gamma*prox_tau_g( uk/gamma - gradF(uk) ,lambda/gamma);
    cout = 0.5*norm(-Gt(uk1)-z, "fro")^2+ lambda*norm(-Gt(uk),1);
    ENERGIE = cat(2,ENERGIE,cout); %[ENERGIE, 0.5*norm(-Gt(uk1)+z, "fro") ];
    
    uk = uk1;
    iteration = iteration + 1;
    % Critère d'arrêt : à refaire avec energie et non l'itéré
    %if abs( (ENERGIE(iteration) - ENERGIE(iteration-1))/ENERGIE(iteration)) < epsilon
    %    flag = false;
    %end
end
figure(5)
loglog(ENERGIE)
uhat = uk;
xhat = -Gt(uhat) + z;
%%
figure(6)
imshow(z)

figure(7)
imshow(xhat)

%%
[Gx,Gy] = gradient(xhat);
NormCarre = Gx.^2 + Gy.^2;
%NormCarre = 10000 * NormCarre;
figure(4)
imshow(NormCarre,[])
%colorbar
%caxis([0 4.5e-3])
nbElnonNul = numel(NormCarre(NormCarre>0.1*max(NormCarre(:))));
%moyenne = mean(mean(NormCarre))/(H*W) % moyenne sur le nb de pixels non nuls 
moyenne = mean(mean(NormCarre))/nbElnonNul
OdG = abs(log10(moyenne))

pourcent = abs(OdG/10);
if OdG >= 7
    disp('cancer bebew')
else
    disp('oklm mon reuf')
end