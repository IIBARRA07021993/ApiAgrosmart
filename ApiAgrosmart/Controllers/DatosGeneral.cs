using ApiAgrosmart.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Hosting;

namespace ApiAgrosmart.Controllers
{
   

    public class DatosGeneral
    {
        List<ConfiguracionEmpresa> configurations;
        public ConfiguracionEmpresa GetConnection(string id)
        {
            ConfiguracionEmpresa configuration = null;
            if (configurations == null)
            {
                configurations = JsonConvert.DeserializeObject<List<ConfiguracionEmpresa>>(
                    File.ReadAllText(HostingEnvironment.MapPath(
                        ConfigurationManager.AppSettings["ConfiguracionEmpresas"])));
            }
            foreach (ConfiguracionEmpresa item in configurations)
            {
                if (item.Id.Equals(id))
                {
                    configuration = item;
                    break;
                }
            }
            return configuration;
        }

         public List<Empresa> ListAllEnterprises()
        {
            List<Empresa> list = new List<Empresa>();
            if (configurations == null)
            {
                configurations = JsonConvert.DeserializeObject<List<ConfiguracionEmpresa>>(
                    File.ReadAllText(HostingEnvironment.MapPath(
                        ConfigurationManager.AppSettings["ConfiguracionEmpresas"])));
            }
            foreach (ConfiguracionEmpresa item in configurations)
            {
                list.Add(new Empresa
                {
                    C_codigo_emp = item.Id,
                    V_nombre_emp = item.Nombre
                });
            }
            return list;
        }



    }
}