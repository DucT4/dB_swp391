-- Tạo CSDL tên ev_warranty
CREATE DATABASE ev_warranty;

-- Chuyển context sang CSDL vừa tạo
USE ev_warranty;

-- =========================================================
-- 1) LOOKUPS (các bảng danh mục / trạng thái chuẩn)
-- =========================================================

-- Bảng danh mục vai trò người dùng (quyền/role)
CREATE TABLE lkp_roles(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính tự tăng
  name VARCHAR(50) NOT NULL UNIQUE,            -- Tên vai trò, duy nhất (Admin, SC_STAFF, ...)
  description VARCHAR(200)                     -- Mô tả ngắn cho vai trò
);

-- Bảng loại kho: kho hãng (EVM) hay kho trung tâm dịch vụ (SC)
CREATE TABLE lkp_warehouse_type(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(30) NOT NULL UNIQUE             -- Tên loại kho, duy nhất: 'EVM' hoặc 'SC'
);

-- Bảng trạng thái yêu cầu bảo hành (claim)
CREATE TABLE lkp_claim_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Tên trạng thái: Open, Pending..., Closed...
);

-- Bảng cấp phê duyệt (Manager / EVM)
CREATE TABLE lkp_approval_level(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Tên cấp phê duyệt
);

-- Bảng trạng thái vận chuyển (shipment)
CREATE TABLE lkp_shipment_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Created, Shipped, Delivered...
);

-- Bảng trạng thái GRN (phiếu nhập kho)
CREATE TABLE lkp_grn_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Trạng thái phiếu GRN
);

-- Bảng trạng thái Issue (phiếu xuất kho)
CREATE TABLE lkp_issue_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Trạng thái phiếu Issue
);

-- Bảng trạng thái RMA (trả hàng về hãng)
CREATE TABLE lkp_rma_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Trạng thái phiếu RMA
);

-- Bảng trạng thái phân bổ/điều phối phụ tùng
CREATE TABLE lkp_allocation_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Trạng thái phân bổ (Requested, Allocated, ...)
);

-- Bảng trạng thái quyết toán
CREATE TABLE lkp_settlement_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Trạng thái quyết toán (Draft, Submitted, ...)
);

-- Bảng loại chiến dịch (Recall/Service Campaign)
CREATE TABLE lkp_campaign_type(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- 'Recall' hoặc 'Service Campaign'
);

-- Bảng trạng thái chiến dịch
CREATE TABLE lkp_campaign_status(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  name VARCHAR(40) NOT NULL UNIQUE             -- Active, Planned, Done, ...
);

-- =========================================================
-- 2) SECURITY / ORG (người dùng, trung tâm dịch vụ, kho)
-- =========================================================

-- Bảng người dùng của hệ thống
CREATE TABLE users(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  full_name VARCHAR(120) NOT NULL,             -- Họ tên
  email VARCHAR(150) NOT NULL UNIQUE,          -- Email đăng nhập (duy nhất)
  phone VARCHAR(20),                           -- Số điện thoại
  password_hash VARCHAR(255) NOT NULL,         -- Mật khẩu đã băm
  role_id BIGINT NOT NULL,                     -- Tham chiếu vai trò (FK -> lkp_roles)
  is_active TINYINT(1) DEFAULT 1,              -- Kích hoạt tài khoản (1) hay khóa (0)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian tạo
  FOREIGN KEY (role_id) REFERENCES lkp_roles(id)  -- Ràng buộc khóa ngoại tới lkp_roles
);

-- Bảng trung tâm dịch vụ (Service Center - SC)
CREATE TABLE service_centers(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  code VARCHAR(50) NOT NULL UNIQUE,            -- Mã SC duy nhất
  name VARCHAR(150) NOT NULL,                  -- Tên SC
  address VARCHAR(200),                        -- Địa chỉ
  region VARCHAR(100),                         -- Khu vực/miền
  manager_user_id BIGINT,                      -- User là SC_MANAGER quản lý SC
  FOREIGN KEY (manager_user_id) REFERENCES users(id) -- FK tới users
);

