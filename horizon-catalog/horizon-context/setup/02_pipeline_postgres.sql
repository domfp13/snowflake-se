-- =============================================================================
-- Pipeline: Postgres-side Iceberg table creation with SYNTHETIC DATA
-- =============================================================================
-- Run this in DataGrip connected to the `postgres` database on PG_SNOWFLAKE_PROD
-- Prerequisites: pg_lake extension already enabled
-- =============================================================================

-- Verify you're in the right database
SELECT current_database();

-- =============================================================================
-- 1. CUSTOMERS ICEBERG TABLE (40 customers matching CUSTOMER_IDs in orders)
-- =============================================================================
CREATE TABLE customers_iceberg (
    customer_id    INT,
    customer_name  TEXT,
    customer_email TEXT,
    customer_region TEXT,
    customer_segment TEXT,
    created_at     TIMESTAMP
) USING iceberg;

INSERT INTO customers_iceberg (customer_id, customer_name, customer_email, customer_region, customer_segment, created_at) VALUES
(3001, 'Audi AG', 'procurement@audi.de', 'Europe', 'Enterprise', NOW()),
(3002, 'BMW Group', 'supply@bmw.de', 'Europe', 'Enterprise', NOW()),
(3003, 'Tesla Motors', 'parts@tesla.com', 'North America', 'Enterprise', NOW()),
(3004, 'Toyota Motor Corp', 'sourcing@toyota.jp', 'Asia Pacific', 'Enterprise', NOW()),
(3005, 'Ford Motor Company', 'purchasing@ford.com', 'North America', 'Enterprise', NOW()),
(3006, 'Volkswagen AG', 'einkauf@vw.de', 'Europe', 'Enterprise', NOW()),
(3007, 'Mercedes-Benz', 'supply@mercedes.de', 'Europe', 'Enterprise', NOW()),
(3008, 'Hyundai Motor', 'procurement@hyundai.kr', 'Asia Pacific', 'Enterprise', NOW()),
(3009, 'General Motors', 'sourcing@gm.com', 'North America', 'Enterprise', NOW()),
(3010, 'Stellantis NV', 'supply@stellantis.com', 'Europe', 'Enterprise', NOW()),
(4001, 'Rivian Automotive', 'parts@rivian.com', 'North America', 'Growth', NOW()),
(4002, 'Lucid Motors', 'procurement@lucid.com', 'North America', 'Growth', NOW()),
(4003, 'NIO Inc', 'supply@nio.cn', 'Asia Pacific', 'Growth', NOW()),
(4004, 'BYD Company', 'sourcing@byd.cn', 'Asia Pacific', 'Enterprise', NOW()),
(4005, 'Volvo Cars', 'purchasing@volvo.se', 'Europe', 'Mid-Market', NOW()),
(4006, 'Mazda Motor', 'procurement@mazda.jp', 'Asia Pacific', 'Mid-Market', NOW()),
(4007, 'Subaru Corp', 'supply@subaru.jp', 'Asia Pacific', 'Mid-Market', NOW()),
(4008, 'Jaguar Land Rover', 'sourcing@jlr.co.uk', 'Europe', 'Mid-Market', NOW()),
(4009, 'Porsche AG', 'einkauf@porsche.de', 'Europe', 'Enterprise', NOW()),
(4010, 'Ferrari NV', 'procurement@ferrari.it', 'Europe', 'Enterprise', NOW()),
(5001, 'Caterpillar Inc', 'supply@cat.com', 'North America', 'Enterprise', NOW()),
(5002, 'John Deere', 'procurement@deere.com', 'North America', 'Enterprise', NOW()),
(5003, 'Komatsu Ltd', 'sourcing@komatsu.jp', 'Asia Pacific', 'Enterprise', NOW()),
(5004, 'Volvo Trucks', 'parts@volvotrucks.se', 'Europe', 'Enterprise', NOW()),
(5005, 'Daimler Truck', 'supply@daimler-truck.de', 'Europe', 'Enterprise', NOW()),
(5006, 'PACCAR Inc', 'purchasing@paccar.com', 'North America', 'Mid-Market', NOW()),
(5007, 'CNH Industrial', 'procurement@cnhi.com', 'Europe', 'Enterprise', NOW()),
(5008, 'Liebherr Group', 'supply@liebherr.com', 'Europe', 'Mid-Market', NOW()),
(5009, 'Hitachi Construction', 'sourcing@hitachi-cm.jp', 'Asia Pacific', 'Mid-Market', NOW()),
(5010, 'Doosan Infracore', 'parts@doosan.kr', 'Asia Pacific', 'Mid-Market', NOW()),
(6001, 'SpaceX', 'procurement@spacex.com', 'North America', 'Enterprise', NOW()),
(6002, 'Blue Origin', 'supply@blueorigin.com', 'North America', 'Growth', NOW()),
(6003, 'Airbus SE', 'sourcing@airbus.eu', 'Europe', 'Enterprise', NOW()),
(6004, 'Boeing Company', 'purchasing@boeing.com', 'North America', 'Enterprise', NOW()),
(6005, 'Lockheed Martin', 'procurement@lm.com', 'North America', 'Enterprise', NOW()),
(6006, 'Northrop Grumman', 'supply@northropgrumman.com', 'North America', 'Enterprise', NOW()),
(6007, 'Rolls-Royce Holdings', 'sourcing@rolls-royce.co.uk', 'Europe', 'Enterprise', NOW()),
(6008, 'Safran SA', 'achats@safran.fr', 'Europe', 'Enterprise', NOW()),
(6009, 'GE Aerospace', 'procurement@ge.com', 'North America', 'Enterprise', NOW()),
(6010, 'Pratt & Whitney', 'supply@prattwhitney.com', 'North America', 'Enterprise', NOW());

