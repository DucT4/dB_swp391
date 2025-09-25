

CREATE DATABASE ev_warranty
USE ev_warranty;

-- =========================================================
-- 1) LOOKUPS (các bảng danh mục / trạng thái chuẩn)
-- =========================================================
CREATE TABLE lkp_roles(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,      -- Admin, SC_STAFF, SC_TECH, SC_MANAGER, SC_STOREKEEPER, EVM_STAFF
  description VARCHAR(200)
);

CREATE TABLE lkp_warehouse_type(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(30) NOT NULL UNIQUE       -- EVM = kho hãng, SC = kho service center
);

CREATE TABLE lkp_claim_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Open, Pending Manager, Pending EVM, Approved, In Repair, Closed...
);

CREATE TABLE lkp_approval_level(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Cấp phê duyệt: Manager hoặc EVM
);

CREATE TABLE lkp_shipment_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái vận chuyển: Created, Shipped, Delivered...
);

CREATE TABLE lkp_grn_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái phiếu nhập kho
);

CREATE TABLE lkp_issue_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái phiếu xuất kho
);

CREATE TABLE lkp_rma_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái trả linh kiện (SC -> EVM)
);

CREATE TABLE lkp_allocation_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái phân bổ phụ tùng
);

CREATE TABLE lkp_settlement_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Trạng thái quyết toán
);

CREATE TABLE lkp_campaign_type(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Recall, Service Campaign
);

CREATE TABLE lkp_campaign_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE       -- Active, Planned, Done
);

-- =========================================================
-- 2) SECURITY / ORG (người dùng, trung tâm dịch vụ, kho)
-- =========================================================
CREATE TABLE users(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(20),
  password_hash VARCHAR(255) NOT NULL,
  role_id BIGINT NOT NULL,               -- FK đến lkp_roles
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES lkp_roles(id)
);

CREATE TABLE service_centers(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,      -- Mã SC
  name VARCHAR(150) NOT NULL,            -- Tên SC
  address VARCHAR(200),
  region VARCHAR(100),
  manager_user_id BIGINT,                -- User có role = SC_MANAGER
  FOREIGN KEY (manager_user_id) REFERENCES users(id)
);

CREATE TABLE warehouses(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,      -- Mã kho
  name VARCHAR(150) NOT NULL,
  type_id BIGINT NOT NULL,               -- EVM hoặc SC
  service_center_id BIGINT,              -- Nếu là kho SC thì gắn với SC
  address VARCHAR(200),
  FOREIGN KEY (type_id) REFERENCES lkp_warehouse_type(id),
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id)
);

-- =========================================================
-- 3) CUSTOMER / VEHICLE / PARTS
-- =========================================================
CREATE TABLE customers(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(150),
  address VARCHAR(200),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicles(
  vin VARCHAR(32) PRIMARY KEY,           -- Số VIN xe điện
  model VARCHAR(80) NOT NULL,
  customer_id BIGINT,                    -- Chủ xe
  purchase_date DATE,
  coverage_to DATE,                      -- Ngày hết hạn bảo hành
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE parts(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  part_no VARCHAR(64) NOT NULL UNIQUE,   -- Mã phụ tùng
  name VARCHAR(150) NOT NULL,
  track_serial TINYINT(1) DEFAULT 0,     -- Có quản lý theo số serial?
  track_lot TINYINT(1) DEFAULT 0,        -- Có quản lý theo lô?
  uom VARCHAR(20) DEFAULT 'EA'           -- Đơn vị tính
);

CREATE TABLE part_policies(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  part_id BIGINT NOT NULL,
  warranty_months INT,                   -- Số tháng bảo hành
  limit_km INT,                          -- Km giới hạn (nếu có)
  notes VARCHAR(200),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE part_substitutions(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  part_id BIGINT NOT NULL,               -- Phụ tùng gốc
  substitute_part_id BIGINT NOT NULL,    -- Phụ tùng thay thế
  UNIQUE(part_id, substitute_part_id),
  FOREIGN KEY (part_id) REFERENCES parts(id),
  FOREIGN KEY (substitute_part_id) REFERENCES parts(id)
);

-- =========================================================
-- 4) CLAIMS & APPROVAL (yêu cầu bảo hành)
-- =========================================================
CREATE TABLE claims(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  vin VARCHAR(32) NOT NULL,              -- Xe bị lỗi
  opened_by BIGINT NOT NULL,             -- SC Staff tạo
  service_center_id BIGINT NOT NULL,
  status_id BIGINT NOT NULL,             -- Trạng thái hiện tại
  failure_desc TEXT,                     -- Mô tả hỏng hóc
  approval_level_id BIGINT,              -- Nếu đã duyệt, bởi Manager/EVM
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (vin) REFERENCES vehicles(vin),
  FOREIGN KEY (opened_by) REFERENCES users(id),
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id),
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id),
  FOREIGN KEY (approval_level_id) REFERENCES lkp_approval_level(id)
);

