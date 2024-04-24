
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_recepcion_terceros_cp')
          AND type IN ( N'U' )
)
    CREATE TABLE dbo.t_recepcion_terceros_cp
    (
        GrowerName NVARCHAR(255) NULL,
        Color NVARCHAR(255) NULL,
        Qty FLOAT NULL,
        Region NVARCHAR(255) NULL,
        TagId NVARCHAR(255) NULL,
        BlockId NVARCHAR(255) NULL,
        Metodo NVARCHAR(255) NULL,
        Grado NVARCHAR(255) NULL,
        Cliente VARCHAR(100) NULL
    );


/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='bAplicado' AND object_id=OBJECT_ID('t_recepcion_terceros_cp'))
ALTER TABLE dbo.t_recepcion_terceros_cp ADD bAplicado BIT NOT NULL DEFAULT 0

/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='dtFecha' AND object_id=OBJECT_ID('t_recepcion_terceros_cp'))
Alter table t_recepcion_terceros_cp Add dtFecha DateTime Not Null Default GetDate()