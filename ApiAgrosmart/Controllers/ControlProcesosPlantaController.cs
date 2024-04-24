using ApiAgrosmart.Models;
using libx.log;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Cors;
using System.Web.Http.Description;
using static ApiAgrosmart.Models.PreMuestreoModel;

namespace ApiAgrosmart.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class ControlProcesosPlantaController : ApiController
    {
        DatosGeneral DatosG = new DatosGeneral();
        ConfiguracionEmpresa configuration;



        [HttpPut]
        [Route("api/ControlProcesosPlanta")]
        public string ControlProcesosPlanta(string as_empresa, int as_operation, string as_json)
        {

            WebLog.Write(EventLogType.Information, "Iniciando  Operacion =" + as_operation + "[ControlProcesosPlanta]");
            var sp = "sp_APPControlProcesosPlanta";
            int success = 0;
            string message = "";

            configuration = DatosG.GetConnection(as_empresa);
            using (var sqlCon = new SqlConnection(configuration.Conexion))
            {
                try
                {
                    WebLog.Write(EventLogType.Information, "Abriendo Conexion ala Base de datos[ControlProcesosPlanta]");
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

                    WebLog.Write(EventLogType.Information, "Ejecutando Procedimiento sp_APPControlProcesosPlanta [ControlProcesosPlanta]");
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
                    WebLog.Write(EventLogType.Error, "Cerrando Conexion finally [ControlProcesosPlanta]");
                    sqlCon.Close();
                }
                WebLog.Write(EventLogType.Information, "Terminando Operacion Exitosa[ControlProcesosPlanta]");
                return success.ToString() + "|" + message;


            }

        }


        [HttpPut]
        [Route("api/ControlProcesosPlantaBody")]
        public string ControlProcesosPlantaBody(string as_empresa, int as_operation,  [FromBody] Fotos fotos)
        {
            WebLog.Write(EventLogType.Information, "Iniciando  Operacion =" + as_operation + "[ControlProcesosPlantaBody]");
            var sp = "[sp_APPControlProcesosPlanta]";
            int success = 0;
            string message = "";

            configuration = DatosG.GetConnection(as_empresa);
            using (var sqlCon = new SqlConnection(configuration.Conexion))
            {
                try
                {
                    WebLog.Write(EventLogType.Information, "Abriendo Conexion ala Base de datos[ControlProcesosPlantaBody]");
                    sqlCon.Open();

                    SqlCommand sql_cmnd = new SqlCommand(sp, sqlCon)
                    {

                        CommandType = CommandType.StoredProcedure,
                        CommandText = sp
                    };
                    sql_cmnd.CommandTimeout = 240;

                    sql_cmnd.Parameters.AddWithValue("@as_operation", as_operation);
                    sql_cmnd.Parameters.AddWithValue("@as_json", JsonConvert.SerializeObject(fotos));
       
                    sql_cmnd.Parameters.Add("@as_success", SqlDbType.Int);
                    sql_cmnd.Parameters["@as_success"].Direction = ParameterDirection.Output;
                    sql_cmnd.Parameters.Add("@as_message", SqlDbType.VarChar, 1024);
                    sql_cmnd.Parameters["@as_message"].Direction = ParameterDirection.Output;

                    WebLog.Write(EventLogType.Information, "Ejecutando Procedimiento sp_APPControlProcesosPlantav2 [ControlProcesosPlantaBody]");
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
                    WebLog.Write(EventLogType.Error, "Cerrando Conexion finally [ControlProcesosPlantaBody]");
                    sqlCon.Close();
                }
                WebLog.Write(EventLogType.Information, "Terminando Operacion Exitosa[ControlProcesosPlantaBody]");
                return success.ToString() + "|" + message;


            }

        }

       


    }
}
