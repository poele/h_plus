


CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL UNIQUE,
  email VARCHAR NOT NULL,
  image VARCHAR DEFAULT '/images/default.png',
  bio TEXT,
  created_at TIMESTAMP NOT NULL,
  password VARCHAR NOT NULL
);

CREATE TABLE topics (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  descrip TEXT
);


CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  subject TEXT NOT NULL,
  content TEXT DEFAULT 'this post has no content',
  popularity INT DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  topic INT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE
);


CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  post INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location VARCHAR
);


  