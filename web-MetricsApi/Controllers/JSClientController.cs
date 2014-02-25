using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Web;
using System.Web.Http;
using web_MetricsApi.Models;
using web_MetricsApi.Services;

namespace web_MetricsApi.Controllers
{
    public class JsClientController : ApiController
    {
        private IMetricService _metricService;

        public JsClientController(IMetricService metricService)
        {
            _metricService = metricService;
        }

        // POST api/metric
        public HttpResponseMessage Post(Metric metric)
        {
            string url = HttpContext.Current.Request.Url.AbsolutePath;
            return new HttpResponseMessage()
                {
                    StatusCode = HttpStatusCode.Created
                };
        }
    }
}