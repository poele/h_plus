\c transhumanity
TRUNCATE TABLE users, topics, comments, posts;

INSERT INTO users
  (name, email, image, bio, password, created_at)
VALUES
	('s16', 'ckaczmarek@amail.com', '/images/clay.png', 'there were a lot of things i should have said. who thought i''d end up dead.', 'pen15club', current_timestamp),
	('s17', 'dmiles@amail.com', '/images/desmond.jpg', 'clay is morbid and unfunny.', 'sh1rleymustBkidding', current_timestamp),
	('s4', 'dcross@tmail.com', '/images/daniel.jpg', 'god i hate you people.', 'nyet', current_timestamp),
	('nepnep', 'purpleprogress@cpumail.com', '/images/neptune.jpg', 'ummm hi my name is neptune and i really like pudding!!!', 'g0ttag0f4st', current_timestamp),
	('blackheart', 'blackregality@cpumail.com', '/images/noire.jpg', 'you''re welcome for the last of us btw', 'pl4y1n0urs', current_timestamp),
	('hammertime', 'whiteserenity@cpumail.com', '/images/blanc.jpg', 'please buy the wiiu. please. i''m so hungry...', 'w11', current_timestamp),
	('onlyonlychild', 'greenpastures@cpumail.com', '/images/vert.png', 'http://www.ezdrm.com/html/advantages.asp', 'xbone', current_timestamp),
	('og', 'wbirkin@umbrellapharm.org', '/images/birkin.jpg', 'iuhfa;.jihgahreieolk', 'annie62', current_timestamp),
	('whensmahvel', 'woolietheliar@subparbestfriendenterprises.com', '/images/woolie.png', 'christmases saved: 4 | christmases ruined: at least 7', 'gr3n4d4', current_timestamp);

INSERT INTO topics
	(name, descrip)
VALUES
	('philosophy', 'contemplating if there''s more'),
	('regrets', 'where we''ll think over what could have been');

INSERT INTO posts
	(subject, content, popularity, created_at, topic, user_id)
VALUES
	('i wish i was never born', 'i never asked for this.', 3, current_timestamp, 1, 2),
	('thoughts?', 'i think we did all right in the end', 7, current_timestamp, 1, 2),
	('there''s life after death.', 'i just don''t know if i''d call it living', 1, current_timestamp, 1, 1),
	('dont trust others', 'i have never gotten anything from helping people. the world is fine without my help.', 2, current_timestamp, 1, 1),
	('let''s talk about something cheery!', 'seriously why are you guys always so depressing ლ(ಥ Д ಥ )ლ', 0, current_timestamp, 1, 4),
	('video game discussion board y/y?', 'at least one of you has to do something other than sitting in your room slitting your wrists while listening to linkin park', 2, current_timestamp, 2, 7);

INSERT INTO comments
	(content, created_at, post, user_id)
VALUES
	('none of us did.', current_timestamp, 1, 1),
	('how dare you try to speak on right and wrong.', current_timestamp, 1, 2),
	('don''t run away from the truth.', current_timestamp, 4, 2),
	('do you even go here?', current_timestamp, 5, 2),
	('c''mon at least say we''re listening to someone good', current_timestamp, 6, 1),
	('3edgy5me', current_timestamp, 6, 4),
	('jeez vert that''s dark', current_timestamp, 6, 6)
	;