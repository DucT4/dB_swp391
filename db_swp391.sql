/* =========================================================
   EV WARRANTY – FULL SCHEMA (with Flow-1 & Flow-2)
   Order is FK-safe. Charset: utf8mb4 / Collation: utf8mb4_unicode_ci
   ========================================================= */

DROP DATABASE IF EXISTS ev_warranty;                                    -- Xóa DB cũ (nếu có) để chạy sạch
CREATE DATABASE ev_warranty                                             -- Tạo DB mới
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE ev_warranty;                                                        -- Chọn DB để làm việc

/* =========================================================
   1) LOOKUPS (tất cả bảng danh mục / trạng thái chuẩn)
   ========================================================= */

-- Roles
CREATE TABLE lkp_roles(                                                 -- Vai trò người dùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(50) NOT NULL UNIQUE,                                     -- Tên vai trò (Admin/SC_TECH/SC_MANAGER/EVM_STAFF…)
  description VARCHAR(200)                                              -- Mô tả
);

-- Warehouse types
CREATE TABLE lkp_warehouse_type(                                        -- Loại kho: EVM (hãng) / SC (trung tâm DV)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(30) NOT NULL UNIQUE                                      -- 'EVM' | 'SC'
);

-- Claim status
CREATE TABLE lkp_claim_status(                                          -- Trạng thái yêu cầu bảo hành (Open/Submitted/Approved/Rejected/Closed…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- Approval level
CREATE TABLE lkp_approval_level(                                        -- Cấp duyệt (Manager/EVM…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên cấp
);

-- Shipment status
CREATE TABLE lkp_shipment_status(                                       -- Trạng thái đơn giao hàng (Created/Shipped/Delivered…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- GRN status
CREATE TABLE lkp_grn_status(                                            -- Trạng thái phiếu nhập kho (Draft/Posted…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- Issue status
CREATE TABLE lkp_issue_status(                                          -- Trạng thái phiếu xuất kho (Draft/Posted…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- RMA status
CREATE TABLE lkp_rma_status(                                            -- Trạng thái phiếu trả hàng về hãng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- Allocation status
CREATE TABLE lkp_allocation_status(                                     -- Trạng thái phân bổ/điều phối phụ tùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- Settlement status
CREATE TABLE lkp_settlement_status(                                     -- Trạng thái quyết toán claim
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- Campaign type
CREATE TABLE lkp_campaign_type(                                         -- Loại chiến dịch (Recall/Service…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên loại
);

-- Campaign status
CREATE TABLE lkp_campaign_status(                                       -- Trạng thái chiến dịch (Planned/Active/Closed…)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- (Flow-1) Resolution type (for claims)
CREATE TABLE lkp_resolution_type(                                       -- Kết quả xử lý claim (REPLACE/REPAIR/INSPECT/NFF)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(40) NOT NULL UNIQUE                                      -- Tên loại
);

-- (Flow-1) Assignment status (for claim assignments)
CREATE TABLE lkp_assignment_status(                                     -- Trạng thái giao việc (ASSIGNED/ACCEPTED/IN_PROGRESS/COMPLETED/CANCELLED)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(30) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- (Flow-2) Work order type
CREATE TABLE lkp_work_order_type(                                       -- Loại WO (CAMPAIGN/SERVICE)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(20) NOT NULL UNIQUE                                      -- Tên loại
);

-- (Flow-2) Work order status
CREATE TABLE lkp_work_order_status(                                     -- Trạng thái WO (OPEN/INSPECTING/QUOTED/APPROVED/IN_PROGRESS/DONE/CLOSED/CANCELLED)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(30) NOT NULL UNIQUE                                      -- Tên trạng thái
);

-- (Flow-2) Work order item type
CREATE TABLE lkp_item_type(                                             -- Loại mục trong WO (PART/LABOUR)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(20) NOT NULL UNIQUE                                      -- Tên loại
);

-- (Flow-2) Payment method
CREATE TABLE lkp_payment_method(                                        -- Phương thức thanh toán (CASH/CARD/TRANSFER/EWALLET)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(20) NOT NULL UNIQUE                                      -- Tên phương thức
);

-- (Flow-2) Payment status
CREATE TABLE lkp_payment_status(                                        -- Trạng thái thanh toán (PENDING/PAID/FAILED/REFUNDED)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  name VARCHAR(20) NOT NULL UNIQUE                                      -- Tên trạng thái
);

/* =========================================================
   2) SECURITY / ORG (người dùng, trung tâm dịch vụ, kho)
   ========================================================= */

CREATE TABLE users(                                                     -- Người dùng hệ thống
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  full_name VARCHAR(120) NOT NULL,                                      -- Họ tên
  email VARCHAR(150) NOT NULL UNIQUE,                                   -- Email duy nhất (login)
  phone VARCHAR(20),                                                    -- SĐT
  password_hash VARCHAR(255) NOT NULL,                                  -- Mật khẩu băm
  role_id BIGINT NOT NULL,                                              -- FK → lkp_roles
  is_active TINYINT(1) DEFAULT 1,                                       -- 1=active
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Thời điểm tạo
  FOREIGN KEY (role_id) REFERENCES lkp_roles(id)                        -- Ràng buộc FK
);

CREATE TABLE service_centers(                                           -- Trung tâm dịch vụ (SC)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  code VARCHAR(50) NOT NULL UNIQUE,                                     -- Mã SC
  name VARCHAR(150) NOT NULL,                                           -- Tên SC
  address VARCHAR(200),                                                 -- Địa chỉ
  region VARCHAR(100),                                                  -- Khu vực/miền
  manager_user_id BIGINT,                                               -- FK → users (quản lý SC)
  FOREIGN KEY (manager_user_id) REFERENCES users(id)                    -- Ràng buộc FK
);

CREATE TABLE warehouses(                                                -- Kho vật tư
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  code VARCHAR(50) NOT NULL UNIQUE,                                     -- Mã kho
  name VARCHAR(150) NOT NULL,                                           -- Tên kho
  type_id BIGINT NOT NULL,                                              -- FK → lkp_warehouse_type
  service_center_id BIGINT,                                             -- FK → service_centers (nếu kho SC)
  address VARCHAR(200),                                                 -- Địa chỉ kho
  FOREIGN KEY (type_id) REFERENCES lkp_warehouse_type(id),              -- Ràng buộc FK
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id)        -- Ràng buộc FK
);

/* =========================================================
   3) CUSTOMER / VEHICLE / PARTS
   ========================================================= */

CREATE TABLE customers(                                                 -- Khách hàng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  full_name VARCHAR(150) NOT NULL,                                      -- Họ tên KH
  phone VARCHAR(20),                                                    -- SĐT
  email VARCHAR(150),                                                   -- Email
  address VARCHAR(200),                                                 -- Địa chỉ
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP                        -- Thời điểm tạo
);

CREATE TABLE vehicles(                                                  -- Xe/VIN
  vin VARCHAR(32) PRIMARY KEY,                                          -- VIN (PK)
  model VARCHAR(80) NOT NULL,                                           -- Model
  customer_id BIGINT,                                                   -- FK → customers
  purchase_date DATE,                                                   -- Ngày mua
  coverage_to DATE,                                                     -- Hết hạn BH
  FOREIGN KEY (customer_id) REFERENCES customers(id)                    -- Ràng buộc FK
);

CREATE TABLE parts(                                                     -- Phụ tùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  part_no VARCHAR(64) NOT NULL UNIQUE,                                  -- Mã phụ tùng
  name VARCHAR(150) NOT NULL,                                           -- Tên
  track_serial TINYINT(1) DEFAULT 0,                                    -- Theo dõi serial?
  track_lot TINYINT(1) DEFAULT 0,                                       -- Theo dõi lô?
  uom VARCHAR(20) DEFAULT 'EA'                                          -- ĐVT
);

CREATE TABLE part_policies(                                             -- Chính sách BH theo phụ tùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  part_id BIGINT NOT NULL,                                              -- FK → parts
  warranty_months INT,                                                  -- Tháng BH
  limit_km INT,                                                         -- Km giới hạn
  notes VARCHAR(200),                                                   -- Ghi chú
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE part_substitutions(                                        -- Phụ tùng thay thế tương đương
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  part_id BIGINT NOT NULL,                                              -- FK → parts (gốc)
  substitute_part_id BIGINT NOT NULL,                                   -- FK → parts (thay thế)
  UNIQUE(part_id, substitute_part_id),                                  -- Mỗi cặp 1 lần
  FOREIGN KEY (part_id) REFERENCES parts(id),                           -- Ràng buộc FK
  FOREIGN KEY (substitute_part_id) REFERENCES parts(id)                 -- Ràng buộc FK
);

/* =========================================================
   4) CLAIMS & APPROVAL (Flow-1)
   ========================================================= */

CREATE TABLE claims(                                                    -- Yêu cầu bảo hành
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  vin VARCHAR(32) NOT NULL,                                             -- FK → vehicles
  opened_by BIGINT NOT NULL,                                            -- FK → users (người mở)
  service_center_id BIGINT NOT NULL,                                    -- FK → service_centers (tiếp nhận)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_claim_status
  failure_desc TEXT,                                                    -- Mô tả hư hỏng
  approval_level_id BIGINT,                                             -- FK → lkp_approval_level (nếu đang ở mức duyệt)
  resolution_type_id BIGINT NULL,                                       -- FK → lkp_resolution_type (kết quả xử lý)
  resolution_note VARCHAR(300) NULL,                                    -- Ghi chú kết quả
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Thời điểm tạo
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Cập nhật tự động
  FOREIGN KEY (vin) REFERENCES vehicles(vin),                           -- Ràng buộc FK
  FOREIGN KEY (opened_by) REFERENCES users(id),                         -- Ràng buộc FK
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id),       -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id),              -- Ràng buộc FK
  FOREIGN KEY (approval_level_id) REFERENCES lkp_approval_level(id),    -- Ràng buộc FK
  FOREIGN KEY (resolution_type_id) REFERENCES lkp_resolution_type(id)   -- Ràng buộc FK
);

CREATE TABLE claim_status_history(                                      -- Lịch sử đổi trạng thái claim
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  status_id BIGINT NOT NULL,                                            -- FK → lkp_claim_status
  changed_by BIGINT NOT NULL,                                           -- FK → users
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Thời điểm đổi
  note VARCHAR(200),                                                    -- Ghi chú
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id),              -- Ràng buộc FK
  FOREIGN KEY (changed_by) REFERENCES users(id)                         -- Ràng buộc FK
);

CREATE TABLE claim_approvals(                                           -- Nhật ký phê duyệt claim
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  approver_id BIGINT NOT NULL,                                          -- FK → users
  level_id BIGINT NOT NULL,                                             -- FK → lkp_approval_level
  decision VARCHAR(20) NOT NULL,                                        -- APPROVE/REJECT/…
  decision_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                      -- Thời điểm quyết
  remark VARCHAR(200),                                                  -- Ghi chú
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (approver_id) REFERENCES users(id),                       -- Ràng buộc FK
  FOREIGN KEY (level_id) REFERENCES lkp_approval_level(id)              -- Ràng buộc FK
);

CREATE TABLE claim_parts(                                               -- Phụ tùng cho claim (kế hoạch/thực dùng)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty DECIMAL(12,2) NOT NULL,                                           -- Số lượng
  planned TINYINT(1) DEFAULT 1,                                         -- 1=planned, 0=actual
  serial_no VARCHAR(100),                                               -- Serial nếu có
  lot_no VARCHAR(50),                                                   -- Lô nếu có
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE claim_labour(                                              -- Công lao động cho claim
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  technician_id BIGINT,                                                 -- FK → users (kỹ thuật viên)
  hours DECIMAL(6,2) NOT NULL,                                          -- Giờ công
  rate DECIMAL(10,2) NOT NULL,                                          -- Đơn giá
  note VARCHAR(200),                                                    -- Ghi chú
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (technician_id) REFERENCES users(id)                      -- Ràng buộc FK
);

CREATE TABLE claim_assignments(                                         -- Giao việc claim cho technician (Flow-1)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  technician_id BIGINT NOT NULL,                                        -- FK → users (nhận việc)
  assigned_by BIGINT NOT NULL,                                          -- FK → users (người giao)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_assignment_status
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                      -- Lúc giao
  accepted_at TIMESTAMP NULL,                                           -- Lúc nhận
  started_at TIMESTAMP NULL,                                            -- Lúc bắt đầu
  completed_at TIMESTAMP NULL,                                          -- Lúc hoàn thành
  note VARCHAR(200),                                                    -- Ghi chú
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (technician_id) REFERENCES users(id),                     -- Ràng buộc FK
  FOREIGN KEY (assigned_by) REFERENCES users(id),                       -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_assignment_status(id)          -- Ràng buộc FK
);

/* =========================================================
   5) CAMPAIGNS
   ========================================================= */

CREATE TABLE campaigns(                                                 -- Chiến dịch (recall/service)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  type_id BIGINT NOT NULL,                                              -- FK → lkp_campaign_type
  name VARCHAR(150) NOT NULL,                                           -- Tên
  description TEXT,                                                     -- Mô tả
  start_date DATE,                                                      -- Bắt đầu
  end_date DATE,                                                        -- Kết thúc
  created_by BIGINT,                                                    -- FK → users (EVM_STAFF)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_campaign_status
  FOREIGN KEY (type_id) REFERENCES lkp_campaign_type(id),               -- Ràng buộc FK
  FOREIGN KEY (created_by) REFERENCES users(id),                        -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_campaign_status(id)            -- Ràng buộc FK
);

CREATE TABLE campaign_vins(                                             -- VIN nằm trong chiến dịch
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  campaign_id BIGINT NOT NULL,                                          -- FK → campaigns
  vin VARCHAR(32) NOT NULL,                                             -- FK → vehicles
  status VARCHAR(30) DEFAULT 'Planned',                                 -- Trạng thái VIN trong campaign
  UNIQUE(campaign_id, vin),                                             -- Mỗi VIN 1 lần/campaign
  FOREIGN KEY (campaign_id) REFERENCES campaigns(id),                   -- Ràng buộc FK
  FOREIGN KEY (vin) REFERENCES vehicles(vin)                            -- Ràng buộc FK
);

/* =========================================================
   6) WORK ORDERS (Flow-2 – thực thi tại SC)
   ========================================================= */

CREATE TABLE work_orders(                                               -- Work Order (CAMPAIGN/SERVICE)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  type_id BIGINT NOT NULL,                                              -- FK → lkp_work_order_type
  campaign_id BIGINT NULL,                                              -- FK → campaigns (nếu CAMPAIGN)
  vin VARCHAR(32) NOT NULL,                                             -- FK → vehicles
  service_center_id BIGINT NOT NULL,                                    -- FK → service_centers
  created_by BIGINT NOT NULL,                                           -- FK → users (SC_STAFF)
  assigned_tech_id BIGINT NULL,                                         -- FK → users (tech)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_work_order_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Cập nhật
  FOREIGN KEY (type_id) REFERENCES lkp_work_order_type(id),             -- Ràng buộc FK
  FOREIGN KEY (campaign_id) REFERENCES campaigns(id),                   -- Ràng buộc FK
  FOREIGN KEY (vin) REFERENCES vehicles(vin),                           -- Ràng buộc FK
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id),       -- Ràng buộc FK
  FOREIGN KEY (created_by) REFERENCES users(id),                        -- Ràng buộc FK
  FOREIGN KEY (assigned_tech_id) REFERENCES users(id),                  -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_work_order_status(id)          -- Ràng buộc FK
);

CREATE TABLE work_order_inspections(                                    -- Biên bản kiểm tra WO
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  work_order_id BIGINT NOT NULL,                                        -- FK → work_orders
  inspected_by BIGINT NOT NULL,                                         -- FK → users (SC_TECH)
  report TEXT,                                                          -- Nội dung biên bản
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id),               -- Ràng buộc FK
  FOREIGN KEY (inspected_by) REFERENCES users(id)                       -- Ràng buộc FK
);

CREATE TABLE work_order_items(                                          -- Mục công việc/vật tư (PART/LABOUR)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  work_order_id BIGINT NOT NULL,                                        -- FK → work_orders
  item_type_id BIGINT NOT NULL,                                         -- FK → lkp_item_type
  description VARCHAR(200),                                             -- Mô tả
  part_id BIGINT NULL,                                                  -- FK → parts (nếu PART)
  qty DECIMAL(10,2) DEFAULT 1,                                          -- Số lượng
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,                          -- Đơn giá (báo giá/thu tiền)
  is_approved TINYINT(1) DEFAULT 0,                                     -- KH chấp thuận?
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id),               -- Ràng buộc FK
  FOREIGN KEY (item_type_id) REFERENCES lkp_item_type(id),              -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE customer_payments(                                         -- Thanh toán của KH cho WO
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  work_order_id BIGINT NOT NULL,                                        -- FK → work_orders
  method_id BIGINT NOT NULL,                                            -- FK → lkp_payment_method
  status_id BIGINT NOT NULL,                                            -- FK → lkp_payment_status
  amount DECIMAL(12,2) NOT NULL,                                        -- Số tiền
  paid_at TIMESTAMP NULL,                                               -- Thời điểm trả (nếu PAID)
  note VARCHAR(200),                                                    -- Ghi chú
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id),               -- Ràng buộc FK
  FOREIGN KEY (method_id) REFERENCES lkp_payment_method(id),            -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_payment_status(id)             -- Ràng buộc FK
);

/* =========================================================
   7) INVENTORY (tồn kho, cấp phát, giao nhận, xuất/nhập, RMA)
   ========================================================= */

CREATE TABLE stock(                                                     -- Tồn kho theo kho/phụ tùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  warehouse_id BIGINT NOT NULL,                                         -- FK → warehouses
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty_on_hand DECIMAL(12,2) DEFAULT 0,                                  -- SL hiện có
  qty_reserved DECIMAL(12,2) DEFAULT 0,                                 -- SL giữ chỗ
  UNIQUE(warehouse_id, part_id),                                        -- Duy nhất mỗi kho–part
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),                 -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE stock_serials(                                             -- Theo dõi từng serial
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  part_id BIGINT NOT NULL,                                              -- FK → parts
  serial_no VARCHAR(100) NOT NULL,                                      -- Số serial
  warehouse_id BIGINT NOT NULL,                                         -- FK → warehouses
  status VARCHAR(20) NOT NULL,                                          -- ON_HAND/RESERVED/ISSUED/RMA
  UNIQUE(serial_no, part_id),                                           -- Serial duy nhất theo part
  FOREIGN KEY (part_id) REFERENCES parts(id),                           -- Ràng buộc FK
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)                  -- Ràng buộc FK
);

CREATE TABLE parts_requests(                                            -- Yêu cầu cấp phát phụ tùng từ SC
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  service_center_id BIGINT NOT NULL,                                    -- FK → service_centers
  requested_by BIGINT NOT NULL,                                         -- FK → users (người tạo)
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty DECIMAL(12,2) NOT NULL,                                           -- Số lượng yêu cầu
  status_id BIGINT NOT NULL,                                            -- FK → lkp_allocation_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id),       -- Ràng buộc FK
  FOREIGN KEY (requested_by) REFERENCES users(id),                      -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id),                           -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id)          -- Ràng buộc FK
);

CREATE TABLE parts_allocations(                                         -- Phân bổ/điều chuyển phụ tùng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  request_id BIGINT,                                                    -- FK → parts_requests (có thể NULL)
  claim_id BIGINT,                                                      -- FK → claims (có thể NULL)
  source_wh_id BIGINT NOT NULL,                                         -- FK → warehouses (kho nguồn)
  dest_wh_id BIGINT NOT NULL,                                           -- FK → warehouses (kho đích)
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty_alloc DECIMAL(12,2) NOT NULL,                                     -- Số lượng phân bổ
  eta_date DATE,                                                        -- Dự kiến đến
  status_id BIGINT NOT NULL,                                            -- FK → lkp_allocation_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (request_id) REFERENCES parts_requests(id),               -- Ràng buộc FK
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id),                 -- Ràng buộc FK
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),                   -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id),                           -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id)          -- Ràng buộc FK
);

CREATE TABLE shipments(                                                 -- Đơn giao hàng (DO)
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  do_no VARCHAR(50) NOT NULL UNIQUE,                                    -- Số DO
  source_wh_id BIGINT NOT NULL,                                         -- FK → warehouses
  dest_wh_id BIGINT NOT NULL,                                           -- FK → warehouses
  carrier VARCHAR(100),                                                 -- Hãng VC (nếu có)
  tracking_no VARCHAR(100),                                             -- Mã tracking (nếu có)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_shipment_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id),                 -- Ràng buộc FK
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),                   -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_shipment_status(id)            -- Ràng buộc FK
);

