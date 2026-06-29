-- Relocate the summit combat mobs off Ysera's steep slope (evade-loop) down to the flat WP1 threshold.
-- Runs after 01 (shades) + 06 (wisps); idempotent UPDATEs. NPCs (Ysera/Maldoran, immune) stay at the summit.
-- 8 Albtraum-Schemen (Q1) -> NW cluster at WP1
UPDATE `creature` SET position_x=5192,position_y=-3314,position_z=1643.5,orientation=1.0,map=1 WHERE guid=5300683;
UPDATE `creature` SET position_x=5198,position_y=-3314,position_z=1643.5,orientation=1.5,map=1 WHERE guid=5300684;
UPDATE `creature` SET position_x=5188,position_y=-3318,position_z=1643.5,orientation=2.0,map=1 WHERE guid=5300685;
UPDATE `creature` SET position_x=5196,position_y=-3320,position_z=1643.5,orientation=2.5,map=1 WHERE guid=5300686;
UPDATE `creature` SET position_x=5192,position_y=-3322,position_z=1643.5,orientation=3.0,map=1 WHERE guid=5300687;
UPDATE `creature` SET position_x=5200,position_y=-3316,position_z=1643.5,orientation=0.5,map=1 WHERE guid=5300688;
UPDATE `creature` SET position_x=5186,position_y=-3314,position_z=1643.5,orientation=1.2,map=1 WHERE guid=5300689;
UPDATE `creature` SET position_x=5202,position_y=-3312,position_z=1643.5,orientation=2.2,map=1 WHERE guid=5300690;
-- 6 Verdorbene Wisps (QA2) -> SW cluster at WP1
UPDATE `creature` SET position_x=5190,position_y=-3332,position_z=1643.5,orientation=1.0,map=1 WHERE guid=5301201;
UPDATE `creature` SET position_x=5196,position_y=-3336,position_z=1643.5,orientation=1.5,map=1 WHERE guid=5301202;
UPDATE `creature` SET position_x=5188,position_y=-3336,position_z=1643.5,orientation=2.0,map=1 WHERE guid=5301203;
UPDATE `creature` SET position_x=5194,position_y=-3330,position_z=1643.5,orientation=2.5,map=1 WHERE guid=5301204;
UPDATE `creature` SET position_x=5200,position_y=-3338,position_z=1643.5,orientation=3.0,map=1 WHERE guid=5301205;
UPDATE `creature` SET position_x=5186,position_y=-3330,position_z=1643.5,orientation=0.5,map=1 WHERE guid=5301206;
