/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_folio_sma' AND object_id=OBJECT_ID('t_seleccion'))
ALTER Table t_seleccion Add c_folio_sma VarChar(15) Not Null Default ''