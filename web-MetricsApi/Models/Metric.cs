using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Pbp.Metrics.Core.Clients;

namespace web_MetricsApi.Models
{
    public class Metric
    {
        // e.g. page name    
        public string Name { get; set; }
        public long Value { get; set; }
        public DateTime Time { get; set; }
        public MetricType Type { get; set; }
       // public IList<Tag> Tags { get; set; }
    }

    public class Tag
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }
}