-- mod-character-portability: replay-protection ledger for imports.
-- Each (file_id, source_pubkey) can be imported at most once per this server.

CREATE TABLE IF NOT EXISTS `wcpx_imported_files` (
    `file_id`       VARCHAR(36)  NOT NULL COMMENT 'UUIDv4 from .wcpx header',
    `source_pubkey` VARCHAR(44)  NOT NULL COMMENT 'base64 Ed25519 pubkey (32 bytes)',
    `account_id`    INT UNSIGNED NOT NULL,
    `character_id`  INT UNSIGNED NOT NULL,
    `source_name`   VARCHAR(64)  NULL     COMMENT 'display name of source server',
    `imported_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`file_id`, `source_pubkey`),
    KEY `idx_account`  (`account_id`),
    KEY `idx_charac`   (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Track TOFU-pending pubkeys so the admin can review + promote via GM command.
CREATE TABLE IF NOT EXISTS `wcpx_pending_pubkeys` (
    `source_pubkey` VARCHAR(44)  NOT NULL,
    `source_name`   VARCHAR(64)  NULL,
    `source_core`   VARCHAR(32)  NULL,
    `source_contact` VARCHAR(255) NULL,
    `first_seen`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `seen_count`    INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`source_pubkey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Track free-export usage per account per month for rate limiting.
CREATE TABLE IF NOT EXISTS `wcpx_export_log` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id`  INT UNSIGNED NOT NULL,
    `character_id` INT UNSIGNED NULL,
    `file_id`     VARCHAR(36)  NOT NULL,
    `was_paid`    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '0 = counted against free quota',
    `exported_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_account_time` (`account_id`, `exported_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
