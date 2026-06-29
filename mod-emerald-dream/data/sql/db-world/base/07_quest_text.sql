-- Quest turn-in dialogue (RewardText) + incomplete lines (CompletionText) for all custom Hyjal quests. Idempotent.
DELETE FROM `quest_offer_reward`  WHERE `ID` IN (990050,990051,990052,990020,990022,990023,990024,990021);
DELETE FROM `quest_request_items` WHERE `ID` IN (990050,990051,990052,990020,990022,990023,990024,990021);

INSERT INTO `quest_offer_reward` (`ID`,`RewardText`) VALUES
 (990050,'Gut, dass du gekommen bist, $N. Hyjal braucht Helden mehr denn je - und du sollst einer von ihnen sein.'),
 (990051,'Verdorbene Wisps, hier oben am heiligen Gipfel... Der Albtraum reicht weiter, als ich befuerchtet habe. Wir muessen zur Quelle vordringen.'),
 (990052,'Ich habe deine Schritte im Traum vernommen, Sterblicher. Komm naeher - der Albtraum wartet in der Senke unter uns, und du wirst ihn schauen.'),
 (990020,'Du hast die Schemen zerstreut, doch dies sind nur Auslaeufer. Tiefer im Hain lauert weit Schlimmeres.'),
 (990022,'So wagt ein Sterblicher den Abstieg. Gut. Hinter mir beginnt der Albtraum - bleib dicht am Pfad, oder er verschlingt dich.'),
 (990023,'Du hast dir den Weg freigekaempft. Die Brut wird nachwachsen, doch fuer den Augenblick ist der Pfad offen.'),
 (990024,'Naralassa und Gnarl sind gefallen - die letzten Waechter vor dem Herzen des Albtraums. Was nun folgt, ist der Lord selbst.'),
 (990021,'Der Albtraum-Lord ist bezwungen. Der Traum atmet wieder auf - dank dir, Held von Hyjal. Doch wache weiter: der Albtraum schlaeft nie ganz.');

INSERT INTO `quest_request_items` (`ID`,`CompletionText`) VALUES
 (990051,'Hast du die Wisps bereits erloest, $N? Ihre Faeulnis darf den Gipfel nicht erreichen.'),
 (990020,'Die Schemen wanken noch, $N. Vertreibe sie, ehe du zurueckkehrst.'),
 (990023,'Noch wimmelt der Pfad von Bestien und Hippogryphen, $N. Raeum ihn frei.'),
 (990024,'Die beiden Waechter leben noch, $N. Ohne ihren Fall bleibt dir der Talboden verwehrt.'),
 (990021,'Spuerst du ihn noch, $N? Der Lord lebt, solange du zoegerst. Kehre erst zurueck, wenn er gefallen ist.');
