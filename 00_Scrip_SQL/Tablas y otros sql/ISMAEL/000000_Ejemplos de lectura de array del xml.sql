DECLARE @contador INT,
        @xml XML,
        @as_json VARCHAR(MAX),
        @codigo VARCHAR(2),
        @pal INT,
        @codigo_PAL VARCHAR(4);




SET @contador = 1;
SET @as_json
    = N'{"c_codigo" : "01","n_pal" : "4","Pallets" :[{"c_codigo_pal": "0001","c_codigo_pro": "1"},{"c_codigo_pal": "0002","c_codigo_pro": "2"}]}';
SELECT @xml = dbo.fn_parse_json2xml(@as_json);

SELECT @codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(2)'), ''))),
       @pal = RTRIM(LTRIM(ISNULL(n.el.value('n_pal[1]', 'INT'), '')))
FROM @xml.nodes('/') n(el);


PRINT @codigo;
PRINT @pal;


SELECT c_codigo_pal = T.c.query('c_codigo_pal').value('c_codigo_pal[1]', 'varchar(4)'),
       c_codigo_pro = T.c.query('c_codigo_pro').value('c_codigo_pro[1]', 'varchar(1)')
FROM @xml.nodes('/Pallets') T(c);

