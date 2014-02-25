using web_MetricsApi.Models;

namespace web_MetricsApi.Repository
{
    public interface IMetricRepository
    {
        void WriteToDb(Metric metric);
    }
}
