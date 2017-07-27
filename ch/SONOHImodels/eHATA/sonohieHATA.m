classdef sonohieHATA
    
    properties
        Channel;
    end
    
    methods
        
        function obj = sonohieHATA(Channel)
            obj.Channel = Channel;
            
        end
        
        function Users = run(obj,Stations,Users)
            users  = [Stations.Users];
            numLinks = nnz(users);
            
            Pairing = obj.Channel.getPairing(Stations);
            
            for i = 1:numLinks
                station = Stations(Pairing(1,i));
                % Local copy for mutation
                user = Users(find([Users.UeId] == Pairing(2,i)));
                
                try
                
                if strcmp(obj.Channel.fieldType,'full')
                    user.RxWaveform = obj.addFading([...
                        station.TxWaveform;zeros(25,1)],station.WaveformInfo);
                    
                    
                    
                    %interLossdB = obj.getInterference(Stations,station,Users(Pairing(2,i)));
                    
                    [user.RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
                        station,user,user.RxWaveform);
                    
                    
                  
                    
                elseif strcmp(obj.Channel.fieldType,'pathloss')
                    [user.RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
                        station,user,user.RxWaveform);
                    
                end
                
                user.RxInfo.SNRdB = 10*log10(SNRLin);
                user.RxInfo.rxPw = rxPw;
                
                catch ME
                    
                user.RxInfo.SNRdB = NaN;
                user.RxInfo.rxPw = NaN;    
                    
                end
                
                
                
                % Write changes to user object in array.
                Users(find([Users.UeId] == Pairing(2,i))) = user; 
                
            end
            
            
            
        end
        
        function rx = addFading(obj,tx,info)
            
           
            cfg.SamplingRate = info.SamplingRate;
            cfg.Seed = 1;                  % Random channel seed
            cfg.NRxAnts = 1;               % 1 receive antenna
            cfg.DelayProfile = 'EPA';      % EVA delay spread
            cfg.DopplerFreq = 5;         % 120Hz Doppler frequency
            cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
            cfg.InitTime = 0;              % Initialize at time zero
            cfg.NTerms = 16;               % Oscillators used in fading model
            cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
            cfg.InitPhase = 'Random';      % Random initial phases
            cfg.NormalizePathGains = 'On'; % Normalize delay profile power
            cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas
            % Pass data through the fading channel model
            rx = lteFadingChannel(cfg,tx);
            
            
        end
        
        function [rxSig, SNRLin, rxPw] = addPathlossAwgn(obj,Station,User,txSig,varargin)
            thermalNoise = obj.Channel.ThermalNoise(Station.NDLRB);
            hbPos = Station.Position;
            hmPos = User.Position;
            distance = obj.Channel.getDistance(hbPos,hmPos)/1e3;
            
            %[lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.DlFreq, ...
            %  distance, hbPos(3), hmPos(3), obj.Region);
            
            [numPoints,distVec,elev_profile] = obj.getElevation(hbPos,hmPos);
            
            if numPoints == 0
                numPoints_scale = 1;
            else
                numPoints_scale = numPoints;
            end
            
            elev = [numPoints_scale; distVec(end)/(numPoints_scale); hbPos(3); elev_profile'; hmPos(3)];
            
            lossdB = ExtendedHata_PropLoss(Station.DlFreq, hbPos(3), ...
                hmPos(3), obj.Channel.Region, elev);
            
            txPw = 10*log10(Station.Pmax)+30; %dBm.
            
            rxPw = txPw-lossdB;
            % SNR = P_rx_db - P_noise_db
            rxNoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
            SNR = rxPw-rxNoiseFloor;
            SNRLin = 10^(SNR/10);
            str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
                Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
            sonohilog(str1,'NFO0');
            
            %% Apply SNR
            
            % Compute average symbol energy
            % This is based on the number of useed subcarriers.
            % Scale it by the number of used RE since the power is
            % equally distributed
            Es = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft)*Station.WaveformInfo.OfdmEnergyScale);
            
            % Compute spectral noise density NO
            N0 = 1/(Es*SNRLin);
            
            % Add AWGN
            
            noise = N0*complex(randn(size(txSig)), ...
                randn(size(txSig)));
            
            rxSig = txSig + noise;
            
        end
        
        function [numPoints,distVec,elavationProfile] = getElevation(obj,txPos,rxPos)
            elavationProfile(1) = 0;
            distVec(1) = 0;
            
            % Check if x and y are equal
            
            if txPos(1:2) == rxPos(1:2)
                numPoints = 0;
                distVec = 0;
                elavationProfile = 0;
                
                
            else
                
           
            
            % Walk towards rxPos
            signX = sign(rxPos(1)-txPos(1));
            signY = sign(rxPos(2)-txPos(2));
            avgG = (txPos(1)-rxPos(1))/(txPos(2)-rxPos(2))+normrnd(0,0.01); %Small offset
            position(1:2,1) = txPos(1:2);
            i = 2;
            max_i = 10e4;
            numPoints = 0;
            resolution = 0.05; % Given in meters
         
            while true
                if i >= max_i
                    break;
                end
                
                % Check current distance
                distance = norm(position(1:2,i-1)'-rxPos(1:2));
                
                % Move position
                [moved_dist,position(1:2,i)] = move(position(1:2,i-1),signX,signY,avgG,resolution);
                distVec(i) = distVec(i-1)+moved_dist;
                
                % Check if new position is at a greater distance, if so, we
                % passed it.
                distance_n = norm(position(1:2,i)'-rxPos(1:2));
                if distance_n >= distance
                    break;
                else
                    % Check if we're inside a building
                    fbuildings_x = obj.Channel.Buildings(obj.Channel.Buildings(:,1) < position(1,i) & obj.Channel.Buildings(:,3) > position(1,i),:);
                    fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);
                    
                    if ~isempty(fbuildings_y)
                        elavationProfile(i) = fbuildings_y(5);
                        if elavationProfile(i-1) == 0
                            numPoints = numPoints +1;
                        end
                    else
                        elavationProfile(i) = 0;
                        
                    end
                end
                i = i+1;
                
                 end

            end
            
            
            
            function [distance,position] = move(position,signX,signY,avgG,moveS)
                if abs(avgG) > 1
                    moveX = abs(avgG)*signX*moveS;
                    moveY = 1*signY*moveS;
                    position(1) = position(1)+moveX;
                    position(2) = position(2)+moveY;
                    
                else
                    moveX = 1*signX*moveS;
                    moveY = (1/abs(avgG))*signY*moveS;
                    position(1) = position(1)+moveX;
                    position(2) = position(2)+moveY;
                end
                distance = sqrt(moveX^2+moveY^2);
            end
            
        end
        
        
        
        
        
        
        
    end
    
    
    
    
    
end