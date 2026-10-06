-- ============================================================
-- 废水站运营管理系统 - Supabase 数据库建表脚本
-- 运行方式：Supabase SQL Editor 中粘贴执行（顺序执行）
-- ============================================================

-- 1. users - 用户账号
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'viewer'
    CHECK (role IN ('admin', 'operator', 'viewer')),
  phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE users IS '用户账号与角色';
COMMENT ON COLUMN users.role IS 'admin=管理员 operator=运行员 viewer=查看者';

-- 2. daily_record - 运营日报（10 大分类）
CREATE TABLE IF NOT EXISTS daily_record (
  id BIGSERIAL PRIMARY KEY,
  record_date DATE NOT NULL,
  shift VARCHAR(10) NOT NULL DEFAULT '白班'
    CHECK (shift IN ('白班', '夜班')),
  operator VARCHAR(100),
  
  -- 水量
  treated_water NUMERIC(10,2) DEFAULT 0,     -- 日处理水量(吨)
  high_conc_waste NUMERIC(10,2) DEFAULT 0,   -- 高浓废液(吨)
  low_conc_waste NUMERIC(10,2) DEFAULT 0,    -- 低浓废水(吨)
  
  -- 进水水质
  high_conc_cod NUMERIC(10,2) DEFAULT 0,     -- 高浓水COD(mg/L)
  low_conc_cod NUMERIC(10,2) DEFAULT 0,      -- 低浓水COD(mg/L)
  
  -- 出水水质
  cod NUMERIC(10,2) DEFAULT 0,               -- 出水COD(mg/L)
  ph NUMERIC(4,1) DEFAULT 7.0,               -- 出水pH
  compliance_status VARCHAR(20) DEFAULT '达标排放'
    CHECK (compliance_status IN ('达标排放', '未排放', '未做水')),
  
  -- 水电
  electricity INTEGER DEFAULT 0,              -- 总电量(kWh)
  tap_water NUMERIC(10,2) DEFAULT 0,         -- 用水量(吨)
  utility_cost NUMERIC(12,2) DEFAULT 0,      -- 水电总费用(元)
  
  -- 人工
  direct_labor INTEGER DEFAULT 0,            -- 直接人工(位)
  indirect_labor INTEGER DEFAULT 0,          -- 间接人工(位)
  labor_cost NUMERIC(12,2) DEFAULT 0,        -- 人工总费用(元)
  
  -- 药剂
  pac NUMERIC(10,2) DEFAULT 0,
  pam NUMERIC(10,2) DEFAULT 0,
  demulsifier NUMERIC(10,2) DEFAULT 0,       -- 破乳剂(kg)
  caustic NUMERIC(10,2) DEFAULT 0,           -- 片碱/复合碱(kg)
  defoamer NUMERIC(10,2) DEFAULT 0,          -- 消泡剂(kg)
  chemical_cost NUMERIC(12,2) DEFAULT 0,     -- 药剂总费用(元)
  
  -- 耗材
  ro_membrane INTEGER DEFAULT 0,             -- RO膜(支)
  sludge_bag INTEGER DEFAULT 0,              -- 污泥料袋(只)
  consumable_cost NUMERIC(12,2) DEFAULT 0,   -- 耗材总费用(元)
  
  -- 危废
  sludge NUMERIC(10,2) DEFAULT 0,            -- 污泥量(吨)
  floor_wash NUMERIC(10,2) DEFAULT 0,        -- 洗地水量(吨)
  hazmat_cost NUMERIC(12,2) DEFAULT 0,       -- 危废总费用(元)
  
  -- 备品
  seal INTEGER DEFAULT 0,                    -- 机封
  impeller INTEGER DEFAULT 0,                -- 叶轮
  spare_cost NUMERIC(12,2) DEFAULT 0,        -- 备品总费用(元)
  
  -- 成本
  cost_per_ton NUMERIC(12,2) DEFAULT 0,      -- 处理费用(元/吨)
  
  -- 签名
  signature TEXT,                              -- 签名图片(dataURL)
  sign_time TIMESTAMP WITH TIME ZONE,
  sign_user VARCHAR(100),
  
  -- 元数据
  remark TEXT,
  created_by VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(record_date, shift)
);

CREATE INDEX idx_daily_record_date ON daily_record(record_date);
COMMENT ON TABLE daily_record IS '运营日报 - 含 10 大分类字段';

