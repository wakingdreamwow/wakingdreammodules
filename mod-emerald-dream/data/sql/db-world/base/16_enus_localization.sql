-- enUS LOCALIZATION: all custom Hyjal/Emerald-Dream content to English. PROJECT RULE: enUS only, all in-game text English. Idempotent.
-- ===== creature names/subnames =====
UPDATE `creature_template` SET `name`='Ysera',`subname`='the Dreamer' WHERE `entry`=990011;
UPDATE `creature_template` SET `name`='Nightmare Shade',`subname`='' WHERE `entry`=990012;
UPDATE `creature_template` SET `name`='Nightmare Lord',`subname`='Tyrant of the Corrupted Dream' WHERE `entry`=990014;
UPDATE `creature_template` SET `name`='Warden of the Path',`subname`='Guardian of the Descent' WHERE `entry`=990015;
UPDATE `creature_template` SET `name`='Nightmare Beast',`subname`='' WHERE `entry`=990016;
UPDATE `creature_template` SET `name`='Corrupted Hippogryph',`subname`='' WHERE `entry`=990017;
UPDATE `creature_template` SET `name`='Naralassa',`subname`='the Dreamweaver' WHERE `entry`=990018;
UPDATE `creature_template` SET `name`='Gnarl',`subname`='the Nightmare Warden' WHERE `entry`=990019;
UPDATE `creature_template` SET `name`='Archdruid Maldoran',`subname`='Cenarion Circle' WHERE `entry`=990040;
UPDATE `creature_template` SET `name`='Corrupted Wisp',`subname`='' WHERE `entry`=990042;
UPDATE `creature_template` SET `name`='Cenarion Druid',`subname`='Defender of Hyjal' WHERE `entry`=990044;
UPDATE `creature_template` SET `name`='Nightmare Weaver',`subname`='Defiler of the Grove' WHERE `entry`=990045;
UPDATE `creature_template` SET `name`='Keeper of the Dream Portal',`subname`='Green Dragonflight' WHERE `entry`=990061;

-- ===== quest titles/descriptions/objectives/completion =====
UPDATE `quest_template` SET `LogTitle`='Shadows over the Emerald Dream',
 `QuestDescription`='The Nightmare seeps into the Dream. Destroy 8 Nightmare Shades around the clearing and weaken the grip of the Nightmare, $N.',
 `ObjectiveText1`='Nightmare Shades destroyed' WHERE `ID`=990020;
UPDATE `quest_template` SET `LogTitle`='The Corrupted Path',
 `QuestDescription`='The Nightmare wells up from the valley far below Nordrassil, $N. Descend the path and find the Warden of the Path. He guards the way into the corrupted heart of Hyjal and will show you onward.',
 `QuestCompletionLog`='Speak with the Warden of the Path at the start of the descent.' WHERE `ID`=990022;
UPDATE `quest_template` SET `LogTitle`='Brood of the Nightmare',
 `QuestDescription`='The path below teems with the creatures of the Nightmare, $N. Slay 10 Nightmare Beasts and 7 Corrupted Hippogryphs and carve your way into the valley.',
 `ObjectiveText1`='Nightmare Beasts slain',`ObjectiveText2`='Corrupted Hippogryphs slain' WHERE `ID`=990023;
UPDATE `quest_template` SET `LogTitle`='Wardens of the Nightmare',
 `QuestDescription`='Two mighty wardens bar the final stretch of the descent. Defeat Naralassa the Dreamweaver and Gnarl the Nightmare Warden. Only then will the valley floor lie open to you, $N.',
 `ObjectiveText1`='Naralassa defeated',`ObjectiveText2`='Gnarl defeated' WHERE `ID`=990024;
UPDATE `quest_template` SET `LogTitle`='The Nightmare Lord',
 `QuestDescription`='The shades were mere harbingers, $N. In the heart of the corrupted grove the Nightmare Lord himself holds court. Slay him and free the Emerald Dream from his reign of terror.',
 `ObjectiveText1`='Nightmare Lord slain' WHERE `ID`=990021;
