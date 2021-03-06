function [x,fiii,fiii2] = kalman_fusion(u, slamx)
settings();%设置参数
global initial
% zupt = ZUPTDetector(u);%零ꀦÿՋ

N1 = length(u);
N2 = length(slamx);
N = min(N1, N2)
[P,Q,R,H,x] = init_matrix(N);%初始化协方差矩阵，以及各矩阵维数
[x(1:10,1),d_x,quat]=init_state(u);%初始化x和四元数。x包含2组三维元素：位置，ꀥڦ䀱uat丿x1
fiii = zeros(3,N);
for k = 2:N
%%  if(mod(k,2460*6) == 0)
%     P=zeros(15);
%    P(10:12,10:12)=diag(1*initial.P_acc_bias.^2);
%    P(13:15,13:15)=diag(1*initial.P_gyro_bias.^2);  
%    P(1:3,1:3)=diag(1*initial.P_pos.^2);
%    P(4:6,4:6)=diag(1*initial.P_vel.^2);
%    P(7:9,7:9)=diag(1*initial.P_att.^2);
      
%  end
    u_c = u(1:6,k)+d_x(10:15); %补偿加ꀥڦ和角ꀥڿ
    [x(:,k),quat,Cbn] = state_update(x(:,k-1),u_c,quat);%状瀦۴新和四元数更新  