-- =============================================================================
-- 2. PRODUCTS ICEBERG TABLE (40 products matching PRODUCT_IDs in orders)
-- =============================================================================
CREATE TABLE products_iceberg (
    product_id       INT,
    product_name     TEXT,
    product_category TEXT,
    product_brand    TEXT,
    unit_cost        NUMERIC(12,2),
    weight_kg        NUMERIC(8,2)
) USING iceberg;

INSERT INTO products_iceberg (product_id, product_name, product_category, product_brand, unit_cost, weight_kg) VALUES
(5001, 'Precision Gearbox Assembly', 'Drivetrain', 'PowerDrive', 45000.00, 120.5),
(5002, 'Electric Motor Unit 500kW', 'Powertrain', 'ElectraMot', 62000.00, 85.0),
(5003, 'Carbon Fiber Body Panel Set', 'Body', 'CompositeTech', 68000.00, 15.2),
(5004, 'Lithium Battery Pack 100kWh', 'Energy', 'VoltCell', 52000.00, 450.0),
(5005, 'Hydraulic Brake System', 'Chassis', 'StopForce', 38000.00, 28.0),
(5006, 'Turbocharger Assembly', 'Powertrain', 'BoostMax', 64000.00, 12.8),
(5007, 'Titanium Exhaust System', 'Exhaust', 'FlowTech', 105000.00, 8.5),
(5008, 'Adaptive Suspension Kit', 'Chassis', 'RideControl', 48000.00, 65.0),
(5009, 'LED Matrix Headlight Set', 'Lighting', 'LumiDrive', 55000.00, 4.2),
(5010, 'Infotainment Control Unit', 'Electronics', 'SmartDash', 68000.00, 2.1),
(6001, 'Aerospace Turbine Blade Set', 'Propulsion', 'AeroForge', 125000.00, 6.8),
(6002, 'Flight Control Computer', 'Avionics', 'SkyLogic', 89000.00, 3.5),
(6003, 'Composite Wing Section', 'Airframe', 'CompositeTech', 180000.00, 250.0),
(6004, 'Landing Gear Assembly', 'Structure', 'TitanLand', 145000.00, 180.0),
(6005, 'Satellite Communication Module', 'Electronics', 'OrbitComm', 92000.00, 1.8),
(6006, 'Rocket Nozzle Assembly', 'Propulsion', 'AeroForge', 210000.00, 45.0),
(6007, 'Thermal Protection Tiles', 'Thermal', 'HeatShield', 78000.00, 12.0),
(6008, 'Fuel Injection System', 'Propulsion', 'PrecisionFuel', 56000.00, 18.5),
(6009, 'Radar Array Module', 'Avionics', 'SkyLogic', 135000.00, 22.0),
(6010, 'Navigation Gyroscope', 'Avionics', 'NavPrecision', 98000.00, 5.2),
(7001, 'Industrial Hydraulic Pump', 'Hydraulics', 'HydraForce', 32000.00, 95.0),
(7002, 'CNC Spindle Motor', 'Machinery', 'SpinTech', 44000.00, 55.0),
(7003, 'Mining Drill Bit Set', 'Mining', 'RockBreaker', 28000.00, 35.0),
(7004, 'Conveyor Belt System', 'Material Handling', 'FlowLine', 65000.00, 320.0),
(7005, 'Industrial Robot Arm', 'Automation', 'RoboFlex', 88000.00, 120.0),
(7006, 'Welding Torch Assembly', 'Fabrication', 'ArcMaster', 15000.00, 8.0),
(7007, 'Pneumatic Valve Bank', 'Pneumatics', 'AirLogic', 22000.00, 12.5),
(7008, 'Bearing Housing Unit', 'Mechanical', 'PrecisionBear', 18000.00, 45.0),
(7009, 'Cooling Tower Fan', 'HVAC', 'CoolFlow', 35000.00, 75.0),
(7010, 'PLC Controller Module', 'Automation', 'LogicPro', 12000.00, 2.8),
(8001, 'Solar Panel Inverter', 'Energy', 'SunConvert', 25000.00, 35.0),
(8002, 'Wind Turbine Gearbox', 'Energy', 'WindDrive', 185000.00, 850.0),
(8003, 'Transformer Core Assembly', 'Electrical', 'GridPower', 42000.00, 220.0),
(8004, 'Circuit Breaker Panel', 'Electrical', 'SafeSwitch', 8500.00, 15.0),
(8005, 'Electric Vehicle Charger', 'Energy', 'ChargePoint', 15000.00, 45.0),
(8006, 'Battery Management System', 'Energy', 'VoltCell', 9500.00, 3.2),
(8007, 'Power Distribution Unit', 'Electrical', 'GridPower', 28000.00, 55.0),
(8008, 'Hydrogen Fuel Cell Stack', 'Energy', 'H2Power', 95000.00, 65.0),
(8009, 'Smart Grid Controller', 'Electrical', 'GridPower', 38000.00, 8.0),
(8010, 'Supercapacitor Module', 'Energy', 'VoltCell', 22000.00, 12.0);

