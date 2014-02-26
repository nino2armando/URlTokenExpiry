using System;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Models;
using web_MetricsApi.Repository;

namespace web_MetricsApi.Services
{
    public class MetricService : IMetricService
    {
        public ICoreClientFactory _clientFactory;
        public IMetricRepository _metricRepository;

        public MetricService(ICoreClientFactory clientFactory, IMetricRepository metricRepository)
        {
            _clientFactory = clientFactory;
            _metricRepository = metricRepository;
        }

        public Action<string, long, DateTime> FindClientActionToInvoke<T>(Metric metric) where T : class , IMetricClient 
        {
            var node = _clientFactory.FindClient<T>();

            if(metric == null)
                throw new ArgumentNullException("metric");

            Action<string, long, DateTime> clientMethod = null;

            switch (metric.Type)
            {
                case MetricType.Timing:
                    clientMethod = (s, v, t) => node.LogTiming(s, v, t);                  
                    break;
                case MetricType.Count:
                    clientMethod = (s, v, t) => node.LogCount(s, v, t);   
                    break;
                case MetricType.Gauge:
                    clientMethod = (s, v, t) => node.LogGauge(s, v, t);   
                    break;
                case MetricType.Set:
                    clientMethod = (s, v, t) => node.LogSet(s, v, t);   
                    break;
            }

            return clientMethod;
        }

        public void Publish(Action<string, long, DateTime> action, Metric metric)
        {
            action.Invoke(metric.Name, metric.Value, metric.Time);
            _metricRepository.WriteToDb(metric);
        }
    }
}