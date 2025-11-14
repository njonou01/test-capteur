-- ========================================
-- ENTRANCE COCKPIT - PostgreSQL Database Schema
-- ========================================
-- Version: 1.0.0
-- Description: Complete schema for Entrance Cockpit System
-- Author: Entrance Cockpit Team
-- Date: 2025-01-14
-- ========================================

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for advanced cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- USERS & AUTHENTICATION
-- ========================================

-- Users table (Core Operational Backend)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'USER',
    -- Roles: SUPER_ADMIN, ADMIN, SECURITY_OFFICER, USER, GUEST
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP,
    login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    CONSTRAINT valid_role CHECK (role IN ('SUPER_ADMIN', 'ADMIN', 'SECURITY_OFFICER', 'USER', 'GUEST'))
);

-- User sessions for JWT tracking
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    ip_address VARCHAR(50),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- BADGES & ACCESS CONTROL
-- ========================================

-- Badges table
CREATE TABLE badges (
    id BIGSERIAL PRIMARY KEY,
    badge_id VARCHAR(50) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL DEFAULT 'RFID',
    -- Types: RFID, NFC, QR_CODE, BIOMETRIC
    is_active BOOLEAN DEFAULT true,
    activation_date TIMESTAMP,
    expiration_date TIMESTAMP,
    access_level INT DEFAULT 1,
    -- 1: Basic, 2: Elevated, 3: High, 4: Critical
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_badge_type CHECK (badge_type IN ('RFID', 'NFC', 'QR_CODE', 'BIOMETRIC')),
    CONSTRAINT valid_access_level CHECK (access_level BETWEEN 1 AND 4)
);

-- Access zones (locations with different security levels)
CREATE TABLE access_zones (
    id BIGSERIAL PRIMARY KEY,
    zone_name VARCHAR(100) UNIQUE NOT NULL,
    zone_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    required_access_level INT DEFAULT 1,
    location VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_required_access_level CHECK (required_access_level BETWEEN 1 AND 4)
);

-- Badge access permissions
CREATE TABLE badge_permissions (
    id BIGSERIAL PRIMARY KEY,
    badge_id BIGINT NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    zone_id BIGINT NOT NULL REFERENCES access_zones(id) ON DELETE CASCADE,
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(badge_id, zone_id)
);

-- ========================================
-- ENTRY REQUESTS & LOGS
-- ========================================

-- Entry requests (Entrance Cockpit Backend)
CREATE TABLE entry_requests (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    badge_id VARCHAR(50) NOT NULL,
    user_id BIGINT REFERENCES users(id),
    zone_id BIGINT REFERENCES access_zones(id),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    -- Status: PENDING, APPROVED, REJECTED, TIMEOUT, ERROR
    entry_type VARCHAR(50) DEFAULT 'BADGE_SCAN',
    -- Types: BADGE_SCAN, MANUAL, EMERGENCY, OVERRIDE
    location VARCHAR(100),
    device_id VARCHAR(100),
    request_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by BIGINT REFERENCES users(id),
    rejection_reason VARCHAR(255),
    notes TEXT,
    metadata JSONB,
    CONSTRAINT valid_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'TIMEOUT', 'ERROR')),
    CONSTRAINT valid_entry_type CHECK (entry_type IN ('BADGE_SCAN', 'MANUAL', 'EMERGENCY', 'OVERRIDE'))
);

-- Entry logs (immutable audit trail)
CREATE TABLE entry_logs (
    id BIGSERIAL PRIMARY KEY,
    entry_request_id BIGINT REFERENCES entry_requests(id),
    badge_id VARCHAR(50) NOT NULL,
    user_id BIGINT REFERENCES users(id),
    zone_id BIGINT REFERENCES access_zones(id),
    action VARCHAR(50) NOT NULL,
    -- Actions: SCAN, APPROVE, REJECT, TIMEOUT, DOOR_OPEN, DOOR_CLOSE
    status VARCHAR(50) NOT NULL,
    performed_by BIGINT REFERENCES users(id),
    ip_address VARCHAR(50),
    device_id VARCHAR(100),
    location VARCHAR(100),
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_action CHECK (action IN ('SCAN', 'APPROVE', 'REJECT', 'TIMEOUT', 'DOOR_OPEN', 'DOOR_CLOSE', 'ERROR'))
);

