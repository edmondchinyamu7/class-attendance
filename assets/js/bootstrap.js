/* Loads the static HTML modules before starting the ClassPilot application. */
(async function loadClassPilotModules(){
  const root = document.getElementById('classpilotRoot');
  const modules = [
    'partials/auth.html',
    'partials/dashboard.html',
    'partials/modals.html',
    'partials/feedback.html'
  ];

  try {
    const responses = await Promise.all(
      modules.map(async (path) => {
        const response = await fetch(path, { cache: 'no-cache' });
        if (!response.ok) throw new Error(`Could not load ${path} (${response.status})`);
        return response.text();
      })
    );

    root.innerHTML = responses.join('\n');

    // app.js binds events directly to the interface, so load it only
    // after every HTML partial has been inserted into the page.
    const appScript = document.createElement('script');
    appScript.src = 'assets/js/app.js';
    appScript.onload = () => document.documentElement.classList.add('classpilot-ready');
    appScript.onerror = () => {
      root.innerHTML = '<main role="alert" style="max-width:620px;margin:60px auto;padding:24px;font:16px system-ui"><h2>ClassPilot could not start</h2><p>The application script could not be loaded. Refresh the page or check your connection.</p></main>';
    };
    document.body.appendChild(appScript);
  } catch (error) {
    console.error('ClassPilot module loading failed:', error);
    root.innerHTML = '<main role="alert" style="max-width:620px;margin:60px auto;padding:24px;font:16px system-ui"><h2>ClassPilot could not load</h2><p>Some interface files could not be loaded. Check your internet connection and refresh the page.</p></main>';
  }
})();
