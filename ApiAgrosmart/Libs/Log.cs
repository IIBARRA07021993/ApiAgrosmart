using System;
using System.Configuration;
using System.IO;
using System.Threading;

namespace InventarioAgricolaApi.Libs
{
    public enum EventLogType  
    {
        //
        // Resumen:
        //     Un evento de error. Esto indica un problema importante que debe conocer el usuario;
        //     Normalmente, una pérdida de funcionalidad o datos.
        Error = 1,
        //
        // Resumen:
        //     Un evento de advertencia. Esto indica un problema que no es importante, pero
        //     que puede indicar las condiciones que pueden causar problemas futuros.
        Warning = 2,
        //
        // Resumen:
        //     Un evento de información. Indica una operación importante y correcta.
        Information = 4,
        //
        // Resumen:
        //     Evento de depuración. Indica eventos que resultan útiles durante el
        //     desarrollo de aplicaciones.
        Debug = 8
    }

    public class Log
    {
        private static object sync = new object();

        private static int GetLevel()
        {
            int level = (int)EventLogType.Information;
            if (ConfigurationManager.AppSettings["LogLevel"] != null && !ConfigurationManager.AppSettings["LogLevel"].Trim().Equals(""))
            {
                level = int.Parse(ConfigurationManager.AppSettings["LogLevel"].Trim());
            }
            return level;
        }

        private static string GetName()
        {
            string name = "Application";
            if (ConfigurationManager.AppSettings["LogName"] != null && !ConfigurationManager.AppSettings["LogName"].Trim().Equals(""))
            {
                name = ConfigurationManager.AppSettings["LogName"].Trim();
            }
            return name ;
        }

        public static void Write(string message)
        {
            Write(EventLogType.Information, message);
        }

        public static void Write(EventLogType level, string message)
        {
            int NivelLog;
            string NombreLog;
            string RutaLog;
            DateTime date = DateTime.Now;
            lock (sync)
            {
                try
                {
                    NivelLog = GetLevel();
                    NombreLog = GetName();
                    RutaLog = ApplicationPath.Log();
                 
                    if (!Directory.Exists(RutaLog))
                    {
                        Directory.CreateDirectory(RutaLog);
                    }
                    if (NivelLog >= (int)level)
                    {
                        using (StreamWriter sw = File.AppendText(string.Format("{0}\\{1}_{2}.txt", RutaLog, NombreLog, date.ToString("MMdd"))))
                        {
                            sw.WriteLine(string.Format("{0} {1} {2} {3}", date.ToString("HH:mm:ss"), Thread.CurrentThread.ManagedThreadId.ToString("D6"), ((int)level).ToString("D3"), message));
                        }
                    }
                }
                catch (Exception)
                {
                }
            }
        }
    }
}
