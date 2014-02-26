using NUnit.Framework;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Services;

namespace web_MetricsApi.Tests.Unit
{
    [TestFixture]
    class CoreMetricClientTest
    {
        public ICoreClientFactory ClientFactory;

        [SetUp]
        public void SetUp()
        {
            ClientFactory = new CoreClientFactory();
        }

        [Test]
        public void FidClient_Should_Return_a_Correct_Client_BasedOn_Persistence()
        {
            var statsdClient = ClientFactory.FindClient<Statsd>();
            var graphiteClient = ClientFactory.FindClient<GraphiteClient>();
            var pipeClient = ClientFactory.FindClient<MetricPipeClient>();

            Assert.AreEqual(typeof(Statsd), statsdClient.GetType());
            Assert.AreEqual(typeof(GraphiteClient), graphiteClient.GetType());
            Assert.AreEqual(typeof(MetricPipeClient), pipeClient.GetType());
        }
    }
}
