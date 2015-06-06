\c transhumanity
TRUNCATE TABLE users, topics, comments, posts;

INSERT INTO users
  (name, email, image, bio, password, created_at)
VALUES
	('s16', 'ckaczmarek@amail.com', '/images/clay.png', 'there were a lot of things i should have said. who thought i''d end up dead.', 'pen15club', current_timestamp),
	('s17', 'dmiles@amail.com', '/images/desmond.jpg', 'clay is morbid and unfunny.', 'sh1rleymustBkidding', current_timestamp)
	;

INSERT INTO topics
	(name, descrip)
VALUES
	('philosophy', 'contemplating if there''s more'),
	('regrets', 'where we''ll think over what could have been')
	;

INSERT INTO posts
	(subject, content, popularity, created_at, topic, user_id)
VALUES
	('i wish i was never born', 'i never asked for this.', 3, current_timestamp, 2, 2),
	('thoughts?', 'i think we did all right in the end', 7, current_timestamp, 1, 2),
	('there''s life after death.', 'i just don''t know if i''d call it living', 1, current_timestamp, 1, 1),
	('dont trust others', 'i have never gotten anything from helping people. the world is fine without my help.', 2, current_timestamp, 1, 1)
	;

INSERT INTO comments
	(content, created_at, post, user_id)
VALUES
	('none of us did.', current_timestamp, 1, 1),
	('how dare you try to speak on right and wrong.', current_timestamp, 1, 2),
	('don''t run away from the truth.', current_timestamp, 4, 2)
	;

