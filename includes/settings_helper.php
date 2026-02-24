<?php
require_once __DIR__ . '/config.php';

function get_setting(string $name, $default = null) {
	global $conn;
	$stmt = $conn->prepare("SELECT setting_value FROM settings WHERE setting_name = ? LIMIT 1");
	if (!$stmt) { return $default; }
	$stmt->bind_param('s', $name);
	$stmt->execute();
	$res = $stmt->get_result();
	$row = $res ? $res->fetch_assoc() : null;
	$stmt->close();
	if (!$row) return $default;
	return $row['setting_value'];
}

function set_setting(string $name, $value): bool {
	global $conn;
	$sql = "INSERT INTO settings (setting_name, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)";

	// First attempt to prepare the statement
	$stmt = $conn->prepare($sql);

	// If the settings table doesn't exist yet, create it on the fly
	if (!$stmt) {
		$createSql = "CREATE TABLE IF NOT EXISTS settings (
			setting_id INT AUTO_INCREMENT PRIMARY KEY,
			setting_name VARCHAR(255) NOT NULL UNIQUE,
			setting_value TEXT,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
		)";
		@$conn->query($createSql);

		// Try preparing again after creating the table
		$stmt = $conn->prepare($sql);
		if (!$stmt) {
			return false;
		}
	}

	$stmt->bind_param('ss', $name, $value);
	$ok = $stmt->execute();
	$stmt->close();
	return $ok;
}

function get_bool_setting(string $name, bool $default = false): bool {
	$val = get_setting($name, $default ? '1' : '0');
	return in_array(strtolower((string)$val), ['1','true','yes','on'], true);
}

function get_int_setting(string $name, int $default = 0): int {
	$val = get_setting($name, $default);
	return is_numeric($val) ? (int)$val : $default;
}

?>