UPDATE `quest_template` SET `LogTitle`='Arrival at the World Tree',
 `QuestDescription`='Be welcome at the foot of Nordrassil, $N. I am Maldoran, Archdruid of the Cenarion Circle. The World Tree has healed since the Battle of Mount Hyjal - yet new shadows stir. The Emerald Dream is corrupting, fire churns in the deep, and the scars of the Legion still fester in the crater. We need every hand.',
 `QuestCompletionLog`='Speak with Archdruid Maldoran at the summit.' WHERE `ID`=990050;
UPDATE `quest_template` SET `LogTitle`='First Signs',
 `QuestDescription`='Even here at the sacred summit the rot shows itself: corrupted wisps drift among the roots. Release 5 of them, $N, so we may gauge how far the Nightmare already reaches.',
 `ObjectiveText1`='Corrupted Wisps released' WHERE `ID`=990051;
UPDATE `quest_template` SET `LogTitle`='The Call of the Dream',
 `QuestDescription`='The source of the rot lies within the Emerald Dream itself. Only one can guide you there: Ysera, the Keeper of Dreams. She watches over the summit - step before her, $N, and follow her call down into the valley.',
 `QuestCompletionLog`='Speak with Ysera at the summit.' WHERE `ID`=990052;
UPDATE `quest_template` SET `LogTitle`='The Congealed Blood of the Forest',
 `QuestDescription`='Behold these crystals, $N - the Nightmare presses the very lifeblood of the forest into pulsing shards. Gather 6 Corrupted Bloodcrystals along the path so the Cenarion Circle may study and cleanse the corruption.',
 `ObjectiveText1`='Corrupted Bloodcrystals gathered' WHERE `ID`=990053;
UPDATE `quest_template` SET `LogTitle`='The Call of the Emerald Dragons',
 `QuestDescription`='Four dragons of the flight of Ysera guard the dream portals to Hyjal - but the Nightmare has corrupted them. Slay Ysondre, Lethon, Emeriss and Taerar, $N, and the portals to the World Tree shall open to you.',
 `ObjectiveText1`='Ysondre slain',`ObjectiveText2`='Lethon slain',`ObjectiveText3`='Emeriss slain',`ObjectiveText4`='Taerar slain' WHERE `ID`=990054;

-- ===== quest offer-reward text =====
UPDATE `quest_offer_reward` SET `RewardText`='Good that you have come, $N. Hyjal needs heroes more than ever - and you shall be one of them.' WHERE `ID`=990050;
UPDATE `quest_offer_reward` SET `RewardText`='Corrupted wisps, here at the sacred summit... The Nightmare reaches further than I feared. We must press on to the source.' WHERE `ID`=990051;
UPDATE `quest_offer_reward` SET `RewardText`='I have heard your steps in the Dream, mortal. Come closer - the Nightmare waits in the valley below, and you shall behold it.' WHERE `ID`=990052;
UPDATE `quest_offer_reward` SET `RewardText`='You have scattered the shades, yet these are but outrunners. Deeper in the grove lurks far worse.' WHERE `ID`=990020;
UPDATE `quest_offer_reward` SET `RewardText`='So a mortal dares the descent. Good. Beyond me the Nightmare begins - stay close to the path, or it will swallow you.' WHERE `ID`=990022;
UPDATE `quest_offer_reward` SET `RewardText`='You have carved your way through. The brood will regrow, but for now the path lies open.' WHERE `ID`=990023;
UPDATE `quest_offer_reward` SET `RewardText`='Naralassa and Gnarl have fallen - the last wardens before the heart of the Nightmare. What follows now is the Lord himself.' WHERE `ID`=990024;
UPDATE `quest_offer_reward` SET `RewardText`='The Nightmare Lord is vanquished. The Dream breathes again - thanks to you, hero of Hyjal. Yet remain watchful: the Nightmare never fully sleeps.' WHERE `ID`=990021;
UPDATE `quest_offer_reward` SET `RewardText`='These shards still pulse... as if alive. The Circle will cleanse them. You have taken a measure of pain from the forest, $N.' WHERE `ID`=990053;
UPDATE `quest_offer_reward` SET `RewardText`='The wardens have fallen. Do you feel it? The dream portals awaken - the way to Hyjal lies open, hero.' WHERE `ID`=990054;

