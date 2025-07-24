-- Initialize Semaphore database
USE semaphore;

-- Create users table if not exists
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime NOT NULL,
  `username` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `admin` tinyint(1) NOT NULL DEFAULT '0',
  `external` tinyint(1) NOT NULL DEFAULT '0',
  `alert` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_username_unique` (`username`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Insert admin user if not exists
INSERT IGNORE INTO `users` (`created`, `username`, `name`, `email`, `password`, `admin`, `external`, `alert`) 
VALUES (NOW(), 'admin', 'Administrator', 'admin@localhost', '$2y$10$0.WaFZY5HLEGLgvIKkR.bOHmRYzC6v6Q6G1jM0eJ5g5Z5Z5Z5Z5Z5Z', 1, 0, 1);

-- Add any additional initialization here
