using web_MetricsApi.Models;

namespace web_MetricsApi.Services
{
    public interface IMetricService
    {
        void Publish(Metric metric);
    }
}