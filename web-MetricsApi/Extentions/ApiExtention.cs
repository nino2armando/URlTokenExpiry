using System;
using System.Linq;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Contracts;
using web_MetricsApi.Models;

namespace web_MetricsApi.Extentions
{
    public static class ApiExtention
    {
        public static bool ValidateType(this MetricContract metric)
        {
            if(metric == null)
                throw new ArgumentNullException("metric");

            return Enum.GetNames(typeof(MetricType)).Contains(metric.Type);
        }
    }
}