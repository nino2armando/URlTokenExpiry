using System;
using Pbp.Metrics.Core;
using Pbp.Metrics.Core.Clients;
using Pbp.Metrics.Core.Configuration;

namespace web_MetricsApi.Services
{
    public class CoreClientFactory : ICoreClientFactory
    {
        public T FindClient<T>() where T : class 
        {
            object node = default(T);

            if (typeof(T) == typeof(MetricPipeClient))
            {
                node = WebMetricProvider.Instance;
            }
            if (typeof(T) == typeof(GraphiteClient))
            {
                node = new GraphiteClient(MetricsConfiguration.Instance.Graphite.Address,
                                       MetricsConfiguration.Instance.Graphite.Port,
                                       MetricsConfiguration.Instance.Graphite.PrefixKey);
            }
            if(typeof(T) == typeof(Statsd))
            {
                node = new Statsd(MetricsConfiguration.Instance.Graphite.Address,
                                       MetricsConfiguration.Instance.Graphite.Port);
            }
            return (T)Convert.ChangeType(node, typeof(T));
        }
    }
}