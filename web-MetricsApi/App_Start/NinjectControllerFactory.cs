using System;
using System.Web.Mvc;
using System.Web.Routing;
using Ninject;

namespace web_MetricsApi.App_Start
{
    public class NinjectControllerFactory : DefaultControllerFactory
    {
        private IKernel kernel;

        public NinjectControllerFactory()
        {
            kernel = new StandardKernel();
            AddBindings();
        }

        protected override IController GetControllerInstance(RequestContext requestContext, Type controllerType)
        {
            return controllerType == null
                       ? null
                       : (IController)kernel.Get(controllerType);
        }

        private void AddBindings()
        {
            //kernel.Bind<IMetricService>().To<MetricService>();
            //kernel.Bind<IMetricRepository>().To<MetricRepository>();
            //kernel.Bind<IMetricClient>().To<MetricPipeClient>();
            //kernel.Bind<ILog>().ToMethod(context => LogManager.GetLogger(context.Request.Target.Member.DeclaringType));
        }
    }
}