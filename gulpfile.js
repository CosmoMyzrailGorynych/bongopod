'use strict';

/* eslint no-console: 0 */
const path = require('path'),
      gulp = require('gulp'),
      concat = require('gulp-concat'),
      sourcemaps = require('gulp-sourcemaps'),
      stylus = require('gulp-stylus'),
      riot = require('gulp-riot'),
      pug = require('gulp-pug'),
      sprite = require('gulp-svgstore'),

      execa = require('execa'),

      streamQueue = require('streamqueue'),
      fs = require('fs-extra');

const npm = (/^win/).test(process.platform) ? 'npm.cmd' : 'npm';

const pack = require('./app/package.json');

const compileStylus = () =>
    gulp.src('./src/stylus/_index.styl')
    .pipe(sourcemaps.init())
    .pipe(stylus({
        compress: true,
        'include css': true
    }))
    .pipe(concat('bundle.css'))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./app/data/'));

const compilePug = () =>
    gulp.src('./src/pug/*.pug')
    .pipe(sourcemaps.init())
    .pipe(pug({
        pretty: false
    }))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./app/'));

const compileRiot = () =>
    gulp.src('./src/riotTags/**')
    .pipe(riot({
        compact: false,
        template: 'pug'
    }))
    .pipe(concat('riot.js'))
    .pipe(gulp.dest('./temp/'));

const concatScripts = () =>
    streamQueue({objectMode: true},
        gulp.src('./src/js/3rdparty/riot.min.js'),
        gulp.src(['./src/js/**', '!./src/js/3rdparty/riot.min.js']),
        gulp.src('./temp/riot.js')
    )
    .pipe(sourcemaps.init())
    .pipe(concat('bundle.js'))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./app/data/'));

const copyRequires = () =>
    gulp.src('./src/node_requires/**/*')
    .pipe(gulp.dest('./app/data/node_requires'));

const compileScripts = gulp.series(compileRiot, concatScripts);

const icons = () =>
    gulp.src('./src/icons/**/*.svg')
    .pipe(sprite())
    .pipe(gulp.dest('./app/data'));

const watch = () => {
    gulp.watch('./src/js/**/*', gulp.series(compileScripts));
    gulp.watch('./src/riotTags/**/*', gulp.series(compileScripts));
    gulp.watch('./src/stylus/**/*', compileStylus);
    gulp.watch('./src/pug/*.pug', compilePug);
    gulp.watch('./src/node_requires/**/*', copyRequires);
    gulp.watch('./src/icons/**/*.svg', icons);
};

const lintStylus = () => {
    const stylint = require('gulp-stylint');
    return gulp.src(['./src/stylus/**/*.styl', '!./src/stylus/3rdParty/**/*.styl'])
    .pipe(stylint())
    .pipe(stylint.reporter())
    .pipe(stylint.reporter('fail', {
        failOnWarning: true
    }));
};

const lintJS = () => {
    const eslint = require('gulp-eslint');
    return gulp.src(['./src/js/**/*.js', '!./src/js/3rdparty/**/*.js', './src/node_requires/**/*.js'])
    .pipe(eslint())
    .pipe(eslint.format())
    .pipe(eslint.failAfterError());
};

const lint = gulp.series(lintJS, lintStylus);

const launchApp = () => {
    execa(npm, ['run', 'start'], {
        cwd: './app'
    }).then(launchApp);
};


const build = gulp.parallel([
    compilePug,
    compileStylus,
    compileScripts,
    copyRequires,
    icons
]);

const bakePackages = async () => {
    const builder = require('electron-builder');
    await fs.remove(path.join('./build', `ctjs - v${pack.version}`));
    await builder.build({// @see https://github.com/electron-userland/electron-builder/blob/master/packages/app-builder-lib/src/packagerApi.ts
        projectDir: './app',
        //mac: pack.build.mac.target || ['default'],
        //win: pack.build.win.target,
        //linux: pack.build.linux.target
    });
};


const examples = () => gulp.src('./src/examples/**/*')
    .pipe(gulp.dest('./app/examples'));

// eslint-disable-next-line valid-jsdoc
/**
 * @see https://stackoverflow.com/a/22907134
 */
const patronsCache = done => {
    const http = require('https');

    const dest = './app/data/patronsCache.csv',
          src = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTUMd6nvY0if8MuVDm5-zMfAxWCSWpUzOc81SehmBVZ6mytFkoB3y9i9WlUufhIMteMDc00O9EqifI3/pub?output=csv';
    const file = fs.createWriteStream(dest);
    http.get(src, function(response) {
        response.pipe(file);
        file.on('finish', function() {
            file.close(() => done()); // close() is async, call cb after close completes.
        });
    })
    .on('error', function(err) { // Handle errors
        fs.unlink(dest); // Delete the file async. (But we don't check the result)
        done(err);
    });
};

const packages = gulp.series([
    lint,
    build,
    patronsCache,
    examples,
    bakePackages
]);

const launchDevMode = done => {
    watch();
    launchApp();
    done();
};
const defaultTask = gulp.series(build, launchDevMode);


exports.lint = lint;
exports.packages = packages;
exports.build = build;
exports.default = defaultTask;
