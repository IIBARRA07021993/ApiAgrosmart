/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_recepcion_terceros') AND type in (N'U'))

CREATE TABLE dbo.t_recepcion_terceros
(
    c_tagid_ret VARCHAR(20) NULL,
    c_variety_ret VARCHAR(20) NULL,
    c_commodity_ret VARCHAR(20) NULL,
    c_grade_ret VARCHAR(20) NULL,
    d_recive_ret DATE NULL,
    c_blockid_ret VARCHAR(20) NULL,
    c_region_ret VARCHAR(3) NULL,
    c_method_ret VARCHAR(3) NULL,
    c_color_ret VARCHAR(20) NULL,
    c_style_ret VARCHAR(20) NULL,
    c_size_ret VARCHAR(20) NULL,
    c_label_ret VARCHAR(20) NULL,
    c_inventoryref_ret VARCHAR(20) NULL,
    c_lotid_ret VARCHAR(20) NULL,
    n_receiveequivqty_ret NUMERIC(18, 0) NULL,
    v_recepcionado_ret CHAR(1) NULL
);