CREATE TABLE shipment_lines(                                            -- Dòng chi tiết shipment
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  shipment_id BIGINT NOT NULL,                                          -- FK → shipments
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty DECIMAL(12,2) NOT NULL,                                           -- Số lượng
  lot_no VARCHAR(50),                                                   -- Mã lô (nếu có)
  FOREIGN KEY (shipment_id) REFERENCES shipments(id),                   -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE grn(                                                       -- Phiếu nhập kho từ shipment
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  shipment_id BIGINT NOT NULL,                                          -- FK → shipments
  warehouse_id BIGINT NOT NULL,                                         -- FK → warehouses
  received_by BIGINT NOT NULL,                                          -- FK → users (người nhận)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_grn_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (shipment_id) REFERENCES shipments(id),                   -- Ràng buộc FK
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),                 -- Ràng buộc FK
  FOREIGN KEY (received_by) REFERENCES users(id),                       -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_grn_status(id)                 -- Ràng buộc FK
);

CREATE TABLE grn_lines(                                                 -- Dòng chi tiết nhập kho
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  grn_id BIGINT NOT NULL,                                               -- FK → grn
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty_ok DECIMAL(12,2) DEFAULT 0,                                       -- SL đạt
  qty_damaged DECIMAL(12,2) DEFAULT 0,                                  -- SL hỏng
  FOREIGN KEY (grn_id) REFERENCES grn(id),                              -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE issues(                                                    -- Phiếu xuất kho cho claim/WO
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  warehouse_id BIGINT NOT NULL,                                         -- FK → warehouses
  requested_by BIGINT NOT NULL,                                         -- FK → users (người yêu cầu)
  issued_by BIGINT,                                                     -- FK → users (người xuất)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_issue_status
  work_order_id BIGINT NULL,                                            -- FK → work_orders (Flow-2, nếu xuất cho WO)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),                 -- Ràng buộc FK
  FOREIGN KEY (requested_by) REFERENCES users(id),                      -- Ràng buộc FK
  FOREIGN KEY (issued_by) REFERENCES users(id),                         -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_issue_status(id),              -- Ràng buộc FK
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id)                -- Ràng buộc FK
);

