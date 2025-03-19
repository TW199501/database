-------------------------------
-- 日誌表
-------------------------------
CREATE TABLE error_log (
    error_logid INT IDENTITY(1,1) PRIMARY KEY,
    error_message NVARCHAR(4000),
    error_severity INT,
    error_state INT,
    error_time DATETIME DEFAULT GETDATE()
);