-- ========================================
-- DOOR LOCKS & DEVICES
-- ========================================

-- Door locks (Telemetry Backend)
CREATE TABLE door_locks (
    id BIGSERIAL PRIMARY KEY,
    lock_id VARCHAR(100) UNIQUE NOT NULL,
    zone_id BIGINT REFERENCES access_zones(id),
    lock_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    lock_type VARCHAR(50) DEFAULT 'ELECTROMAGNETIC',
    -- Types: ELECTROMAGNETIC, MECHANICAL, ELECTRONIC, SMART
    status VARCHAR(50) NOT NULL DEFAULT 'LOCKED',
    -- Status: LOCKED, UNLOCKED, JAMMED, MAINTENANCE, OFFLINE
    is_online BOOLEAN DEFAULT true,
    firmware_version VARCHAR(50),
    last_unlock TIMESTAMP,
    last_unlock_by BIGINT REFERENCES users(id),
    last_lock TIMESTAMP,
    unlock_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_lock_type CHECK (lock_type IN ('ELECTROMAGNETIC', 'MECHANICAL', 'ELECTRONIC', 'SMART')),
    CONSTRAINT valid_lock_status CHECK (status IN ('LOCKED', 'UNLOCKED', 'JAMMED', 'MAINTENANCE', 'OFFLINE'))
);

-- Door lock commands history
CREATE TABLE door_lock_commands (
    id BIGSERIAL PRIMARY KEY,
    lock_id BIGINT NOT NULL REFERENCES door_locks(id) ON DELETE CASCADE,
    command VARCHAR(50) NOT NULL,
    -- Commands: LOCK, UNLOCK, STATUS, RESET, MAINTENANCE
    issued_by BIGINT REFERENCES users(id),
    entry_request_id BIGINT REFERENCES entry_requests(id),
    status VARCHAR(50) DEFAULT 'PENDING',
    -- Status: PENDING, SENT, ACKNOWLEDGED, COMPLETED, FAILED
    response TEXT,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT valid_command CHECK (command IN ('LOCK', 'UNLOCK', 'STATUS', 'RESET', 'MAINTENANCE')),
    CONSTRAINT valid_command_status CHECK (status IN ('PENDING', 'SENT', 'ACKNOWLEDGED', 'COMPLETED', 'FAILED'))
);

-- ========================================
-- SENSOR DATA & TELEMETRY
-- ========================================

-- Sensor data (Telemetry Backend)
CREATE TABLE sensor_data (
    id BIGSERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    sensor_type VARCHAR(50) NOT NULL,
    -- Types: TEMPERATURE, HUMIDITY, VIBRATION, MOTION, SMOKE, CO2
    zone_id BIGINT REFERENCES access_zones(id),
    location VARCHAR(100),
    value FLOAT NOT NULL,
    unit VARCHAR(20),
    status VARCHAR(50) DEFAULT 'NORMAL',
    -- Status: NORMAL, WARNING, CRITICAL, ERROR
    threshold_min FLOAT,
    threshold_max FLOAT,
    metadata JSONB,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_sensor_type CHECK (sensor_type IN ('TEMPERATURE', 'HUMIDITY', 'VIBRATION', 'MOTION', 'SMOKE', 'CO2', 'PRESSURE')),
    CONSTRAINT valid_sensor_status CHECK (status IN ('NORMAL', 'WARNING', 'CRITICAL', 'ERROR'))
);

