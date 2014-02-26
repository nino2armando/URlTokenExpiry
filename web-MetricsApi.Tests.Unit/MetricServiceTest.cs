using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using NUnit.Framework;
using Pbp.Metrics.Core;
using Pbp.Metrics.Core.Clients;
using Rhino.Mocks;
using web_MetricsApi.Models;
using web_MetricsApi.Repository;
using web_MetricsApi.Services;

namespace web_MetricsApi.Tests.Unit
{
    [TestFixture]
    class MetricServiceTest
    {
        public IMetricService _service;
        public IMetricRepository _metricRepository;
        public ICoreClientFactory _clientFactory;
        public IMetricClient _metricClient;

        [SetUp]
        public void SetUp()
        {
            _clientFactory = new CoreClientFactory();
            _metricRepository = MockRepository.GenerateStub<IMetricRepository>();
            _service = new MetricService(_clientFactory, _metricRepository);
        }

        [Test]
        [TestCase(MetricType.Count)]
        [TestCase(MetricType.Timing)]
        [TestCase(MetricType.Gauge)]
        [TestCase(MetricType.Set)]
        public void FindClientActionToInvoke_Should_return_Correct_Client_Method(MetricType metricType)
        {
            var metric = new Metric()
                {
                    Name = "default_aspx",
                    Value = 12334234,
                    Time = DateTime.Now,
                    Type = metricType
                };

            _metricClient = MockRepository.GenerateMock<IMetricClient>();

            var method = _service.FindClientActionToInvoke<MetricPipeClient>(metric);
            method.Invoke(metric.Name, metric.Value, metric.Time);

            switch (metricType)
            {
                case MetricType.Count:
                    _metricClient.AssertWasCalled(x => x.LogCount(metric.Name, metric.Value, metric.Time));
                    break;
                case MetricType.Timing:
                    _metricClient.AssertWasCalled(x => x.LogTiming(metric.Name, metric.Value, metric.Time));
                    break;
                case MetricType.Gauge:
                    _metricClient.AssertWasCalled(x => x.LogGauge(metric.Name, metric.Value, metric.Time));
                    break;
                case MetricType.Set:
                    _metricClient.AssertWasCalled(x => x.LogSet(metric.Name, metric.Value, metric.Time));
                    break;
            }
        }

        [Test]
        public void FindClientActionToInvoke_Should_Accespt_Metric_For_Argument()
        {
            Type metricService = (typeof (MetricService));
            MethodInfo method = metricService.GetMethod("FindClientActionToInvoke");
            ParameterInfo[] parameters = method.GetParameters();
            var metric = parameters[0];

            Assert.AreEqual(typeof(Metric), metric.ParameterType);

        }

        [Test]
        public void FindClientActionToInvoker_Sould_Return_Correct_Type()
        {
            Type metricService = (typeof(MetricService));
            MethodInfo method = metricService.GetMethod("FindClientActionToInvoke");
            var returnType = method.ReturnType;

            Assert.AreEqual(typeof(Action<string, long, DateTime>), returnType);
        }

        [Test]
        [TestCase(MetricType.Count)]
        [TestCase(MetricType.Timing)]
        [TestCase(MetricType.Gauge)]
        [TestCase(MetricType.Set)]
        public void Publish_Should_Invoke_Correct_MetricClient_Method(MetricType metricType)
        {
            var metric = new Metric()
            {
                Name = "default_aspx",
                Value = 12334234,
                Time = DateTime.Now,
                Type = metricType
            };

            var metricClient = MockRepository.GenerateMock<IMetricClient>();
            var method = _service.FindClientActionToInvoke<MetricPipeClient>(metric);

            _service.Publish(method, metric);

            switch (metricType)
            {
                    case MetricType.Count:
                    metricClient.AssertWasCalled(x => x.LogCount(metric.Name, metric.Value, metric.Time));
                    break;
                    case MetricType.Gauge:
                    metricClient.AssertWasCalled(x => x.LogGauge(metric.Name, metric.Value, metric.Time));
                    break;
                    case MetricType.Set:
                    metricClient.AssertWasCalled(x => x.LogSet(metric.Name, metric.Value, metric.Time));
                    break;
                    case MetricType.Timing:
                    metricClient.AssertWasCalled(x => x.LogTiming(metric.Name, metric.Value, metric.Time));
                    break;
            }
        }
    }
}
