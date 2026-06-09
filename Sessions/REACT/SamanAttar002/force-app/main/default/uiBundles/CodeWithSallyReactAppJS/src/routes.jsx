import AppLayout from '@/appLayout';
import Home from './pages/Home';
import NotFound from './pages/NotFound';
import FoundingMembers from './pages/FoundingMembers';
import Contact from './pages/Contact';
import Accounts from './pages/Accounts';
export const routes = [
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        index: true,
        element: <Home />,
        handle: {
          showInNavigation: true,
          label: 'Home',
        },
      },
      {
        path: '/founding-members',
        element: <FoundingMembers />,
        handle: {
          showInNavigation: true,
          label: 'Founding Members',
        },
      },
      {
        path: '/contact-us',
        element: <Contact />,
        handle: {
          showInNavigation: true,
          label: 'Contact Us',
        },
      },
      {
        path: '/accounts',
        element: <Accounts />,
        handle: {
          showInNavigation: true,
          label: 'Accounts',
        },
      },
      {
        path: '*',
        element: <NotFound />,
      },
    ],
  },
];
