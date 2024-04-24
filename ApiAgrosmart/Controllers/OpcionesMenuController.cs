using System;
using System.Web.Http;
using libx.log;
using Newtonsoft.Json;
using System.Data;
using System.Data.SqlClient;
using System.Web.Http.Cors;
using ApiAgrosmart.Models;

namespace ApiAgrosmart.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class OpcionesMenuController : ApiController
    {

        DatosGeneral DatosG = new DatosGeneral();
        ConfiguracionEmpresa configuration;

        [HttpGet]
        [Route("api/GetOpcionesMenu")]
        public string GetOpcionesMenu(string as_empresa, int as_operation, string as_json)
        {
            WebLog.Write(EventLogType.Information, "Iniciando consulta de Opciones de Menu por Usuario[GetOpcionesMenu]");
            var sp = "sp_AppOpcionesMenu";
            int success = 0;
            string message = "";
            var ds = new DataTable();
            var da = new SqlDataAdapter();
            string JSONString = string.Empty;

            configuration = DatosG.GetConnection(as_empresa);
            using (var sqlCon = new SqlConnection(configuration.Conexion))
            {
                try
                {
                    WebLog.Write(EventLogType.Information, "Abriendo Conexion ala Base de datos[GetOpcionesMenu]");
                    sqlCon.Open();

                    SqlCommand sql_cmnd = new SqlCommand(sp, sqlCon)
                    {

                        CommandType = CommandType.StoredProcedure,
                        CommandText = sp
                    };
                    sql_cmnd.CommandTimeout = 240;

                    sql_cmnd.Parameters.AddWithValue("@as_operation", as_operation);
                    sql_cmnd.Parameters.AddWithValue("@as_json", as_json);

                    /*PARAMETROS OUTPUT*/
                    sql_cmnd.Parameters.Add("@as_success", SqlDbType.Int);
                    sql_cmnd.Parameters["@as_success"].Direction = ParameterDirection.Output;
                    sql_cmnd.Parameters.Add("@as_message", SqlDbType.VarChar, 1024);
                    sql_cmnd.Parameters["@as_message"].Direction = ParameterDirection.Output;

                    WebLog.Write(EventLogType.Information, "Ejecutando Procedimiento sp_AppOpcionesMenu [GetOpcionesMenu]");
                    sql_cmnd.ExecuteNonQuery();
                    success = Convert.ToByte(sql_cmnd.Parameters["@as_success"].Value);
                    message = Convert.ToString(sql_cmnd.Parameters["@as_message"].Value);

                    da.SelectCommand = sql_cmnd;
                    da.Fill(ds);


                }
                catch (Exception ex)
                {
                    WebLog.Write(EventLogType.Error, success.ToString() + "|" + ex.Message.ToString() + "[GetOpcionesMenu]");
                    success = 0;
                    return success.ToString() + "|" + ex.Message.ToString();
                    throw;
                }
                finally
                {
                    WebLog.Write(EventLogType.Error, "Cerrando Conexion finally [GetOpcionesMenu]");
                    sqlCon.Close();
                }

                WebLog.Write(EventLogType.Information, "Terminando Operacion Exitosa[GetOpcionesMenu]");
                JSONString = JsonConvert.SerializeObject(ds);
                return JSONString;


            }

        }



    }
}
