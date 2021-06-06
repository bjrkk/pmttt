# pmTTT
A stupid simple GMOD Lua script dedicated to having custom playermodels for TTT/TTT2.

## ConCommands
```
ttt_pm_enable <1/0>             - Enable or disable pmTTT
ttt_pm_randbodygroups <1/0>     - Picks random bodygroups depending on the order type
ttt_pm_randskin <1/0>           - Picks a random skin value depending on the order type
ttt_pm_ordertype <-1/0/1/2>     - This sets the order type for playermodels. 
                                  -1 will always pick the first playermodel from the list
                                   0 will always pick the playermodel depending on the players UserID
                                   1 will pick the randomly picked playermodel from when the player initially spawned.
                                   2 will pick a new random playermodel for every player on a new round.
ttt_pm_reloadconfig             - Upon execution, it'll reload the configuration file.
```

## Usage
Drop these folders inside of your `garrysmod` folder, and then edit the config file located in `data/pmttt_config.json`.

The format of the config is very simple and easy. 
Taking a look at the default config JSON, we can see the root has 3 objects: `terror`, `detective`, and `maps`. `terror` contains a string array of all playermodels for non-detectives, while `detective` contains the ones specifically for the detective. `maps` define map-specific playermodels; every object name contains the name of the map that the user may want to apply their custom settings to.