CREATE TABLE claim_status_history(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  status_id BIGINT NOT NULL,
  changed_by BIGINT NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  note VARCHAR(200),
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id),
  FOREIGN KEY (changed_by) REFERENCES users(id)
);

CREATE TABLE claim_approvals(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  approver_id BIGINT NOT NULL,           -- Manager hoặc EVM staff
  level_id BIGINT NOT NULL,
  decision VARCHAR(20) NOT NULL,         -- Approved / Rejected
  decision_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  remark VARCHAR(200),
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (approver_id) REFERENCES users(id),
  FOREIGN KEY (level_id) REFERENCES lkp_approval_level(id)
);

CREATE TABLE claim_parts(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  planned TINYINT(1) DEFAULT 1,          -- 1: dự kiến, 0: thực tế
  serial_no VARCHAR(100),
  lot_no VARCHAR(50),
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE claim_labour(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  technician_id BIGINT,                  -- User có role SC_TECH
  hours DECIMAL(6,2) NOT NULL,
  rate DECIMAL(10,2) NOT NULL,
  note VARCHAR(200),
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (technician_id) REFERENCES users(id)
);

-- =========================================================
-- 5) SETTLEMENT (quyết toán chi phí)
-- =========================================================
CREATE TABLE settlements(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL UNIQUE,       -- 1 claim = 1 settlement
  status_id BIGINT NOT NULL,
  submitted_by BIGINT,                   -- SC Manager submit
  submitted_at TIMESTAMP NULL,
  approved_by BIGINT,                    -- EVM Staff approve
  approved_at TIMESTAMP NULL,
  total_parts DECIMAL(12,2) DEFAULT 0,
  total_labour DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_parts + total_labour) STORED,
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (status_id) REFERENCES lkp_settlement_status(id)
);

CREATE TABLE settlement_items(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  settlement_id BIGINT NOT NULL,
  item_type VARCHAR(20) NOT NULL,        -- PART hoặc LABOUR
  description VARCHAR(200),
  qty DECIMAL(10,2) DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  amount DECIMAL(12,2) GENERATED ALWAYS AS (qty*unit_price) STORED,
  FOREIGN KEY (settlement_id) REFERENCES settlements(id)
);

-- =========================================================
-- 6) INVENTORY (quản lý kho)
-- =========================================================
CREATE TABLE stock(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  warehouse_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty_on_hand DECIMAL(12,2) DEFAULT 0,
  qty_reserved DECIMAL(12,2) DEFAULT 0,
  UNIQUE(warehouse_id, part_id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE stock_serials(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  part_id BIGINT NOT NULL,
  serial_no VARCHAR(100) NOT NULL,
  warehouse_id BIGINT NOT NULL,
  status VARCHAR(20) NOT NULL,           -- ON_HAND, RESERVED, ISSUED, RMA
  UNIQUE(serial_no, part_id),
  FOREIGN KEY (part_id) REFERENCES parts(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);

CREATE TABLE parts_requests(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  service_center_id BIGINT NOT NULL,
  requested_by BIGINT NOT NULL,          -- User SC_STOREKEEPER tạo
  part_id BIGINT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id),
  FOREIGN KEY (requested_by) REFERENCES users(id),
  FOREIGN KEY (part_id) REFERENCES parts(id),
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id)
);

CREATE TABLE parts_allocations(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  request_id BIGINT,
  claim_id BIGINT,                       -- Có thể allocate trực tiếp cho claim
  source_wh_id BIGINT NOT NULL,
  dest_wh_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty_alloc DECIMAL(12,2) NOT NULL,
  eta_date DATE,
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (request_id) REFERENCES parts_requests(id),
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (part_id) REFERENCES parts(id),
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id)
);