-- Sensor alerts
CREATE TABLE sensor_alerts (
    id BIGSERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    sensor_data_id BIGINT REFERENCES sensor_data(id),
    alert_type VARCHAR(50) NOT NULL,
    -- Types: THRESHOLD_EXCEEDED, SENSOR_OFFLINE, ANOMALY, CRITICAL
    severity VARCHAR(50) NOT NULL,
    -- Severity: LOW, MEDIUM, HIGH, CRITICAL
    message TEXT,
    acknowledged BOOLEAN DEFAULT false,
    acknowledged_by BIGINT REFERENCES users(id),
    acknowledged_at TIMESTAMP,
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_alert_type CHECK (alert_type IN ('THRESHOLD_EXCEEDED', 'SENSOR_OFFLINE', 'ANOMALY', 'CRITICAL')),
    CONSTRAINT valid_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- ========================================
-- AUDIT LOGS
-- ========================================

-- Comprehensive audit trail
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id BIGINT,
    user_id BIGINT REFERENCES users(id),
    ip_address VARCHAR(50),
    user_agent TEXT,
    old_value JSONB,
    new_value JSONB,
    status VARCHAR(50) DEFAULT 'SUCCESS',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_audit_status CHECK (status IN ('SUCCESS', 'FAILED', 'UNAUTHORIZED'))
);

-- ========================================
-- SYSTEM CONFIGURATION
-- ========================================

-- System settings
CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(50) DEFAULT 'STRING',
    -- Types: STRING, INTEGER, BOOLEAN, JSON
    description TEXT,
    is_secret BOOLEAN DEFAULT false,
    updated_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_setting_type CHECK (setting_type IN ('STRING', 'INTEGER', 'BOOLEAN', 'JSON'))
);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Users indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_uuid ON users(uuid);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Badges indexes
CREATE INDEX idx_badges_badge_id ON badges(badge_id);
CREATE INDEX idx_badges_user_id ON badges(user_id);
CREATE INDEX idx_badges_is_active ON badges(is_active);
CREATE INDEX idx_badges_expiration ON badges(expiration_date);

-- Entry requests indexes
CREATE INDEX idx_entry_requests_uuid ON entry_requests(uuid);
CREATE INDEX idx_entry_requests_badge_id ON entry_requests(badge_id);
CREATE INDEX idx_entry_requests_user_id ON entry_requests(user_id);
CREATE INDEX idx_entry_requests_status ON entry_requests(status);
CREATE INDEX idx_entry_requests_request_at ON entry_requests(request_at DESC);
CREATE INDEX idx_entry_requests_zone_id ON entry_requests(zone_id);

-- Entry logs indexes
CREATE INDEX idx_entry_logs_entry_request_id ON entry_logs(entry_request_id);
CREATE INDEX idx_entry_logs_badge_id ON entry_logs(badge_id);
CREATE INDEX idx_entry_logs_user_id ON entry_logs(user_id);
CREATE INDEX idx_entry_logs_created_at ON entry_logs(created_at DESC);
CREATE INDEX idx_entry_logs_action ON entry_logs(action);

-- Door locks indexes
CREATE INDEX idx_door_locks_lock_id ON door_locks(lock_id);
CREATE INDEX idx_door_locks_zone_id ON door_locks(zone_id);
CREATE INDEX idx_door_locks_status ON door_locks(status);

-- Sensor data indexes
CREATE INDEX idx_sensor_data_sensor_id ON sensor_data(sensor_id);
CREATE INDEX idx_sensor_data_sensor_type ON sensor_data(sensor_type);
CREATE INDEX idx_sensor_data_recorded_at ON sensor_data(recorded_at DESC);
CREATE INDEX idx_sensor_data_status ON sensor_data(status);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_badges_updated_at BEFORE UPDATE ON badges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_access_zones_updated_at BEFORE UPDATE ON access_zones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_door_locks_updated_at BEFORE UPDATE ON door_locks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INITIAL DATA SEED
-- ========================================

