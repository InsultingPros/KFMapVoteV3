# Voting Handler Fix v3

[![GitHub all releases](https://img.shields.io/github/downloads/InsultingPros/KFMapVoteV3/total)](https://github.com/InsultingPros/KFMapVoteV3/releases)

Greylisted, yet a minor upgrade over Voting Handler Fix v2.

All credits to [Marco](https://steamcommunity.com/profiles/76561197975509070/). Check [`v2_legacy` branch](https://github.com/InsultingPros/KFMapVoteV3/tree/v2_legacy) for more details.

* Fixed a bug, when forcing a mapswitch as an admin was picking an initial voting.
* Maplist support.
* Minor fixes.

## Installation

```cpp
[Engine.GameInfo]
...
VotingHandlerType=KFMapVoteV3.KFVotingHandler
```

## Building and Dependancies

Use [KF Compile Tool](https://github.com/InsultingPros/KFCompileTool) for easy compilation.

**EditPackages**

```cpp
EditPackages=KFMapVoteV3
```

## Config Files

[KFMapVote.ini](Configs/KFMapVote.ini 'main config')
