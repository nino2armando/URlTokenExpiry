using System;
using System.Web.Mvc;
using System.Web.Routing;
using Microsoft.Practices.Unity;

namespace web_MetricsApi.DependencyResolver
{
    public class UnityControllerFactory : DefaultControllerFactory
    {
        //Unity container instance.
        private IUnityContainer _unityContainer;

        //Creates a new instance of UnityControllerFactory.
        public UnityControllerFactory(IUnityContainer unityContainer)
        {
            if (unityContainer == null)
            {
                throw new ArgumentException();
            }
            _unityContainer = unityContainer;
        }

        //Retrieves a controller instance for the specified request context and controller type by using Unity.
        protected override IController GetControllerInstance(RequestContext requestContext, Type controllerType)
        {
            if (controllerType == null)
            {
                return null;
            }
            return _unityContainer.Resolve(controllerType) as IController;
        }
    }
}