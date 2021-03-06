function [procs] = harqTxBulk(Param, txId, rxList, timeNow)

% 	HARQ TX BULK is used to create a bulk of HARQ transmitters
%
%   Function fingerprint
%   Param			->	the simulation parameters
% 	txId			->	the unique ID of the transmitter
% 	rxList		->	a list of intended receivers	
%		timeNow		-> 	current simulation time
%
% 	procs		->  transmitter processes

	% The timestamp passed to the constructor is 0 as this bulk is called at setup 
	for iRx = 1:length(rxList)
		procs(iRx) = HarqTx(Param, txId, rxList(iRx), timeNow);
	end
end
