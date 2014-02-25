using System;
using System.Collections.Generic;
using NUnit.Framework;
using Pbp.Metrics.Core;
using Pbp.Metrics.Core.Clients;
using Rhino.Mocks;
using web_MetricsApi.Models;
using web_MetricsApi.Repository;
using web_MetricsApi.Services;

namespace web_MetricsApi.Test
{
    [TestFixture]
    public class MainTest
    {
        public IMetricService _Service;
        public IMetricRepository _MetricRepository;

        [Test]
        public void CallService_can_handle_statdClient()
        {
            // prefixKey.includeMachineName.metricsHttpModule_type.HttpContextUri.ClientName
            // MetricsApi.Nkhoda001.stat_type.Ios.default_aspx
            var statsd = WebMetricProvider.Instance;
            _MetricRepository = MockRepository.GenerateStub<IMetricRepository>();
            _Service = new MetricService(statsd, _MetricRepository);

            var ran = new Random();
            for (int i = 0; i < 100; i++)
            {
                int item = ran.Next(0, 3);
                var metric = GetMetic(item);
                _Service.Publish(metric);
            }
        }

        [Test]
        public void StatDServerTest()
        {
            //var statsd = WebMetricProvider.Instance;
            //statsd.LogCount("site.hits");
            //statsd.LogGauge("site.activeUsers", 200);
            //statsd.LogTiming("site.pageLoad", 100 /* milliseconds */ );


            //statsd.LogTiming("test.carbon.direct7", randomVal, DateTime.Now);

            //statsd.LogRaw("test.carbon.direct", randomVal, DateTime.Now);

            //statsd.LogRaw("test.carbon.direct2", 3000, DateTime.Now);

            //var logs = new List<TimerMetric>()
            //    {
            //        new TimerMetric()
            //            {
            //                Name = "Root Response Time",
            //                Value = 4008,
            //                Time = DateTime.UtcNow,
            //                MetricType = "Timer",
            //                Tags = null,
            //            }
            //    };

            //switch (logs[0].MetricType)
            //{
            //    case "Timer":
            //        // statsd.LogTiming(logs[0].Name, logs[0].Value);

            //        break;
            //}
        }

        public Metric GetMetic(int item = 0)
        {
            var selector = new Random();
            var random = new Random();
            long randomVal = random.Next(0, 10000);

            var metrics = new List<Metric>()
                {
                    new Metric()
                        {
                            Name = "Default.aspx".ToMetricKey(),
                            Value = randomVal,
                            Time = DateTime.Now,
                            Type = MetricType.Timing

                        },
                    new Metric()
                        {
                            Name = "Location.aspx".ToMetricKey(),
                            Value = randomVal,
                            Time = DateTime.Now,
                            Type = MetricType.Count

                        },
                    new Metric()
                        {
                            Name = "Help.aspx".ToMetricKey(),
                            Value = randomVal,
                            Time = DateTime.Now,
                            Type = MetricType.Set

                        }
                };

            return metrics[item];
        }
    }
}
