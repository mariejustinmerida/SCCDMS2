<?php
/**
 * Environment Variable Loader
 * Loads variables from .env file into PHP environment
 * 
 * This file should be included before config.php if you want to use .env files
 */

if (!function_exists('load_env_file')) {
    function load_env_file($filePath) {
        if (!file_exists($filePath)) {
            return false;
        }
        
        $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            // Skip comments
            if (strpos(trim($line), '#') === 0) {
                continue;
            }
            
            // Parse KEY=VALUE format
            if (strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $key = trim($key);
                $value = trim($value);
                
                // Remove quotes if present
                $value = trim($value, '"\'');
                
                // Set environment variable if not already set
                if (!getenv($key)) {
                    putenv("$key=$value");
                    $_ENV[$key] = $value;
                    $_SERVER[$key] = $value;
                }
            }
        }
        
        return true;
    }
}

// Auto-load .env file if it exists
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    load_env_file($envFile);
}

