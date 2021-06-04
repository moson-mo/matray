project('matray', 'vala', 'c')

gnome = import('gnome')

deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-unix-2.0'),
    dependency('gee-0.8'),
    dependency('gtk+-3.0'),
    dependency('libsoup-2.4'),
    dependency('json-glib-1.0'),
    dependency('appindicator3-0.1')
]

src = files([
    'src/main.vala',
    'src/ui/SettingsWindow.vala',
    'src/ui/AboutWindow.vala',
    'src/ui/TrayIcon.vala',
    'src/NewsReader.vala',
    'src/Settings.vala',
    'src/Enums.vala',
    'src/data/NewsItem.vala',
    'src/data/Config.vala',
    'src/data/Request.vala',
    'src/data/ItemCollection.vala'
])

resources = gnome.compile_resources('ui', 'resources/ui.gresource.xml', source_dir: 'resources')

subdir('po')

executable(
    'matray',
    resources,
    dependencies: deps,
    sources: src,
    vala_args: ['--pkg=posix'],
    install: true
)
