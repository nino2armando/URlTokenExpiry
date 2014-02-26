using System;
using AutoMapper;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Contracts;
using web_MetricsApi.Models;

namespace web_MetricsApi.Mappers
{
    public class AutoMapperConfiguration
    {
        public static void LoadConfiguration()
        {
            ConfigureDataContract();
        }

        private static void ConfigureDataContract()
        {
            Mapper.CreateMap<MetricContract, Metric>()
                .ForMember(src => src.Name, trg => trg.MapFrom(a => a.Name))
                .ForMember(src => src.Value, trg => trg.MapFrom(a => a.Value))
                .ForMember(src => src.Time, trg => trg.MapFrom(a => a.Time))
                .ForMember(src => src.Type, trg => trg.MapFrom(a => a.Type));

            //todo: add other properties
        }


    }

    internal class EnumResolver : ValueResolver<string, MetricType>
    {
        protected override MetricType ResolveCore(string source)
        {
            return (MetricType) Enum.Parse(typeof (MetricType), source, true);
        }
    }
}