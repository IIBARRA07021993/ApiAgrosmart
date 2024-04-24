using ApiAgrosmart.Models;
using libx.log;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Http;
using System.Web.Http.Cors;

namespace ApiAgrosmart.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class ControlConteoCajaController : ApiController
    {

        DatosGeneral DatosG = new DatosGeneral();
        ConfiguracionEmpresa configuration;
          
        [HttpPut]
        [Route("api/ControlConteoCaja")]
        public string ControlConteoCaja(string as_empresa, int as_operation, string as_json)
        {
            WebLog.Write(EventLogType.Information, "Iniciando  Operacion =" + as_operation + "[ControlConteoCaja]");
            var sp = "sp_AppControlConteoCaja";
            int success = 0;
            string message = "";

            configuration = DatosG.GetConnection(as_empresa);
            using (var sqlCon = new SqlConnection(configuration.Conexion))
            {
                try
                {
                    WebLog.Write(EventLogType.Information, "Abriendo Conexion ala Base de datos[ControlConteoCaja]");
                    sqlCon.Open();

                    SqlCommand sql_cmnd = new SqlCommand(sp, sqlCon)
                    {

                        CommandType = CommandType.StoredProcedure,
                        CommandText = sp
                    };
                    sql_cmnd.CommandTimeout = 240;

                    sql_cmnd.Parameters.AddWithValue("@as_operation", as_operation);
                    sql_cmnd.Parameters.AddWithValue("@as_json", as_json);


                    sql_cmnd.Parameters.Add("@as_success", SqlDbType.Int);
                    sql_cmnd.Parameters["@as_success"].Direction = ParameterDirection.Output;
                    sql_cmnd.Parameters.Add("@as_message", SqlDbType.VarChar, 1024);
                    sql_cmnd.Parameters["@as_message"].Direction = ParameterDirection.Output;

                    WebLog.Write(EventLogType.Information, "Ejecutando Procedimiento sp_AppControlConteoCaja [ControlConteoCaja]");
                    sql_cmnd.ExecuteNonQuery();
                    success = Convert.ToByte(sql_cmnd.Parameters["@as_success"].Value);
                    message = Convert.ToString(sql_cmnd.Parameters["@as_message"].Value);

                }
                catch (Exception ex)
                {
                    success = 0;
                    return success.ToString() + "|" + ex.Message.ToString();
                    throw;
                }
                finally
                {
                    WebLog.Write(EventLogType.Error, "Cerrando Conexion finally [ControlConteoCaja]");
                    sqlCon.Close();
                }
                WebLog.Write(EventLogType.Information, "Terminando Operacion Exitosa[ControlConteoCaja]");
                return success.ToString() + "|" + message;


            }

        }

    }
}