CREATE TABLE issue_lines(                                               -- Dòng chi tiết xuất kho
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  issue_id BIGINT NOT NULL,                                             -- FK → issues
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty DECIMAL(12,2) NOT NULL,                                           -- Số lượng
  serial_no VARCHAR(100),                                               -- Serial (nếu có)
  lot_no VARCHAR(50),                                                   -- Lô (nếu có)
  FOREIGN KEY (issue_id) REFERENCES issues(id),                         -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

CREATE TABLE rma(                                                       -- Phiếu hoàn trả về hãng
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL,                                             -- FK → claims
  from_wh_id BIGINT NOT NULL,                                           -- FK → warehouses (kho gửi)
  to_wh_id BIGINT NOT NULL,                                             -- FK → warehouses (kho nhận – thường EVM)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_rma_status
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Tạo
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (from_wh_id) REFERENCES warehouses(id),                   -- Ràng buộc FK
  FOREIGN KEY (to_wh_id) REFERENCES warehouses(id),                     -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_rma_status(id)                 -- Ràng buộc FK
);

CREATE TABLE rma_lines(                                                 -- Dòng chi tiết RMA
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  rma_id BIGINT NOT NULL,                                               -- FK → rma
  part_id BIGINT NOT NULL,                                              -- FK → parts
  qty DECIMAL(12,2) NOT NULL,                                           -- Số lượng
  serial_no VARCHAR(100),                                               -- Serial (nếu có)
  reason VARCHAR(200),                                                  -- Lý do trả
  FOREIGN KEY (rma_id) REFERENCES rma(id),                              -- Ràng buộc FK
  FOREIGN KEY (part_id) REFERENCES parts(id)                            -- Ràng buộc FK
);

/* =========================================================
   8) SETTLEMENTS (quyết toán claim)
   ========================================================= */

CREATE TABLE settlements(                                               -- Quyết toán 1–1 theo claim
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  claim_id BIGINT NOT NULL UNIQUE,                                      -- FK → claims (mỗi claim tối đa 1 settlement)
  status_id BIGINT NOT NULL,                                            -- FK → lkp_settlement_status
  submitted_by BIGINT,                                                  -- User submit (SC_MANAGER)
  submitted_at TIMESTAMP NULL,                                          -- Thời điểm submit
  approved_by BIGINT,                                                   -- User approve (EVM_STAFF)
  approved_at TIMESTAMP NULL,                                           -- Thời điểm approve
  total_parts DECIMAL(12,2) DEFAULT 0,                                  -- Tổng tiền parts
  total_labour DECIMAL(12,2) DEFAULT 0,                                 -- Tổng tiền công
  total_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_parts + total_labour) STORED, -- Tổng cộng (computed)
  FOREIGN KEY (claim_id) REFERENCES claims(id),                         -- Ràng buộc FK
  FOREIGN KEY (status_id) REFERENCES lkp_settlement_status(id)          -- Ràng buộc FK
);

