SELECT c_codigo_tem = cnt.c_codigo_tem,
       c_idcaja_cnt = cnt.c_idcaja_cnt,
       c_empleado_cnt = cnt.c_empleado_cnt,
       n_bulxpa_cnt = cnt.n_bulxpa_cnt,
       c_cajascaneo_cnt = cnt.c_cajascaneo_cnt
FROM dbo.t_palet_multiestiba_conteo cnt (NOLOCK)
WHERE cnt.c_activo_cnt = '1'
      AND cnt.c_activo_cnt = '1'
      AND cnt.c_codigo_tem = '06'
      AND cnt.c_codigo_emp = '00'
      AND cnt.c_codigo_pme = 'VIR0000001';



