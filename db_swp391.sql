
CREATE DATABASE IF NOT EXISTS ev_warranty_final

USE ev_warranty_final;

-- ======================================================================
-- 1) USERS / ROLES / ORGS
-- ======================================================================

-- Lookups
CREATE TABLE lk_user_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- ví dụ: 'active', 'inactive'
);

CREATE TABLE lk_service_center_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'active', 'inactive'
);

-- Core
CREATE TABLE roles (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,        -- 'ADMIN','SC_STAFF','SC_TECH','EVM_STAFF','CUSTOMER'
);

CREATE TABLE users (
  id            int AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(200) NOT NULL,
  email         VARCHAR(200) UNIQUE,
  phone         VARCHAR(30),
  password  VARCHAR(255),
  role_id       int   NOT NULL,          -- FK -> roles
  status_id     int NOT NULL,          -- FK -> lk_user_status
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role   FOREIGN KEY (role_id)   REFERENCES roles(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_users_status FOREIGN KEY (status_id) REFERENCES lk_user_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE service_centers (
  id         int AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(200) NOT NULL,
  phone      VARCHAR(30),
  address    VARCHAR(255),
  status_id  int NOT NULL,             -- FK -> lk_service_center_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sc_status FOREIGN KEY (status_id) REFERENCES lk_service_center_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE customers (
  id         int AUTO_INCREMENT PRIMARY KEY,
  user_id    int UNIQUE NULL,            -- có thể null nếu khách chưa có tài khoản
  full_name  VARCHAR(200) NOT NULL,
  phone      VARCHAR(30),
  email      VARCHAR(200),
  address    VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_customer_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL
);

-- ======================================================================
-- 2) VEHICLES
-- ======================================================================

-- Lookups
CREATE TABLE lk_vehicle_model_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'ev_scooter','ev_bike','car'
);

CREATE TABLE lk_vehicle_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'active','inactive','stolen','total_loss'
);

