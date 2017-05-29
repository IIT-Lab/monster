%   EVOLVED NODE B defines a value class for creating and working with eNodeBs

classdef EvolvedNodeB
	%   EVOLVED NODE B defines a value class for creating and working with eNodeBs
	properties
		NCellID;
		DuplexMode;
		Position;
		NDLRB;
		CellRefP;
		CyclicPrefix;
		CFI;
		PHICHDuration;
		Ng;
		NFrame;
		TotSubframes;
		OCNG;
		Windowing;
		Users;
		Schedule;
		RrNext;
		ReGrid;
		TxWaveform;
		PDSCH;
		Channel;
	end

	methods
		% Constructor
		function obj = EvolvedNodeB(Param, bsClass, cellId)
			switch bsClass
				case 'macro'
					obj.NDLRB = Param.numSubFramesMacro;
				case 'micro'
					obj.NDLRB = Param.numSubFramesMicro;
			end
			obj.NCellID = cellId;
			obj.CellRefP = 1;
			obj.CyclicPrefix = 'Normal';
			obj.CFI = 2;
			obj.PHICHDuration = 'Normal';
			obj.Ng = 'Sixth';
			obj.NFrame = 0;
			obj.TotSubframes = 1;
			obj.OCNG = 'On';
            obj.Windowing = 0;
			obj.DuplexMode = 'FDD';
			obj.RrNext = struct('ueId',0,'index',1);
			obj.TxWaveform = zeros(obj.NDLRB * 307.2, 1);
			obj = resetUsers(obj, Param);
			obj = resetSchedule(obj);
			obj = initResourceGrid(obj);
			obj = initPDSCH(obj);
            
            % Construct channel
            obj.Channel = ChBulk_v1(Param);
		end

		% Posiiton base station
		function obj = setPosition(obj, pos)
			obj.Position = pos;
            
            % Set position for channel configuration.
            obj.Channel.Tx_pos = pos;
        end
        


		% reset users
		function obj = resetUsers(obj, Param)
			temp(1:Param.numUsers) = struct('velocity', Param.velocity,...
				'queue', struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0, 'scheduled', ...
				false, 'ueId', 0, 'position', [0 0], 'wCqi',6);
			obj.Users = temp;
		end

		% reset schedule
		function obj = resetSchedule(obj)
			temp(1:obj.NDLRB,1) = struct('ueId', 0, 'mcs', 0, 'modOrd', 0);
			obj.Schedule = temp;
		end
	end

	methods (Access = private)
		% Set resource grid for eNOdeB
		function obj = initResourceGrid(obj)
			str = lteDLResourceGrid(struct(obj));
			obj.ReGrid = str;
		end

		% set PDSCH
		function obj = initPDSCH(obj)
			ch = struct('TxScheme', 'Port0', 'Modulation', {'QPSK'}, 'NLayers', 1, ...
				'Rho', -3, 'RNTI', 1, 'RVSeq', [0 1 2 3], 'RV', 0, 'NHARQProcesses', 8, ...
				'NTurboDecIts', 5, 'PRBSet', (0:obj.NDLRB-1)', 'TrBlkSizes', [], ...
				'CodedTrBlkSizes', [], 'CSIMode', 'PUCCH 1-0', 'PMIMode', 'Wideband', 'CSI', 'On');
			obj.PDSCH = ch;
		end

	end
end
