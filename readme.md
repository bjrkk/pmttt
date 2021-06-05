# pmTTT
A stupid simple GMOD Lua script dedicated to having custom playermodels for TTT/TTT2.

## CVars
```
ttt_pm_enable <1/0>             - Enable or disable pmTTT
ttt_pm_randbodygroups <1/0>     - Picks random bodygroups for every round
ttt_pm_ordertype <-1/0/1/2>     - This sets the order type for playermodels. 
                                  -1 will always pick the first playermodel from the list
                                   0 will always pick the playermodel depending on the players UserID
                                   1 will pick the randomly picked playermodel from when the player initially spawned.
                                   2 will pick a random playermodel everytime TTTPlayerSetColor gets called (usually will happen everytime the round starts)
```

## Usage
Drop these folders inside of your `garrysmod` folder, and then edit the config file located in `data/pmttt_config.json`.

The format of the config is very simple and easy. 
Taking a look at the default config JSON, we can see the root has 3 objects: `terror`, `detective`, and `maps`. `terror` contains a string array of all playermodels for non-detectives, while `detective` contains the ones specifically for the detective. `maps` define map-specific playermodels; every object name contains the name of the map that the user may want to apply their custom settings to.
