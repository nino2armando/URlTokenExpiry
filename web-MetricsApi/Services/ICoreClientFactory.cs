namespace web_MetricsApi.Services
{
    public interface ICoreClientFactory
    {
        T FindClient<T>() where T : class;
    }
}