-- Insert default super admin user (password: Admin123!)
-- Password hash generated with bcrypt (cost factor: 10)
INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_active, is_verified)
VALUES
    ('admin', 'admin@entrancecockpit.com', '$2a$10$xQJ7v0ORZK6j3Z7Y0k5Eb.C0P2PxZU8h9xE1jYWz.vFqIKQF.9YFa', 'System', 'Administrator', 'SUPER_ADMIN', true, true),
    ('security', 'security@entrancecockpit.com', '$2a$10$xQJ7v0ORZK6j3Z7Y0k5Eb.C0P2PxZU8h9xE1jYWz.vFqIKQF.9YFa', 'Security', 'Officer', 'SECURITY_OFFICER', true, true),
    ('john.doe', 'john.doe@entrancecockpit.com', '$2a$10$xQJ7v0ORZK6j3Z7Y0k5Eb.C0P2PxZU8h9xE1jYWz.vFqIKQF.9YFa', 'John', 'Doe', 'USER', true, true);

-- Insert default access zones
INSERT INTO access_zones (zone_name, zone_code, description, required_access_level, location, is_active)
VALUES
    ('Main Entrance', 'ZONE-001', 'Main building entrance', 1, 'Building A - Ground Floor', true),
    ('Server Room', 'ZONE-002', 'Data center and server room', 3, 'Building A - Basement', true),
    ('Executive Floor', 'ZONE-003', 'Executive offices', 2, 'Building A - 5th Floor', true),
    ('Laboratory', 'ZONE-004', 'Research laboratory', 3, 'Building B - 2nd Floor', true),
    ('Parking Garage', 'ZONE-005', 'Underground parking', 1, 'Building A - Underground', true);

-- Insert default badges
INSERT INTO badges (badge_id, user_id, badge_type, is_active, access_level)
VALUES
    ('BADGE-001', 1, 'RFID', true, 4),  -- Admin badge
    ('BADGE-002', 2, 'RFID', true, 3),  -- Security badge
    ('BADGE-003', 3, 'RFID', true, 1);  -- Regular user badge

-- Insert default badge permissions
INSERT INTO badge_permissions (badge_id, zone_id, granted_by, is_active)
VALUES
    (1, 1, 1, true),  -- Admin: Main Entrance
    (1, 2, 1, true),  -- Admin: Server Room
    (1, 3, 1, true),  -- Admin: Executive Floor
    (1, 4, 1, true),  -- Admin: Laboratory
    (1, 5, 1, true),  -- Admin: Parking
    (2, 1, 1, true),  -- Security: Main Entrance
    (2, 2, 1, true),  -- Security: Server Room
    (2, 5, 1, true),  -- Security: Parking
    (3, 1, 1, true),  -- User: Main Entrance
    (3, 5, 1, true);  -- User: Parking

-- Insert default door locks
INSERT INTO door_locks (lock_id, zone_id, lock_name, location, lock_type, status, is_online)
VALUES
    ('LOCK-001', 1, 'Main Door Lock', 'Building A - Main Entrance', 'ELECTROMAGNETIC', 'LOCKED', true),
    ('LOCK-002', 2, 'Server Room Lock', 'Building A - Basement', 'ELECTRONIC', 'LOCKED', true),
    ('LOCK-003', 3, 'Executive Door Lock', 'Building A - 5th Floor', 'SMART', 'LOCKED', true),
    ('LOCK-004', 4, 'Lab Door Lock', 'Building B - 2nd Floor', 'ELECTRONIC', 'LOCKED', true),
    ('LOCK-005', 5, 'Garage Gate Lock', 'Building A - Underground', 'ELECTROMAGNETIC', 'LOCKED', true);

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, setting_type, description)
VALUES
    ('jwt.expiration.seconds', '3600', 'INTEGER', 'JWT token expiration time in seconds'),
    ('cache.sync.interval.seconds', '300', 'INTEGER', 'Cache synchronization interval'),
    ('max.login.attempts', '5', 'INTEGER', 'Maximum failed login attempts before lockout'),
    ('lockout.duration.minutes', '30', 'INTEGER', 'Account lockout duration after max attempts'),
    ('entry.timeout.seconds', '30', 'INTEGER', 'Entry request timeout duration'),
    ('door.unlock.duration.seconds', '5', 'INTEGER', 'How long door stays unlocked'),
    ('sensor.alert.enabled', 'true', 'BOOLEAN', 'Enable sensor alerts'),
    ('audit.retention.days', '90', 'INTEGER', 'Audit log retention period');

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- Active entry requests view
CREATE VIEW v_active_entry_requests AS
SELECT
    er.id,
    er.uuid,
    er.badge_id,
    u.username,
    u.first_name,
    u.last_name,
    az.zone_name,
    er.status,
    er.entry_type,
    er.location,
    er.request_at,
    er.approved_by,
    approver.username as approved_by_username
