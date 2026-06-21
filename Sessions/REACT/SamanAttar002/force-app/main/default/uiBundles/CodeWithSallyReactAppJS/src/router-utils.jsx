import { routes } from './routes';
const flatMapRoutes = (route, parentPath = '') => {
  let fullPath;
  if (route.index) {
    fullPath = parentPath || '/';
  } else if (route.path) {
    if (route.path.startsWith('/')) {
      fullPath = route.path;
    } else {
      fullPath =
        parentPath === '/' ? `/${route.path}` : `${parentPath}/${route.path}`;
    }
  } else {
    fullPath = parentPath;
  }
  const routeWithPath = {
    ...route,
    fullPath,
  };
  const childRoutes =
    route.children?.flatMap(child => flatMapRoutes(child, fullPath)) || [];
  return [routeWithPath, ...childRoutes];
};
export const getAllRoutes = () => {
  return routes.flatMap(route => flatMapRoutes(route));
};
