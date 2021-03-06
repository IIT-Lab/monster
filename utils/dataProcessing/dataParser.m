%% DATA PARSER is use to generate charts of the results
% feel free to comment out the blocks not needed and modify this script in whichever way suits your needs

util_low = 60;
util_high = 100 ;

metrics_arr = cell([length(util_low),length(util_high)]);
powerConsumed = cell([length(util_low),length(util_high)]);
util = cell([length(util_low),length(util_high)]);
thr = cell([length(util_low),length(util_high)]);
ber = cell([length(util_low),length(util_high)]);
rsrq = cell([length(util_low),length(util_high)]);
bler = cell([length(util_low),length(util_high)]);
sinr = cell([length(util_low),length(util_high)]);
harq = cell([length(util_low),length(util_high)]);
powerState = cell([length(util_low),length(util_high)]);

for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		filename = sprintf('utilLo_%s-utilHi_%s.mat',int2str(util_low(j)),int2str(util_high(k)));
		metrics  = load(strcat('results\',filename));

		powerConsumed{j,k} = metrics(1).SimulationMetrics.powerConsumed;
		util{j,k} = metrics(1).SimulationMetrics.util;
		thr{j,k} = metrics(1).SimulationMetrics.throughput;
		ber{j,k} = metrics(1).SimulationMetrics.ber;
		bler{j,k} = metrics(1).SimulationMetrics.bler;
		rsrq{j,k} = metrics(1).SimulationMetrics.rsrqdB;
		sinr{j,k} = metrics(1).SimulationMetrics.sinrdB;
		harq{j,k} = metrics(1).SimulationMetrics.harqRtx;
		powerState{j,k} = metrics(1).SimulationMetrics.powerState;
	
	end
end

%% Prepare the baseline (basically when we have no energy saving)
metricsBase  = load('results\utilLo_1-utilHi_100.mat');
powerConsumedBase = metricsBase(1).SimulationMetrics.powerConsumed;
utilBase = metricsBase(1).SimulationMetrics.util;
harqBase = metricsBase(1).SimulationMetrics.harqRtx;
thrBase = metricsBase(1).SimulationMetrics.throughput;

powerConsumedBaseTot = sum(mean(powerConsumedBase, 1));
utilTot = sum(mean(utilBase, 1));
thrBaseTot = sum(mean(thrBase, 1));
harqBaseTot = sum(harqBase(length(harqBase), :));

% Power saved 
figure;
title('Power saved (%)');
hold on;
savePercent = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		powerAllStations = cell2mat(powerConsumed(j,k));
		averageAllStations = mean(powerAllStations, 1);
		totalNetwork = sum(averageAllStations);
		savePercent(numel(util_high)*(j-1) + k) = 100*(1 - totalNetwork/powerConsumedBaseTot);
		legendStr = strcat(num2str(util_low(j)), '/', num2str(util_high(k)));
		utilLegend{numel(util_high)*(j-1) + k} = legendStr;
	end
end
bar(savePercent);
legend(utilLegend);

% HARQ 
figure;
title('Reduction of HARQ retransmissions (%)');
hold on;
harqPercent = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		harqAllStations = cell2mat(harq(j,k));
		harqTot = sum(harqAllStations(length(harqAllStations), :));
		harqPercent(numel(util_high)*(j-1) + k) = 100*(1 - harqTot/harqBaseTot);
		legendStr = strcat(num2str(util_low(j)), '/', num2str(util_high(k)));
		utilLegend{numel(util_high)*(j-1) + k} = legendStr;
	end
end
bar(harqPercent);
legend(utilLegend);

% Throughput 
figure;
title('Throughput');
hold on;
thrTotal = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		thrAllUsers = cell2mat(thr(j,k));
		averageAllUsers = mean(thrAllUsers, 1);
		totalNetwork = sum(averageAllUsers);
		thrTotal(numel(util_high)*(j-1) + k) = totalNetwork;
		legendStr = strcat(num2str(util_low(j)), '/', num2str(util_high(k)));
		utilLegend{numel(util_high)*(j-1) + k} = legendStr;
	end
end

bar([thrBaseTot,thrTotal'] );
legend(utilLegend)


%% Raw plots
% Plot raw power consumption for all stations
num_rounds = length(cell2mat(powerConsumed(1,1)));
figure;
title('Average eNodeB power used (W)');
hold on;
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		power_all_stations = cell2mat(powerConsumed(j,k));
		for iNode = 1:size(power_all_stations,2)
			plot(1:num_rounds, power_all_stations(:,iNode));
			stationsLegend{iNode} = ['eNodeB ' num2str(iNode)];
		end
	end
end
legend(stationsLegend);

%%
% Plot raw util for all stations
num_rounds = length(cell2mat(util(1,1)));
figure;
title('Per eNodeB utilisation (%)');
hold on;
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		util_all_stations = cell2mat(util(j,k));
		for iNode = 1:size(util_all_stations,2)
			plot(1:num_rounds, util_all_stations(:,iNode));
		end
	end
end
legend(stationsLegend);

%%
% Plot raw throughput for all users
num_rounds = length(cell2mat(thr(1,1)));
figure;
title('Per UE throughput (Mbps)');
hold on;
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    thr_all_users = cell2mat(thr(j,k));
		for iNode = 1:size(thr_all_users,2)
			plot(1:num_rounds, thr_all_users(:,iNode)*10^-6);
			usersLegend{iNode} = ['UE ' num2str(iNode)];
		end
	end
end
legend(usersLegend);

%%
% Plot raw ber for all users
num_rounds = length(cell2mat(ber(1,1)));
figure;
title('Per UE BER');
hold on;
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    ber_all_users = cell2mat(ber(j,k));
		for iNode = 1:size(ber_all_users,2)
			plot(1:num_rounds, ber_all_users(:,iNode)*10^-6);
		end
	end
end
legend(usersLegend);

%%
% Plot raw rsrq for all users 
num_rounds = length(cell2mat(rsrq(1,1)));
figure;
title('Per UE RSRQ');
hold on;
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    rsrq_all_users = cell2mat(rsrq(j,k));
		for iNode = 1:size(rsrq_all_users,2)
			plot(1:num_rounds, rsrq_all_users(:,iNode));
		end
	end
end
legend(usersLegend);

%%
% Plot average network metrics
num_rounds = length(cell2mat(ber(1,1)));
figure;
title('Timeseries of aggregated average network metrics');
hold on;
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    ber_all_users = cell2mat(ber(j,k));
		thr_all_users = cell2mat(thr(j,k));
		pwr_all_stations = cell2mat(powerConsumed(j,k));
		util_all_stations = cell2mat(util(j,k));
		avBer = mean(ber_all_users, 2);
		avThr = mean(thr_all_users, 2)*10^-6;
		avPwr = mean(pwr_all_stations, 2);
		avUtil = mean(util_all_stations, 2);
		plot(1:num_rounds, avBer);
		plot(1:num_rounds, avThr);
		plot(1:num_rounds, avPwr);
		plot(1:num_rounds, avUtil);
	end
end
legend('Average UE BER','Average UE throughput (Mbps)', 'Average eNodeB power consumed (W)', 'Average eNodeB utilisation (%)');

%%
% Plot correlations for ue
num_rounds = length(cell2mat(ber(1,1)));
figure;
title('Correlation between BLER and RSRQ/SINR');
hold on;
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    bler_all_users = cell2mat(bler(j,k));
		rsrq_all_users = cell2mat(rsrq(j,k));
		sinr_all_users = cell2mat(sinr(j,k));
		avBler = mean(bler_all_users, 2);
		avSinr = mean(sinr_all_users, 2);
		avRsrq = mean(rsrq_all_users, 2);
		semilogx(avRsrq, log10(avBler));
		semilogx(avSinr, log10(avBler));
	end
end
