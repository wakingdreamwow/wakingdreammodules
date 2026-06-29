-- Hyjal attunement: slay the 4 Emerald dragons -> portal to Hyjal. + Maldoran gossip-teleport TEST (quest-gated). Idempotent.
SET @Q:=990054; SET @ARCH:=990040; SET @MENU:=60100;

-- dragons stationary (stop roaming so they never block the portal spot)
UPDATE `creature` SET `spawntimesecs`=1800 WHERE `id1` IN (14887,14888,14889,14890);
UPDATE `creature` SET `MovementType`=0,`wander_distance`=0 WHERE `id1` IN (14887,14888,14889,14890);

-- attunement quest: kill the 4 emerald dragons
DELETE FROM `quest_offer_reward` WHERE `ID`=@Q;
DELETE FROM `quest_request_items` WHERE `ID`=@Q;
DELETE FROM `quest_template_addon` WHERE `ID`=@Q;
DELETE FROM `quest_template` WHERE `ID`=@Q;
INSERT INTO `quest_template` (`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`RewardXPDifficulty`,`RewardMoney`,`AllowableRaces`,`LogTitle`,`QuestDescription`,`ObjectiveText1`,`RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,`ObjectiveText2`,`RequiredNpcOrGo2`,`RequiredNpcOrGoCount2`,`ObjectiveText3`,`RequiredNpcOrGo3`,`RequiredNpcOrGoCount3`,`ObjectiveText4`,`RequiredNpcOrGo4`,`RequiredNpcOrGoCount4`)
VALUES (@Q,2,80,80,0,500000,0,'Der Ruf der Smaragddrachen',
 'Vier Drachen aus Yseras Schwarm bewachen die Traum-Portale zu Hyjal - doch der Albtraum hat sie verdorben. Erschlage Ysondre, Lethon, Emeriss und Taerar, $N, und die Portale zum Weltenbaum werden sich dir oeffnen.',
 'Ysondre erschlagen',14887,1,'Lethon erschlagen',14888,1,'Emeriss erschlagen',14889,1,'Taerar erschlagen',14890,1);
INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES (@Q,'Die Waechter sind gefallen. Spuerst du es? Die Traum-Portale erwachen - der Weg nach Hyjal steht dir offen, Held.');
INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES (@Q,'Noch lebt einer der vier Drachen, $N. Erst wenn alle gefallen sind, oeffnen sich die Portale.');

-- Maldoran gossip-teleport TEST (quest-gated): only shows the option if attunement (990054) is rewarded
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@MENU;
DELETE FROM `gossip_menu` WHERE `MenuID`=@MENU;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=@MENU;
DELETE FROM `smart_scripts` WHERE `entryorguid`=@ARCH AND `source_type`=0 AND `event_type`=62;
INSERT INTO `gossip_menu` (`MenuID`,`TextID`) VALUES (@MENU,1);
INSERT INTO `gossip_menu_option` (`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`) VALUES (@MENU,1,2,'Oeffne mir das Portal nach Hyjal, Archdruide.',1,1);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES (15,@MENU,1,0,0,8,0,@Q,0,0,0,0,0,'','Hyjal portal option only if attunement 990054 rewarded');
UPDATE `creature_template` SET `gossip_menu_id`=@MENU, `AIName`='SmartAI' WHERE `entry`=@ARCH;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES (@ARCH,0,10,0,62,0,100,0,@MENU,1,0,0,62,1,0,0,0,0,0,7,0,0,0,0,5373,-3379,1656,0,'Maldoran: gossip select -> teleport player to Nordrassil summit');

-- dragons onto terrain below their platform (sampler GroundZ)
UPDATE `creature` SET `position_z`=134.2 WHERE `guid`=32343;
UPDATE `creature` SET `position_z`=95.0 WHERE `guid`=52350;
UPDATE `creature` SET `position_z`=31.3 WHERE `guid`=50012;
UPDATE `creature` SET `position_z`=44.5 WHERE `guid`=4256;