-- ===== quest request-items (incomplete) text =====
UPDATE `quest_request_items` SET `CompletionText`='Have you released the wisps yet, $N? Their rot must not reach the summit.' WHERE `ID`=990051;
UPDATE `quest_request_items` SET `CompletionText`='The shades still waver, $N. Drive them off before you return.' WHERE `ID`=990020;
UPDATE `quest_request_items` SET `CompletionText`='The path still teems with beasts and hippogryphs, $N. Clear it.' WHERE `ID`=990023;
UPDATE `quest_request_items` SET `CompletionText`='The two wardens still live, $N. Without their fall the valley floor remains barred to you.' WHERE `ID`=990024;
UPDATE `quest_request_items` SET `CompletionText`='Do you still feel him, $N? The Lord lives while you hesitate. Return only when he has fallen.' WHERE `ID`=990021;
UPDATE `quest_request_items` SET `CompletionText`='Have you gathered enough bloodcrystals, $N? The Nightmare feeds on every one we leave it.' WHERE `ID`=990053;
UPDATE `quest_request_items` SET `CompletionText`='One of the four dragons still lives, $N. Only when all have fallen will the portals open.' WHERE `ID`=990054;

-- ===== creature_text (yells) =====
UPDATE `creature_text` SET `Text`='At last... a mortal brave enough to enter the Dream.' WHERE `CreatureID`=990011 AND `GroupID`=0 AND `ID`=0;
UPDATE `creature_text` SET `Text`='The Emerald Dream is corrupting. The Nightmare devours the very weave of the world.' WHERE `CreatureID`=990011 AND `GroupID`=0 AND `ID`=1;
UPDATE `creature_text` SET `Text`='Help me, hero - or all that lives will drown in the Nightmare.' WHERE `CreatureID`=990011 AND `GroupID`=0 AND `ID`=2;
UPDATE `creature_text` SET `Text`='The Dream belongs to the Nightmare now! You come just in time to break.' WHERE `CreatureID`=990014 AND `GroupID`=0;
UPDATE `creature_text` SET `Text`='The Nightmare... endures... forever...' WHERE `CreatureID`=990014 AND `GroupID`=1;
UPDATE `creature_text` SET `Text`='The Dream will devour you!' WHERE `CreatureID`=990018 AND `GroupID`=0;
UPDATE `creature_text` SET `Text`='Ysera... forgive me...' WHERE `CreatureID`=990018 AND `GroupID`=1;
UPDATE `creature_text` SET `Text`='No waking for you!' WHERE `CreatureID`=990019 AND `GroupID`=0;
UPDATE `creature_text` SET `Text`='The Nightmare... remains...' WHERE `CreatureID`=990019 AND `GroupID`=1;
UPDATE `creature_text` SET `Text`='Halt, mortal. Beyond this path lies only the Nightmare.' WHERE `CreatureID`=990015 AND `GroupID`=0;

-- ===== gossip options =====
UPDATE `gossip_menu_option` SET `OptionText`='Open the portal to Hyjal for me, Archdruid.' WHERE `MenuID`=60100 AND `OptionID`=1;
UPDATE `gossip_menu_option` SET `OptionText`='Step through the portal to Hyjal.' WHERE `MenuID`=60101 AND `OptionID`=1;

-- ===== quest item =====
UPDATE `item_template` SET `name`='Pulsing Bloodcrystal Shard',`description`='It pulses to the beat of an alien heart.' WHERE `entry`=990060;
UPDATE `gameobject_template` SET `name`='Corrupted Bloodcrystal' WHERE `entry`=990060;
