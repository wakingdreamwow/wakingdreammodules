-- =====================================================================
-- Eastern Kingdoms world bosses (entries 990101-990105) — Daniel-scouted spots.
-- Themed per Daniel: ek1 Elwynn forest beast (rare), ek2 Westfall gnoll warlord,
-- ek3 Duskwood undead colossus (rare), ek4 Wetlands hydra, ek5 Burning Steppes mini-Ragnaros.
-- All oversized vs. normal mobs of their kind. Idempotent (DELETE+INSERT). Map 0.
-- HealthModifier = targetHP / basehp0(class1,level): see comments.
-- =====================================================================

-- ---- clean ----
DELETE FROM `creature`                WHERE `id1` IN (990101,990102,990103,990104,990105);
DELETE FROM `smart_scripts`           WHERE `source_type`=0 AND `entryorguid` IN (990101,990102,990103,990104,990105);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (990101,990102,990103,990104,990105);
DELETE FROM `creature_template`       WHERE `entry` IN (990101,990102,990103,990104,990105);
DELETE FROM `event_worldbosses`       WHERE `entry` IN (990101,990102,990103,990104,990105);

-- ---- templates ----
-- rank: 4=rare(silver), 3=worldboss(elite). type: 1 beast,7 humanoid,6 undead,4 elemental. faction 14=hostile-to-all.
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`rank`,`DamageModifier`,`BaseAttackTime`,`unit_class`,`unit_flags`,`type`,`type_flags`,`AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`)
VALUES
 (990101,'Old Ironclaw','Terror of Goldshire',8,8,14,0,4,2,2000,1,0,1,0,'SmartAI',0,320,1,1,1,0),       -- bear  ~49.9k HP (156*320) Lvl8
 (990102,'Warlord Redpaw','Gnoll Chieftain',22,22,14,0,3,3,2000,1,0,7,0,'SmartAI',0,280,1,1,1,0),   -- gnoll ~157k  (562*280) Lvl22
 (990103,'Rotvein the Plague Colossus','Terror of Duskwood',35,35,14,0,4,2,2000,1,0,6,0,'SmartAI',0,125,1,1,1,0), -- undead ~152k (1220*125) Lvl35
 (990104,'Mudmaw the Three-Headed','Hydra of the Wetlands',50,50,14,0,3,3,2000,1,0,1,0,'SmartAI',0,92,1,1,1,0), -- hydra ~204k (2215*92) Lvl50
 (990105,'Emberlord Cinderspawn','Lesser Cousin of Ragnaros',58,58,14,0,3,3,2000,1,0,4,0,'SmartAI',0,160,1,1,1,0); -- fire ~459k (2871*160) Lvl58

-- ---- models (display IDs verified; DisplayScale = oversize factor vs normal mob) ----
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES
 (990101,0,762,2.2,1,0),    -- Grizzled Black Bear, big
 (990102,0,10790,2.3,1,0),  -- Riverpaw Overseer (gnoll), big
 (990103,0,1693,2.0,1,0),   -- Stitches abomination, big
 (990104,0,2423,2.0,1,0),   -- Strashaz Hydra (3-headed), big
 (990105,0,11121,0.5,1,0);  -- Ragnaros (mini cousin, still towering)

-- ---- spawns (coords = Daniel's .tele add ek1..ek5) ----
INSERT INTO `creature`
 (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
 (5300701,990101,0,0,0,0,0,1,1,0,-9702.96,135.253,47.6724,6.17885,300,0,0,60000,0,0,0,0,0,'',0,0,'EK WB ek1 Elwynn bear'),
 (5300702,990102,0,0,0,0,0,1,1,0,-11127.8,832.725,37.4164,2.97838,300,0,0,170000,0,0,0,0,0,'',0,0,'EK WB ek2 Westfall gnoll'),
 (5300703,990103,0,0,0,0,0,1,1,0,-10381.4,182.683,34.67,1.38717,300,0,0,160000,0,0,0,0,0,'',0,0,'EK WB ek3 Duskwood undead'),
 (5300704,990104,0,0,0,0,0,1,1,0,-10193.1,-3955.25,23.9502,4.23427,300,0,0,210000,0,0,0,0,0,'',0,0,'EK WB ek4 Wetlands hydra'),
 (5300705,990105,0,0,0,0,0,1,1,0,-7888.52,-1011.41,137.705,2.21826,300,0,0,470000,0,0,0,0,0,'',0,0,'EK WB ek5 Burning Steppes fire');

-- ---- roster (event_worldbosses): is_elite 0=rare/1=elite, loot_quality 3=blue/4=epic ----
INSERT INTO `event_worldbosses` (`entry`,`is_elite`,`loot_quality`,`comment`) VALUES
 (990101,0,3,'ek1 Elwynn bear - rare, blue'),
 (990102,1,4,'ek2 Westfall gnoll - elite, epic'),
 (990103,0,3,'ek3 Duskwood undead - rare, blue'),
 (990104,1,4,'ek4 Wetlands hydra - elite, epic'),
 (990105,1,4,'ek5 Burning Steppes Ragnaros-cousin - elite, epic');

-- ---- abilities (SmartAI). event 0=UPDATE_IC(init,init,repeat,repeat ms), 2=HEALTH_PCT(min%,max%), 4=AGGRO. action 11=cast. target 2=victim,1=self. ----
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- ek1 Old Ironclaw (bear, lvl10)
 (990101,0,0,0,0,0,100,0,4000,7000,9000,13000,0,0,11,31279,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Old Ironclaw - IC - Swipe'),
 (990101,0,1,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Old Ironclaw - <30% - Enrage'),
-- ek2 Warlord Redpaw (gnoll, lvl18)
 (990102,0,0,0,0,0,100,0,3000,6000,9000,14000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Warlord Redpaw - IC - Cleave'),
 (990102,0,1,0,0,0,100,0,7000,10000,13000,18000,0,0,11,6253,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Warlord Redpaw - IC - Backhand (knockback)'),
 (990102,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warlord Redpaw - <30% - Enrage'),
-- ek3 Rotvein the Plague Colossus (undead, lvl30)
 (990103,0,0,0,0,0,100,0,4000,7000,10000,15000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Rotvein - IC - Cleave'),
 (990103,0,1,0,0,0,100,0,6000,9000,12000,17000,0,0,11,3427,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Rotvein - IC - Infected Wound (disease DoT)'),
 (990103,0,2,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Rotvein - <30% - Enrage'),
-- ek4 Mudmaw the Three-Headed (hydra, lvl25)
 (990104,0,0,0,0,0,100,0,3000,6000,8000,12000,0,0,11,52307,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Mudmaw - IC - Hydra Sputum (acid)'),
 (990104,0,1,0,0,0,100,0,6000,10000,12000,18000,0,0,11,15496,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Mudmaw - IC - Cleave'),
 (990104,0,2,0,2,0,100,1,0,25,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Mudmaw - <25% - Enrage'),
-- ek5 Emberlord Cinderspawn (fire, lvl56)
 (990105,0,0,0,4,0,100,1,0,0,0,0,0,0,11,63778,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Emberlord - Aggro - Fire Shield (retaliation aura)'),
 (990105,0,1,0,0,0,100,0,4000,7000,9000,13000,0,0,11,12470,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Emberlord - IC - Fire Nova (AoE)'),
 (990105,0,2,0,0,0,100,0,7000,10000,12000,17000,0,0,11,66813,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Emberlord - IC - Lava Burst'),
 (990105,0,3,0,2,0,100,1,0,30,0,0,0,0,11,8599,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Emberlord - <30% - Enrage');