%     [F,G] = state_transition_matrix(Cbn,u_c);%求卡尔曼状瀨ݬ移矩阵，F丿5x15,G丿5x12
    F = calF(quat, u_c(1:3,k), u_c(4:6, k));
    Qd = calQ(quat, u_c(1:3,k), u_c(4:6, k)); 
    P=F*P*F'+ Qd;%协方差矩阵时间更斿P丿5x15
    P=(P+P')/2;%使P对称，减少EKF发散的可能濊%     fiii(k) = atan2(Cbn(2,1),Cbn(1,1));
%      dcm = q2Cbn([slamx(8,k),slamx(5,k),slamx(6,k),slamx(7,k)]);
     dcm = q2Cbn(slamx(5:8,k));
     fiii(:,k) = [atan2(dcm(3,2),dcm(3,3)),asin(-dcm(3,1)),atan2(dcm(2,1),dcm(1,1))]';
     fiii2(:,k) = [atan2(Cbn(3,2),Cbn(3,3)),asin(-Cbn(3,1)),atan2(Cbn(2,1),Cbn(1,1))]';
if mod(k,2) == 0%棿Ջ到零速度，运行EKF
    
     
     temp_att = - [atan2(Cbn(3,2),Cbn(3,3))- atan2(dcm(3,2),dcm(3,3)), asin(-Cbn(3,1))-asin(-dcm(3,1)), atan2(Cbn(2,1),Cbn(1,1))-atan2(dcm(2,1),dcm(1,1))]';
%        m = [slamx(2:4,k)-x(1:3,k);temp_att];%观测釿   
     m = slamx(2:4,k) / 2-x(1:3,k); 
     H = H * x(10,k);
     K=(P*H')/(H*P*H'+R);%增益
      d_x = K*m; %误差朿ܘ估计
     [x(:,k),quat] = correct_state(d_x,Cbn,x(:,k));%通过误差对x进行补偿   
      P=(eye(16)-K*H)*P;%协方差的量测更新
      P=(P+P')/2;
end    
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%矩阵初始化函敿%N为初始数据的数据长度
%P为状态协方差矩阵
%Q为过程噪声协方差矩阵
%R为量测噪声协方差矩阵
%x为输出状态向釿
function [P,Q,R,H,x] = init_matrix(N)
    global initial
      
    P=zeros(16);
    P(10:12,10:12)=diag(1*initial.P_gyro_bias.^2);
    P(13:15,13:15)=diag(1*initial.P_acc_bias.^2);  
    P(1:3,1:3)=diag(1*initial.P_pos.^2);
    P(4:6,4:6)=diag(1*initial.P_vel.^2);
    P(7:9,7:9)=diag(1*initial.P_att.^2);
    
    P(15,15) = initial.P_scale;%%%%
    
    
    Q=zeros(12);
    Q(4:6,4:6)=diag(1*initial.Q_acc_bias_noise.^2);
    Q(10:12,10:12)=diag(1*initial.Q_gyro_bias_noise.^2);
    Q(1:3,1:3)=diag(1*initial.Q_acc.^2);
    Q(7:9,7:9)=diag(1*initial.Q_gyro.^2);
    Q  = Q * 1;
    
    R = zeros(3);  
    R(1:3,1:3)=diag(1*initial.R_vel.^2);
%    R(4:6,4:6)=diag(1*initial.R_att.^2);
    H=zeros(3,16);
    H(1:3,1:3) = eye(3);
%     H(1:3,7:9) = eye(3);
%    P = single(P);
%    Q = single(Q);
%    H = single(H);
%    R = single(R);
    x = zeros(10,N);
    x(10,1) = 1.2;
    x(10,1) = 1.1;
%     x = single(x);

end
%%
%四元数和状瀥Б量x初始化函敿%x0为初始化输出状瀥Б量
%q为初始化四元敿%u为原始数据输兿
function [x0,dx,q]=init_state(u)

    a_x=mean(u(4,1:240));
    a_y=mean(u(5,1:240));
    a_z=mean(u(6,1:240));
%     u0(1:3) = mean(u(7:9,1:240),2);
    roll=atan2(-a_y,-a_z);
    pitch=atan2(a_x,sqrt(a_y^2+a_z^2));
%     yaw = compa_d([roll,pitch],u0);
   
    
    attitude=[roll pitch 0]';

    Cbn=att2Cbn(attitude);
    q = Cbn2q(Cbn);

    x0=zeros(10,1);
    dx = zeros(16,1);
     x0(10,1) = 1.2;
%     dx = single(dx);
end
%%
%x和四元数更新函数
%输入分别为上丿׶刻的x，本时刻的加速度角ꀥڦ信息和四元数，输出为本时刻的x和四元数
function [x_out,q_out,Cbn]=state_update(x_in,u,q_in)
global initial;
ts = initial.ts;

w_tb = u(1:3)*ts;

ou = 0.5*[0,-w_tb(1),-w_tb(2),-w_tb(3);
          w_tb(1),0,w_tb(3),-w_tb(2);
          w_tb(2),-w_tb(3),0,w_tb(1);
          w_tb(3),w_tb(2),-w_tb(1),0];  
v=norm(w_tb);
if v~=0
    q_out=(cos(v/2)*eye(4)+2/v*sin(v/2)*ou )*q_in;
    q_out=q_out./norm(q_out);
else
    q_out = q_in;
end

Cbn = q2Cbn(q_out);
g_n=[0,0,initial.g]';
a_n=Cbn*u(4:6);
acc_n=a_n+g_n;

A=eye(6); A(1,4)=ts; A(2,5)=ts; A(3,6)=ts;

B=[(ts^2)/2*eye(3);ts*eye(3)];

x_out(1:6)=A*x_in(1:6)+B*acc_n;
x_out(7) = atan2(Cbn(3,2),Cbn(3,3));
x_out(8) = asin(-Cbn(3,1));
x_out(9) = atan2(Cbn(2,1),Cbn(1,1));
x_out(10) = x_in(10);
end
%%
%求状态转移矩阵，q为四元数，u为加速度信息
%F丿5x15，G丿5x12
function m = skew(v)
    
    m = [0,-v(3),v(2); v(3) 0,-v(1); -v(2),v(1),0];
end


function F = calF(q_,ew, ea)
   global initial
   dt = initial.ts;
  
   a_sk = skew(ea);
   w_sk = skew(ew);
   eye3 = eye(3);

   C_eq = q2Cbn(q_);

   dt_p2_2 = dt * dt * 0.5; 
   dt_p3_6 = dt_p2_2 * dt / 3.0;
   dt_p4_24 = dt_p3_6 * dt * 0.25; 
   dt_p5_120 = dt_p4_24 * dt * 0.2;

   Ca3 = C_eq * a_sk;
   A = Ca3 * (-dt_p2_2 * eye3 + dt_p3_6 * w_sk - dt_p4_24 * w_sk * w_sk);
   B = Ca3 * (dt_p3_6 * eye3 - dt_p4_24 * w_sk + dt_p5_120 * w_sk * w_sk);
   D = -A;
   E = eye3 - dt * w_sk + dt_p2_2 * w_sk * w_sk;
   F = -dt * eye3 + dt_p2_2 * w_sk - dt_p3_6 * (w_sk * w_sk);
   C = Ca3 * F;

  
  Fd = eye(16);
  Fd(1:3, 4:6) = dt * eye3;
  Fd(1:3, 7:9) = A;
  Fd(1:3, 10:12) = B;
  Fd(1:3, 13:15) = -C_eq * dt_p2_2;

  Fd(4:6, 7:9) = C;
  Fd(4:6, 10:12) = D;
  Fd(4:6, 13:15) = -C_eq * dt;

  Fd(7:9, 7:9) = E;
  Fd(7:9, 10:12) = F;

end
function [F,G] = state_transition_matrix(Cbn,u)
global initial
ts = initial.ts;

 O = zeros(3);
 I = eye(3);

a_n = Cbn*u(4:6);
St=[0,-a_n(3),a_n(2); a_n(3) 0,-a_n(1); -a_n(2),a_n(1),0];
V3 = [0,0,0];
% G=[O,O,O,O; Cbn,O,O,O; O,-Cbn,O,O; O,O,I,O; O,O,O,I;zeros(1,12)];%15x12
Gc = zeros(16,12);

Gc(4:6, 1:3) = -Cbn;
Gc(7:9, 7:9) = -I;
Gc(10:12, 10:12) = I;
Gc(13:15, 4:6) = I;




F = zeros(16);
F(1:3,4:6) = I;
F(4:6,13:15) = -Cbn;
F(4:6,7:9) = -St;
F(7:9,10:12) = -Cbn;%%%%%
Fc = F * ts/2;
F = eye(16)+F.*ts;
Fc = eye(16)*ts + Fc ;

G = Fc * Gc;        
end
%%
%x和四元数补偿，dx为卡尔曼求得的误差，
function [Qd] = calQ(q, ew, ea)
    global initial
    dt = initial.ts;
    
    n_ba = initial.Q_acc_bias_noise; 
    n_bw = initial.Q_gyro_bias_noise; s
    n_a = initial.Q_acc;
    n_w = initial.Q_gyro;
    n_L = initial.Q_L;
    
     global initial
    dt = initial.ts;
    
    n_ba = initial.Q_acc_bias_noise; 
    n_bw = initial.Q_gyro_bias_noise; s
    n_a = initial.Q_acc;
    n_w = initial.Q_gyro;
    n_L = initial.Q_L;
    
     q1=q(1) 
     q2=q(2); 
     q3=q(3); 
     q4=q(4);
	 ew1=ew(1);
     ew2=ew(2); 
     ew3=ew(2);
	 ea1=ea(1);
     ea2=ea(2); 
     ea3=ea(2);
	 n_a1=n_a(1);
     n_a2=n_a(2); 
     n_a3=n_a(3);
	 n_ba1=n_ba(1);
     n_ba2=n_ba(2);
     n_ba3=n_ba(3);
	 n_w1=n_w(1);
     n_w2=n_w(2); 
     n_w3=n_w(3);
	 n_bw1=n_bw(1);
     n_bw2=n_bw(2);
     n_bw3=n_bw(3);
	 

	 t343 = dt*dt;
	 t348 = q1*q4*2.0;
	 t349 = q2*q3*2.0;
	 t344 = t348-t349;
	 t356 = q1*q3*2.0;
	 t357 = q2*q4*2.0;
	 t345 = t356+t357;
	 t350 = q1*q1;
	 t351 = q2*q2;
	 t352 = q3*q3;
	 t353 = q4*q4;
	 t346 = t350+t351-t352-t353;
	 t347 = n_a1*n_a1;
	 t354 = n_a2*n_a2;
	 t355 = n_a3*n_a3;
	 t358 = q1*q2*2.0;
	 t359 = t344*t344;
	 t360 = t345*t345;
	 t361 = t346*t346;
	 t363 = ea2*t345;
	 t364 = ea3*t344;
	 t362 = t363+t364;
	 t365 = t362*t362;
	 t366 = t348+t349;
	 t367 = t350-t351+t352-t353;
	 t368 = q3*q4*2.0;
	 t369 = t356-t357;
	 t370 = t350-t351-t352+t353;
	 t371 = n_w3*n_w3;
	 t372 = t358+t368;
	 t373 = n_w2*n_w2;
	 t374 = n_w1*n_w1;
	 t375 = dt*t343*t346*t347*t366*(1.0/3.0);
	 t376 = t358-t368;
	 t377 = t343*t346*t347*t366*(1.0/2.0);
	 t378 = t366*t366;
	 t379 = t376*t376;
	 t380 = ea1*t367;
	 t391 = ea2*t366;
	 t381 = t380-t391;
	 t382 = ea3*t367;
	 t383 = ea2*t376;
	 t384 = t382+t383;
	 t385 = t367*t367;
	 t386 = ea1*t376;
	 t387 = ea3*t366;
	 t388 = t386+t387;
	 t389 = ea2*t370;
	 t407 = ea3*t372;
	 t390 = t389-t407;
	 t392 = ea1*t372;
	 t393 = ea2*t369;
	 t394 = t392+t393;
	 t395 = ea1*t370;
	 t396 = ea3*t369;
	 t397 = t395+t396;
	 t398 = n_ba1*n_ba1;
	 t399 = n_ba2*n_ba2;
	 t400 = n_ba3*n_ba3;
	 t401 = dt*t343*t345*t355*t370*(1.0/3.0);
	 t402 = t401-dt*t343*t346*t347*t369*(1.0/3.0)-dt*t343*t344*t354*t372*(1.0/3.0);
	 t403 = dt*t343*t354*t367*t372*(1.0/3.0);
	 t404 = t403-dt*t343*t347*t366*t369*(1.0/3.0)-dt*t343*t355*t370*t376*(1.0/3.0);
	 t405 = t343*t345*t355*t370*(1.0/2.0);
	 t406 = dt*t343*t362*t373*t397*(1.0/6.0);
	 t421 = t343*t346*t347*t369*(1.0/2.0);
	 t422 = dt*t343*t362*t371*t394*(1.0/6.0);
	 t423 = t343*t344*t354*t372*(1.0/2.0);
	 t424 = dt*t343*t362*t374*t390*(1.0/6.0);
	 t408 = t405+t406-t421-t422-t423-t424;
	 t409 = t343*t354*t367*t372*(1.0/2.0);
	 t410 = dt*t343*t374*t384*t390*(1.0/6.0);
	 t411 = dt*t343*t373*t388*t397*(1.0/6.0);
	 t463 = t343*t355*t370*t376*(1.0/2.0);
	 t464 = t343*t347*t366*t369*(1.0/2.0);
	 t465 = dt*t343*t371*t381*t394*(1.0/6.0);
	 t412 = t409+t410+t411-t463-t464-t465;
	 t413 = t369*t369;
	 t414 = t372*t372;
	 t415 = t370*t370;
	 t416 = t343*t354*t359*(1.0/2.0);
	 t417 = t343*t355*t360*(1.0/2.0);
	 t418 = t343*t347*t361*(1.0/2.0);
	 t419 = t416+t417+t418-dt*t343*t365*t371*(1.0/6.0)-dt*t343*t365*t373*(1.0/6.0)-dt*t343*t365*t374*(1.0/6.0);
	 t453 = t343*t344*t354*t367*(1.0/2.0);
	 t454 = t343*t345*t355*t376*(1.0/2.0);
	 t420 = t377-t453-t454;
	 t426 = ew2*t362;
	 t427 = ew3*t362;
	 t425 = t426-t427;
	 t428 = dt*t365;
	 t429 = ew1*ew1;
	 t430 = ew2*ew2;
	 t431 = ew3*ew3;
	 t432 = t430+t431;
	 t433 = t362*t432;
	 t434 = ew1*t343*t365;
	 t435 = t429+t431;
	 t436 = t362*t435;
	 t443 = ew2*ew3*t362;
	 t437 = t433+t436-t443;
	 t438 = ew1*t362*t394;
	 t511 = ew1*t362*t397;
	 t439 = t438-t511;
	 t440 = t343*t439*(1.0/2.0);
	 t441 = t429+t430;
	 t442 = t362*t441;
	 t444 = t390*t432;
	 t445 = ew2*t394;
	 t446 = ew3*t397;
	 t447 = t445+t446;
	 t448 = ew1*ew2*t362;
	 t449 = ew1*ew3*t362;
	 t450 = ew1*ew3*t362*(1.0/2.0);
	 t451 = dt*t362;
	 t452 = ew1*t343*t362*(1.0/2.0);
	 t455 = dt*t343*t362*t374*t384*(1.0/6.0);
	 t456 = t343*t347*t378*(1.0/2.0);
	 t457 = t343*t355*t379*(1.0/2.0);
	 t458 = t381*t381;
	 t459 = t384*t384;
	 t460 = t343*t354*t385*(1.0/2.0);
	 t461 = t388*t388;
	 t462 = t456+t457+t460-dt*t343*t371*t458*(1.0/6.0)-dt*t343*t374*t459*(1.0/6.0)-dt*t343*t373*t461*(1.0/6.0);
	 t466 = t433+t442-t443;
	 t467 = ew1*t362*t388;
	 t468 = ew1*t362*t381;
	 t469 = t467+t468;
	 t470 = t343*t469*(1.0/2.0);
	 t471 = t384*t432;
	 t472 = ew2*t381;
	 t479 = ew3*t388;
	 t473 = t472-t479;
	 t474 = -t433+t448+t449;
	 t475 = dt*t343*t346*t366*t398*(1.0/3.0);
	 t476 = dt*t346*t347*t366;
	 t477 = ew2*ew3*t381;
	 t492 = t388*t435;
	 t478 = t471+t477-t492;
	 t480 = t472-t479;
	 t481 = ew1*ew3*t381;
	 t482 = ew1*ew2*t388;
	 t483 = t471+t481+t482;
	 t484 = ew2*ew3*t388;
	 t486 = t381*t441;
	 t485 = t471+t484-t486;
	 t487 = t394*t441;
	 t488 = ew2*ew3*t397;
	 t489 = t444+t487+t488;
	 t490 = t397*t435;
	 t491 = ew2*ew3*t394;
	 t493 = ew1*t381*t397;
	 t541 = ew1*t388*t394;
	 t494 = t493-t541;
	 t495 = t343*t494*(1.0/2.0);
	 t496 = ew1*ew2*t397;
	 t527 = ew1*ew3*t394;
	 t497 = t444+t496-t527;
	 t498 = ew2*ew3*t381*(1.0/2.0);
	 t499 = ew1*t343*t381*(1.0/2.0);
	 t500 = t384*t432*(1.0/2.0);
	 t501 = ew2*ew3*t388*(1.0/2.0);
	 t502 = n_bw1*n_bw1;
	 t503 = n_bw3*n_bw3;
	 t504 = t343*t347*t413*(1.0/2.0);
	 t505 = t343*t354*t414*(1.0/2.0);
	 t506 = t397*t397;
	 t507 = t390*t390;
	 t508 = t343*t355*t415*(1.0/2.0);
	 t509 = t394*t394;
	 t510 = t504+t505+t508-dt*t343*t373*t506*(1.0/6.0)-dt*t343*t371*t509*(1.0/6.0)-dt*t343*t374*t507*(1.0/6.0);
	 t512 = -t444+t490+t491;
	 t513 = t397*t437*(1.0/2.0);
	 t514 = t362*t394*t429;
	 t515 = dt*t362*t397;
	 t516 = t362*t489*(1.0/2.0);
	 t517 = t394*t466*(1.0/2.0);
	 t518 = t362*t397*t429;
	 t519 = t516+t517+t518;
	 t520 = dt*t362*t394;
	 t521 = t440+t520-dt*t343*t519*(1.0/3.0);
	 t522 = t371*t521;
	 t523 = t362*t447;
	 t524 = t390*t425;
	 t525 = t523+t524;
	 t526 = t343*t525*(1.0/2.0);
	 t528 = t425*t447;
	 t529 = t390*t474*(1.0/2.0);
	 t530 = t528+t529-t362*t497*(1.0/2.0);
	 t531 = dt*t343*t530*(1.0/3.0);
	 t532 = dt*t362*t390;
	 t533 = t526+t531+t532;
	 t534 = t374*t533;
	 t535 = dt*t343*t345*t370*t400*(1.0/3.0);
	 t536 = dt*t345*t355*t370;
	 t537 = t381*t489*(1.0/2.0);
	 t538 = t388*t397*t429;
	 t539 = t537+t538-t394*t485*(1.0/2.0);
	 t540 = dt*t343*t539*(1.0/3.0);
	 t542 = t495+t540-dt*t381*t394;
	 t543 = t388*t512*(1.0/2.0);
	 t544 = t381*t394*t429;
	 t545 = t543+t544-t397*t478*(1.0/2.0);
	 t546 = dt*t343*t545*(1.0/3.0);
	 t547 = t495+t546-dt*t388*t397;
	 t548 = t373*t547;
	 t549 = t384*t447;
	 t550 = t549-t390*t473;
	 t551 = t343*t550*(1.0/2.0);
	 t552 = t384*t497*(1.0/2.0);
	 t553 = t390*t483*(1.0/2.0);
	 t554 = t447*t473;
	 t555 = t552+t553+t554;
	 t556 = dt*t384*t390;
	 t557 = t551+t556-dt*t343*t555*(1.0/3.0);
	 t558 = dt*t343*t367*t372*t399*(1.0/3.0);
	 t559 = dt*t354*t367*t372;
	 t560 = t548+t558+t559-t371*t542-t374*t557-dt*t347*t366*t369-dt*t355*t370*t376-dt*t343*t366*t369*t398*(1.0/3.0)-dt*t343*t370*t376*t400*(1.0/3.0);
	 t561 = ew1*t343*t394*t397;
	 t562 = ew1*t343*t397*(1.0/2.0);
	 t563 = n_bw2*n_bw2;
	 t564 = dt*t343*t362*t374*(1.0/6.0);
	 t565 = dt*t343*t374*t390*(1.0/6.0);
	 t566 = ew1*ew2*t362*(1.0/2.0);
	 t567 = -t433+t450+t566;
	 t568 = dt*t343*t567*(1.0/3.0);
	 t569 = t343*t425*(1.0/2.0);
	 t570 = t451+t568+t569;
	 t571 = dt*t343*t362*t373*t432*(1.0/6.0);
	 t572 = dt*t343*t362*t371*t432*(1.0/6.0);
	 t573 = t571+t572-t374*t570;
	 t574 = ew1*ew2*t397*(1.0/2.0);
	 t575 = t444+t574-ew1*ew3*t394*(1.0/2.0);
	 t576 = t343*t447*(1.0/2.0);
	 t577 = dt*t390;
	 t578 = t576+t577-dt*t343*t575*(1.0/3.0);
	 t579 = dt*t343*t371*t394*t432*(1.0/6.0);
	 t580 = t579-t374*t578-dt*t343*t373*t397*t432*(1.0/6.0);
	 t581 = dt*t343*t373*t388*(1.0/6.0);
	 t582 = t362*t432*(1.0/2.0);
	 t583 = ew2*ew3*t362*(1.0/2.0);
	 t584 = t362*t429;
	 t585 = t583+t584;
	 t586 = ew3*t473;
	 t587 = ew1*ew2*t384*(1.0/2.0);
	 t588 = t586+t587;
	 t589 = dt*t343*t588*(1.0/3.0);
	 t590 = t374*(t589-ew3*t343*t384*(1.0/2.0));
	 t591 = t388*t429;
	 t592 = t498+t591;
	 t593 = dt*t343*t592*(1.0/3.0);
	 t594 = t499+t593;
	 t595 = -t492+t498+t500;
	 t596 = dt*t343*t595*(1.0/3.0);
	 t597 = dt*t388;
	 t598 = -t499+t596+t597;
	 t599 = t590-t371*t594-t373*t598;
	 t600 = t397*t429;
	 t601 = ew2*ew3*t394*(1.0/2.0);
	 t602 = ew1*t343*t394*(1.0/2.0);
	 t603 = ew3*t447;
	 t604 = t603-ew1*ew2*t390*(1.0/2.0);
	 t605 = dt*t343*t604*(1.0/3.0);
	 t606 = ew3*t343*t390*(1.0/2.0);
	 t607 = t605+t606;
	 t608 = t374*t607;
	 t609 = t390*t432*(1.0/2.0);
	 t610 = dt*t397;
	 t611 = t430*(1.0/2.0);
	 t612 = t431*(1.0/2.0);
	 t613 = t611+t612;
	 t614 = ew1*t343*(1.0/2.0);
	 t615 = dt*t343*t362*t371*(1.0/6.0);
	 t616 = dt*t343*t371*t381*(1.0/6.0);
	 t617 = dt*t343*t371*t394*(1.0/6.0);
	 t618 = ew2*t425;
	 t619 = t450+t618;
	 t620 = dt*t343*t619*(1.0/3.0);
	 t621 = ew2*t343*t362*(1.0/2.0);
	 t622 = t620+t621;
	 t623 = dt*t343*t585*(1.0/3.0);
	 t624 = t381*t429;
	 t625 = t501+t624;
	 t626 = dt*t343*t625*(1.0/3.0);
	 t627 = ew1*t343*t388*(1.0/2.0);
	 t628 = ew2*t473;
	 t629 = t628-ew1*ew3*t384*(1.0/2.0);
	 t630 = dt*t343*t629*(1.0/3.0);
	 t631 = t630-ew2*t343*t384*(1.0/2.0);
	 t632 = -t486+t500+t501;
	 t633 = dt*t343*t632*(1.0/3.0);
	 t634 = dt*t381;
	 t635 = t627+t633+t634;
	 t636 = ew2*t447;
	 t637 = ew1*ew3*t390*(1.0/2.0);
	 t638 = t636+t637;
	 t639 = dt*t343*t638*(1.0/3.0);
	 t640 = ew2*t343*t390*(1.0/2.0);
	 t641 = t639+t640;
	 t642 = t394*t429;
	 t643 = ew2*ew3*t397*(1.0/2.0);
	 t644 = t487+t609+t643;
	 t645 = dt*t343*t644*(1.0/3.0);
	 t646 = t562+t645-dt*t394;
	 t647 = t371*t646;
	 t648 = ew2*t343*(1.0/2.0);
	 t649 = dt*ew1*ew3*t343*(1.0/6.0);
	 t650 = t648+t649;
	 t651 = t374*t650;
	 t652 = t651-dt*t343*t371*t613*(1.0/3.0);
	 t653 = dt*ew2*ew3*t343*(1.0/6.0);
	 t654 = t614+t653;
	 t655 = t371*t654;
	 t656 = dt*t343*t397*t563*(1.0/6.0);
	 t657 = dt*ew1*t343*t563*(1.0/6.0);
	 t658 = dt*t343*t369*t398*(1.0/6.0);
	 t659 = t343*t369*t398*(1.0/2.0);
	 t660 = dt*t343*t344*t399*(1.0/6.0);
	 t661 = t343*t344*t399*(1.0/2.0);
	 t662 = dt*t343*t376*t400*(1.0/6.0);
	 t663 = t343*t376*t400*(1.0/2.0);
	Qd(1,1) = dt*t343*t347*t361*(1.0/3.0)+dt*t343*t354*t359*(1.0/3.0)+dt*t343*t355*t360*(1.0/3.0);
	Qd(1,2) = t375-dt*t343*t345*t355*(t358-q3*q4*2.0)*(1.0/3.0)-dt*t343*t344*t354*t367*(1.0/3.0);
	Qd(1,3) = t402;
	Qd(1,4) = t419;
	Qd(1,5) = t420;
	Qd(1,6) = t408;
	Qd(1,7) = t564;
	Qd(1,9) = t615;
	Qd(1,13) = dt*t343*t346*t398*(-1.0/6.0);
	Qd(1,14) = t660;
	Qd(1,15) = dt*t343*t345*t400*(-1.0/6.0);
	Qd(2,1) = t375-dt*t343*t344*t354*t367*(1.0/3.0)-dt*t343*t345*t355*t376*(1.0/3.0);
	Qd(2,2) = dt*t343*t347*t378*(1.0/3.0)+dt*t343*t355*t379*(1.0/3.0)+dt*t343*t354*t385*(1.0/3.0);
	Qd(2,3) = t404;
	Qd(2,4) = t377+t455-t343*t344*t354*t367*(1.0/2.0)-t343*t345*t355*t376*(1.0/2.0)-dt*t343*t362*t371*t381*(1.0/6.0)-dt*t343*t362*t373*t388*(1.0/6.0);
	Qd(2,5) = t462;
	Qd(2,6) = t412;
	Qd(2,7) = dt*t343*t374*t384*(-1.0/6.0);
	Qd(2,8) = t581;
	Qd(2,9) = t616;
	Qd(2,13) = dt*t343*t366*t398*(-1.0/6.0);
	Qd(2,14) = dt*t343*t367*t399*(-1.0/6.0);
	Qd(2,15) = t662;
	Qd(3,1) = t402;
	Qd(3,2) = t404;
	Qd(3,3) = dt*t343*t347*t413*(1.0/3.0)+dt*t343*t354*t414*(1.0/3.0)+dt*t343*t355*t415*(1.0/3.0);
	Qd(3,4) = t408;
	Qd(3,5) = t412;
	Qd(3,6) = t510;
	Qd(3,7) = t565;
	Qd(3,8) = dt*t343*t373*t397*(-1.0/6.0);
	Qd(3,9) = t617;
	Qd(3,13) = t658;
	Qd(3,14) = dt*t343*t372*t399*(-1.0/6.0);
	Qd(3,15) = dt*t343*t370*t400*(-1.0/6.0);
	Qd(4,1) = t419;
	Qd(4,2) = t420;
	Qd(4,3) = t408;
	Qd(4,4) = t374*(t428+t343*t362*t425+dt*t343*(t362*(t448+t449-t362*t432)+t425*t425)*(1.0/3.0))+t373*(t428-t434+dt*t343*(t365*t429-t362*t437)*(1.0/3.0))+t371*(t428+t434+dt*t343*(t365*t429-t362*(t433+t442-ew2*ew3*t362))*(1.0/3.0))+dt*t347*t361+dt*t354*t359+dt*t355*t360+dt*t343*t359*t399*(1.0/3.0)+dt*t343*t361*t398*(1.0/3.0)+dt*t343*t360*t400*(1.0/3.0);
	Qd(4,5) = t475+t476-dt*t344*t354*t367-dt*t345*t355*t376-dt*t343*t344*t367*t399*(1.0/3.0)-dt*t343*t345*t376*t400*(1.0/3.0);
	Qd(4,6) = t522+t534+t535+t536-t373*(t440+t515-dt*t343*(t513+t514+t362*(t490+t491-t390*t432)*(1.0/2.0))*(1.0/3.0))-dt*t346*t347*t369-dt*t344*t354*t372-dt*t343*t346*t369*t398*(1.0/3.0)-dt*t343*t344*t372*t399*(1.0/3.0);
	Qd(4,7) = t573;
	Qd(4,9) = -t371*(t451+t452-dt*t343*(t442+t582-ew2*ew3*t362*(1.0/2.0))*(1.0/3.0))-t374*t622+t373*(t452-dt*t343*t585*(1.0/3.0));
	Qd(4,10) = dt*t343*t362*t502*(-1.0/6.0);
	Qd(4,12) = dt*t343*t362*t503*(-1.0/6.0);
	Qd(4,13) = t343*t346*t398*(-1.0/2.0);
	Qd(4,14) = t661;
	Qd(4,15) = t343*t345*t400*(-1.0/2.0);
	Qd(5,1) = t377-t453-t454+t455-dt*t343*t362*t371*t381*(1.0/6.0)-dt*t343*t362*t373*t388*(1.0/6.0);
	Qd(5,2) = t462;
	Qd(5,3) = t412;
	Qd(5,4) = t475+t476-t374*(t343*(t384*t425-t362*t473)*(1.0/2.0)-dt*t343*(t362*t483*(1.0/2.0)-t384*t474*(1.0/2.0)+t425*t473)*(1.0/3.0)+dt*t362*t384)+t371*(t470+dt*t362*t381+dt*t343*(t362*t485*(1.0/2.0)-t381*t466*(1.0/2.0)+t362*t388*t429)*(1.0/3.0))+t373*(-t470+dt*t362*t388+dt*t343*(t388*t437*(-1.0/2.0)+t362*t478*(1.0/2.0)+t362*t381*t429)*(1.0/3.0))-dt*t344*t354*t367-dt*t345*t355*t376-dt*t343*t344*t367*t399*(1.0/3.0)-dt*t343*t345*t376*t400*(1.0/3.0);
	Qd(5,5) = -t374*(-dt*t459+dt*t343*(t384*t483-t480*t480)*(1.0/3.0)+t343*t384*t473)+t373*(dt*t461+dt*t343*(t388*t478+t429*t458)*(1.0/3.0)-ew1*t343*t381*t388)+t371*(dt*t458+dt*t343*(t381*t485+t429*t461)*(1.0/3.0)+ew1*t343*t381*t388)+dt*t347*t378+dt*t355*t379+dt*t354*t385+dt*t343*t378*t398*(1.0/3.0)+dt*t343*t385*t399*(1.0/3.0)+dt*t343*t379*t400*(1.0/3.0);
	Qd(5,6) = t560;
	Qd(5,7) = -t374*(-dt*t384+t343*t473*(1.0/2.0)+dt*t343*(t471+ew1*ew2*t388*(1.0/2.0)+ew1*ew3*t381*(1.0/2.0))*(1.0/3.0))+dt*t343*t371*t381*t432*(1.0/6.0)+dt*t343*t373*t388*t432*(1.0/6.0);
	Qd(5,8) = t599;
	Qd(5,9) = -t374*t631-t371*t635-t373*(t626-ew1*t343*t388*(1.0/2.0));
	Qd(5,10) = dt*t343*t384*t502*(1.0/6.0);
	Qd(5,11) = dt*t343*t388*t563*(-1.0/6.0);
	Qd(5,12) = dt*t343*t381*t503*(-1.0/6.0);
	Qd(5,13) = t343*t366*t398*(-1.0/2.0);
	Qd(5,14) = t343*t367*t399*(-1.0/2.0);
	Qd(5,15) = t663;
	Qd(6,1) = t408;
	Qd(6,2) = t412;
	Qd(6,3) = t510;
	Qd(6,4) = t522+t534+t535+t536-t373*(t440+t515-dt*t343*(t513+t514+t362*t512*(1.0/2.0))*(1.0/3.0))-dt*t346*t347*t369-dt*t344*t354*t372-dt*t343*t346*t369*t398*(1.0/3.0)-dt*t343*t344*t372*t399*(1.0/3.0);
	Qd(6,5) = t560;
	Qd(6,6) = -t371*(t561-dt*t509+dt*t343*(t394*t489-t429*t506)*(1.0/3.0))+t373*(t561+dt*t506-dt*t343*(t397*t512-t429*t509)*(1.0/3.0))+t374*(dt*t507-dt*t343*(t390*t497-t447*t447)*(1.0/3.0)+t343*t390*t447)+dt*t347*t413+dt*t354*t414+dt*t355*t415+dt*t343*t398*t413*(1.0/3.0)+dt*t343*t399*t414*(1.0/3.0)+dt*t343*t400*t415*(1.0/3.0);
	Qd(6,7) = t580;
	Qd(6,8) = t608+t371*(dt*t343*(t600-ew2*ew3*t394*(1.0/2.0))*(1.0/3.0)-ew1*t343*t394*(1.0/2.0))+t373*(t602+t610-dt*t343*(t490+t601-t390*t432*(1.0/2.0))*(1.0/3.0));
	Qd(6,9) = t647-t374*t641-t373*(t562+dt*t343*(t642-ew2*ew3*t397*(1.0/2.0))*(1.0/3.0));
	Qd(6,10) = dt*t343*t390*t502*(-1.0/6.0);
	Qd(6,11) = t656;
	Qd(6,12) = dt*t343*t394*t503*(-1.0/6.0);
	Qd(6,13) = t659;
	Qd(6,14) = t343*t372*t399*(-1.0/2.0);
	Qd(6,15) = t343*t370*t400*(-1.0/2.0);
	Qd(7,1) = t564;
	Qd(7,3) = t565;
	Qd(7,4) = t573;
	Qd(7,6) = t580;
	Qd(7,7) = t374*(dt-dt*t343*t432*(1.0/3.0))+dt*t343*t502*(1.0/3.0);
	Qd(7,9) = t652;
	Qd(7,10) = t343*t502*(-1.0/2.0);
	Qd(8,1) = dt*t343*t362*t373*(1.0/6.0);
	Qd(8,2) = t581;
	Qd(8,3) = dt*t343*t373*t397*(-1.0/6.0);
	Qd(8,4) = -t371*(t452+t623)-t374*(dt*t343*(t566-ew3*t425)*(1.0/3.0)-ew3*t343*t362*(1.0/2.0))+t373*(-t451+t452+dt*t343*(t436+t582-t583)*(1.0/3.0));
	Qd(8,5) = t599;
	Qd(8,6) = t608+t373*(t602+t610-dt*t343*(t490+t601-t609)*(1.0/3.0))-t371*(t602-dt*t343*(t600-t601)*(1.0/3.0));
	Qd(8,7) = -t374*(ew3*t343*(1.0/2.0)-dt*ew1*ew2*t343*(1.0/6.0))-dt*t343*t373*t613*(1.0/3.0);
	Qd(8,8) = t373*(dt-dt*t343*t435*(1.0/3.0))+dt*t343*t563*(1.0/3.0)+dt*t343*t371*t429*(1.0/3.0)+dt*t343*t374*t431*(1.0/3.0);
	Qd(8,9) = t655-t373*(t614-dt*ew2*ew3*t343*(1.0/6.0))-dt*ew2*ew3*t343*t374*(1.0/3.0);
	Qd(8,10) = dt*ew3*t343*t502*(1.0/6.0);
	Qd(8,11) = t343*t563*(-1.0/2.0);
	Qd(8,12) = dt*ew1*t343*t503*(-1.0/6.0);
	Qd(9,1) = t615;
	Qd(9,2) = t616;
	Qd(9,3) = t617;
	Qd(9,4) = -t374*t622-t371*(t451+t452-dt*t343*(t442+t582-t583)*(1.0/3.0))+t373*(t452-t623);
	Qd(9,5) = -t374*t631-t371*t635-t373*(t626-t627);
	Qd(9,6) = t647-t374*t641-t373*(t562+dt*t343*(t642-t643)*(1.0/3.0));
	Qd(9,7) = t652;
	Qd(9,8) = t655-t373*(t614-t653)-dt*ew2*ew3*t343*t374*(1.0/3.0);
	Qd(9,9) = t371*(dt-dt*t343*t441*(1.0/3.0))+dt*t343*t503*(1.0/3.0)+dt*t343*t373*t429*(1.0/3.0)+dt*t343*t374*t430*(1.0/3.0);
	Qd(9,10)= dt*ew2*t343*t502*(-1.0/6.0);
	Qd(9,11) = t657;
	Qd(9,12) = t343*t503*(-1.0/2.0);
	Qd(10,4) = dt*t343*t362*t502*(-1.0/6.0);
	Qd(10,6) = dt*t343*t390*t502*(-1.0/6.0);
	Qd(10,7) = t343*t502*(-1.0/2.0);
	Qd(10,9) = dt*ew2*t343*t502*(-1.0/6.0);
	Qd(10,10)= dt*t502;
	Qd(11,4) = dt*t343*t362*t563*(-1.0/6.0);
	Qd(11,5) = dt*t343*t388*t563*(-1.0/6.0);
	Qd(11,6) = t656;
	Qd(11,8) = t343*t563*(-1.0/2.0);
	Qd(11,9) = t657;
	Qd(11,11) = dt*t563;
	Qd(12,4) = dt*t343*t362*t503*(-1.0/6.0);
	Qd(12,5) = dt*t343*t381*t503*(-1.0/6.0);
	Qd(12,6) = dt*t343*t394*t503*(-1.0/6.0);
	Qd(12,8) = dt*ew1*t343*t503*(-1.0/6.0);
	Qd(12,9) = t343*t503*(-1.0/2.0);
	Qd(12,12) = dt*t503;
	Qd(13,1) = dt*t343*t346*t398*(-1.0/6.0);
	Qd(13,2) = dt*t343*t366*t398*(-1.0/6.0);
	Qd(13,3) = t658;
	Qd(13,4) = t343*t346*t398*(-1.0/2.0);
	Qd(13,5) = t343*t366*t398*(-1.0/2.0);
	Qd(13,6) = t659;
	Qd(13,13) = dt*t398;
	Qd(14,1) = t660;
	Qd(14,2) = dt*t343*t367*t399*(-1.0/6.0);
	Qd(14,3) = dt*t343*t372*t399*(-1.0/6.0);
	Qd(14,4) = t661;
	Qd(14,5) = t343*t367*t399*(-1.0/2.0);
	Qd(14,6) = t343*t372*t399*(-1.0/2.0);
	Qd(14,14) = dt*t399;
	Qd(15,1) = dt*t343*t345*t400*(-1.0/6.0);
	Qd(15,2) = t662;
	Qd(15,3) = dt*t343*t370*t400*(-1.0/6.0);
	Qd(15,4) = t343*t345*t400*(-1.0/2.0);
	Qd(15,5) = t663;
	Qd(15,6) = t343*t370*t400*(-1.0/2.0);
	Qd(15,15) = dt*t400;
	Qd(16,16) = dt*(n_L*n_L);



end
function [x_out,q_out] = correct_state(dx,Cbn,x_in)

x_out(1:6) = x_in(1:6)+dx(1:6);%补偿位置和ꀥڿ
epsilon = dx(7:9);
fii =  [0 -epsilon(3) epsilon(2); epsilon(3) 0 -epsilon(1); -epsilon(2) epsilon(1) 0];
Cbn = (eye(3)-fii)*Cbn;%补偿姿瀧ߩ阵
x_out(7) = atan2(Cbn(3,2),Cbn(3,3));
x_out(8) = asin(-Cbn(3,1));
x_out(9) = atan2(Cbn(2,1),Cbn(1,1));
x_out(10) = x_in(10) + dx(16);
q_out = Cbn2q(Cbn);
end

%%
%ZUPT棿Ջ
function zupt = ZUPTDetector(u)
global initial
g=initial.g;
sigma_a=1*initial.sigma_a^2;
sigma_g=1*initial.sigma_g^2;
W=initial.Window_size;

N=length(u);
zupt=zeros(1,length(u));
T=zeros(1,N-W+1);
for k=1:N-W+1
   
    a_m=mean(u(1:3,k:k+W-1),2);
    
    for l=k:k+W-1
        tmp=u(1:3,l)-g*a_m/norm(a_m);
        T(k)=T(k)+u(4:6,l)'*u(4:6,l)/sigma_g+tmp'*tmp/sigma_a;    
    end    
end
T=T./W;

for k=1:length(T)
    if T(k)<1*initial.gamma
       zupt(k:k+W-1)=ones(1,W); 
    end    
end

end
%%
%参数设置
function settings()

global initial;

initial.latitude=40;

initial.altitude=43.1;

initial.g=gravity(initial.latitude,initial.altitude);
initial.g=9.8004;
initial.ts=1/200;

initial.sigma_a=0.015;%% 

initial.sigma_g=0.333*pi/180;     

initial.Window_size=3;


initial.gamma=0.3e5; 

%R
initial.R_vel = 0.1*ones(3,1);      
initial.R_att = 0.0001*ones(3,1);  
%P 
initial.P_pos=1e-5*ones(3,1);               
initial.P_vel=1e-5*ones(3,1);               
initial.P_att=0.09*pi/180*ones(3,1);     
initial.P_acc_bias=0.003*ones(3,1);           
initial.P_gyro_bias=0.003*pi/180*ones(3,1);                                
initial.P_scale = 0.4;
% Q动瀨ϯ差时间常数 

initial.Q_acc_bias_noise=0.0000001*ones(3,1); 
initial.Q_gyro_bias_noise=0.0000001*pi/180*ones(3,1); 
initial.Q_acc =0.12*ones(3,1);
initial.Q_gyro =1.6*ones(3,1)*pi/180;
initial.Q_L = 0.4;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%姿瀧ߩ阵转四元数
function q=Cbn2q(Cbn)

tr=Cbn(1,1)+Cbn(2,2)+Cbn(3,3);
Pa=1+tr;
Pb=1+2*Cbn(1,1)-tr;
Pc=1+2*Cbn(2,2)-tr;
Pd=1+2*Cbn(3,3)-tr;

q=zeros(4,1);
if (Pa>0)
    q(1)=0.5*sqrt(Pa);
    q(2)=(Cbn(3,2)-Cbn(2,3))/4/q(1);
    q(3)=(Cbn(1,3)-Cbn(3,1))/4/q(1);
    q(4)=(Cbn(2,1)-Cbn(1,2))/4/q(1);
elseif (Pb>=Pc && Pb>=Pd)
    q(2)=0.5*sqrt(Pb);
    q(3)=(Cbn(2,1)+Cbn(1,2))/4/q(2);
    q(4)=(Cbn(1,3)+Cbn(3,1))/4/q(2);
    q(1)=(Cbn(3,2)-Cbn(2,3))/4/q(2);
elseif (Pc>=Pd)
    q(3)=0.5*sqrt(Pc);
    q(4)=(Cbn(3,2)+Cbn(2,3))/4/q(3);
    q(1)=(Cbn(1,3)-Cbn(3,1))/4/q(3);
    q(2)=(Cbn(2,1)+Cbn(1,2))/4/q(3);
else
    q(4)=0.5*sqrt(Pd);
    q(1)=(Cbn(2,1)-Cbn(1,2))/4/q(4);
    q(2)=(Cbn(1,3)+Cbn(3,1))/4/q(4);
    q(3)=(Cbn(3,2)+Cbn(2,3))/4/q(4);
end

if (q(1)<=0)
    q=-q;
end

end
%%
%四元数转姿瀧ߩ阵
function Cbn=q2Cbn(q)

q0 = q(1);
q1 = q(2);
q2 = q(3);
q3 = q(4);

Cbn(1,1) = q0^2+q1^2-q2^2-q3^2;
Cbn(2,2) = q0^2-q1^2+q2^2-q3^2;
Cbn(3,3) = q0^2-q1^2-q2^2+q3^2;
Cbn(1,2) = 2*(q1*q2-q0*q3);
Cbn(1,3) = 2*(q1*q3+q0*q2);
Cbn(2,1) = 2*(q1*q2+q0*q3);
Cbn(2,3) = 2*(q2*q3-q0*q1);
Cbn(3,1) = 2*(q1*q3-q0*q2);
Cbn(3,2) = 2*(q2*q3+q0*q1);
if(q0^2+q1^2+q2^2+q3^2>0)
    Cbn = Cbn/sqrt(q0^2+q1^2+q2^2+q3^2);
else
    Cbn = eye(3); 
end

end

%%
%姿瀨ǒ转姿瀧ߩ阵
function Cbn=att2Cbn(att)

cr=cos(att(1));
sr=sin(att(1));

cp=cos(att(2));
sp=sin(att(2));

cy=cos(att(3));
sy=sin(att(3));

Cbn = [cy*cp,-sy*cr+cy*sp*sr,sy*sr+cy*sp*sr;
       sy*cp,cy*cr+sy*sp*sr,-cy*sr+sy*sp*cr;
       -sp,cp*sr,cp*cr];
end
%%
%通过磁力计求航向
%由当前姿态角和三轴磁力参数求得航向角
function fi = compa_d(x,u)
Bx = u(1)*cos(x(2))+u(2)*sin(x(2))*sin(x(1))+u(3)*sin(x(2))*cos(x(1));
By = u(2)*cos(x(1))-u(3)*sin(x(1));
fi= atan2(-By,Bx);
end

%%
%由纬度和海拔求重力加速度
function g=gravity(latitude,altitude)

latitude=pi/180*latitude;
g0=9.780327*(1+0.0053024*sin(latitude)^2-0.0000058*sin(2*latitude)^2);
g=g0-((3.0877e-6)-(0.004e-6)*sin(latitude)^2)*altitude+(0.072e-12)*altitude^2;
end
