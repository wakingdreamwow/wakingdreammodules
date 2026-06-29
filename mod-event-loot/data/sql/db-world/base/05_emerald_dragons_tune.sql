-- Smaragddrachen bot-farmbar: C++-Heal/Bann-Script abhaengen -> SmartAI (Atem + Enrage), HP senken.
UPDATE `creature_template` SET `ScriptName`='', `AIName`='SmartAI', `HealthModifier`=80 WHERE `entry` IN (14887,14888,14889,14890);
DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (14887,14888,14889,14890);
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`target_type`,`comment`) VALUES
(14887,0,0,0,0,0,100,0,7000,12000,10000,15000,11,24818,0,2,'Ysondre - Noxious Breath'),
(14887,0,1,0,2,0,100,0,0,30,0,0,11,8599,0,1,'Ysondre - Enrage <30%'),
(14888,0,0,0,0,0,100,0,7000,12000,10000,15000,11,24818,0,2,'Lethon - Noxious Breath'),
(14888,0,1,0,2,0,100,0,0,30,0,0,11,8599,0,1,'Lethon - Enrage <30%'),
(14889,0,0,0,0,0,100,0,7000,12000,10000,15000,11,24818,0,2,'Emeriss - Noxious Breath'),
(14889,0,1,0,2,0,100,0,0,30,0,0,11,8599,0,1,'Emeriss - Enrage <30%'),
(14890,0,0,0,0,0,100,0,7000,12000,10000,15000,11,24818,0,2,'Taerar - Noxious Breath'),
(14890,0,1,0,2,0,100,0,0,30,0,0,11,8599,0,1,'Taerar - Enrage <30%');
