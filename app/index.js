/* eslint-disable camelcase */
const {app, BrowserWindow} = require('electron');

let mainWindow;
const createMainWindow = () => {
    mainWindow = new BrowserWindow({
        width: 1024,
        height: 720,
        minWidth: 380,
        minHeight: 380,
        center: true,
        resizable: true,

        title: 'BongoPod',
        //icon: 'ct_ide.png',

        webPreferences: {
            nodeIntegration: true,
            defaultFontFamily: 'sansSerif',
            backgroundThrottling: true
        }
    });

    mainWindow.removeMenu();
    mainWindow.loadFile('index.html');

    try {
        require('gulp'); // a silly check for development environment
        mainWindow.webContents.openDevTools();
    } catch (e) {
        void 0;
    }

};

app.on('ready', createMainWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createMainWindow();
    }
});
