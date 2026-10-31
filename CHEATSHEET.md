# GM Command Cheatsheet

AzerothCore (3.3.5a) commands. Type them in-game (chat box, prefixed with `.`) or in the worldserver console (`./azeroth console`, no dot needed for most).

- `.help <command>` shows syntax for any command; `.commands` lists what your GM level allows.
- Many commands act on your **current target**; with no target they act on you.
- Console-only account commands are marked 🖥️.

## Accounts 🖥️

```
account create <name> <password>
account set password <name> <pw> <pw>
account set gmlevel <name> <level> -1     # level 0-3; -1 = all realms
account onlinelist
account lock country|ip <name> on|off
ban account <name> <time> <reason>        # e.g. 7d, 1h, -1 = permanent
unban account <name>
```

GM levels: `0` player, `1` moderator, `2` game master, `3` administrator.

## Getting around

```
.gm on | off                  # GM mode (flags, invulnerable, no cooldowns on some)
.gm visible on | off          # become invisible to players
.gm fly on | off
.gm chat on | off             # GM tag in chat
.gm ingame                    # list GMs online
.appear <player>              # teleport to player
.summon <player>              # pull player to you
.groupsummon <player>         # pull player's whole group
.tele <location>              # e.g. .tele stormwind
.tele name <player> <location>
.tele add <name>              # save current spot
.tele del <name>
.tele group <location>
.worldport <mapId> <x> <y> <z> [o]
.go xyz <x> <y> <z> [map]
.go creature <guid>
.go object <guid>
.go zonexy <x> <y> [zone]
.modify speed all <1-50>      # run/swim/fly speed
.recall / .gps                # show coordinates, map, zone, area
.unstuck <player> inn|graveyard|startzone
```

## Character

```
.levelup [n]                  # +n levels (negative to reduce); .character level <n>
.modify money <copper>        # 10000 = 1g; negative removes
.modify hp|mana|rage|energy <n>
.modify scale <0.1-10>
.modify faction <id>
.modify talentpoints <n>
.modify drunk <0-100>
.modify mount <displayId> <speed>
.demorph
.morph <displayId>
.character rename <player>    # force rename on next login
.character customize|changefaction|changerace <player>
.character titles <player>
.character deleted list
.character deleted restore <guid|name> [newname] [account]
.reset talents|spells|stats|level|items|all <player>
.maxskill                     # max all skills of target
.learn all_myclass|all_myspells|all_mytalents|all_recipes
.learn <spellId>
.unlearn <spellId>
.setskill <skillId> <level> [max]
.additem <itemId> [count]
.additem <itemId> [count] [bonus]
.additemset <setId>
.lookup item <name>
.lookup spell <name>
.lookup skill <name>
.lookup title <name>
.title add|remove <id>
.aura <spellId>
.unaura <spellId> | all
.cast <spellId> [triggered]
.cooldown                     # clear all cooldowns on target
.revive
.die
.damage <n>
.kill
```

## Looking things up

```
.lookup creature <name>
.lookup object <name>
.lookup quest <name>
.lookup item <name>
.lookup itemset <name>
.lookup faction <name>
.lookup map <name>
.lookup area <name>
.lookup zone <name>
.lookup teleport <name>
.lookup player ip|account|email <value>
.lookup event <name>
.lookup taxinode <name>
```

Add `[nolimit]` or a full name to narrow large result lists.

## Quests

```
.quest add <id>
.quest complete <id>
.quest remove <id>
.quest reward <id>
.quest status <id> [player]
```

## Spawning and NPCs

```
.npc add <creatureId>                 # spawn (persists in DB)
.npc delete                           # delete targeted NPC
.npc info
.npc near [distance]
.npc move                             # move target to your position
.npc say|yell|whisper <text>
.npc set level <n>
.npc set phase <mask>
.npc set model <displayId>
.npc follow|unfollow
.npc tame
.npc playemote <emoteId>
.npc addvendor <itemId> [maxcount incrtime extcost]
.npc delvendor <itemId>
.npc addmove <guid> [wait]
.npc setmovetype <stay|random|way> [NODEL]
.gobject add <entry> [spawntimeSecs]
.gobject delete <guid>
.gobject near [distance]
.gobject move <guid> [x y z]
.gobject turn <guid>
.gobject info <entry>
.gobject target <entry>
.gobject activate <guid>
```

