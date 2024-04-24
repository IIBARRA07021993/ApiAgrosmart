using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Cors;

namespace ApiAgrosmart.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class AccionesController : ApiController
    {


        /*
        [HttpPut]
        [Route("api/usp_control_pedidos_app/")]
        public string fn_procesar_pallets(int as_operation, string as_json)
        {
            var sp = "usp_control_pedidos_app";
            int success = 0;
            string message = "";

            using (var sqlCon = new SqlConnection(ConfigurationManager.ConnectionStrings["Pedidos"].ConnectionString))
            {
                try
                {
                    sqlCon.Open();

                    SqlCommand sql_cmnd = new SqlCommand(sp, sqlCon)
                    {

                        CommandType = CommandType.StoredProcedure,
                        CommandText = sp
                    };
                    sql_cmnd.CommandTimeout = 240;

                    sql_cmnd.Parameters.AddWithValue("@operation", as_operation);
                    sql_cmnd.Parameters.AddWithValue("@json", as_json);


                    sql_cmnd.Parameters.Add("@success", SqlDbType.Int);
                    sql_cmnd.Parameters["@success"].Direction = ParameterDirection.Output;
                    sql_cmnd.Parameters.Add("@message", SqlDbType.VarChar, 1024);
                    sql_cmnd.Parameters["@message"].Direction = ParameterDirection.Output;


                    sql_cmnd.ExecuteNonQuery();
                    success = Convert.ToByte(sql_cmnd.Parameters["@success"].Value);
                    message = Convert.ToString(sql_cmnd.Parameters["@message"].Value);

                }
                catch (Exception ex)
                {
                    success = 0;
                    return success.ToString() + "|" + ex.Message.ToString();
                    throw;
                }
                finally
                {
                    sqlCon.Close();
                }

                return success.ToString() + "|" + message;


            }

        }*/


    }
}