-- Bảng kho (Warehouse) - có thể là kho EVM hoặc kho thuộc SC
CREATE TABLE warehouses(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  code VARCHAR(50) NOT NULL UNIQUE,            -- Mã kho duy nhất
  name VARCHAR(150) NOT NULL,                  -- Tên kho
  type_id BIGINT NOT NULL,                     -- Loại kho (FK -> lkp_warehouse_type)
  service_center_id BIGINT,                    -- Nếu kho SC thì gán với SC này
  address VARCHAR(200),                        -- Địa chỉ kho
  FOREIGN KEY (type_id) REFERENCES lkp_warehouse_type(id), -- FK loại kho
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id) -- FK tới SC
);

-- =========================================================
-- 3) CUSTOMER / VEHICLE / PARTS
-- =========================================================

-- Bảng khách hàng (chủ xe)
CREATE TABLE customers(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  full_name VARCHAR(150) NOT NULL,             -- Họ tên KH
  phone VARCHAR(20),                           -- SĐT
  email VARCHAR(150),                          -- Email
  address VARCHAR(200),                        -- Địa chỉ
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Ngày tạo
);

-- Bảng xe (Vehicle) - dùng VIN làm khóa chính
CREATE TABLE vehicles(
  vin VARCHAR(32) PRIMARY KEY,                 -- VIN xe (khóa chính)
  model VARCHAR(80) NOT NULL,                  -- Model xe
  customer_id BIGINT,                          -- FK tới khách hàng sở hữu
  purchase_date DATE,                          -- Ngày mua
  coverage_to DATE,                            -- Ngày hết hạn bảo hành
  FOREIGN KEY (customer_id) REFERENCES customers(id) -- FK khách hàng
);

-- Bảng danh mục phụ tùng
CREATE TABLE parts(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  part_no VARCHAR(64) NOT NULL UNIQUE,         -- Mã phụ tùng (duy nhất)
  name VARCHAR(150) NOT NULL,                  -- Tên phụ tùng
  track_serial TINYINT(1) DEFAULT 0,           -- 1: quản lý theo serial
  track_lot TINYINT(1) DEFAULT 0,              -- 1: quản lý theo lô
  uom VARCHAR(20) DEFAULT 'EA'                 -- Đơn vị tính (mặc định 'EA' = each)
);

-- Bảng chính sách bảo hành gắn với phụ tùng
CREATE TABLE part_policies(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  part_id BIGINT NOT NULL,                     -- FK tới parts
  warranty_months INT,                         -- Số tháng bảo hành
  limit_km INT,                                -- Giới hạn km nếu có
  notes VARCHAR(200),                           -- Ghi chú
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK parts
);

-- Bảng map phụ tùng thay thế (part A có thể thay bằng part B)
CREATE TABLE part_substitutions(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  part_id BIGINT NOT NULL,                     -- Part gốc (FK -> parts)
  substitute_part_id BIGINT NOT NULL,          -- Part thay thế (FK -> parts)
  UNIQUE(part_id, substitute_part_id),         -- Tránh trùng cặp map
  FOREIGN KEY (part_id) REFERENCES parts(id),  -- FK part gốc
  FOREIGN KEY (substitute_part_id) REFERENCES parts(id) -- FK part thay thế
);

-- =========================================================
-- 4) CLAIMS & APPROVAL (yêu cầu bảo hành)
-- =========================================================

