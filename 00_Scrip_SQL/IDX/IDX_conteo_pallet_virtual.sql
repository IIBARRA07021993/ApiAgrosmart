/*|AGS|*/
IF EXISTS
(
    SELECT 1
    FROM sysindexes
    WHERE name = 'IDX_t_conteocajas_emp_idcaja'
)
    DROP INDEX IDX_t_conteocajas_emp_idcaja ON t_conteocajas_app_temp;

/*|AGS|*/
CREATE UNIQUE NONCLUSTERED INDEX IDX_t_conteocajas_emp_idcaja
ON t_conteocajas_app_temp (
                              c_codigo_emp,
                              c_idcaja_ccp
                          )
INCLUDE (c_terminal_ccp)
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF);
/*|AGS|*/
IF EXISTS
(
    SELECT 1
    FROM sysindexes
    WHERE name = 'IDX_t_palet_mestiba_tem_emp_pme'
)
    DROP INDEX IDX_t_palet_mestiba_tem_emp_pme ON t_palet_multiestiba_conteo;

/*|AGS|*/
CREATE NONCLUSTERED INDEX IDX_t_palet_mestiba_tem_emp_pme
ON t_palet_multiestiba_conteo (
                                  c_codigo_tem,
                                  c_codigo_emp,
                                  c_codigo_pme,
                                  c_codsec_pme
                              )
INCLUDE (c_idcaja_cnt)
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF);

/*|AGS|*/
IF EXISTS (SELECT 1 FROM sysindexes WHERE name = 'IDX_t_palet_tem_emp')
    DROP INDEX IDX_t_palet_tem_emp ON t_palet;

/*|AGS|*/
CREATE NONCLUSTERED INDEX IDX_t_palet_tem_emp
ON [dbo].[t_palet] (
                       [c_codigo_tem],
                       [c_codigo_emp]
                   )
INCLUDE (
            [c_codigo_pro],
            [c_codigo_est]
        )
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF);
/*|AGS|*/
IF EXISTS (SELECT 1 FROM sysindexes WHERE name = 'IDX_t_palet_tem_pro_emp')
    DROP INDEX IDX_t_palet_tem_pro_emp ON t_palet;

CREATE NONCLUSTERED INDEX IDX_t_palet_tem_pro_emp
ON [dbo].[t_palet] (
                       [c_codigo_tem],
                       [c_codigo_pro],
                       [c_codigo_emp]
                   )
INCLUDE ([c_codigo_est])
WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF);