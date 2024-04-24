using ApiAgrosmart.Models;
using System;
using System.Collections.Generic;
using System.Web.Http;
using libx.log;
using Newtonsoft.Json;
using System.Web.Http.Cors;

namespace ApiAgrosmart.Controllers
{
    /*IIBARRA PRUERBAS 2024/04/24*/
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class EmpresasController : ApiController
    {
        DatosGeneral DatosG = new DatosGeneral();
        List<Empresa> empresas;

        [HttpGet]
        [Route("api/empresas")]
        public string Cargarempresa()
        {
            WebLog.Write(EventLogType.Information, "Iniciando Carga de Empresas[CargarEmpresas]");
            try
            {
                WebLog.Write(EventLogType.Information, "Consultando Empresas[CargarEmpresas]");
                empresas = DatosG.ListAllEnterprises();
            }
            catch (Exception ex)
            {
                WebLog.Write(EventLogType.Error, ex.Message.ToString() + "[CargarEmpresas]");
                return ex.Message.ToString();
                throw;
            }
            WebLog.Write(EventLogType.Information, "Terminando Operacion Exitosa[CargarEmpresas]");
            return JsonConvert.SerializeObject(empresas);

        }



    }
}
