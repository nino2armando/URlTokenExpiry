using Microsoft.Practices.Unity;
using web_MetricsApi.Repository;
using web_MetricsApi.Services;

namespace web_MetricsApi.DependencyResolver
{
    public static class GlobalTypeRegistration
    {
        public static void RegisterLocalServices(this IUnityContainer container)
        {
            container.RegisterType<IMetricService, MetricService>(new HierarchicalLifetimeManager());
            container.RegisterType<IMetricRepository, MetricRepository>(new HierarchicalLifetimeManager());
        }
    }
}