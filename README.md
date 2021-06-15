<img src="https://raw.githubusercontent.com/moson-mo/matray/master/resources/images/matray_logo.png?inline=true"  align="left" width="120" />

# matray
## A Manjaro Linux announcements notification app (successor of mntray)
</br>

[![GitHub release](https://img.shields.io/github/v/tag/moson-mo/matray.svg?label=release&sort=semver)](https://github.com/moson-mo/matray/releases)
[![matray](https://img.shields.io/aur/version/matray?label=AUR%3A%20matray)](https://aur.archlinux.org/packages/matray/)

A small tray application showing announcements and news for [Manjaro Linux](https://manjaro.org).\
It creates a tray icon with a menu showing the latest announcements from the Manjaro Forum RSS feed & "manjarolinux" twitter account.

This project is the successor of [mntray](https://github.com/moson-mo/matray) and has been re-developed in [Vala](https://wiki.gnome.org/Projects/Vala).\
[Gtk](https://www.gtk.org/) serves as a basis for the GUI part.\
Main reason for the re-development is that qt library binding used by mntray does not seem to be maintained anymore (last commit in Sep. 2020).

Announcements are retrieved from a http server (see [mnserver](https://github.com/moson-mo/mnserver/)) via post request.

Why is it connecting to a server application rather then parsing the RSS feed directly?\
The RSS feed can be quite large (around 300 to 500 KB).\
Instead of downloading this file from the Manjaro forums host on a regular basis, it fetches news from mnserver.\
There's much less data to be transferred and less burden on the forum host and client since the data is stripped down to the bare minimum.
</br>

## How to build

* Make sure all [dependencies](https://github.com/moson-mo/matray#dependencies) are installed
* Download this package with: `git clone https://github.com/moson-mo/matray`
* Change to package dir: `cd matray`
* Build: `meson build && ninja -C build`
* The binary will be in the `build` dir
</br>

## How to install

For Arch-based distributions there is an [AUR package](https://aur.archlinux.org/packages/matray/) available.
</br>

## Configuration

On the first startup, a config file (`~/.config/matray/config.json`) is created with some default settings.
You can either use the GUI to change the configuration (open "Settings" from the menu) or edit the config file.

```
{
	"Version": "1.0.0"
	"ServerURL": "http://manjaro.moson.eu:10111/news",
	"MaxArticles": 15,
	"AvailableCategories" : [
        "Testing Updates",
        "Stable Updates",
        "Stable Staging Updates",
        "Unstable Updates",
        "Twitter",
        "News",
        "Announcements",
        "Releases",
        "ARM News",
        "ARM Releases",
        "ARM Stable Updates",
        "ARM Testing Updates",
        "ARM Unstable Updates"
    ],
	"Categories" : [
        "Stable Updates",
        "News",
        "Announcements",
        "Releases"
    ],
	"AddCategoriesBranch" : [
        "News",
        "Announcements",
        "Releases"
    ],
	"RefreshInterval": 600,
	"HideNoNews": false,
	"Autostart": true,
	"ErrorNotifications": true,
	"DelayAfterStart": 15,
	"SetCategoriesFromBranch": true,
    "IconTheme" : "Bright"
}
```

Option | Description
--- | ---
Version| Version number. Do not change!|
URL| WebSocket URL of the mnservice server|
MaxArticles| The maximum number of articles to retrieve / show in the menu|
AvailableCategories| The categories that available for subscription. Do not change!|
Categories| The categories you want to get announcements for</br>Remove unwanted categories if needed</br></br>**note:* Is ignored when SetCategoriesFromBranch is "true"|
AddCategoriesBranch| The categories you want to get announcements for</br>additional to the branch you are using</br></br>**note:* Is ignored when SetCategoriesFromBranch is "false"|
RefreshInterval| The interval (in seconds) in which matray will check for new articles|
Autostart| Places a .desktop file in the users autostart folder when "true"|
HideNoNews| When set to "true", the tray icon is hidden when all news have been read</br></br>**note:* Does not work reliably on GNOME & KDE. See "Known issues"|
ErrorNotifications| Show a notification in case articles can not be retrieved (f.e. network down)|
DelayAfterStart| Delays checking for news articles after startup (in seconds), f.e. wait for network to be up.</br></br> **note:* This setting only takes effect when matray is started with parameter "--delay"|
SetCategoriesFromBranch| If "true", it auto-detects the Manjaro branch and filters categories accordingly (f.e. "Stable Updates" & "Announcements")</br></br>|
IconTheme| The color of the tray icon. Can be "Bright", "Dark", "Colorful" or "System"</br></br>|

</br>

## Dependencies

* gtk3
* glib2
* json-glib
* libappindicator-gtk3
* libgee
* libsoup
</br>

#### Build dependencies

* meson
* ninja
* vala
</br>

## Screenshots

#### Tray icon / menu

![xfce menu](https://github.com/moson-mo/matray/raw/master/screenshots/xfce_menu.png?inline=true)
![kde menu](https://github.com/moson-mo/matray/raw/master/screenshots/kde_menu.png?inline=true)
![gnome menu](https://github.com/moson-mo/matray/raw/master/screenshots/gnome_menu.png?inline=true)
</br>

#### Notifications

![xfce notification](https://github.com/moson-mo/matray/raw/master/screenshots/xfce_notification.png?inline=true)
![kde notification](https://github.com/moson-mo/matray/raw/master/screenshots/kde_notification.png?inline=true)
![gnome notification](https://github.com/moson-mo/matray/raw/master/screenshots/gnome_notification.png?inline=true)
</br>

#### Settings dialog

![xfce settings](https://github.com/moson-mo/matray/raw/master/screenshots/xfce_settings.png?inline=true)
![kde settings](https://github.com/moson-mo/matray/raw/master/screenshots/kde_settings.png?inline=true)
![gnome settings](https://github.com/moson-mo/matray/raw/master/screenshots/gnome_settings.png?inline=true)
</br>

## Thanks to

* The Manjaro Team for the great distro
* The Manjaro community for testing and feedback
* [SGS](https://github.com/sgse) for providing the app logo
* The ones I forgot to mention here :)
</br>

