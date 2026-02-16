-- Olitun Database Schema
-- Optimized for Hostinger MySQL

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Database: `olitun_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE IF NOT EXISTS `categories` (
  `id` varchar(36) NOT NULL,
  `title_ol_chiki` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title_latin` varchar(255) NOT NULL,
  `icon_name` varchar(50) DEFAULT NULL,
  `icon_url` varchar(255) DEFAULT NULL,
  `gradient_preset` varchar(50) DEFAULT 'blue',
  `order_index` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `total_lessons` int(11) NOT NULL DEFAULT 0,
  `description` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lessons`
--

CREATE TABLE IF NOT EXISTS `lessons` (
  `id` varchar(36) NOT NULL,
  `category_id` varchar(36) NOT NULL,
  `title_ol_chiki` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title_latin` varchar(255) NOT NULL,
  `level` enum('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
  `order_index` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `estimated_minutes` int(11) DEFAULT 5,
  `description` text,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `is_premium` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lesson_blocks`
--

CREATE TABLE IF NOT EXISTS `lesson_blocks` (
  `id` varchar(36) NOT NULL,
  `lesson_id` varchar(36) NOT NULL,
  `type` enum('text','image','audio','video','lottie','quiz') NOT NULL,
  `content_json` json NOT NULL,
  `order_index` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`lesson_id`) REFERENCES `lessons`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `letters`
--

CREATE TABLE IF NOT EXISTS `letters` (
  `id` varchar(36) NOT NULL,
  `char_ol_chiki` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `transliteration_latin` varchar(50) NOT NULL,
  `order_index` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `example_word` varchar(255) DEFAULT NULL,
  `audio_url` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `lottie_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `numbers`
--

CREATE TABLE IF NOT EXISTS `numbers` (
  `id` varchar(36) NOT NULL,
  `numeral` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` int(11) NOT NULL,
  `name_ol_chiki` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name_latin` varchar(255) NOT NULL,
  `order_index` int(11) NOT NULL DEFAULT 0,
  `audio_url` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `words`
--

CREATE TABLE IF NOT EXISTS `words` (
  `id` varchar(36) NOT NULL,
  `word_ol_chiki` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `word_latin` varchar(255) NOT NULL,
  `meaning` varchar(255) NOT NULL,
  `usage_example` text,
  `category` varchar(50) DEFAULT NULL,
  `order_index` int(11) NOT NULL DEFAULT 0,
  `audio_url` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rhymes`
--

CREATE TABLE IF NOT EXISTS `rhymes` (
  `id` varchar(36) NOT NULL,
  `title_ol_chiki` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title_latin` varchar(255) NOT NULL,
  `content_ol_chiki` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `content_latin` text,
  `audio_url` varchar(255) DEFAULT NULL,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  `subcategory` varchar(50) DEFAULT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT 'easy',
  `duration_seconds` int(11) DEFAULT 0,
  `is_premium` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE IF NOT EXISTS `banners` (
  `id` varchar(36) NOT NULL,
  `title` varchar(255) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `lottie_url` varchar(255) DEFAULT NULL,
  `button_text` varchar(50) DEFAULT NULL,
  `action_url` varchar(255) DEFAULT NULL,
  `gradient_preset` varchar(50) DEFAULT 'blue',
  `bg_color` varchar(20) DEFAULT NULL,
  `text_color` varchar(20) DEFAULT '#FFFFFF',
  `order_index` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `app_settings`
--

CREATE TABLE IF NOT EXISTS `app_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default settings
INSERT IGNORE INTO `app_settings` (`setting_key`, `setting_value`) VALUES
('onboarding_video_url', NULL);
