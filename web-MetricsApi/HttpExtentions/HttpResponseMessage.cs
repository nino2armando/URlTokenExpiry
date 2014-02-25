﻿using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;

namespace web_MetricsApi.HttpExtentions
{
    public class HttpResponseMessage<T> : HttpResponseMessage
    {
        public HttpResponseMessage(T value, HttpStatusCode statusCode, MediaTypeFormatter formatter)
        {
            StatusCode = statusCode;
            Content = new ObjectContent<T>(value, formatter);
        }

        public HttpResponseMessage(object errorValue, HttpStatusCode statusCode, MediaTypeFormatter formatter)
        {
            StatusCode = statusCode;
            Content = new ObjectContent(errorValue.GetType(), errorValue, formatter);
        }
    }
}