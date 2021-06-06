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
Taking a look at the default config JSON, we can see that there are role-specific configurations inside `maps`, which will load the playermodels inside there if the current map is located in the list. Outside of `maps` are the default configurations. Inside of them contain string arrays containing the modelpaths for the specific roles. If using TTT2, you can run `ttt_roles_index` in console to get a list of all your installed roles. For TTT1, stick to using only `innocent`, `traitor` and `detective`. If a role isn't specified, it'll either pick the playermodels for `innocent` (or whatever the first role is if using TTT2), or the first role specified in the list.
