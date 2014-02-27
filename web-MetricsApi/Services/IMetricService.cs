using System;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Contracts;
using web_MetricsApi.Models;

namespace web_MetricsApi.Services
{
    public interface IMetricService
    {
        void Publish(Action<string, long, DateTime> action, Metric metric);
        Action<string, long, DateTime> FindClientActionToInvoke<T>(Metric metric) where T : class, IMetricClient;
    }
}