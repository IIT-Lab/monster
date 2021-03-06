![MONSTeR](https://raw.githubusercontent.com/Sonohi/monster/master/docs/resources/graphics/monster.png)

Checkout the documentation [here](https://sonohi.github.io/monster/)

# Introduction #
MONSTeR (MObile Networks SimulaToR) is a framework built around the LTE system toolbox available in Matlab.
It uses functions from the toolbox to perform complete DL and UL processing of the main data channel.
It also simulates a multi-UE and multi-eNodeB scenario.
The entire framework is in **alpha** and updated frequently. 
If you encounter bugs or some unexpected behaviour, please open an issue.
Contributors are welcome and encouraged! We have an always-growing number of feature requests, so feel free to pick or just go ahead with your own.

# Environment requirements #
Matlab (tested version is R2017B) and included [LTE system toolbox](https://se.mathworks.com/products/lte-system.html).

# Features 
MONSTeR is intended modular, however built around a main simulation loop which has a granularity of 2 LTE resource blocks, e.g. one scheduling round.

The loop is split into three major parts, a transmitter, a channel and a receiver. Major features are listed below:

* Different traffic models (e.g. full buffer and video streaming)
* Multiple mobility patterns (pedestrian, vehicular)
* Customizable network layout and scenarios (number of sites, users, tiers of base stations and presence of buildings)
* Automatic Repeat reQuest (ARQ) and Hybrid Automatic Repeat reQuest (HARQ) for fast retransmissions
* Packets re-ordering at receiver using SeQuence Numbers (SQNs)
* Multi-user scheduling with customizable algorithms (e.g. greedy round robin)
* Complete Down Link Shared CHannel (DL-SCH) and Physical Downlink Shared CHannel (PDSCH) processing chain
* Generation of LTE-compliant Downlink and Uplink resource grid
* Complete Uplink Shared CHannel (UL-SCH) and Physical Uplink Shared CHannel (PUSCH) processing chain
* Different channel models and independent ones for UL and DL
* eNodeB power consumption tracking and load-based autonomous sleeping mode for energy saving

# Getting started

* Set all paths needed for matlab to operate by running `sonohi`

The framework can be run as a CLI:
* Set configurations in `initParam.m`
* Save configurations by running `initParam.m`
* Run simulations by running `main.m`
* This executes the simulation script which contains the main loop.
* After the simulation is done, results are saved in the results folder

Alternatively, a Matlab app is provided where the majority of the parameters in the `initParam` file are available.
The file is called **monster.mlapp** at the root of the repo and runs the default folder loading at startup.

## Assumptions
As of 02.2018 the follwing assumptions are made for ease of implementation:

* Full synchronization
* Perfect backhaul (not for long :) )

## Initial Requirements

* Map layout with x,y,z coordinates given in meters.
* Number of `Users` and their positions (currently initialized as random)
* Number of `Stations` and their types.

### Downlink

See `enbTransmitterModule.m` and `ueReceiverModule.m`

#### Transmitter

* (Initial) User association based on basic path loss
* CellID broadcast BCH
* PSS and SSS signals for synchronization.
* Realistic scheduling using non-full buffers
* Power tracking of eNBs
* OFDM modulation based on number of RBs

#### Channel

Currently two modes:

`eHATA`

* For path loss: Extended Okumura Hata model [[1]](https://github.com/usnistgov/eHATA)
* For fading: MATLAB lteFading based on 3GPP fading requirements

`winner`

WINNER II is implemented as a toolbox in MATLAB [[2]](https://se.mathworks.com/matlabcentral/fileexchange/59690-winner-ii-channel-model-for-communications-system-toolbox) which enables highly customizable propagation scenarios.

Please note, no MIMO is supported yet.

`ITU1546`

* For path loss: ITU implementation [[3]](https://www.itu.int/en/ITU-R/study-groups/rsg3/Pages/iono-tropo-spheric.aspx)
* For fading: MATLAB lteFading channel based on 3GPP fading requirements.

#### Receiver

* Channel estimation
* Channel equalization
* EVM computation
* CQI selection


## Uplink
The uplink is currently in development and it is simply configured in back-to-back mode.

## Simulation batches
The project includes also some utilities to run batches of simulations in parallel for a set of parameters.
There are some sample cases in the folder `batches/`, while the main script that initiate the batches is called `batch_main.m` at the root of the project.
Each simulation is wrapped in a `try-catch` statement to limit the error propagation in case of failure.
All logs in batched simulations are re-directed to file by default and they are located in `logs/`. This can be changed within the specific batch file.

## Performance metrics
The framework uses a class for taking care of recording performance metrics from the simulations.
The details of this class can be found in `/results/MetricRecorder.m`.
The key concepts are that one defines a class property for each of the metrics that are deemed interesting to record throughout the simulations (e.g. *powerConsumed* for the power consumed by an eNodeB).
In additions to this, one has also to define a method with which such metric is recorded.
See for example the method *recordPower* that takes care of recording the power consumed by the eNodeB.
Finally, a metric is typically a UE-side metric or an eNodeB-side metric. 
To ease the code and make it more scalable, there are 2 wrapper methods that are the only ones called from the main simulation loop. 
These are `recordEnbMetrics` and `recordUeMetrics`. When a new metric is added, the metric-recording method should be called from inside one of these 2 directly.
As regards the structure of the data produced, they are normally recorded once per scheduling round, thus rows represent the time evolution of the metric in the simulation. Columns on the other hand. represent either the number of UEs, or those of the eNodeBs, depending on the metric.

# Licence
**MONSTer** is release under **MIT** licence available in copy at the root of the repository.

