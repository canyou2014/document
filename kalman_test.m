imu(:,1) = imumdata(:,4);
imu(:,2) = imumdata(:,5);
imu(:,3) = imumdata(:,6);
imu(:,4) = imumdata(:,1);
imu(:,5) = imumdata(:,2);
imu(:,6) = imumdata(:,3);

[out_x, fii,fii2] = kalman_fusion(imu', groundmdata');

% plot(out_x(1,:), out_x(2,:));
% hold on;
% plot(groundmdata(:,2), groundmdata(:,3))
% figure;
% plot(out_x(7,:)); hold on;
plot(fii(3,1:5000));hold on;
plot(ground(2,1:5000));hold on;

% plot(fii2(1,:))
