/*|AGS|*/
IF EXISTS (  SELECT *  FROM sys.objects    WHERE object_id = OBJECT_ID(N't_distribucion_pedido')  AND type IN ( N'U' ) )
    DROP TABLE t_distribucion_pedido
/*|AGS|*/
IF NOT  EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_distribucion_pedido')
          AND type IN ( N'U' )
)
BEGIN
CREATE TABLE t_distribucion_pedido
(
    c_codigo_tem CHAR(2) NOT NULL,
    c_codigo_emp CHAR(2) NOT NULL,
    c_codigo_pdo CHAR(16) NOT NULL,
    c_secuencia_dcg CHAR(4) NOT NULL,
    id_pack VARCHAR(50) NOT NULL,
    c_codigo_niv CHAR(4) NOT NULL,
    c_columna_col CHAR(4) NOT NULL,
    c_codigo_pos CHAR(4) NOT NULL,
    c_codigo_usu CHAR(20) NOT NULL,
    c_codigo_def CHAR(10) NOT NULL,
    d_creacion_dcg DATETIME NOT NULL,
    c_usumod_dcg CHAR(20) NULL,
    d_modifi_dcg DATETIME NULL,
    c_activo_dcg CHAR(1) NOT NULL,
    PRIMARY KEY (
                    c_codigo_tem,
                    c_codigo_emp,
                    c_codigo_pdo,
                    c_secuencia_dcg
                )
)
END
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_niv' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE dbo.t_palet ADD c_codigo_niv CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_columna_col' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE dbo.t_palet ADD c_columna_col CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_pos' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE dbo.t_palet ADD c_codigo_pos CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_def' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE dbo.t_palet ADD c_codigo_def CHAR(10) NULL
