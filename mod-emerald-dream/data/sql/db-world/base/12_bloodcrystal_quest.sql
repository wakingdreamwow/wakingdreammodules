-- Bloodcrystal gather side-quest (custom lore: the Nightmare crystallizes the forest's lifeblood). Idempotent.
SET @CRYSTAL:=990060; SET @ITEM:=990060; SET @LOOT:=990060; SET @Q:=990053; SET @ARCH:=990040; SET @QA1:=990050;

DELETE FROM `quest_offer_reward` WHERE `ID`=@Q;
DELETE FROM `quest_request_items` WHERE `ID`=@Q;
DELETE FROM `creature_queststarter` WHERE `quest`=@Q;
DELETE FROM `creature_questender` WHERE `quest`=@Q;
DELETE FROM `quest_template_addon` WHERE `ID`=@Q;
DELETE FROM `quest_template` WHERE `ID`=@Q;
DELETE FROM `gameobject_loot_template` WHERE `Entry`=@LOOT;
DELETE FROM `gameobject_template` WHERE `entry`=@CRYSTAL;
DELETE FROM `item_template` WHERE `entry`=@ITEM;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 5400130 AND 5400145;

INSERT INTO `item_template` (`entry`,`class`,`subclass`,`name`,`displayid`,`Quality`,`Flags`,`BuyCount`,`InventoryType`,`Bonding`,`stackable`,`MaxCount`,`RequiredLevel`,`Description`,`VerifiedBuild`)
VALUES (@ITEM,12,0,'Pulsierende Blutkristall-Scherbe',7052,1,0,1,0,4,20,0,0,'Pulsiert im Takt eines fremden Herzschlags.',0);

INSERT INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`data0`,`data1`,`VerifiedBuild`)
VALUES (@CRYSTAL,3,7623,'Verderbter Blutkristall',1.2,0,@LOOT,0);
INSERT INTO `gameobject_loot_template` (`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
VALUES (@LOOT,@ITEM,0,100,1,1,0,1,1,'Blutkristall-Scherbe');

INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredItemId1`,`RequiredItemCount1`)
VALUES (@Q,2,80,80,0,200000,0,'Das geronnene Blut des Waldes',
 'Sieh diese Kristalle, $N - der Albtraum presst das Lebensblut des Waldes selbst zu pochenden Scherben. Sammle 6 Verderbte Blutkristalle entlang des Pfades, damit der Zirkel des Cenarius die Verderbnis studieren und laeutern kann.',
 'Verderbte Blutkristalle gesammelt',@ITEM,6);
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES (@Q,@QA1);
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (@ARCH,@Q);
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (@ARCH,@Q);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q,'Diese Scherben pochen noch... als lebten sie. Der Zirkel wird sie laeutern. Du hast dem Wald ein Stueck seines Schmerzes genommen, $N.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q,'Hast du genug Blutkristalle gesammelt, $N? Der Albtraum naehrt sich von jedem, den wir ihm lassen.');
-- harvestable bloodcrystals (ground-snapped)
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400130,990060,1,0,0,1,1,5360.000,-3382.000,1653.142,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400131,990060,1,0,0,1,1,5335.000,-3360.000,1656.263,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400132,990060,1,0,0,1,1,5310.000,-3370.000,1643.486,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400133,990060,1,0,0,1,1,5290.000,-3345.000,1653.612,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400134,990060,1,0,0,1,1,5265.000,-3358.000,1632.092,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400135,990060,1,0,0,1,1,5240.000,-3330.000,1647.741,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400136,990060,1,0,0,1,1,5215.000,-3340.000,1642.886,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400137,990060,1,0,0,1,1,5200.000,-3318.000,1643.745,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400138,990060,1,0,0,1,1,5230.000,-3350.000,1644.969,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400139,990060,1,0,0,1,1,5300.000,-3350.000,1654.930,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400140,990060,1,0,0,1,1,5340.000,-3375.000,1653.383,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
INSERT INTO `gameobject` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`,`Comment`) VALUES (5400141,990060,1,0,0,1,1,5275.000,-3360.000,1633.616,0.00,0,0,0,1,45,255,1,'',0,'questCrystal');