-- Bảng Claim (yêu cầu bảo hành)
CREATE TABLE claims(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  vin VARCHAR(32) NOT NULL,                    -- VIN xe bị lỗi
  opened_by BIGINT NOT NULL,                   -- User SC Staff tạo claim
  service_center_id BIGINT NOT NULL,           -- SC phụ trách claim
  status_id BIGINT NOT NULL,                   -- Trạng thái hiện tại (FK -> lkp_claim_status)
  failure_desc TEXT,                           -- Mô tả hỏng hóc
  approval_level_id BIGINT,                    -- Cấp phê duyệt đã dùng (nếu có)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Thời điểm cập nhật
  FOREIGN KEY (vin) REFERENCES vehicles(vin),  -- FK tới vehicles
  FOREIGN KEY (opened_by) REFERENCES users(id),-- FK người mở
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id), -- FK SC
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id), -- FK trạng thái
  FOREIGN KEY (approval_level_id) REFERENCES lkp_approval_level(id) -- FK cấp duyệt
);

-- Lịch sử trạng thái của Claim
CREATE TABLE claim_status_history(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- FK claim
  status_id BIGINT NOT NULL,                   -- Trạng thái sau khi đổi
  changed_by BIGINT NOT NULL,                  -- Ai đổi (user)
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Khi nào đổi
  note VARCHAR(200),                           -- Ghi chú chuyển trạng thái
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (status_id) REFERENCES lkp_claim_status(id), -- FK trạng thái
  FOREIGN KEY (changed_by) REFERENCES users(id) -- FK user đổi
);

-- Log các lần phê duyệt claim (Manager/EVM)
CREATE TABLE claim_approvals(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- FK claim
  approver_id BIGINT NOT NULL,                 -- Người duyệt (user)
  level_id BIGINT NOT NULL,                    -- Cấp duyệt (Manager/EVM)
  decision VARCHAR(20) NOT NULL,               -- Kết quả: Approved/Rejected
  decision_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm quyết định
  remark VARCHAR(200),                          -- Ghi chú duyệt
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (approver_id) REFERENCES users(id), -- FK user duyệt
  FOREIGN KEY (level_id) REFERENCES lkp_approval_level(id) -- FK cấp duyệt
);

-- Phụ tùng gắn cho claim (dự kiến hoặc thực tế)
CREATE TABLE claim_parts(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- FK claim
  part_id BIGINT NOT NULL,                     -- FK part
  qty DECIMAL(12,2) NOT NULL,                  -- Số lượng
  planned TINYINT(1) DEFAULT 1,                -- 1: dự kiến, 0: thực tế dùng
  serial_no VARCHAR(100),                      -- Serial dùng (nếu track serial)
  lot_no VARCHAR(50),                          -- Số lô (nếu track lot)
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- Công lao động cho claim
CREATE TABLE claim_labour(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- FK claim
  technician_id BIGINT,                        -- Kỹ thuật viên (user có vai SC_TECH)
  hours DECIMAL(6,2) NOT NULL,                 -- Số giờ công
  rate DECIMAL(10,2) NOT NULL,                 -- Đơn giá/giờ
  note VARCHAR(200),                           -- Ghi chú
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (technician_id) REFERENCES users(id) -- FK kỹ thuật viên
);

-- =========================================================
-- 5) SETTLEMENT (quyết toán chi phí)
-- =========================================================

-- Quyết toán 1-1 với claim
CREATE TABLE settlements(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL UNIQUE,             -- Mỗi claim chỉ có 1 settlement
  status_id BIGINT NOT NULL,                   -- Trạng thái quyết toán
  submitted_by BIGINT,                         -- User SC Manager submit
  submitted_at TIMESTAMP NULL,                 -- Thời điểm submit
  approved_by BIGINT,                          -- User EVM Staff approve
  approved_at TIMESTAMP NULL,                  -- Thời điểm approve
  total_parts DECIMAL(12,2) DEFAULT 0,         -- Tổng tiền phụ tùng
  total_labour DECIMAL(12,2) DEFAULT 0,        -- Tổng tiền công
  total_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_parts + total_labour) STORED, -- Tổng cộng (cột tạo)
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (status_id) REFERENCES lkp_settlement_status(id) -- FK trạng thái quyết toán
);