-- =============================================================================
-- 3. ORDER ITEMS ICEBERG TABLE (line-level details for orders)
-- =============================================================================
CREATE TABLE order_items_iceberg (
    order_item_id   INT,
    order_id        INT,
    product_id      INT,
    quantity        INT,
    unit_price      NUMERIC(12,2),
    line_total      NUMERIC(12,2),
    notes           TEXT
) USING iceberg;

-- Generate order items: 1-3 line items per order (orders 2-49 from orders_iceberg)
INSERT INTO order_items_iceberg (order_item_id, order_id, product_id, quantity, unit_price, line_total, notes)
SELECT
    ROW_NUMBER() OVER (ORDER BY o.ORDER_ID)::INT AS order_item_id,
    o.ORDER_ID,
    o.PRODUCT_ID::INT,
    o.QUANTITY,
    o.UNIT_PRICE,
    o.TOTAL_PRICE,
    CASE
        WHEN o.ORDER_STATUS = 'Delivered' THEN 'Delivered on schedule'
        WHEN o.ORDER_STATUS = 'Shipped' THEN 'In transit'
        WHEN o.ORDER_STATUS = 'In Production' THEN 'Manufacturing in progress'
        ELSE 'Awaiting production slot'
    END AS notes
FROM orders_iceberg o;

-- =============================================================================
-- Verify row counts
-- =============================================================================
SELECT 'customers_iceberg' AS table_name, COUNT(*) AS row_count FROM customers_iceberg
UNION ALL
SELECT 'products_iceberg', COUNT(*) FROM products_iceberg
UNION ALL
SELECT 'order_items_iceberg', COUNT(*) FROM order_items_iceberg
UNION ALL
SELECT 'orders_iceberg', COUNT(*) FROM orders_iceberg;
