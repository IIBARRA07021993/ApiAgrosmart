using System.Web.Hosting;

namespace InventarioAgricolaApi.Libs
{
    public class ApplicationPath
    {
        private static readonly string CurrentPath = HostingEnvironment.ApplicationPhysicalPath;
        private static readonly string CurrentHttpPath = HostingEnvironment.ApplicationVirtualPath;

        public static string Data()
        {
            return string.Format("{0}App_Data", CurrentPath);
        }

        public static string Log()
        {
            return string.Format("{0}Log", CurrentPath);
        }

        public static string Resources()
        {
            return string.Format("{0}Resources", CurrentPath);
        }

        public static string WebHosted()
        {
            return string.Format("{0}", CurrentHttpPath);
        }
    }
}
