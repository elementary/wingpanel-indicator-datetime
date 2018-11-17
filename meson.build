project(
    'datetime',
    'vala', 'c',
    version: '2.1.2'
)

i18n = import('i18n')
gettext_name = meson.project_name() + '-indicator'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

wingpanel_dep = dependency('wingpanel-2.0')

shared_module(
    meson.project_name(),
    'src/DateRange.vala',
    'src/Indicator.vala',
    'src/Widgets/PanelLabel.vala',
    'src/Widgets/calendar/Calendar.vala',
    'src/Widgets/calendar/CalendarModel.vala',
    'src/Widgets/calendar/CalendarView.vala',
    'src/Widgets/calendar/ControlHeader.vala',
    'src/Widgets/calendar/Grid.vala',
    'src/Widgets/calendar/GridDay.vala',
    'src/Widgets/calendar/Header.vala',
    'src/Widgets/calendar/Util.vala',
    'src/Widgets/calendar/WeekLabels.vala',
    'src/Services/SettingsManager.vala',
    'src/Services/TimeManager.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libecal-1.2'),
        dependency('libedataserver-1.2'),
        dependency('libical'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