FROM entry_requests er
LEFT JOIN users u ON er.user_id = u.id
LEFT JOIN access_zones az ON er.zone_id = az.id
LEFT JOIN users approver ON er.approved_by = approver.id
WHERE er.status = 'PENDING'
ORDER BY er.request_at DESC;

-- Recent entry logs view
CREATE VIEW v_recent_entry_logs AS
SELECT
    el.id,
    el.badge_id,
    u.username,
    u.first_name,
    u.last_name,
    az.zone_name,
    el.action,
    el.status,
    el.location,
    el.created_at,
    performer.username as performed_by_username
FROM entry_logs el
LEFT JOIN users u ON el.user_id = u.id
LEFT JOIN access_zones az ON el.zone_id = az.id
LEFT JOIN users performer ON el.performed_by = performer.id
ORDER BY el.created_at DESC
LIMIT 100;

-- Door lock status view
CREATE VIEW v_door_lock_status AS
SELECT
    dl.id,
    dl.lock_id,
    dl.lock_name,
    az.zone_name,
    dl.location,
    dl.status,
    dl.is_online,
    dl.last_unlock,
    u.username as last_unlocked_by,
    dl.unlock_count
FROM door_locks dl
LEFT JOIN access_zones az ON dl.zone_id = az.id
LEFT JOIN users u ON dl.last_unlock_by = u.id;

-- Critical sensor alerts view
CREATE VIEW v_critical_sensor_alerts AS
SELECT
    sa.id,
    sa.sensor_id,
    sa.alert_type,
    sa.severity,
    sa.message,
    sa.acknowledged,
    sa.resolved,
    sa.created_at,
    u.username as acknowledged_by_username
FROM sensor_alerts sa
LEFT JOIN users u ON sa.acknowledged_by = u.id
WHERE sa.severity IN ('HIGH', 'CRITICAL')
  AND sa.resolved = false
ORDER BY sa.created_at DESC;

-- ========================================
-- PARTITIONING FOR LARGE TABLES (Optional)
-- ========================================
-- Uncomment if you expect very large volumes of data

-- Convert entry_logs to partitioned table by month
-- ALTER TABLE entry_logs RENAME TO entry_logs_old;
-- CREATE TABLE entry_logs (LIKE entry_logs_old INCLUDING ALL) PARTITION BY RANGE (created_at);
-- CREATE TABLE entry_logs_2025_01 PARTITION OF entry_logs FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
-- CREATE TABLE entry_logs_2025_02 PARTITION OF entry_logs FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- INSERT INTO entry_logs SELECT * FROM entry_logs_old;
-- DROP TABLE entry_logs_old;

-- ========================================
-- COMMENTS ON TABLES
-- ========================================

COMMENT ON TABLE users IS 'User accounts with authentication credentials';
COMMENT ON TABLE badges IS 'Physical access badges assigned to users';
COMMENT ON TABLE entry_requests IS 'Access requests from badge scans';
COMMENT ON TABLE entry_logs IS 'Immutable audit trail of all entry events';
COMMENT ON TABLE door_locks IS 'Physical door lock devices';
COMMENT ON TABLE sensor_data IS 'Telemetry data from IoT sensors';
COMMENT ON TABLE audit_logs IS 'Comprehensive system audit trail';

-- ========================================
-- GRANT PERMISSIONS (adjust as needed)
-- ========================================

-- Grant necessary permissions to application user
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO entrance_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO entrance_user;

-- ========================================
-- COMPLETION
-- ========================================

SELECT 'Database schema initialized successfully!' AS status;
SELECT 'Default users created: admin, security, john.doe (password: Admin123!)' AS info;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';
