# Voting Handler Fix v3

Greylisted, yet a minor upgrade over Voting Handler Fix v2.

All credits to [Marco](https://steamcommunity.com/profiles/76561197975509070/). For reference you can use [v2 info](https://forums.tripwireinteractive.com/index.php?threads/mod-voting-handler-fix.43202/).

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

At the moment of 2021.03.27 there are no dependencies.

**EditPackages**

```cpp
EditPackages=KFMapVoteV3
```

## Config Files

[KFMapVote.ini](Configs/KFMapVote.ini 'main config')