-- 3. chemical_record - 药剂领用记录
CREATE TABLE IF NOT EXISTS chemical_record (
  id BIGSERIAL PRIMARY KEY,
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  chemical_name VARCHAR(100) NOT NULL,        -- PAC / PAM / 破乳剂 / 片碱 / 消泡剂
  dosage NUMERIC(10,2) NOT NULL DEFAULT 0,   -- 投加量(kg)
  stock NUMERIC(10,2) DEFAULT 0,             -- 当前库存(kg)
  unit_price NUMERIC(10,4) DEFAULT 0,        -- 单价(元/kg)
  operator VARCHAR(100),
  remark TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chemical_date ON chemical_record(record_date);
COMMENT ON TABLE chemical_record IS '药剂领用与库存';

-- 4. equipment_inspection - 设备巡检
CREATE TABLE IF NOT EXISTS equipment_inspection (
  id BIGSERIAL PRIMARY KEY,
  equipment_name VARCHAR(200) NOT NULL,
  location VARCHAR(200),
  inspection_date DATE NOT NULL DEFAULT CURRENT_DATE,
  inspector VARCHAR(100),
  status VARCHAR(20) NOT NULL DEFAULT '正常'
    CHECK (status IN ('正常', '异常', '检修')),
  abnormal_desc TEXT,
  remark TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_equipment_date ON equipment_inspection(inspection_date);
COMMENT ON TABLE equipment_inspection IS '设备巡检记录';

-- 5. waste_record - 危废管理记录
CREATE TABLE IF NOT EXISTS waste_record (
  id BIGSERIAL PRIMARY KEY,
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  waste_name VARCHAR(100) NOT NULL,           -- 污泥 / 洗地水 / 废液
  quantity NUMERIC(10,2) NOT NULL DEFAULT 0, -- 产生量(吨)
  unit_price NUMERIC(10,2) DEFAULT 0,        -- 处置单价(元/吨)
  total_cost NUMERIC(12,2) DEFAULT 0,        -- 总费用(元)
  disposal_unit VARCHAR(200),                 -- 处置单位
  transfer_no VARCHAR(100),                   -- 转移联单号
  operator VARCHAR(100),
  remark TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_waste_date ON waste_record(record_date);
COMMENT ON TABLE waste_record IS '危废产生与处置记录';

-- 6. spare_part_record - 备品备件记录
CREATE TABLE IF NOT EXISTS spare_part_record (
  id BIGSERIAL PRIMARY KEY,
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  part_name VARCHAR(100) NOT NULL,            -- 机封 / 叶轮
  spec VARCHAR(100),                          -- 规格型号
  quantity INTEGER NOT NULL DEFAULT 1,        -- 领用数量
  unit_price NUMERIC(10,2) DEFAULT 0,        -- 单价(元)
  total_cost NUMERIC(12,2) DEFAULT 0,        -- 总费用(元)
  operator VARCHAR(100),
  remark TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_spare_date ON spare_part_record(record_date);
COMMENT ON TABLE spare_part_record IS '备品备件领用记录';

-- 7. config - 系统配置
CREATE TABLE IF NOT EXISTS config (
  id BIGSERIAL PRIMARY KEY,
  config_key VARCHAR(100) UNIQUE NOT NULL,
  config_value JSONB NOT NULL,
  description TEXT,
  updated_by VARCHAR(100),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入默认配置
INSERT INTO config (config_key, config_value, description) VALUES
('utility_prices', '{"electricity": 0.7, "water": 4.6}', '水电单价：电费元/kWh，水价元/吨'),
('chemical_prices', '{"pac": 1.875, "pam": 7.29, "demulsifier": 7.97, "caustic": 1.35, "defoamer": 0}', '药剂单价：元/kg'),
('consumable_prices', '{"ro_membrane": 0, "sludge_bag": 0}', '耗材单价：RO膜元/支，料袋元/只'),
('hazmat_prices', '{"sludge": 599, "floor_wash": 0}', '危废处置单价：污泥元/吨，洗地水元/吨'),
('spare_prices', '{"seal": 0, "impeller": 0}', '备品单价：机封元/个，叶轮元/个'),
('quality_limits', '{"cod_limit": 500, "ph_min": 6, "ph_max": 9, "high_conc_cod_limit": 100000}', '水质达标标准'),
('system', '{"company_name": "领益科技(深圳)有限公司", "station_name": "盛涛废水站", "daily_avg_salary": 261.90}', '系统设置');

COMMENT ON TABLE config IS '系统配置（单价/标准/系统参数）';

-- Row Level Security（可选，启用后按角色控制）
-- ALTER TABLE daily_record ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "admin全权限" ON daily_record FOR ALL USING (auth.role() = 'admin');
-- CREATE POLICY "运行员读写" ON daily_record FOR INSERT USING (auth.role() = 'operator');