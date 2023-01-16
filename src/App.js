import React, { useEffect } from 'react';
import { Switch, Route, Redirect, useLocation } from 'react-router-dom';

import './App.css';
import "./css/tailwind.output.css";
import './font/font.css';
import './css/fontawesome-free-6.0.0-beta3-web/css/fontawesome.css';
import './css/fontawesome-free-6.0.0-beta3-web/css/brands.css';
import './css/fontawesome-free-6.0.0-beta3-web/css/solid.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'react-notifications/lib/notifications.css';

import Home from './pages/Home';
import Tournament from './pages/Tournament';
import { ToastContainer, toast } from 'react-toastify';

localStorage.setItem('reward', 0);

function App() {
  const location = useLocation();
  useEffect(() => {
    localStorage.setItem('reward', 0);
  }, [location]);

  return (
    <React.Fragment>
      <Switch>
        <Redirect from="/" exact to="/home" />
        <Route path="/home" exact component={Home} />
        <Route path="/create" exact component={Tournament} />
      </Switch>
    </React.Fragment>
  );
}

export default App;
