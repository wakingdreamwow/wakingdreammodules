-- Hyjal Hub fast-travel: "Druid of the Winds Lyalia" — central gossip NPC at Nordrassil
-- summit offering wind-travel to all 4 sub-zone hubs (S2-S5). Daniel-locked design:
-- "Es soll Flugpunkte geben" — implemented as SmartAI teleport (no DBC patch needed,
-- matches existing pattern in 17_attunement_giver_and_return.sql Return-Portal-Keeper).
-- Return-trip = self-fly via mod-fly-in-old-world (no per-sub-zone return NPC needed in v1,
-- avoids touching the hash-tracked 18/19/20_s3/s4/s5 SQL files).
-- enUS. Idempotent.

SET @LYALIA := 990049;
SET @MENU   := 60149;
SET @TEXT   := 60149;

DELETE FROM `creature` WHERE `id1`=@LYALIA;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@LYALIA;
DELETE FROM `creature_template` WHERE `entry`=@LYALIA;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@LYALIA AND `source_type`=0;
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@MENU;
DELETE FROM `gossip_menu` WHERE `MenuID`=@MENU;
DELETE FROM `npc_text` WHERE `ID`=@TEXT;

INSERT INTO `npc_text` (`ID`,`text0_0`,`text0_1`,`BroadcastTextID0`,`lang0`,`Probability0`,`em0_0`,`em0_1`,`em0_2`,`em0_3`,`em0_4`,`em0_5`)
VALUES (@TEXT,
 'The winds of Nordrassil obey the Druids of the Cycle, $N. Speak a sub-zone and I will call the gale to carry you. Returning is on your own wing - the Cycle teaches us that the path back is its own lesson.',
 '',0,0,1,1,1,1,1,1,1);

INSERT INTO `gossip_menu` (`MenuID`,`TextID`) VALUES (@MENU,@TEXT);
INSERT INTO `gossip_menu_option` (`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`) VALUES
 (@MENU,1,2,'Carry me to the Twisted Glade (S2).',1,1),
 (@MENU,2,2,'Carry me to the Shores of the Well (S3).',1,1),
 (@MENU,3,2,'Carry me to the Crater (S4).',1,1),
 (@MENU,4,2,'Carry me to the Smouldering Deep (S5).',1,1);

-- Druid female display 4249 (matches Cenarion Emissary / Hub lore-consistency)
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`gossip_menu_id`)
VALUES (@LYALIA,'Druid of the Winds Lyalia','Caller of the Cycle',80,80,35,1,1,768,7,'SmartAI',0,150,1,1,1,@MENU);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@LYALIA,0,4249,1.0,1,0);

-- SmartAI: gossip-select → teleport to matching sub-zone hub
-- event 62 = RECEIVE_GOSSIP_HELLO/SELECT; param1=MenuID, param2=OptionID
-- action 62 = TELEPORT; target_type=7=ACTION_INVOKER (the player)
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
 (@LYALIA,0,0,0,62,0,100,0,@MENU,1,0,0,62,1,0,0,0,0,0,7,0,0,0,0,5430.0,-3320.0,1650.0,4.5,'Lyalia: tele -> S2 Twisted Glade (Maevra)'),
 (@LYALIA,0,1,0,62,0,100,0,@MENU,2,0,0,62,1,0,0,0,0,0,7,0,0,0,0,5340.0,-3520.0,1574.0,2.0,'Lyalia: tele -> S3 Well Shores (Senara)'),
 (@LYALIA,0,2,0,62,0,100,0,@MENU,3,0,0,62,1,0,0,0,0,0,7,0,0,0,0,5430.0,-2860.0,1469.0,3.9,'Lyalia: tele -> S4 Crater (Ordanus)'),
 (@LYALIA,0,3,0,62,0,100,0,@MENU,4,0,0,62,1,0,0,0,0,0,7,0,0,0,0,4805.0,-1725.0,1152.0,2.5,'Lyalia: tele -> S5 Smouldering Deep (Thessaly)');

-- Spawn at the Hub plateau, central among the existing scouts (5358-5388 / -3360 to -3404)
-- guid 5301449 (sits between Sythel 5301448 and Maevra 5301450)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301449,@LYALIA,0,0,1,0,0,1,1,0,5370.000,-3370.000,1655.500,3.50,300,0,0,1,0,0,0,0,0,'',0,0,'Druid of the Winds Lyalia (Hub fast-travel)');