CREATE TABLE shipments(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  do_no VARCHAR(50) NOT NULL UNIQUE,     -- Delivery Order No
  source_wh_id BIGINT NOT NULL,
  dest_wh_id BIGINT NOT NULL,
  carrier VARCHAR(100),
  tracking_no VARCHAR(100),
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (status_id) REFERENCES lkp_shipment_status(id)
);

CREATE TABLE shipment_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  shipment_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  lot_no VARCHAR(50),
  FOREIGN KEY (shipment_id) REFERENCES shipments(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE grn(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  shipment_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL,
  received_by BIGINT NOT NULL,           -- SC_STOREKEEPER
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shipment_id) REFERENCES shipments(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  FOREIGN KEY (received_by) REFERENCES users(id),
  FOREIGN KEY (status_id) REFERENCES lkp_grn_status(id)
);

CREATE TABLE grn_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  grn_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty_ok DECIMAL(12,2) DEFAULT 0,
  qty_damaged DECIMAL(12,2) DEFAULT 0,
  FOREIGN KEY (grn_id) REFERENCES grn(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE issues(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL,
  requested_by BIGINT NOT NULL,          -- SC_TECH yêu cầu
  issued_by BIGINT,                      -- SC_STOREKEEPER xuất kho
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  FOREIGN KEY (requested_by) REFERENCES users(id),
  FOREIGN KEY (issued_by) REFERENCES users(id),
  FOREIGN KEY (status_id) REFERENCES lkp_issue_status(id)
);

CREATE TABLE issue_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  issue_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  serial_no VARCHAR(100),
  lot_no VARCHAR(50),
  FOREIGN KEY (issue_id) REFERENCES issues(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

CREATE TABLE rma(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT NOT NULL,
  from_wh_id BIGINT NOT NULL,            -- Kho SC
  to_wh_id BIGINT NOT NULL,              -- Kho EVM
  status_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(id),
  FOREIGN KEY (from_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (to_wh_id) REFERENCES warehouses(id),
  FOREIGN KEY (status_id) REFERENCES lkp_rma_status(id)
);

CREATE TABLE rma_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  rma_id BIGINT NOT NULL,
  part_id BIGINT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  serial_no VARCHAR(100),
  reason VARCHAR(200),
  FOREIGN KEY (rma_id) REFERENCES rma(id),
  FOREIGN KEY (part_id) REFERENCES parts(id)
);

-- =========================================================
-- 7) CAMPAIGNS (recall & service)
-- =========================================================
CREATE TABLE campaigns(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  type_id BIGINT NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_by BIGINT,                      -- EVM Staff tạo
  status_id BIGINT NOT NULL,
  FOREIGN KEY (type_id) REFERENCES lkp_campaign_type(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (status_id) REFERENCES lkp_campaign_status(id)
);

CREATE TABLE campaign_vins(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  campaign_id BIGINT NOT NULL,
  vin VARCHAR(32) NOT NULL,
  status VARCHAR(30) DEFAULT 'Planned',   -- Trạng thái xử lý VIN
  UNIQUE(campaign_id, vin),
  FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
  FOREIGN KEY (vin) REFERENCES vehicles(vin)
);

-- =========================================================
-- 8) AUDIT (theo dõi hành động hệ thống)
-- =========================================================
CREATE TABLE audit_logs(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT,                        -- User thực hiện hành động
  action VARCHAR(60) NOT NULL,            -- Ví dụ: CREATE_CLAIM, APPROVE_EVM
  entity VARCHAR(60) NOT NULL,            -- Bảng liên quan (claims, issues…)
  entity_id BIGINT,                       -- Khóa chính của entity
  before_json JSON,                       -- Dữ liệu trước thay đổi
  after_json JSON,                        -- Dữ liệu sau thay đổi
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (actor_id) REFERENCES users(id)
);