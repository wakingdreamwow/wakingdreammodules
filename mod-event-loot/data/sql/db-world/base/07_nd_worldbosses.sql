-- =====================================================================
-- Northrend world bosses (entries 990121-990125). Open field spots near canonical
-- landmarks (away from hubs), level matched to local mob band. English names. Map 571.
-- Idempotent (DELETE+INSERT). HealthModifier = targetHP / basehp0(class1,level).
-- =====================================================================
DELETE FROM `creature`                WHERE `id1` IN (990121,990122,990123,990124,990125);
DELETE FROM `smart_scripts`           WHERE `source_type`=0 AND `entryorguid` IN (990121,990122,990123,990124,990125);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (990121,990122,990123,990124,990125);
DELETE FROM `creature_template`       WHERE `entry` IN (990121,990122,990123,990124,990125);
DELETE FROM `event_worldbosses`       WHERE `entry` IN (990121,990122,990123,990124,990125);

-- All ~level 80 so endgame chars also feel the bite. HP scaled per biome.
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`rank`,`DamageModifier`,`BaseAttackTime`,`unit_class`,`unit_flags`,`type`,`type_flags`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`)
VALUES
 (990121,'Bloodtusk the Ancient','Patriarch of the Tundra',74,74,14,0,3,3,2000,1,0,1,0,'SmartAI',0,90,1,1,1,0),         -- mammoth ~395k Lvl74
 (990122,'Frostfang Broodmother','Terror of the Fjord',73,73,14,0,3,3,2000,1,0,2,0,'SmartAI',0,90,1,1,1,0),               -- proto-drake ~396k Lvl73
 (990123,'Snarltooth the Berserker','Furbolg Chieftain',75,75,14,0,4,2,2000,1,0,7,0,'SmartAI',0,55,1,1,1,0),              -- furbolg ~256k Lvl75 rare
 (990124,'Verdantmaw','Tyrant of Sholazar',77,77,14,0,3,3,2000,1,0,1,0,'SmartAI',0,90,1,1,1,0),                            -- devilsaur ~450k Lvl77
 (990125,'Hrothgar the Stormclad','Niffelem Frost Giant',80,80,14,0,3,3,2000,1,0,11,0,'SmartAI',0,90,1,1,1,0);             -- giant ~495k Lvl80

INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES
 (990121,0,26423,1.6,1,0),  -- Wooly Mammoth Patriarch
 (990122,0,25141,1.4,1,0),  -- Proto-Drake Broodmother (already huge)
 (990123,0,23429,1.8,1,0),  -- Dire Furbolg (Northrend)
 (990124,0,28052,1.4,1,0),  -- King Krush (devilsaur, already huge)
 (990125,0,24531,1.4,1,0);  -- Niffelem Frost Giant (already huge)

-- Spawns: open field, away from FPs/towns
INSERT INTO `creature`
 (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
 (5300721,990121,0,0,571,0,0,1,1,0,3700,4200,8,0,300,0,0,400000,0,0,0,0,0,'',0,0,'ND WB nd1 Borean Tundra mammoth'),
 (5300722,990122,0,0,571,0,0,1,1,0,1500,-3000,80,0,300,0,0,400000,0,0,0,0,0,'',0,0,'ND WB nd2 Howling Fjord proto-drake'),
 (5300723,990123,0,0,571,0,0,1,1,0,4500,-3800,240,0,300,0,0,260000,0,0,0,0,0,'',0,0,'ND WB nd3 Grizzly Hills furbolg'),
 (5300724,990124,0,0,571,0,0,1,1,0,5500,5800,-80,0,300,0,0,450000,0,0,0,0,0,'',0,0,'ND WB nd4 Sholazar devilsaur'),
 (5300725,990125,0,0,571,0,0,1,1,0,6900,-1200,950,0,300,0,0,500000,0,0,0,0,0,'',0,0,'ND WB nd5 Storm Peaks giant');

INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`,`comment`) VALUES
 (990121,1,4,'nd1 Borean mammoth - elite, epic'),
 (990122,1,4,'nd2 Howling Fjord proto-drake - elite, epic'),
 (990123,0,3,'nd3 Grizzly Hills furbolg - rare, blue'),
 (990124,1,4,'nd4 Sholazar devilsaur - elite, epic'),
 (990125,1,4,'nd5 Storm Peaks frost giant - elite, epic');

-- abilities
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (990121,0,0,0,0,0,100,0,4000,7000,10000,14000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Bloodtusk - IC - Cleave'),
 (990121,0,1,0,0,0,100,0,8000,12000,14000,20000,0,0,11,6253,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Bloodtusk - IC - Trunk Toss (knockback)'),
 (990121,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Bloodtusk - <30% - Enrage'),

 (990122,0,0,0,0,0,100,0,3000,6000,8000,12000,0,0,11,12470,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Frostfang - IC - Frost Nova/AoE'),
 (990122,0,1,0,0,0,100,0,7000,10000,12000,17000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Frostfang - IC - Cleave'),
 (990122,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Frostfang - <30% - Enrage'),

 (990123,0,0,0,0,0,100,0,3000,6000,8000,12000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Snarltooth - IC - Cleave'),
 (990123,0,1,0,2,0,100,1,0,40,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Snarltooth - <40% - Enrage early'),

 (990124,0,0,0,0,0,100,0,3000,6000,8000,12000,0,0,11,31279,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Verdantmaw - IC - Swipe'),
 (990124,0,1,0,0,0,100,0,5000,9000,11000,16000,0,0,11,3427,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Verdantmaw - IC - Rending Bite (DoT)'),
 (990124,0,2,0,2,0,100,1,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Verdantmaw - <25% - Enrage'),

 (990125,0,0,0,0,0,100,0,4000,7000,9000,13000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Hrothgar - IC - Cleave'),
 (990125,0,1,0,0,0,100,0,7000,10000,12000,17000,0,0,11,6253,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Hrothgar - IC - Stomp (knockback)'),
 (990125,0,2,0,0,0,100,0,9000,13000,15000,20000,0,0,11,12470,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hrothgar - IC - Storm Nova'),
 (990125,0,3,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hrothgar - <30% - Enrage');
