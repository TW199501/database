
-- ✅ 一鍵搞定 Always On 架構設定與驗證腳本 --

-- 1. 確認各節點職責與配置
SELECT 
    ag.name AS 可用性群組,
    ar.replica_server_name AS 節點名稱,
    ars.role_desc AS 節點角色,
    ar.availability_mode_desc AS 同步模式,
    ar.failover_mode_desc AS 容錯模式,
    ar.read_only_routing_url AS 查詢路由網址,
    ar.secondary_role_allow_connections_desc AS 是否允許查詢
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id
WHERE ag.name = 'AG2'
ORDER BY ars.role_desc DESC;

-- 2. 設定副本的路由網址
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLG' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQLG:1433'));
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLM' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQLM:1433'));
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLQ' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQLQ:1433'));

-- 3. 設定只讀導向路由優先順序
ALTER AVAILABILITY GROUP [AG2]
MODIFY REPLICA ON N'SQLT'
WITH (
    PRIMARY_ROLE (
        READ_ONLY_ROUTING_LIST = (N'SQLG', N'SQLM', N'SQLQ')
    )
);

-- 4. 確認路由設定是否正確
SELECT 
    ar.replica_server_name,
    ar.read_only_routing_url
FROM sys.availability_replicas ar;

SELECT 
    rs1.replica_server_name AS 主節點,
    rorl.routing_priority AS 優先順序,
    rs2.replica_server_name AS 導向副本
FROM sys.availability_read_only_routing_lists rorl
JOIN sys.availability_replicas rs1 ON rorl.replica_id = rs1.replica_id
JOIN sys.availability_replicas rs2 ON rorl.read_only_replica_id = rs2.replica_id;

-- 5. 確認 SQLG 資料同步狀況
SELECT 
    DB_NAME(drs.database_id) AS 資料庫名稱,
    ar.replica_server_name AS 副本名稱,
    drs.synchronization_state_desc AS 同步狀態,
    drs.synchronization_health_desc AS 同步健康狀態
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON drs.replica_id = ar.replica_id
JOIN sys.databases db ON drs.database_id = db.database_id
WHERE db.name NOT IN ('master', 'model', 'msdb', 'tempdb')
  AND ar.replica_server_name = 'SQLG'
ORDER BY 資料庫名稱, 副本名稱;

-- 6. 設定 SQLG 與 SQLT 為同步 + 自動容錯副本
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLG' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLG' WITH (FAILOVER_MODE = AUTOMATIC);
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLT' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
ALTER AVAILABILITY GROUP [AG2] MODIFY REPLICA ON N'SQLT' WITH (FAILOVER_MODE = AUTOMATIC);

-- 7. 確認容錯與同步設定
SELECT 
    replica_server_name,
    availability_mode_desc,
    failover_mode_desc
FROM sys.availability_replicas
WHERE replica_server_name IN ('SQLT', 'SQLG');

-- 8. 最終完整結構驗證
SELECT 
    ar.replica_server_name         AS 節點名稱,
    ars.role_desc                  AS 當前角色,
    ar.availability_mode_desc     AS 同步模式,
    ar.failover_mode_desc         AS 容錯模式,
    ar.secondary_role_allow_connections_desc AS 允許查詢副本,
    ar.read_only_routing_url      AS 查詢路由網址,
    CASE 
        WHEN ar.availability_mode_desc = 'SYNCHRONOUS_COMMIT' AND ar.failover_mode_desc = 'AUTOMATIC' THEN N'✅ 可自動容錯（副主）'
        WHEN ars.role_desc = 'PRIMARY' THEN N'⭐ 主節點'
        ELSE N'🔁 一般副本'
    END AS 節點說明
FROM sys.availability_replicas ar
JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id
ORDER BY ars.role_desc DESC, ar.replica_server_name;