CREATE TABLE settlement_items(                                          -- Chi tiết dòng quyết toán
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  settlement_id BIGINT NOT NULL,                                        -- FK → settlements
  item_type VARCHAR(20) NOT NULL,                                       -- 'PART' | 'LABOUR' (giữ text vì chỉ 2 loại)
  description VARCHAR(200),                                             -- Mô tả
  qty DECIMAL(10,2) DEFAULT 1,                                          -- SL
  unit_price DECIMAL(12,2) NOT NULL,                                    -- Đơn giá
  amount DECIMAL(12,2) GENERATED ALWAYS AS (qty*unit_price) STORED,     -- Thành tiền (computed)
  FOREIGN KEY (settlement_id) REFERENCES settlements(id)                -- Ràng buộc FK
);

/* =========================================================
   9) AUDIT (nhật ký thay đổi)
   ========================================================= */

CREATE TABLE audit_logs(                                                -- Audit logs
  id BIGINT AUTO_INCREMENT PRIMARY KEY,                                 -- PK
  actor_id BIGINT,                                                      -- FK → users (ai thao tác)
  action VARCHAR(60) NOT NULL,                                          -- Hành động (CREATE/UPDATE/…)
  entity VARCHAR(60) NOT NULL,                                          -- Tên bảng/đối tượng
  entity_id BIGINT,                                                     -- ID bản ghi
  before_json JSON,                                                     -- Dữ liệu trước
  after_json JSON,                                                      -- Dữ liệu sau
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Thời điểm log
  FOREIGN KEY (actor_id) REFERENCES users(id)                           -- Ràng buộc FK
);

/* =========================================================
   END OF SCHEMA
   - Bạn có thể thêm seed cho lookups bên dưới (tùy chọn)
   ========================================================= */