using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using AutoMapper;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Contracts;
using web_MetricsApi.Filters;
using web_MetricsApi.Models;
using web_MetricsApi.Services;

namespace web_MetricsApi.Controllers
{
    public class MetricController : ApiController
    {
        private ICoreClientFactory _coreClientFactory;
        private IMetricService _metricService;

        public MetricController(ICoreClientFactory clientFactory, IMetricService metricService)
        {
            if(clientFactory == null)
                throw new ArgumentNullException("clientFactory");
            if(metricService == null)
                throw new ArgumentNullException("metricService");

            _coreClientFactory = clientFactory;
            _metricService = metricService;
        }

        // POST api/metric
        [ValidateModel]
        public HttpResponseMessage Post(MetricContract metric)
        {
            if (!TypeValidator(metric.Type))
            {
                ModelState.AddModelError("Type","Invalid Type");
            }
            if (metric != null && ModelState.IsValid)
            {
                var metricModel = Mapper.Map<MetricContract, Metric>(metric);
                var clientMethod = _metricService.FindClientActionToInvoke<MetricPipeClient>(metricModel);
                _metricService.Publish(clientMethod, metricModel);

                return new HttpResponseMessage(HttpStatusCode.OK);
            }

            return Request.CreateErrorResponse(HttpStatusCode.BadRequest, ModelState);
        }

        public bool TypeValidator(string type)
        {
            return Enum.GetNames(typeof (MetricType)).Contains(type);

        }
    }
}