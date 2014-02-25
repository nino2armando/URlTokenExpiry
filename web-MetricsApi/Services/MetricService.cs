using System;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Models;
using web_MetricsApi.Repository;

namespace web_MetricsApi.Services
{
    public class MetricService : IMetricService
    {
        public IMetricClient _MetricClient;
        public IMetricRepository _MetricRepository;

        public MetricService(IMetricClient metricClient, IMetricRepository metricRepository)
        {
            _MetricClient = metricClient;
            _MetricRepository = metricRepository;
        }

        public void Publish(Metric metric)
        {
            switch (metric.Type)
            {
                case MetricType.Timing:
                    _MetricClient.LogTiming(metric.Name, metric.Value, metric.Time);
                    _MetricRepository.WriteToDb(metric);
                    break;
                case MetricType.Count:
                    _MetricClient.LogCount(metric.Name, metric.Value, metric.Time);
                    _MetricRepository.WriteToDb(metric);
                    break;
                case MetricType.Gauge:
                    _MetricClient.LogGauge(metric.Name, metric.Value, metric.Time);
                    _MetricRepository.WriteToDb(metric);
                    break;
                case MetricType.Set:
                    _MetricClient.LogSet(metric.Name, metric.Value, metric.Time);
                    _MetricRepository.WriteToDb(metric);
                    break;
            }
        }
    }
}