## Moderation

```
.mute <player> <minutes> [reason]
.unmute <player>
.kick <player> [reason]
.ban character|account|ip <target> <time> <reason>
.unban character|account|ip <target>
.baninfo account|character|ip <target>
.banlist account|character|ip [filter]
.freeze [player]
.unfreeze [player]
.pinfo [player]                       # account, IP, playtime, money, location
.mailbox
.send mail <player> "<subject>" "<body>"
.send items <player> "<subject>" "<body>" <itemId>[:count] ...
.send money <player> "<subject>" "<body>" <copper>
.send message <player> <text>
.announce <text>                      # server-wide message in chat
.nameannounce <text>                  # same, prefixed with GM name
.notify <text>                        # server-wide on-screen message
.channel set ownership <channel> on|off
```

## Server and world

```
.server info
.server motd [text]
.server shutdown <seconds> [exitcode] [reason]
.server restart <seconds> [exitcode] [reason]
.server shutdown cancel
.server idlerestart <seconds>
.server set motd <text>
.server set closed on|off
.reload all                           # reload every table (slow)
.reload creature_template             # reload one table (any DB table name)
.reload config                        # worldserver.conf
.reload smart_scripts
.reload gameobject_template
.reload quest_template
.reload conditions
.reload item_template
.reload spell_dbc
.reload all_loot
.reload all_scripts
.saveall
.save
.event info
.event activelist
.event start|stop <eventId>
.wchange <type> <grade>               # force weather: 1 fog, 2 rain, 3 snow, 4 storm; 0-1 grade
.cometome                             # target NPC moves toward you
.tickets
.ticket list|viewid|assign|close|delete
```

## Visibility, Phasing and Debug

```
.phase <mask>
.debug anim <id>
.debug play sound <id>
.debug play music <id>
.debug play cinematic <id>
.debug area
.debug setvalue <field> <value>
.debug getvalue <field>
.debug moveflags
.debug threat
.wp add|show|modify|unload
.list creature <entry> [count]
.list object <entry> [count]
.list item <entry> [count]
.list mail <player>
.list auras
.getvalue <field> / .setvalue <field> <value>
.showarea <id>
.hidearea <id>
.explorecheat <on|off>
.waterwalk on | off
```

## Guilds, Groups and Arena

```
.guild create <leader> "<name>"
.guild delete "<name>"
.guild invite|uninvite <player> "<name>"
.guild rank <player> <rankId>
.guild rename "<old>" "<new>"
.guild info <name>
.group list <player>
.group leader|disband|remove <player>
.group join <player> <leader>
.arena create <leader> "<name>" <2v2|3v3|5v5>
.arena disband <teamId>
.arena rename "<old>" "<new>"
.arena captain "<team>" <player>
.arena info <teamId>
.arena lookup <name>
```

## Useful IDs

| What | ID |
|------|----|
| Gold | `.modify money 100000000` = 10000g |
| Hearthstone | item `6948` |
| Flying mount (Swift Flight Form) | spell `40120` |
| Stormwind | `.tele stormwind` |
| Orgrimmar | `.tele orgrimmar` |
| Dalaran | `.tele dalaran` |
| Shattrath | `.tele shattrath` |
| GM Island | `.tele gmisland` |

IDs not listed here: use `.lookup <type> <name>`.

## Tips

- Chain with a **target**: click an NPC/player first, then `.npc info`, `.pinfo`, `.die`, `.revive`.
- Shift-click an item or spell link in chat to paste its ID into the command line.
- After editing DB tables directly, run the matching `.reload <table>` instead of restarting.
- Log in to the console with `./azeroth console`; detach with `Ctrl-P Ctrl-Q` (not `Ctrl-C`, which stops the server).
