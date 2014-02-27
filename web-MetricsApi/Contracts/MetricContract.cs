using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Pbp.Metrics.Core.Clients;

namespace web_MetricsApi.Contracts
{
    public class MetricContract
    {
        // e.g. page name
        [Required]
        public string Name { get; set; }
        [Required]
        public long Value { get; set; }
        [Required]
        public DateTime Time { get; set; }
        [Required]
        public string Type { get; set; }
        //public Dictionary<string, string> Tags { get; set; }
    }
}