-- Dòng chi tiết trong settlement (PART hoặc LABOUR)
CREATE TABLE settlement_items(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  settlement_id BIGINT NOT NULL,               -- FK settlement
  item_type VARCHAR(20) NOT NULL,              -- 'PART' hoặc 'LABOUR'
  description VARCHAR(200),                    -- Mô tả dòng
  qty DECIMAL(10,2) DEFAULT 1,                 -- Số lượng
  unit_price DECIMAL(12,2) NOT NULL,           -- Đơn giá
  amount DECIMAL(12,2) GENERATED ALWAYS AS (qty*unit_price) STORED, -- Thành tiền (tự tính)
  FOREIGN KEY (settlement_id) REFERENCES settlements(id) -- FK settlement
);

-- =========================================================
-- 6) INVENTORY (quản lý kho)
-- =========================================================

-- Tồn kho tổng theo kho - phụ tùng
CREATE TABLE stock(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  warehouse_id BIGINT NOT NULL,                -- FK kho
  part_id BIGINT NOT NULL,                     -- FK part
  qty_on_hand DECIMAL(12,2) DEFAULT 0,         -- Số lượng đang có
  qty_reserved DECIMAL(12,2) DEFAULT 0,        -- Số lượng đã giữ chỗ
  UNIQUE(warehouse_id, part_id),               -- Một cặp kho-part chỉ 1 dòng
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id), -- FK kho
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- Quản lý tồn kho theo serial (nếu part track_serial=1)
CREATE TABLE stock_serials(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  part_id BIGINT NOT NULL,                     -- FK part
  serial_no VARCHAR(100) NOT NULL,             -- Số serial
  warehouse_id BIGINT NOT NULL,                -- FK kho hiện tại
  status VARCHAR(20) NOT NULL,                 -- Trạng thái: ON_HAND, RESERVED, ISSUED, RMA
  UNIQUE(serial_no, part_id),                  -- Serial + part là duy nhất
  FOREIGN KEY (part_id) REFERENCES parts(id),  -- FK part
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) -- FK kho
);

-- Phiếu yêu cầu cấp phụ tùng từ SC
CREATE TABLE parts_requests(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  service_center_id BIGINT NOT NULL,           -- SC yêu cầu
  requested_by BIGINT NOT NULL,                -- User tạo (SC_STOREKEEPER)
  part_id BIGINT NOT NULL,                     -- Part yêu cầu
  qty DECIMAL(12,2) NOT NULL,                  -- Số lượng yêu cầu
  status_id BIGINT NOT NULL,                   -- Trạng thái yêu cầu (allocation status)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (service_center_id) REFERENCES service_centers(id), -- FK SC
  FOREIGN KEY (requested_by) REFERENCES users(id), -- FK user tạo
  FOREIGN KEY (part_id) REFERENCES parts(id),  -- FK part
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id) -- FK trạng thái phân bổ
);

-- Bảng phân bổ/điều chuyển phụ tùng (từ kho nguồn tới kho đích)
CREATE TABLE parts_allocations(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  request_id BIGINT,                           -- Liên kết tới parts_requests (nếu phân bổ theo yêu cầu)
  claim_id BIGINT,                             -- Hoặc phân bổ trực tiếp cho claim
  source_wh_id BIGINT NOT NULL,                -- Kho nguồn
  dest_wh_id BIGINT NOT NULL,                  -- Kho đích
  part_id BIGINT NOT NULL,                     -- Part được phân bổ
  qty_alloc DECIMAL(12,2) NOT NULL,            -- Số lượng phân bổ
  eta_date DATE,                               -- Ngày dự kiến tới
  status_id BIGINT NOT NULL,                   -- Trạng thái phân bổ
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (request_id) REFERENCES parts_requests(id), -- FK yêu cầu
  FOREIGN KEY (claim_id) REFERENCES claims(id), -- FK claim (nếu có)
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id), -- FK kho nguồn
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),   -- FK kho đích
  FOREIGN KEY (part_id) REFERENCES parts(id),  -- FK part
  FOREIGN KEY (status_id) REFERENCES lkp_allocation_status(id) -- FK trạng thái phân bổ
);

