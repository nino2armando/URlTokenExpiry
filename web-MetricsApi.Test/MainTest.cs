using System;
using System.Collections.Generic;
using NUnit.Framework;
using Pbp.Metrics.Core;
using Pbp.Metrics.Core.Clients;

namespace web_MetricsApi.Test
{
    [TestFixture]
    public class MainTest
    {
        [Test]
        public void StatDServerTest()
        {
            var statsd = WebMetricProvider.Instance;
            //statsd.LogCount("site.hits");
            //statsd.LogGauge("site.activeUsers", 200);
            //statsd.LogTiming("site.pageLoad", 100 /* milliseconds */ );
            var random = new Random();
            var randomDay = random.Next(-7, 0);
            long randomVal = random.Next(0, 5);

            statsd.LogRaw("test.carbon.direct", randomVal, DateTime.Now);

            //var logs = new List<Metric>()
            //    {
            //        new Metric()
            //            {
            //                Name = "Root Response Time",
            //                Value = 4008,
            //                Time = DateTime.UtcNow,
            //                MetricType = "Timer",
            //                OptionalTags = null,
            //            }
            //    };

            //switch (logs[0].MetricType)
            //{
            //    case "Timer":
            //       // statsd.LogTiming(logs[0].Name, logs[0].Value);

            //        break;
            //}
        }
    }

    public class Metric
    {
        // e.g. page name
        public string Name { get; set; }
        // 
        public long Value { get; set; }
        public string MetricType { get; set; }
        public DateTime Time { get; set; }
        public Tag OptionalTags { get; set; } // or maybe replace for a key/val
    }

    public class Tag
    {
        //todo: specify the optional tags here
    }
}
