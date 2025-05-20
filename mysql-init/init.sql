-- Drop the root user for any host if it exists
DROP USER IF EXISTS 'root'@'%';

-- Create the root user that can connect from any host
CREATE USER 'root'@'%' IDENTIFIED BY 'password';

-- Grant all privileges to the root user
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Make sure the privileges are applied immediately
FLUSH PRIVILEGES;

-- Create and initialize the notes_app database
CREATE DATABASE IF NOT EXISTS notes_app;
USE notes_app;

-- Create a simple notes table if it doesn't exist
CREATE TABLE IF NOT EXISTS notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert a test note to verify the database is working
INSERT INTO notes (content) VALUES ('Test note created during initialization');