-- Core
CREATE TABLE vehicle_models (
  id             int AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(150) NOT NULL,
  type_id        int NOT NULL,         -- FK -> lk_vehicle_model_type
  warranty_years INT DEFAULT 3,
  warranty_km    INT DEFAULT 30000,
  UNIQUE KEY uq_model_name_type (name, type_id),
  CONSTRAINT fk_model_type FOREIGN KEY (type_id) REFERENCES lk_vehicle_model_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE vehicles (
  id                int AUTO_INCREMENT PRIMARY KEY,
  vin               VARCHAR(50) NOT NULL UNIQUE,
  model_id          int NOT NULL,
  customer_id       int NOT NULL,
  purchase_date     DATE,
  service_center_id int,
  status_id         int NOT NULL,      -- FK -> lk_vehicle_status
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_vehicle_model    FOREIGN KEY (model_id)    REFERENCES vehicle_models(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_vehicle_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON UPDATE CASCADE  ON DELETE RESTRICT,
  CONSTRAINT fk_vehicle_sc       FOREIGN KEY (service_center_id) REFERENCES service_centers(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  CONSTRAINT fk_vehicle_status   FOREIGN KEY (status_id)   REFERENCES lk_vehicle_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (customer_id),
  INDEX (model_id)
);

-- ======================================================================
-- 3) BATTERIES
-- ======================================================================

-- Lookups
CREATE TABLE lk_battery_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'in_stock','installed','retired'
);

-- Core
CREATE TABLE battery_packs (
  id          int AUTO_INCREMENT PRIMARY KEY,
  serial_no   VARCHAR(100) NOT NULL UNIQUE,
  soh_percent DECIMAL(5,2) DEFAULT 100.00,
  cycle_count INT DEFAULT 0,
  status_id   int NOT NULL,            -- FK -> lk_battery_status
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_battery_status FOREIGN KEY (status_id) REFERENCES lk_battery_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE vehicle_battery_history (
  id           int AUTO_INCREMENT PRIMARY KEY,
  vehicle_id   int NOT NULL,
  battery_id   int NOT NULL,
  installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  removed_at   TIMESTAMP NULL,
  note         VARCHAR(255),
  CONSTRAINT fk_vbh_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_vbh_battery FOREIGN KEY (battery_id) REFERENCES battery_packs(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX (vehicle_id, installed_at),
  INDEX (battery_id, installed_at)
);

-- ======================================================================
-- 4) WARRANTY POLICIES
-- ======================================================================

-- Lookups
CREATE TABLE lk_warranty_policy_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'vehicle','battery'
);

-- Core
CREATE TABLE warranty_policies (
  id              int AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  type_id         int NOT NULL,        -- FK -> lk_warranty_policy_type
  duration_months INT,
  mileage_km      INT,
  soh_threshold   DECIMAL(5,2),
  description     VARCHAR(255),
  CONSTRAINT fk_policy_type FOREIGN KEY (type_id) REFERENCES lk_warranty_policy_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

-- Binding tách 1–N (đơn giản, dễ query)
CREATE TABLE vehicle_warranty (
  id             int AUTO_INCREMENT PRIMARY KEY,
  vehicle_id     int NOT NULL,
  policy_id      int NOT NULL,
  effective_from DATE NOT NULL,
  effective_to   DATE,
  CONSTRAINT fk_vw_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_vw_policy  FOREIGN KEY (policy_id)  REFERENCES warranty_policies(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (vehicle_id, effective_from)
);

CREATE TABLE battery_warranty (
  id             int AUTO_INCREMENT PRIMARY KEY,
  battery_id     int NOT NULL,
  policy_id      int NOT NULL,
  effective_from DATE NOT NULL,
  effective_to   DATE,
  CONSTRAINT fk_bw_battery FOREIGN KEY (battery_id) REFERENCES battery_packs(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bw_policy  FOREIGN KEY (policy_id)  REFERENCES warranty_policies(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (battery_id, effective_from)
);

-- ======================================================================

-- Lookups
CREATE TABLE lk_warranty_policy_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'vehicle','battery'
);

-- Core
CREATE TABLE warranty_policies (
  id              int AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  type_id         int NOT NULL,        -- FK -> lk_warranty_policy_type
  duration_months INT,
  mileage_km      INT,
  soh_threshold   DECIMAL(5,2),
  description     VARCHAR(255),
  CONSTRAINT fk_policy_type FOREIGN KEY (type_id) REFERENCES lk_warranty_policy_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

-- Binding tách 1–N (đơn giản, dễ query)
CREATE TABLE vehicle_warranty (
  id             int AUTO_INCREMENT PRIMARY KEY,
  vehicle_id     int NOT NULL,
  policy_id      int NOT NULL,
  effective_from DATE NOT NULL,
  effective_to   DATE,
  CONSTRAINT fk_vw_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_vw_policy  FOREIGN KEY (policy_id)  REFERENCES warranty_policies(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (vehicle_id, effective_from)
);

CREATE TABLE battery_warranty (
  id             int AUTO_INCREMENT PRIMARY KEY,
  battery_id     int NOT NULL,
  policy_id      int NOT NULL,
  effective_from DATE NOT NULL,
  effective_to   DATE,
  CONSTRAINT fk_bw_battery FOREIGN KEY (battery_id) REFERENCES battery_packs(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bw_policy  FOREIGN KEY (policy_id)  REFERENCES warranty_policies(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (battery_id, effective_from)
);

-- ======================================================================
-- 5) CLAIMS (Bảo hành)
-- ======================================================================

-- Lookups
CREATE TABLE lk_claim_source (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'walk_in','app','web','call_center'
);

CREATE TABLE lk_claim_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'new','diagnosing','approved','...'
);

CREATE TABLE lk_component_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'battery','motor','charger','controller','dashboard','other'
)
CREATE TABLE lk_resolution_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'repair','replace','firmware_update','none'
);

-- Core
CREATE TABLE warranty_claims (
  id                int AUTO_INCREMENT PRIMARY KEY,
  claim_no          VARCHAR(50) NOT NULL UNIQUE,
  vehicle_id        int NOT NULL,
  customer_id       int NOT NULL,
  service_center_id int NOT NULL,
  reported_by       int,                   -- users.id (SC Staff)
  assigned_to       int,                   -- users.id (Technician)
  source_id         int NOT NULL,        -- lk_claim_source
status_id         int NOT NULL,        -- lk_claim_status
  symptom_desc      TEXT,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_wc_vehicle    FOREIGN KEY (vehicle_id)        REFERENCES vehicles(id)
    ON UPDATE CASCADE  ON DELETE RESTRICT,
  CONSTRAINT fk_wc_customer   FOREIGN KEY (customer_id)       REFERENCES customers(id)
    ON UPDATE CASCADE  ON DELETE RESTRICT,
  CONSTRAINT fk_wc_sc         FOREIGN KEY (service_center_id) REFERENCES service_centers(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_wc_reportedby FOREIGN KEY (reported_by)       REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL,
  CONSTRAINT fk_wc_assignedto FOREIGN KEY (assigned_to)       REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL,
  CONSTRAINT fk_wc_source     FOREIGN KEY (source_id)         REFERENCES lk_claim_source(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_wc_status     FOREIGN KEY (status_id)         REFERENCES lk_claim_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (status_id, created_at),
  INDEX (vehicle_id, created_at)
);

CREATE TABLE claim_items (
  id                 int AUTO_INCREMENT PRIMARY KEY,
  claim_id           int NOT NULL,
  component_type_id  int NOT NULL,       -- lk_component_type
  resolution_type_id int NOT NULL,       -- lk_resolution_type
  diagnosis_code     VARCHAR(50),
  finding_note       TEXT,
  covered_by_warranty BOOLEAN DEFAULT TRUE,
  decision_by        int,                  -- users.id (EVM Staff)
  decision_at        TIMESTAMP NULL,
  CONSTRAINT fk_ci_claim      FOREIGN KEY (claim_id)          REFERENCES warranty_claims(id)
    ON UPDATE CASCADE  ON DELETE CASCADE,
  CONSTRAINT fk_ci_component  FOREIGN KEY (component_type_id) REFERENCES lk_component_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_ci_resolution FOREIGN KEY (resolution_type_id) REFERENCES lk_resolution_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_ci_decider    FOREIGN KEY (decision_by)       REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL
);

CREATE TABLE claim_status_history (
  id            int AUTO_INCREMENT PRIMARY KEY,
  claim_id      int NOT NULL,
  from_status_id int NULL,              -- lk_claim_status
  to_status_id   int NOT NULL,          -- lk_claim_status
  changed_by     int NOT NULL,            -- users.id
  changed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  note           VARCHAR(255),
  CONSTRAINT fk_csh_claim FOREIGN KEY (claim_id)      REFERENCES warranty_claims(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_csh_from  FOREIGN KEY (from_status_id) REFERENCES lk_claim_status(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  CONSTRAINT fk_csh_to    FOREIGN KEY (to_status_id)   REFERENCES lk_claim_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
CONSTRAINT fk_csh_user  FOREIGN KEY (changed_by)     REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE RESTRICT,
  INDEX (claim_id, changed_at)
);

CREATE TABLE diagnostics (
  id            int AUTO_INCREMENT PRIMARY KEY,
  claim_id      int NOT NULL,
  vehicle_id    int NOT NULL,
  battery_id    int NULL,
  read_time     DATETIME DEFAULT CURRENT_TIMESTAMP,
  firmware_ver  VARCHAR(100),
  error_codes   VARCHAR(255),
  notes         VARCHAR(255),
  technician_id int,
  CONSTRAINT fk_diag_claim   FOREIGN KEY (claim_id)   REFERENCES warranty_claims(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_diag_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_diag_battery FOREIGN KEY (battery_id) REFERENCES battery_packs(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_diag_tech    FOREIGN KEY (technician_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX (claim_id, read_time)
);

-- ======================================================================
-- 6) WORK ORDERS & PARTS
-- ======================================================================

-- Lookups
CREATE TABLE lk_work_order_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'open','in_progress','qa_check','done','closed'
);

-- Core
CREATE TABLE work_orders (
  id                int AUTO_INCREMENT PRIMARY KEY,
  claim_id          int NOT NULL,
  service_center_id int NOT NULL,
  technician_id     int NOT NULL,
  started_at        DATETIME,
  completed_at      DATETIME,
  labor_hours       DECIMAL(6,2) DEFAULT 0.00,
  note              VARCHAR(255),
  status_id         int NOT NULL,      -- lk_work_order_status
  CONSTRAINT fk_wo_claim  FOREIGN KEY (claim_id)          REFERENCES warranty_claims(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_wo_sc     FOREIGN KEY (service_center_id) REFERENCES service_centers(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_wo_tech   FOREIGN KEY (technician_id)     REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE RESTRICT,
  CONSTRAINT fk_wo_status FOREIGN KEY (status_id)         REFERENCES lk_work_order_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (claim_id)
);

CREATE TABLE parts (
  id         int AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(200) NOT NULL UNIQUE,   -- có thể dùng 'code' riêng nếu cần
  unit_price DECIMAL(12,2) DEFAULT 0.00,
  active     BOOLEAN DEFAULT TRUE
);

CREATE TABLE work_order_parts (
  id            int AUTO_INCREMENT PRIMARY KEY,
  work_order_id int NOT NULL,
  part_id       int NOT NULL,
  qty           INT NOT NULL DEFAULT 1,
  unit_price    DECIMAL(12,2) DEFAULT 0.00,  -- 0 nếu BH 100%
  CONSTRAINT fk_wop_wo   FOREIGN KEY (work_order_id) REFERENCES work_orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_wop_part FOREIGN KEY (part_id)       REFERENCES parts(id)
ON UPDATE RESTRICT ON DELETE RESTRICT
);

-- ======================================================================
-- 7) RECALL
-- ======================================================================

-- Lookups
CREATE TABLE lk_recall_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'draft','active','paused','completed','closed'
);

CREATE TABLE lk_notify_status (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'pending','notified','scheduled','completed','skipped'
);

-- Core
CREATE TABLE recall_campaigns (
  id          int AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(200) NOT NULL UNIQUE, -- tên campaign
  description TEXT,
  start_date  DATE,
  end_date    DATE,
  status_id   int NOT NULL,            -- lk_recall_status
  created_by  int,
  approved_by int,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_rc_status   FOREIGN KEY (status_id)  REFERENCES lk_recall_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_rc_created  FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL,
  CONSTRAINT fk_rc_approved FOREIGN KEY (approved_by) REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL
);

CREATE TABLE recall_units (
  id               int AUTO_INCREMENT PRIMARY KEY,
  campaign_id      int NOT NULL,
  vehicle_id       int NOT NULL,
  notify_status_id int NOT NULL,       -- lk_notify_status
  last_contacted   TIMESTAMP NULL,
  note             VARCHAR(255),
  CONSTRAINT fk_ru_campaign FOREIGN KEY (campaign_id)    REFERENCES recall_campaigns(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ru_vehicle  FOREIGN KEY (vehicle_id)     REFERENCES vehicles(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ru_notify   FOREIGN KEY (notify_status_id) REFERENCES lk_notify_status(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  UNIQUE KEY uq_campaign_vehicle (campaign_id, vehicle_id)
);

-- ======================================================================
-- 8) ATTACHMENTS
-- ======================================================================

-- Lookups
CREATE TABLE lk_entity_type (
  id   int AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE         -- 'claim','work_order','recall_campaign'
);

-- Core
CREATE TABLE attachments (
  id            int AUTO_INCREMENT PRIMARY KEY,
  entity_type_id int NOT NULL,         -- lk_entity_type
  entity_id     int NOT NULL,
  file_name     VARCHAR(255) NOT NULL,
  file_path     VARCHAR(500) NOT NULL,
  uploaded_by   int,
  uploaded_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_att_entity_type FOREIGN KEY (entity_type_id) REFERENCES lk_entity_type(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_att_user        FOREIGN KEY (uploaded_by)   REFERENCES users(id)
    ON UPDATE CASCADE  ON DELETE SET NULL,
INDEX (entity_type_id, entity_id)
);