-- Phiếu giao hàng (Delivery Order)
CREATE TABLE shipments(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  do_no VARCHAR(50) NOT NULL UNIQUE,           -- Số lệnh giao (duy nhất)
  source_wh_id BIGINT NOT NULL,                -- Kho nguồn
  dest_wh_id BIGINT NOT NULL,                  -- Kho đích
  carrier VARCHAR(100),                        -- Đơn vị vận chuyển
  tracking_no VARCHAR(100),                    -- Mã tracking
  status_id BIGINT NOT NULL,                   -- Trạng thái shipment
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (source_wh_id) REFERENCES warehouses(id), -- FK kho nguồn
  FOREIGN KEY (dest_wh_id) REFERENCES warehouses(id),   -- FK kho đích
  FOREIGN KEY (status_id) REFERENCES lkp_shipment_status(id) -- FK trạng thái
);

-- Dòng hàng hóa trong shipment
CREATE TABLE shipment_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  shipment_id BIGINT NOT NULL,                 -- FK shipment
  part_id BIGINT NOT NULL,                     -- FK part
  qty DECIMAL(12,2) NOT NULL,                  -- Số lượng giao
  lot_no VARCHAR(50),                           -- Số lô (nếu có)
  FOREIGN KEY (shipment_id) REFERENCES shipments(id), -- FK shipment
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- Phiếu nhập kho (Goods Receipt Note) cho một shipment
CREATE TABLE grn(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  shipment_id BIGINT NOT NULL,                 -- FK shipment được nhận
  warehouse_id BIGINT NOT NULL,                -- Kho nhận
  received_by BIGINT NOT NULL,                 -- User nhận (SC_STOREKEEPER)
  status_id BIGINT NOT NULL,                   -- Trạng thái GRN
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (shipment_id) REFERENCES shipments(id), -- FK shipment
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id), -- FK kho nhận
  FOREIGN KEY (received_by) REFERENCES users(id), -- FK người nhận
  FOREIGN KEY (status_id) REFERENCES lkp_grn_status(id) -- FK trạng thái GRN
);

-- Dòng kiểm nhập trong GRN
CREATE TABLE grn_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  grn_id BIGINT NOT NULL,                      -- FK GRN
  part_id BIGINT NOT NULL,                     -- FK part
  qty_ok DECIMAL(12,2) DEFAULT 0,              -- Số lượng đạt
  qty_damaged DECIMAL(12,2) DEFAULT 0,         -- Số lượng hỏng
  FOREIGN KEY (grn_id) REFERENCES grn(id),     -- FK GRN
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- Phiếu xuất kho cho Claim (Issue)
CREATE TABLE issues(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- Claim cần xuất parts
  warehouse_id BIGINT NOT NULL,                -- Kho xuất
  requested_by BIGINT NOT NULL,                -- User yêu cầu (SC_TECH)
  issued_by BIGINT,                            -- User xuất (SC_STOREKEEPER)
  status_id BIGINT NOT NULL,                   -- Trạng thái Issue
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id), -- FK kho
  FOREIGN KEY (requested_by) REFERENCES users(id), -- FK người yêu cầu
  FOREIGN KEY (issued_by) REFERENCES users(id),    -- FK người xuất
  FOREIGN KEY (status_id) REFERENCES lkp_issue_status(id) -- FK trạng thái
);

