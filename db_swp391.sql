
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
