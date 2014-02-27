using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web;
using System.Web.Http;
using AutoMapper;
using Pbp.Metrics.Core.Clients;
using web_MetricsApi.Contracts;
using web_MetricsApi.Filters;
using web_MetricsApi.Models;
using web_MetricsApi.Services;
using web_MetricsApi.Extentions;

namespace web_MetricsApi.Controllers
{
    public class MetricController : ApiController
    {
        private readonly IMetricService _metricService;

        public MetricController(ICoreClientFactory clientFactory, IMetricService metricService)
        {
            if(clientFactory == null)
                throw new ArgumentNullException("clientFactory");
            if(metricService == null)
                throw new ArgumentNullException("metricService");

            _metricService = metricService;
        }

        // POST api/metric
        [ValidateModel]
        public HttpResponseMessage Post(bool persist, MetricContract metric)
        {
            var url = HttpContext.Current.Request.Url.AbsolutePath;

            if (! metric.ValidateType())
            {
                ModelState.AddModelError("Type","Invalid Type");
            }
            if (metric != null && ModelState.IsValid)
            {
                var metricModel = Mapper.Map<MetricContract, Metric>(metric);

                var clientMethod = persist
                                          ? _metricService.FindClientActionToInvoke<MetricPipeClient>(metricModel)
                                          : _metricService.FindClientActionToInvoke<GraphiteClient>(metricModel);
                
                _metricService.Publish(clientMethod, metricModel);

                return new HttpResponseMessage(HttpStatusCode.OK);
            }

            return Request.CreateErrorResponse(HttpStatusCode.BadRequest, ModelState);
        }

    }
}