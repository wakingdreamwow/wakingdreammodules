-- =====================================================================
-- Kalimdor world bosses (entries 990111-990115). Auto-placed at open field spots
-- (away from towns), level matched to local mob band. English names (enUS). Map 1.
-- Idempotent (DELETE+INSERT). HealthModifier = targetHP / basehp0(class1,level).
-- =====================================================================
DELETE FROM `creature`                WHERE `id1` IN (990111,990112,990113,990114,990115);
DELETE FROM `smart_scripts`           WHERE `source_type`=0 AND `entryorguid` IN (990111,990112,990113,990114,990115);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (990111,990112,990113,990114,990115);
DELETE FROM `creature_template`       WHERE `entry` IN (990111,990112,990113,990114,990115);
DELETE FROM `event_worldbosses`       WHERE `entry` IN (990111,990112,990113,990114,990115);

INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`rank`,`DamageModifier`,`BaseAttackTime`,`unit_class`,`unit_flags`,`type`,`type_flags`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`)
VALUES
 (990111,'Bloodmaw','Terror of the Barrens',12,12,14,0,4,2,2000,1,0,1,0,'SmartAI',0,240,1,1,1,0),          -- raptor ~59k (247*240) Lvl12
 (990112,'Gnarlroot the Defiled','Corrupted Ancient',24,24,14,0,3,3,2000,1,0,1,0,'SmartAI',0,245,1,1,1,0), -- ancient ~159k (651*245) Lvl24
 (990113,'Skullcrusher the Silverback','Beast of Feralas',45,45,14,0,3,3,2000,1,0,1,0,'SmartAI',0,108,1,1,1,0), -- gorilla ~200k (1848*108) Lvl45
 (990114,'Sandreaver','Scourge of Tanaris',46,46,14,0,4,2,2000,1,0,1,0,'SmartAI',0,73,1,1,1,0),            -- scorpid ~140k (1921*73) Lvl46
 (990115,'Frostmaw the Ravager','Terror of Winterspring',58,58,14,0,3,3,2000,1,0,1,0,'SmartAI',0,160,1,1,1,0); -- yeti ~459k (2871*160) Lvl58

INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES
 (990111,0,788,2.0,1,0),    -- Stranglethorn Raptor
 (990112,0,1461,2.0,1,0),   -- Ancient of War (treant)
 (990113,0,844,2.2,1,0),    -- Silverback Patriarch (gorilla)
 (990114,0,2487,2.3,1,0),   -- Armored Scorpid
 (990115,0,6767,2.0,1,0);   -- Giant Yeti

INSERT INTO `creature`
 (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
 (5300711,990111,0,0,1,0,0,1,1,0,763.2,-3913.1,18.7,0,300,0,0,70000,0,0,0,0,0,'',0,0,'KA WB ka1 Barrens raptor'),
 (5300712,990112,0,0,1,0,0,1,1,0,2984.8,-722.6,167.5,0,300,0,0,170000,0,0,0,0,0,'',0,0,'KA WB ka2 Ashenvale ancient'),
 (5300713,990113,0,0,1,0,0,1,1,0,-4523.9,640.9,56.4,0,300,0,0,210000,0,0,0,0,0,'',0,0,'KA WB ka3 Feralas gorilla'),
 (5300714,990114,0,0,1,0,0,1,1,0,-6988.9,-3553.6,14.5,0,300,0,0,150000,0,0,0,0,0,'',0,0,'KA WB ka4 Tanaris scorpid'),
 (5300715,990115,0,0,1,0,0,1,1,0,6749.8,-4215.7,706.7,0,300,0,0,470000,0,0,0,0,0,'',0,0,'KA WB ka5 Winterspring yeti');

INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`,`comment`) VALUES
 (990111,0,3,'ka1 Barrens raptor - rare, blue'),
 (990112,1,4,'ka2 Ashenvale ancient - elite, epic'),
 (990113,1,4,'ka3 Feralas gorilla - elite, epic'),
 (990114,0,3,'ka4 Tanaris scorpid - rare, blue'),
 (990115,1,4,'ka5 Winterspring yeti - elite, epic');

-- abilities (SmartAI). event 0=UPDATE_IC(init,init,repeat,repeat ms), 2=HEALTH_PCT(min,max). action 11=cast. target 2=victim,1=self.
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (990111,0,0,0,0,0,100,0,4000,7000,9000,13000,0,0,11,3427,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Bloodmaw - IC - Rend/bleed'),
 (990111,0,1,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Bloodmaw - <30% - Enrage'),
 (990112,0,0,0,0,0,100,0,3000,6000,9000,14000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Gnarlroot - IC - Cleave'),
 (990112,0,1,0,0,0,100,0,7000,10000,13000,18000,0,0,11,6253,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Gnarlroot - IC - Backhand'),
 (990112,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Gnarlroot - <30% - Enrage'),
 (990113,0,0,0,0,0,100,0,3000,6000,8000,12000,0,0,11,31279,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Skullcrusher - IC - Swipe'),
 (990113,0,1,0,0,0,100,0,6000,9000,12000,17000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Skullcrusher - IC - Cleave'),
 (990113,0,2,0,2,0,100,1,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Skullcrusher - <25% - Enrage'),
 (990114,0,0,0,0,0,100,0,4000,7000,10000,15000,0,0,11,3427,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Sandreaver - IC - Poison Sting'),
 (990114,0,1,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Sandreaver - <30% - Enrage'),
 (990115,0,0,0,0,0,100,0,4000,7000,9000,13000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Frostmaw - IC - Cleave'),
 (990115,0,1,0,0,0,100,0,7000,10000,12000,17000,0,0,11,6253,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Frostmaw - IC - Toss (knockback)'),
 (990115,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Frostmaw - <30% - Enrage');