-- Dòng xuất kho (Issue lines)
CREATE TABLE issue_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  issue_id BIGINT NOT NULL,                    -- FK issue
  part_id BIGINT NOT NULL,                     -- FK part
  qty DECIMAL(12,2) NOT NULL,                  -- Số lượng xuất
  serial_no VARCHAR(100),                      -- Serial (nếu có)
  lot_no VARCHAR(50),                          -- Lô (nếu có)
  FOREIGN KEY (issue_id) REFERENCES issues(id),-- FK issue
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- Phiếu hoàn trả vật tư về hãng (RMA) cho một claim
CREATE TABLE rma(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  claim_id BIGINT NOT NULL,                    -- Claim liên quan
  from_wh_id BIGINT NOT NULL,                  -- Kho SC gửi
  to_wh_id BIGINT NOT NULL,                    -- Kho EVM nhận
  status_id BIGINT NOT NULL,                   -- Trạng thái RMA
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tạo
  FOREIGN KEY (claim_id) REFERENCES claims(id),-- FK claim
  FOREIGN KEY (from_wh_id) REFERENCES warehouses(id), -- FK kho gửi
  FOREIGN KEY (to_wh_id) REFERENCES warehouses(id),   -- FK kho nhận
  FOREIGN KEY (status_id) REFERENCES lkp_rma_status(id) -- FK trạng thái
);

-- Dòng hàng trong RMA
CREATE TABLE rma_lines(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  rma_id BIGINT NOT NULL,                      -- FK RMA
  part_id BIGINT NOT NULL,                     -- FK part
  qty DECIMAL(12,2) NOT NULL,                  -- Số lượng hoàn
  serial_no VARCHAR(100),                      -- Serial (nếu có)
  reason VARCHAR(200),                         -- Lý do hoàn
  FOREIGN KEY (rma_id) REFERENCES rma(id),     -- FK RMA
  FOREIGN KEY (part_id) REFERENCES parts(id)   -- FK part
);

-- =========================================================
-- 7) CAMPAIGNS (recall & service)
-- =========================================================

-- Bảng chiến dịch Recall/Service
CREATE TABLE campaigns(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  type_id BIGINT NOT NULL,                     -- Loại chiến dịch (FK -> lkp_campaign_type)
  name VARCHAR(150) NOT NULL,                  -- Tên chiến dịch
  description TEXT,                            -- Mô tả
  start_date DATE,                             -- Ngày bắt đầu
  end_date DATE,                               -- Ngày kết thúc
  created_by BIGINT,                           -- User EVM tạo chiến dịch
  status_id BIGINT NOT NULL,                   -- Trạng thái chiến dịch
  FOREIGN KEY (type_id) REFERENCES lkp_campaign_type(id), -- FK loại
  FOREIGN KEY (created_by) REFERENCES users(id),          -- FK người tạo
  FOREIGN KEY (status_id) REFERENCES lkp_campaign_status(id) -- FK trạng thái
);

-- VIN thuộc phạm vi 1 chiến dịch
CREATE TABLE campaign_vins(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  campaign_id BIGINT NOT NULL,                 -- FK campaign
  vin VARCHAR(32) NOT NULL,                    -- VIN mục tiêu
  status VARCHAR(30) DEFAULT 'Planned',        -- Trạng thái xử lý VIN
  UNIQUE(campaign_id, vin),                    -- Tránh trùng VIN trong cùng chiến dịch
  FOREIGN KEY (campaign_id) REFERENCES campaigns(id), -- FK campaign
  FOREIGN KEY (vin) REFERENCES vehicles(vin)   -- FK VIN
);

-- =========================================================
-- 8) AUDIT (theo dõi hành động hệ thống)
-- =========================================================

-- Bảng log audit hành động hệ thống
CREATE TABLE audit_logs(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,        -- Khóa chính
  actor_id BIGINT,                             -- User thực hiện
  action VARCHAR(60) NOT NULL,                 -- Mã hành động (CREATE_CLAIM, APPROVE_EVM, ...)
  entity VARCHAR(60) NOT NULL,                 -- Tên thực thể (bảng) liên quan
  entity_id BIGINT,                            -- Khóa chính của entity
  before_json JSON,                            -- Dữ liệu trước khi đổi (JSON)
  after_json JSON,                             -- Dữ liệu sau khi đổi (JSON)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời điểm log
  FOREIGN KEY (actor_id) REFERENCES users(id)  -- FK user thực hiện
);