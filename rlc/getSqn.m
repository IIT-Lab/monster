function [Station, sqn] = getSqn(Station, UeId, varargin)

%   GET SQN returns the next available SQN for the pair eNodeB & UE
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   UeId      	->  the id of the UE object
%   varargin		->  variable number of inputs 
%
%   sqn					->  the SQN assigned to this TB

	% Check if there are any options, otherwise assume default
	outFmt = 'd';
	if nargin > 2
		if varargin{1} == 'outFormat'
			outFmt = varargin{2};
		end
	end

	% Let's start by searching if this is a TB that is already being transmitted and
	% is already in the RLC buffer
	sqnTemp = -1;
	iUser = find([Station.Rlc.ArqTxBuffers.rxId] == UeId);
	[Station.Rlc.ArqTxBuffers(iUser), sqnTemp] = getNextSqn(Station.Rlc.ArqTxBuffers(iUser));

	% Finally check the output format and if binary pad to 10 bits in total
	if outFmt ~= 'd'
		sqn = de2bi(sqnTemp, 10, 'left-msb')';
	else
		sqn = sqnTemp;
	end
end