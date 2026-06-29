-- S2 hub-scout: Glade-Walker Sythel in the Nordrassil Hub.
-- Mirrors the pattern of 990045/46/47 (S3/S4/S5 scouts) but points players
-- toward Sentinel Maevra and the Twisted Glade (S2). Soft-gate via gossip only,
-- no quest hook — scout just gives directional flavor.
-- enUS. Idempotent.

SET @SCOUT_GLADE2 := 990048;
SET @GOSSIP       := 60148;
SET @TEXTID       := 60148;

DELETE FROM `creature` WHERE `id1`=@SCOUT_GLADE2;
DELETE FROM `creature_template_model` WHERE `CreatureID`=@SCOUT_GLADE2;
DELETE FROM `creature_template` WHERE `entry`=@SCOUT_GLADE2;
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@GOSSIP;
DELETE FROM `gossip_menu` WHERE `MenuID`=@GOSSIP;
DELETE FROM `npc_text` WHERE `ID`=@TEXTID;

-- Greeting text (broadcast 0, just inline text)
INSERT INTO `npc_text` (`ID`,`text0_0`,`text0_1`,`BroadcastTextID0`,`lang0`,`Probability0`,`em0_0`,`em0_1`,`em0_2`,`em0_3`,`em0_4`,`em0_5`)
VALUES (@TEXTID,
 'I walked the eastern shelf last sunrise, $N. The Twisted Glade is not what it was - the satyrs of the Twistshade have woken, and an Ancient has gone wrong at its heart. Sentinel Maevra holds the line. Find her, and she will set you on the trail.',
 '',0,0,1,1,1,1,1,1,1);

-- Gossip menu (1 option, NPC quest-flagged but quest sits with Maevra)
INSERT INTO `gossip_menu` (`MenuID`,`TextID`) VALUES (@GOSSIP,@TEXTID);
INSERT INTO `gossip_menu_option` (`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`) VALUES
 (@GOSSIP,1,0,'Which way to Sentinel Maevra?',1,1);

-- Creature template (gossip-only, immune, faction 35)
-- Display 4249 = night-elf druid male (matches Cenarion Emissary, lore-consistent)
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`gossip_menu_id`)
VALUES (@SCOUT_GLADE2,'Glade-Walker Sythel','Watcher of the Twisted Glade',80,80,35,1,1,768,7,'',0,150,1,1,1,@GOSSIP);
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (@SCOUT_GLADE2,0,4249,1.0,1,0);

-- Spawn on the hub plateau (z=1655.5, eastern edge — pointing toward S2 to the NE)
INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
 (5301448,@SCOUT_GLADE2,0,0,1,0,0,1,1,0,5395.000,-3375.000,1655.500,1.20,300,0,0,1,0,0,0,0,0,'',0,0,'Glade-Walker Sythel (S2 hub-scout)');
